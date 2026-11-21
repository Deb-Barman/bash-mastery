#!/usr/bin/env bash
# ==========================================================
# Lesson 23 - Code.sh
# Five real tools, written to files and run on sample data:
#   1) backup.sh      archive + verify + rotate (with dry-run)
#   2) logsum.sh      web-log analyzer (awk pipelines)
#   3) organize.sh    sort a messy folder by file type
#   4) newproject.sh  project scaffolder (+ git init)
#   5) deploy.sh      pull-based deploy from a local git repo
# Run   : bash Code.sh
# Safe  : everything happens inside
#         ~/bash-practice/lesson23-demo (cleaned up after).
# Needs : Bash 4+, tar, awk; git for tools 4 and 5.
# TIP   : comment out the CLEANUP at the bottom to keep the
#         scripts and use them in your own projects!
# ==========================================================

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This lesson needs Bash 4 or newer (you have $BASH_VERSION)."
    exit 1
fi

DEMO="$HOME/bash-practice/lesson23-demo"
if [ -d "$DEMO" ]; then
    rm -rf "$DEMO"
fi
mkdir -p "$DEMO/tools"
cd "$DEMO" || exit 1

# ==========================================================
# TOOL 1: backup.sh
# ==========================================================
cat > tools/backup.sh << 'EOF'
#!/usr/bin/env bash
# backup.sh - archive a folder, verify the archive, keep only the newest N copies
# Usage: backup.sh [-n] [-k KEEP] [-d DEST] SRC
set -euo pipefail

usage() {
    cat << USAGE
Usage: ${0##*/} [-n] [-k KEEP] [-d DEST] SRC
  -n         dry run: show what would happen, change nothing
  -k KEEP    how many backups to keep (default 3)
  -d DEST    destination folder (default ./backups)
  -h         this help
USAGE
}
die() { echo "${0##*/}: $*" >&2; exit 1; }
log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*"; }

dry=0
keep=3
dest=./backups
while getopts ":nk:d:h" opt; do
    case "$opt" in
        n)  dry=1 ;;
        k)  keep=$OPTARG ;;
        d)  dest=$OPTARG ;;
        h)  usage; exit 0 ;;
        :)  die "option -$OPTARG needs a value" ;;
        \?) die "unknown option -$OPTARG" ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
src=${1%/}
[[ -d $src ]] || die "not a folder: $src"
[[ $keep =~ ^[0-9]+$ ]] && (( keep >= 1 )) || die "-k must be a whole number >= 1"

name=$(basename "$src")
stamp=$(date +%Y%m%d-%H%M%S)
archive="$dest/$name-$stamp.tar.gz"

run() {
    if (( dry )); then
        log "[dry-run] $*"
    else
        "$@"
    fi
}

run mkdir -p "$dest"
log "backing up $src -> $archive"

if (( dry )); then
    log "[dry-run] tar -czf $archive -C $(dirname "$src") $name"
else
    tmp=$(mktemp "$dest/.partial.XXXXXX")
    trap 'rm -f "$tmp"' EXIT              # never leave a half-written archive behind
    tar -czf "$tmp" -C "$(dirname "$src")" "$name"
    tar -tzf "$tmp" > /dev/null || die "archive failed verification"
    mv -- "$tmp" "$archive"               # appears only when complete (atomic)
    trap - EXIT
    log "created $(basename "$archive") ($(du -h "$archive" | cut -f1))"
fi

# rotation: names contain the timestamp, so alphabetical order = oldest first
shopt -s nullglob
backups=( "$dest/$name"-*.tar.gz )
excess=$(( ${#backups[@]} - keep ))
if (( excess > 0 )); then
    for old in "${backups[@]:0:excess}"; do
        run rm -v -- "$old"
    done
fi
log "done (${#backups[@]} backup(s) before rotation, keeping $keep)"
EOF

# ==========================================================
# TOOL 2: logsum.sh
# ==========================================================
cat > tools/logsum.sh << 'EOF'
#!/usr/bin/env bash
# logsum.sh - summarize a web server access log
# Usage: logsum.sh LOGFILE
set -euo pipefail

[[ $# -eq 1 && -r $1 ]] || { echo "Usage: ${0##*/} LOGFILE" >&2; exit 2; }
f=$1

echo "=== Summary of $f ==="
echo "Total requests : $(wc -l < "$f")"
echo "Bytes served   : $(awk '{s += $10} END {print s + 0}' "$f")"
echo "Server errors  : $(awk '$9 ~ /^5/ {n++} END {print n + 0}' "$f")  (status 5xx)"

echo "--- status codes ---"
awk '{print $9}' "$f" | sort | uniq -c | sort -rn | awk '{printf "  %s : %s\n", $2, $1}'

echo "--- top 3 visitors ---"
awk '{print $1}' "$f" | sort | uniq -c | sort -rn | head -n 3 | awk '{printf "  %-15s %s requests\n", $2, $1}'

echo "--- top 3 pages ---"
awk '{print $7}' "$f" | sort | uniq -c | sort -rn | head -n 3 | awk '{printf "  %-15s %s hits\n", $2, $1}'

echo "--- requests per hour ---"
awk '{h = substr($4, 14, 2); c[h]++} END {for (k in c) print k, c[k]}' "$f" | sort | awk '{printf "  %s:00  %s\n", $1, $2}'

echo "--- not found (404) pages ---"
awk '$9 == 404 {print $7}' "$f" | sort | uniq -c | sort -rn | awk '{printf "  %-15s %s\n", $2, $1}'
EOF

# ==========================================================
# TOOL 3: organize.sh
# ==========================================================
cat > tools/organize.sh << 'EOF'
#!/usr/bin/env bash
# organize.sh - move files into folders by type
# Usage: organize.sh [-n] DIR
set -euo pipefail

usage() { echo "Usage: ${0##*/} [-n] DIR   (-n = dry run)" >&2; exit 2; }

dry=0
while getopts ":n" opt; do
    case "$opt" in
        n) dry=1 ;;
        *) usage ;;
    esac
done
shift $(( OPTIND - 1 ))
[[ $# -eq 1 && -d $1 ]] || usage
dir=${1%/}

category() {                       # category EXTENSION -> folder name
    case "${1,,}" in
        jpg|jpeg|png|gif|webp|svg)   echo Images ;;
        pdf|doc|docx|txt|md|odt)     echo Documents ;;
        mp3|wav|flac|m4a)            echo Audio ;;
        mp4|mkv|mov|avi)             echo Video ;;
        zip|tar|gz|tgz|7z|rar)       echo Archives ;;
        sh|py|js|c|html|css)         echo Code ;;
        *)                           echo Other ;;
    esac
}

moved=0
shopt -s nullglob
for file in "$dir"/*; do
    [[ -f $file ]] || continue                     # skip folders
    base=${file##*/}
    ext=""
    stem=$base
    suffix=""
    if [[ $base == *.* && $base != .* ]]; then
        ext=${base##*.}
        stem=${base%.*}
        suffix=".$ext"
    fi
    cat=$(category "$ext")
    target="$dir/$cat"

    newname=$base
    n=1
    while [[ -e $target/$newname ]]; do            # never overwrite: add -1, -2, ...
        newname="$stem-$n$suffix"
        n=$(( n + 1 ))
    done

    if (( dry )); then
        echo "[dry-run] $base -> $cat/$newname"
    else
        mkdir -p "$target"
        mv -- "$file" "$target/$newname"
        echo "$base -> $cat/$newname"
    fi
    moved=$(( moved + 1 ))                         # NOT (( moved++ )): that returns 1 when moved=0 and set -e would stop us
done
echo "Done: $moved file(s) $( (( dry )) && echo 'would be moved' || echo moved )."
EOF

# ==========================================================
# TOOL 4: newproject.sh
# ==========================================================
cat > tools/newproject.sh << 'EOF'
#!/usr/bin/env bash
# newproject.sh - create a project skeleton
# Usage: newproject.sh [-t bash|python] NAME
set -euo pipefail

usage() { echo "Usage: ${0##*/} [-t bash|python] NAME" >&2; exit 2; }

type=bash
while getopts ":t:" opt; do
    case "$opt" in
        t) type=$OPTARG ;;
        *) usage ;;
    esac
done
shift $(( OPTIND - 1 ))
[[ $# -eq 1 ]] || usage
name=$1
[[ $name =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Invalid project name: $name" >&2; exit 2; }
[[ $type == bash || $type == python ]] || { echo "Unknown type: $type" >&2; exit 2; }
[[ ! -e $name ]] || { echo "Already exists: $name" >&2; exit 1; }

mkdir -p "$name"/{src,tests,docs}

cat > "$name/README.md" << MD
# $name

A $type project created by newproject.sh on $(date +%F).

## Run

\`\`\`
./src/main.$([[ $type == bash ]] && echo sh || echo py)
\`\`\`
MD

printf '*.log\n*.tmp\n.env\n__pycache__/\nbackups/\n' > "$name/.gitignore"

if [[ $type == bash ]]; then
    cat > "$name/src/main.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail

main() {
    echo "Hello from the new project!"
}

main "$@"
SH
    cat > "$name/tests/test_main.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
out=$("$(dirname "$0")/../src/main.sh")
[[ $out == "Hello from the new project!" ]] && echo "PASS" || { echo "FAIL: $out"; exit 1; }
SH
    chmod +x "$name/src/main.sh" "$name/tests/test_main.sh"
else
    printf '#!/usr/bin/env python3\nprint("Hello from the new project!")\n' > "$name/src/main.py"
    chmod +x "$name/src/main.py"
fi

if command -v git > /dev/null 2>&1; then
    git -C "$name" init -q
    git -C "$name" add .
    git -C "$name" -c user.name="newproject" -c user.email="newproject@example.com" commit -q -m "Initial commit"
    echo "git repository created with one commit"
fi
echo "Created $name/"
EOF

# ==========================================================
# TOOL 5: deploy.sh
# ==========================================================
cat > tools/deploy.sh << 'EOF'
#!/usr/bin/env bash
# deploy.sh - clone or update a checkout from a git repository, then run its build hook
# Usage: deploy.sh REPO TARGET
set -euo pipefail

[[ $# -eq 2 ]] || { echo "Usage: ${0##*/} REPO TARGET" >&2; exit 2; }
repo=$1
target=$2

if [[ ! -d $target/.git ]]; then
    git clone -q "$repo" "$target"
    echo "cloned into $target at $(git -C "$target" rev-parse --short HEAD)"
else
    before=$(git -C "$target" rev-parse --short HEAD)
    git -C "$target" pull -q --ff-only
    after=$(git -C "$target" rev-parse --short HEAD)
    if [[ $before == "$after" ]]; then
        echo "already up to date ($after)"
    else
        echo "updated $before -> $after"
        git -C "$target" diff --stat "$before" "$after" | sed 's/^/   /'
    fi
fi

if [[ -x $target/build.sh ]]; then
    echo "running build hook..."
    ( cd "$target" && ./build.sh )
fi
EOF
chmod +x tools/*.sh

# ==========================================================
# DEMO 1: backup
# ==========================================================
echo "== Tool 1: backup.sh =="
mkdir -p mydata
echo "chapter one" > mydata/book.txt
echo "chapter two" > mydata/book2.txt
echo "-- dry run first (nothing is changed) --"
tools/backup.sh -n -d backups mydata
echo "backups folder exists? $([[ -d backups ]] && echo yes || echo no)"
echo "-- four real runs, keeping the 2 newest (rotation) --"
for i in 1 2 3 4; do
    tools/backup.sh -k 2 -d backups mydata | tail -n 3
    sleep 1                                  # timestamps have 1-second resolution
done
echo "-- what is left --"
ls backups
echo "-- the newest archive's contents --"
tar -tzf "backups/$(ls backups | tail -n 1)"
echo "-- error handling --"
tools/backup.sh -d backups nosuchfolder || echo "(exit status $?)"
tools/backup.sh -k 0 mydata || echo "(exit status $?)"
echo ""

# ==========================================================
# DEMO 2: log analyzer
# ==========================================================
echo "== Tool 2: logsum.sh =="
cat > access.log << 'EOF'
192.168.1.10 - - [10/Oct/2026:09:15:01 +0000] "GET /index.html HTTP/1.1" 200 1024
192.168.1.10 - - [10/Oct/2026:09:15:03 +0000] "GET /style.css HTTP/1.1" 200 512
10.0.0.5 - - [10/Oct/2026:09:20:11 +0000] "GET /index.html HTTP/1.1" 200 1024
10.0.0.5 - - [10/Oct/2026:09:21:45 +0000] "GET /missing.html HTTP/1.1" 404 128
172.16.0.9 - - [10/Oct/2026:10:02:19 +0000] "POST /login HTTP/1.1" 302 0
172.16.0.9 - - [10/Oct/2026:10:02:20 +0000] "GET /dashboard HTTP/1.1" 200 4096
192.168.1.10 - - [10/Oct/2026:10:30:00 +0000] "GET /api/data HTTP/1.1" 500 64
192.168.1.10 - - [10/Oct/2026:10:30:05 +0000] "GET /api/data HTTP/1.1" 500 64
10.0.0.5 - - [10/Oct/2026:11:05:40 +0000] "GET /index.html HTTP/1.1" 200 1024
8.8.4.4 - - [10/Oct/2026:11:06:00 +0000] "GET /missing.html HTTP/1.1" 404 128
8.8.4.4 - - [10/Oct/2026:11:06:02 +0000] "GET /secret HTTP/1.1" 404 128
192.168.1.10 - - [10/Oct/2026:11:45:12 +0000] "GET /index.html HTTP/1.1" 200 1024
EOF
tools/logsum.sh access.log
echo ""

# ==========================================================
# DEMO 3: file organizer
# ==========================================================
echo "== Tool 3: organize.sh =="
mkdir -p downloads
touch downloads/{holiday.jpg,Photo.PNG,report.pdf,notes.txt,song.mp3,movie.mkv,backup.zip,script.sh,README,weird.xyz}
touch downloads/notes2.txt
echo "other" > downloads/Notes.TXT
mkdir downloads/keep-this-folder
echo "-- before --"
ls downloads | sed 's/^/   /'
echo "-- dry run --"
tools/organize.sh -n downloads
echo "-- real run --"
tools/organize.sh downloads > /dev/null
echo "-- after --"
find downloads -type f | sort | sed 's/^/   /'
echo "-- a NEW notes.txt arrives; Documents/notes.txt already exists (a real name clash) --"
echo "newer notes" > downloads/notes.txt
tools/organize.sh downloads
ls downloads/Documents | sed 's/^/   /'
echo "-- nothing was overwritten: the newcomer became notes-1.txt --"
echo ""

# ==========================================================
# DEMO 4: project scaffolder
# ==========================================================
echo "== Tool 4: newproject.sh =="
tools/newproject.sh -t bash hello-tool
echo "-- the tree --"
find hello-tool -path '*/.git' -prune -o -print | sort | sed 's/^/   /'
echo "-- run its test --"
hello-tool/tests/test_main.sh
if command -v git > /dev/null 2>&1; then
    echo "-- git log --"
    git -C hello-tool log --oneline | sed 's/^/   /'
fi
echo "-- errors --"
tools/newproject.sh -t bash hello-tool || echo "(exit status $?)"
tools/newproject.sh 'bad name!' || echo "(exit status $?)"
echo ""

# ==========================================================
# DEMO 5: deploy
# ==========================================================
echo "== Tool 5: deploy.sh =="
if ! command -v git > /dev/null 2>&1; then
    echo "git is not installed: skipping this demo."
else
    GITID=(-c user.name=demo -c user.email=demo@example.com)
    git init -q --bare origin.git
    git -C origin.git symbolic-ref HEAD refs/heads/main
    git init -q dev
    echo 'echo "build step: version 1"' > dev/build.sh
    chmod +x dev/build.sh
    echo "v1" > dev/VERSION
    git -C dev add .
    git -C dev "${GITID[@]}" commit -q -m "version 1"
    git -C dev branch -M main
    git -C dev remote add origin "$DEMO/origin.git"
    git -C dev push -q origin main

    echo "-- first deploy (clone) --"
    tools/deploy.sh "$DEMO/origin.git" prod
    echo "-- deploy again, nothing changed --"
    tools/deploy.sh "$DEMO/origin.git" prod
    echo "-- developer pushes version 2 --"
    echo "v2" > dev/VERSION
    echo 'echo "build step: version 2"' > dev/build.sh
    git -C dev add .
    git -C dev "${GITID[@]}" commit -q -m "version 2"
    git -C dev push -q origin main
    echo "-- deploy picks up the change --"
    tools/deploy.sh "$DEMO/origin.git" prod
    echo "production now serves: $(cat prod/VERSION)"
fi
echo ""

# ==========================================================
# CLEANUP (comment these lines out to keep the tools!)
# ==========================================================
cd "$HOME" || exit 1
rm -rf "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

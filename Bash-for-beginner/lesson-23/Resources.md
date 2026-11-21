# Lesson 23 — Resources

## 📋 Cheat Sheet: patterns used in the five tools

| Need | Pattern |
|------|---------|
| script header | `#!/usr/bin/env bash` · `set -euo pipefail` |
| usage + errors | `usage() { cat << EOF … EOF; }` · `die() { echo "${0##*/}: $*" >&2; exit 1; }` |
| options | `getopts ":nk:d:h" opt` · `shift $((OPTIND-1))` |
| dry run | `run() { if (( dry )); then echo "[dry-run] $*"; else "$@"; fi; }` |
| validate number | `[[ $x =~ ^[0-9]+$ ]] && (( x >= 1 ))` |
| safe write | `tmp=$(mktemp …); … > "$tmp"; mv -- "$tmp" "$final"` |
| cleanup | `trap 'rm -f "$tmp"' EXIT` |
| timestamp name | `date +%Y%m%d-%H%M%S` (sorts by name) |
| rotate | `files=( "$dir"/name-*.ext )` · `"${files[@]:0:excess}"` |
| no overwrite | `while [[ -e $t/$n ]]; do n="$stem-$i$suffix"; i=$((i+1)); done` |
| counter under `set -e` | `n=$(( n + 1 ))` (not `(( n++ ))`) |
| frequency table | `awk '{print $1}' f \| sort \| uniq -c \| sort -rn \| head` |
| subshell for `cd` | `( cd "$dir" && ./build.sh )` |
| git without identity | `git -c user.name=x -c user.email=y commit …` |
| fast-forward only | `git pull --ff-only` |

---

## 🏋️ Exercises

Work in `~/bash-practice/ex23`. **Test on sandbox data. Always dry-run first.**

**Level A: Guided changes to the lesson tools** (run `Code.sh` with cleanup commented out first)
1. Make `backup.sh` print the archive size in **bytes** too (hint: `stat -c %s`).
2. Add a `Fonts` category (`ttf`, `otf`, `woff`) to `organize.sh`.
3. Make `logsum.sh` show the **top 5** pages, not 3.
4. Make `newproject.sh` add a `LICENSE` file containing `MIT` plus the current year.

**Level B: Small new tools**
5. `old-files.sh DIR DAYS`: list files in DIR older than DAYS days (`find … -mtime +N`), with the size of each and a total count. Print only, never delete.
6. `dup-finder.sh DIR`: list files with identical content (hash with `sha256sum`, group with `sort | uniq -w64 -D`).
7. `disk-watch.sh [-t PERCENT]`: print a warning for every mounted filesystem above PERCENT (default 85) using `df -P`; exit 1 if any warning was printed.
8. `git-status-all.sh DIR`: for every sub-folder that is a git repository, print `clean` or `DIRTY` with the repository name.
9. `photo-renamer.sh -n DIR`: rename `*.jpg` files to `YYYY-MM-DD_HHMMSS.jpg` using the file's modification time (`stat -c %y` or `date -r`). Dry run first; clash-safe.

**Level C: Capstone (pick one, build it fully, 2 to 4 hours)**
10. Choose a tool from Section 8 of the lesson (or your own idea) and deliver:
    - the usage message written **first**
    - `-h`, argument validation, clear errors, exit codes
    - a **dry-run** switch for destructive steps
    - logging with timestamps
    - sandbox test data and a **test script** (see Lesson 24) with at least 5 test cases
    - `shellcheck` clean (if available)
    - a README with examples
11. (Think!) Why does `backup.sh` write to a temp file and `mv` it, instead of writing directly to the final name?
12. (Think!) What could go wrong if `organize.sh` ran **without** the clash check? Which two lines prevent it?
13. (Think!) Why does `deploy.sh` use `--ff-only`?

---

## ✅ Answers (selected)

<details>
<summary>Click only after trying!</summary>

```bash
# 1
bytes=$(stat -c %s "$archive")
log "created $(basename "$archive") ($(du -h "$archive" | cut -f1), $bytes bytes)"

# 2
#   ttf|otf|woff|woff2)  echo Fonts ;;     (add a line in category())

# 3
# change   head -n 3   to   head -n 5   in the "top pages" pipeline

# 4
printf 'MIT License\n\nCopyright (c) %s\n' "$(date +%Y)" > "$name/LICENSE"

# 5  old-files.sh
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 2 && -d $1 && $2 =~ ^[0-9]+$ ]] || { echo "Usage: ${0##*/} DIR DAYS" >&2; exit 2; }
count=0
while IFS= read -r -d '' f; do
    printf '%8s  %s\n' "$(du -h "$f" | cut -f1)" "$f"
    count=$(( count + 1 ))
done < <(find "$1" -type f -mtime +"$2" -print0)
echo "$count file(s) older than $2 days"

# 6  dup-finder.sh
#!/usr/bin/env bash
find "$1" -type f -print0 | xargs -0 sha256sum | sort | uniq -w64 -D
# prints every file whose hash appears more than once (same hash = same content)

# 7  disk-watch.sh
#!/usr/bin/env bash
limit=85
while getopts ":t:" o; do case "$o" in t) limit=$OPTARG ;; *) exit 2 ;; esac; done
warned=0
while read -r fs size used avail pct mount; do
    pct=${pct%\%}
    if (( pct >= limit )); then
        echo "WARNING: $mount is ${pct}% full ($fs)"
        warned=1
    fi
done < <(df -P | tail -n +2)
exit "$warned"

# 8  git-status-all.sh
#!/usr/bin/env bash
for d in "${1:-.}"/*/; do
    [[ -d $d/.git ]] || continue
    if [[ -z $(git -C "$d" status --porcelain) ]]; then
        echo "clean  $(basename "$d")"
    else
        echo "DIRTY  $(basename "$d")"
    fi
done

# 9  photo-renamer.sh  (core of the loop)
for f in "$dir"/*.jpg; do
    [[ -f $f ]] || continue
    new="$(date -r "$f" +%Y-%m-%d_%H%M%S).jpg"
    n=1
    while [[ -e $dir/$new ]]; do new="$(date -r "$f" +%Y-%m-%d_%H%M%S)-$n.jpg"; n=$((n+1)); done
    if (( dry )); then echo "[dry-run] ${f##*/} -> $new"; else mv -- "$f" "$dir/$new"; fi
done

# 11
# If tar is interrupted (Ctrl+C, full disk, crash), a partly written file would
# sit under the real name and look like a valid backup. With temp file + mv
# (atomic on one filesystem), the final name only ever refers to a COMPLETE
# archive, and the trap removes the leftover temp file.

# 12
# Files with the same name would overwrite each other (data loss). The
# `while [[ -e $target/$newname ]]` loop and the `-N` suffix prevent it.

# 13
# --ff-only refuses anything but a clean fast-forward. If someone edited files on
# the server, or history diverged, the deploy FAILS loudly instead of silently
# creating merge commits or overwriting local changes.
```

</details>

---

## 🐞 Common beginner errors (in bigger scripts)

| Symptom | Cause | Fix |
|---------|-------|-----|
| script dies silently mid-way | `set -e` + `(( n++ ))` / unguarded `grep` | `n=$((n+1))`, `\|\| true`, `if grep -q` |
| `unbound variable` | typo or optional argument under `set -u` | `${1:-}` and defaults |
| two runs in the same second collide | timestamp resolution | include more precision, or sleep, or `mktemp -d` |
| data lost by `mv` | no clash check | `[[ -e ]]` loop |
| huge `rm` accident | no dry run / unvalidated variable | `-n`, `${VAR:?}`, validate |
| works only in one folder | relative paths | `cd "$(dirname "$0")"` or absolute paths |
| `git commit` fails: "Please tell me who you are" | no identity configured | `git -c user.name=… -c user.email=…` |
| `tar` archive contains absolute paths | wrong `-C`/path usage | `tar -C parent folder` |
| `mktemp` file left behind | no trap | `trap 'rm -f "$tmp"' EXIT` |
| tool breaks on file names with spaces | unquoted variables / `ls` parsing | quote everything, use globs and `-print0` |

---

## 💡 Habits of pro coders

1. **Interface first, code second.** Write the usage message before the logic.
2. **Dry-run is a feature, not an afterthought.**
3. **Make a sandbox** with fake data before touching real data. Keep it in the repository as test data.
4. **Fail loudly and early;** validate inputs at the top.
5. **Never destroy before you have created.** Create the new backup, verify, *then* rotate the old ones.
6. **Small functions, clear names, comments that explain *why*.**
7. **One tool, one job**, and compose tools with pipes/cron.
8. **Version-control your scripts** (`git init ~/bin`).

## 📚 Extra resources

- **Google Shell Style Guide** (google.github.io/styleguide/shellguide.html)
- **mywiki.wooledge.org/BashGuide** and **/BashPitfalls**
- **github.com/awesome-lists/awesome-bash** and **github.com/dylanaraps/pure-bash-bible**: ideas and tricks
- **Pro Git** book (git-scm.com/book): free, for Tool 4 and Tool 5
- **`man tar`**, **`man find`**, **`man awk`**, **`man git`**

## 🧠 Self-check

1. What is the 8-step method for building a tool?
2. How does `backup.sh` guarantee that a crashed run never leaves a corrupt backup?
3. How does `organize.sh` avoid overwriting files?
4. How do you produce a frequency table with `awk`, `sort` and `uniq`?
5. What does `git pull --ff-only` protect you from?
6. Why does every tool support a dry run?

## ➡️ Next: Lesson 24 — Mastery (debugging, performance, portability, testing, security, style)

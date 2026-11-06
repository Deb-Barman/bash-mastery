#!/usr/bin/env bash
# ==========================================================
# Lesson 17 - Code.sh
# Topic : set -e / -u / pipefail, their traps, trap EXIT/ERR/
#         TERM, mktemp, retry, timeout, lock, dry-run, atomic write
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson17-demo
#         and cleans up after itself.
# Why helper scripts? set -e would stop THIS script at the first
# failure, so each experiment runs in its own small script.
# ==========================================================

DEMO="$HOME/bash-practice/lesson17-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# run_demo FILE  -> runs the helper, prints its output and exit status
run_demo() {
    bash "$1" 2>&1 | sed 's/^/    | /'
    echo "    => exit status: ${PIPESTATUS[0]}"
}

# --- PART 1: default behaviour -----------------------------
echo "== Part 1: by default Bash keeps going after an error =="
cat > p1.sh << 'EOF'
echo "step 1"
false
echo "step 2 still runs after a failure"
EOF
run_demo p1.sh
echo ""

# --- PART 2: set -e ----------------------------------------
echo "== Part 2: set -e stops at the first failure =="
cat > p2.sh << 'EOF'
set -e
echo "step 1"
false
echo "step 2 (never printed)"
EOF
run_demo p2.sh
echo ""

# --- PART 3: set -u ----------------------------------------
echo "== Part 3: set -u catches unset variables =="
cat > p3.sh << 'EOF'
set -u
backup_dir="/backup"
echo "Deleting $backup_dri/old"      # typo: backup_dri
echo "never printed"
EOF
run_demo p3.sh
echo ""

# --- PART 4: pipefail --------------------------------------
echo "== Part 4: set -o pipefail =="
cat > p4.sh << 'EOF'
false | true
echo "without pipefail: status of 'false | true' = $?"
set -o pipefail
false | true
echo "with    pipefail: status of 'false | true' = $?"
EOF
run_demo p4.sh
echo ""

# --- PART 5: set -e traps ----------------------------------
echo "== Part 5: traps of set -e =="
echo "-- trap 1: (( count++ )) from 0 returns status 1 --"
cat > p5a.sh << 'EOF'
set -e
count=0
(( count++ ))
echo "never printed (the script already exited)"
EOF
run_demo p5a.sh
echo "-- the safe versions --"
cat > p5b.sh << 'EOF'
set -e
count=0
(( count += 1 ))
count=$(( count + 1 ))
echo "safe: count = $count"
EOF
run_demo p5b.sh
echo "-- trap 2: grep finds nothing = status 1 --"
cat > p5c.sh << 'EOF'
set -e
echo "searching..."
grep "needle" /etc/hostname
echo "never printed"
EOF
run_demo p5c.sh
echo "-- the safe versions: || true  and  if grep -q --"
cat > p5d.sh << 'EOF'
set -e
grep "needle" /etc/hostname || true
if grep -q "needle" /etc/hostname; then echo "found"; else echo "not found (handled)"; fi
echo "script continues normally"
EOF
run_demo p5d.sh
echo "-- trap 3: set -e is ignored in conditions and before && / || --"
cat > p5e.sh << 'EOF'
set -e
false || echo "left of || : set -e did NOT stop us"
if false; then :; fi
echo "after the if: still running"
false && echo "never"
echo "after 'false && ...': still running (only the LAST command of a && list counts)"
EOF
run_demo p5e.sh
echo ""

# --- PART 6: explicit handling -----------------------------
echo "== Part 6: explicit error handling =="
cat > p6.sh << 'EOF'
die() { echo "ERROR: $*" >&2; exit 1; }
dir=/definitely/not/here
cd "$dir" || die "cannot enter $dir"
echo "never printed"
EOF
run_demo p6.sh
echo ""

# --- PART 7: trap EXIT with mktemp -------------------------
echo "== Part 7: trap cleanup EXIT + mktemp =="
cat > p7.sh << 'EOF'
set -e
tmpdir=$(mktemp -d)
cleanup() {
    echo "cleanup: removing $tmpdir"
    rm -rf "$tmpdir"
}
trap cleanup EXIT
echo "working in a private temp folder"
echo "data" > "$tmpdir/work.txt"
[[ -f $tmpdir/work.txt ]] && echo "temp file exists: yes"
echo "now something FAILS..."
false
echo "never printed"
EOF
run_demo p7.sh
echo ""

# --- PART 8: trap ERR with line numbers --------------------
echo "== Part 8: trap ERR shows WHERE it failed =="
cat > p8.sh << 'EOF'
set -eE
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND (status $?)" >&2' ERR
echo "line 3 fine"
ls /definitely/not/here
echo "never printed"
EOF
run_demo p8.sh
echo ""

# --- PART 9: trap TERM / INT -------------------------------
echo "== Part 9: trap TERM (the script sends the signal to itself) =="
cat > p9.sh << 'EOF'
trap 'echo "caught TERM, cleaning up"; exit 143' TERM
echo "running... now I receive a TERM signal"
kill -TERM $$
echo "never printed"
EOF
run_demo p9.sh
echo "(143 = 128 + 15, the convention for 'killed by TERM')"
echo ""

# --- PART 10: retry ----------------------------------------
echo "== Part 10: retry (command fails twice, then works) =="
cat > p10.sh << 'EOF'
retry() {
    local tries=$1 delay=$2 n=1
    shift 2
    until "$@"; do
        if (( n >= tries )); then
            echo "failed after $n attempts" >&2
            return 1
        fi
        echo "attempt $n failed, retrying in ${delay}s..." >&2
        sleep "$delay"
        (( n++ ))
    done
    echo "succeeded on attempt $n"
}

counter_file=$(mktemp)
echo 0 > "$counter_file"
flaky() {
    local c
    c=$(cat "$counter_file")
    echo $(( c + 1 )) > "$counter_file"
    (( c >= 2 ))                    # fails for c=0 and c=1, succeeds on the third call
}
retry 5 0 flaky
rm -f "$counter_file"
EOF
run_demo p10.sh
echo ""

# --- PART 11: timeout --------------------------------------
echo "== Part 11: timeout =="
if command -v timeout > /dev/null 2>&1; then
    timeout 1 sleep 3
    echo "    timeout exit status: $?   (124 = the command was stopped for taking too long)"
else
    echo "    (the 'timeout' command is not installed here; it ships with GNU coreutils)"
fi
echo ""

# --- PART 12: lock -----------------------------------------
echo "== Part 12: lock directory (only one copy at a time) =="
cat > p12.sh << 'EOF'
LOCK="$PWD/my.lock"
if ! mkdir "$LOCK" 2> /dev/null; then
    echo "Another copy is already running." >&2
    exit 1
fi
trap 'rmdir "$LOCK"' EXIT
echo "I got the lock"
EOF
echo "-- normal run --"
run_demo p12.sh
echo "-- pretend another copy is running (lock exists) --"
mkdir my.lock
run_demo p12.sh
rmdir my.lock
echo ""

# --- PART 13: dry-run --------------------------------------
echo "== Part 13: dry-run mode =="
cat > p13.sh << 'EOF'
DRY_RUN="${DRY_RUN:-0}"
run() {
    if (( DRY_RUN )); then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}
touch victim.txt
run rm -v victim.txt
[[ -e victim.txt ]] && echo "victim.txt still exists" || echo "victim.txt is gone"
EOF
echo "-- DRY_RUN=1 --"
DRY_RUN=1 run_demo p13.sh
echo "-- real run --"
run_demo p13.sh
echo ""

# --- PART 14: atomic write ---------------------------------
echo "== Part 14: atomic write (temp file + mv) =="
dest="report.txt"
tmp=$(mktemp "${dest}.XXXXXX")
{ echo "line 1"; echo "line 2"; } > "$tmp"
mv -- "$tmp" "$dest"
echo "    $dest now holds $(wc -l < "$dest") lines and no half-written file was ever visible"
echo ""

# --- PART 15: guards before rm -----------------------------
echo "== Part 15: guard a dangerous variable =="
cat > p15.sh << 'EOF'
set -u
unset TARGET_DIR
rm -rf -- "${TARGET_DIR:?TARGET_DIR must be set}/"*
echo "never printed"
EOF
run_demo p15.sh
echo "    (the :? guard refused to run 'rm -rf /*'. Priceless.)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

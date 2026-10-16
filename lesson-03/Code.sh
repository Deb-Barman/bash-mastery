#!/usr/bin/env bash
# ==========================================================
# Lesson 3 - Code.sh
# Topic : head, tail, wc, find, grep, and a first pipe
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson3-demo
#         and cleans up after itself.
# Note  : uses GNU `touch -d` (Linux / WSL / Git Bash).
# ==========================================================

DEMO="$HOME/bash-practice/lesson3-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO/logs" "$DEMO/notes" "$DEMO/data"
cd "$DEMO" || exit 1

# --- BUILD SAMPLE FILES ------------------------------------
# A fake log file with 12 lines
cat > logs/app.log << 'EOF'
2026-10-10 09:00:01 INFO  server started
2026-10-10 09:00:05 INFO  user deb logged in
2026-10-10 09:01:10 DEBUG cache warmed up
2026-10-10 09:02:44 ERROR database timeout
2026-10-10 09:03:00 INFO  retrying connection
2026-10-10 09:03:02 INFO  connection restored
2026-10-10 09:05:30 WARN  disk 85 percent full
2026-10-10 09:07:12 ERROR failed to send email
2026-10-10 09:08:00 INFO  user ravi logged in
2026-10-10 09:09:41 DEBUG session refreshed
2026-10-10 09:10:15 ERROR payment declined
2026-10-10 09:11:00 INFO  server healthy
EOF

# Some notes with a few TODO markers
printf 'Buy milk\nTODO: learn grep\nCall mom\n' > notes/todo.txt
printf 'Bash is fun\nTODO: practice find\nCategory of cat\nThe cat sat\n' > notes/ideas.txt
echo "Nothing special here" > notes/empty-ish.md

# An old file (40 days ago) and a 2 MB file
touch -d "40 days ago" logs/old.log
dd if=/dev/zero of=data/big.bin bs=1024 count=2048 2> /dev/null

echo "Sample files created in $DEMO"
echo ""

# --- PART 1: head and tail ---------------------------------
echo "== Part 1: head and tail =="
echo "-- first 3 lines (head -n 3) --"
head -n 3 logs/app.log
echo "-- last 2 lines (tail -n 2) --"
tail -n 2 logs/app.log
echo ""

# --- PART 2: wc ---------------------------------------------
echo "== Part 2: wc (counting) =="
echo "Lines in app.log:"
wc -l logs/app.log
echo "Words in app.log:"
wc -w logs/app.log
echo ""

# --- PART 3: find -------------------------------------------
echo "== Part 3: find =="
echo "-- all .txt files --"
find . -name "*.txt"
echo "-- all .log files --"
find . -name "*.log"
echo "-- only directories --"
find . -type d
echo "-- files bigger than 1 MB --"
find . -size +1M
echo "-- .log files older than 30 days --"
find . -name "*.log" -mtime +30
echo ""

# --- PART 4: grep -------------------------------------------
echo "== Part 4: grep =="
echo "-- lines with ERROR --"
grep "ERROR" logs/app.log
echo "-- how many ERROR lines? (-c) --"
grep -c "ERROR" logs/app.log
echo "-- ERROR lines with line numbers (-n) --"
grep -n "ERROR" logs/app.log
echo "-- everything EXCEPT DEBUG (-v), first 4 --"
grep -v "DEBUG" logs/app.log | head -n 4
echo "-- ignore case (-i): 'server' --"
grep -i "SERVER" logs/app.log
echo ""

# --- PART 5: grep across many files ------------------------
echo "== Part 5: grep -r (search many files) =="
echo "-- every TODO, with file and line number --"
grep -rn "TODO" .
echo "-- only the NAMES of files containing TODO (-l) --"
grep -rl "TODO" .
echo "-- whole word 'cat' only (-w) --"
grep -w "cat" notes/ideas.txt
echo ""

# --- PART 6: pipes (a first taste) -------------------------
echo "== Part 6: pipes =="
echo "Number of ERROR lines (cat | grep | wc):"
cat logs/app.log | grep "ERROR" | wc -l
echo "Number of items in logs/:"
ls logs | wc -l
echo ""

# --- PART 7: find + grep together --------------------------
echo "== Part 7: find + grep together =="
echo "Which .txt files mention 'grep'?"
grep -l "grep" $(find . -name "*.txt")
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

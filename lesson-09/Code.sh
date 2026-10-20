#!/usr/bin/env bash
# ==========================================================
# Lesson 9 - Code.sh
# Topic : writing scripts, shebang, 3 ways to run, source vs
#         bash, PATH, exit codes, && ||, debugging, CRLF
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson9-demo
#         and cleans up after itself.
# This script WRITES other scripts, runs them, and explains.
# ==========================================================

DEMO="$HOME/bash-practice/lesson9-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO/bin"
cd "$DEMO" || exit 1

echo "Working in: $(pwd)"
echo ""

# --- PART 1: write a first script --------------------------
echo "== Part 1: write a script with a here-document =="
cat > hello.sh << 'EOF'
#!/usr/bin/env bash
# hello.sh - my first script
echo "Hello, $(whoami)!"
echo "Today is $(date +%A)"
EOF
echo "Created hello.sh. Its contents:"
cat hello.sh
echo ""

# --- PART 2: three ways to run -----------------------------
echo "== Part 2: three ways to run a script =="
echo "-- 1) bash hello.sh --"
bash hello.sh
echo "-- 2) ./hello.sh (before chmod +x) --"
./hello.sh 2>&1
echo "-- 2) ./hello.sh (after chmod +x) --"
chmod +x hello.sh
./hello.sh
echo "-- 3) source hello.sh --"
source ./hello.sh
echo ""

# --- PART 3: bash vs source (can a child change its parent?) --
echo "== Part 3: child process vs source =="
mkdir subfolder
cat > setvar.sh << 'EOF'
#!/usr/bin/env bash
MYVAR="hello from setvar.sh"
cd subfolder
EOF

MYVAR="(not set yet)"
echo "Before: MYVAR='$MYVAR'   folder=$(basename "$PWD")"

bash setvar.sh
echo "After 'bash setvar.sh'   : MYVAR='$MYVAR'   folder=$(basename "$PWD")"
echo "   -> nothing changed. The script ran in a CHILD and the child died."

source ./setvar.sh
echo "After 'source setvar.sh' : MYVAR='$MYVAR'   folder=$(basename "$PWD")"
echo "   -> changed! 'source' ran the commands in THIS shell."
cd "$DEMO" || exit 1
echo ""

# --- PART 4: exit codes ------------------------------------
echo "== Part 4: exit codes =="
cat > ok.sh << 'EOF'
#!/usr/bin/env bash
echo "ok.sh: everything fine"
exit 0
EOF
cat > fail.sh << 'EOF'
#!/usr/bin/env bash
echo "fail.sh: something went wrong" >&2
exit 3
EOF
chmod +x ok.sh fail.sh

./ok.sh
echo "exit code of ok.sh   : $?"
./fail.sh 2>&1
echo "exit code of fail.sh : $?"
ls /nonexistent-folder > /dev/null 2>&1
echo "exit code of failed ls: $?"
echo ""

echo "-- && runs the next command only on success --"
./ok.sh   && echo "  (this prints because ok.sh succeeded)"
./fail.sh 2> /dev/null && echo "  (you will NOT see this)"
echo "-- || runs the next command only on failure --"
./fail.sh 2> /dev/null || echo "  (this prints because fail.sh failed)"
echo "-- a handy pattern: do A, and if it fails, handle it --"
./fail.sh 2> /dev/null || { echo "  handling the failure..."; }
echo ""

# --- PART 5: PATH - run a script by name -------------------
echo "== Part 5: put a script in PATH =="
cat > bin/greet << 'EOF'
#!/usr/bin/env bash
echo "Greetings from my own command, $(whoami)!"
EOF
chmod +x bin/greet

echo "Before adding bin to PATH:"
if command -v greet > /dev/null 2>&1; then
    echo "  greet found at $(command -v greet)"
else
    echo "  'greet' is not found by name yet."
fi

export PATH="$DEMO/bin:$PATH"
echo "After export PATH=\"\$DEMO/bin:\$PATH\":"
echo "  greet found at $(command -v greet)"
greet
echo ""

# --- PART 6: a useful mini script --------------------------
echo "== Part 6: a small useful script =="
cat > report.sh << 'EOF'
#!/usr/bin/env bash
#
# report.sh - prints a short system report
# Usage: ./report.sh
#

echo "=== Quick Report ==="
echo "User    : $(whoami)"
echo "Computer: $(hostname)"
echo "Folder  : $(pwd)"
echo "Date    : $(date '+%Y-%m-%d %H:%M')"
echo "Files   : $(ls | wc -l) items here"
echo "Disk    : $(df -h . | tail -n 1 | awk '{print $4 " free of " $2}')"
exit 0
EOF
chmod +x report.sh
./report.sh
echo "(its exit code was: $?)"
echo ""

# --- PART 7: debugging -------------------------------------
echo "== Part 7: debugging tools =="
echo "-- bash -x prints each command as it runs (lines start with +) --"
bash -x hello.sh 2>&1 | head -n 6
echo ""

cat > broken.sh << 'EOF'
#!/usr/bin/env bash
if [ -f notes.txt ]; then
    echo "found it"
EOF
echo "-- bash -n checks syntax without running (broken.sh forgot 'fi') --"
bash -n broken.sh 2>&1 || echo "  (bash -n found a problem, exit code $?)"
echo ""

# --- PART 8: the Windows CRLF trap -------------------------
echo "== Part 8: CRLF line endings =="
printf '#!/usr/bin/env bash\r\necho "hi from a Windows-style file"\r\n' > crlf.sh
chmod +x crlf.sh
echo "-- running a file with CRLF line endings --"
./crlf.sh 2>&1
echo "-- the invisible culprit: carriage returns (\\r), counted: $(grep -c $'\r' crlf.sh) lines --"
tr -d '\r' < crlf.sh > fixed.sh
chmod +x fixed.sh
echo "-- after removing \\r with tr -d --"
./fixed.sh
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

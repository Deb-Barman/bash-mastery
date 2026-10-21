#!/usr/bin/env bash
# ==========================================================
# Lesson 11 - Code.sh
# Topic : arguments ($1 $# "$@" shift), defaults, usage
#         messages, validation, read, here-strings, [ -t 0 ]
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson11-demo
#         and cleans up after itself.
# This script writes small helper scripts, then runs them
# with different arguments so you can SEE how input works.
# ==========================================================

DEMO="$HOME/bash-practice/lesson11-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- BUILD THE HELPER SCRIPTS ------------------------------
cat > args.sh << 'EOF'
#!/usr/bin/env bash
echo "script name  \$0 : $0"
echo "first        \$1 : [$1]"
echo "second       \$2 : [$2]"
echo "count        \$# : $#"
echo "\"\$@\" (one per line):"
printf '  <%s>\n' "$@"
echo "\"\$*\" (one string):"
printf '  <%s>\n' "$*"
EOF

cat > shiftdemo.sh << 'EOF'
#!/usr/bin/env bash
echo "Start        : $# args -> $*"
first="$1"
shift
echo "After shift  : took [$first], $# left -> $*"
shift 2
echo "After shift 2: $# left -> [$*]"
EOF

cat > hello.sh << 'EOF'
#!/usr/bin/env bash
name="${1:-stranger}"
echo "Hello, $name!"
EOF

cat > add.sh << 'EOF'
#!/usr/bin/env bash
# add.sh - add two whole numbers
# Usage: add.sh NUM1 NUM2

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 NUM1 NUM2" >&2
    exit 2
fi

if ! [[ "$1" =~ ^-?[0-9]+$ && "$2" =~ ^-?[0-9]+$ ]]; then
    echo "Error: both arguments must be whole numbers" >&2
    exit 2
fi

echo "$1 + $2 = $(( $1 + $2 ))"
EOF

cat > each.sh << 'EOF'
#!/usr/bin/env bash
count=0
for item in "$@"; do
    count=$(( count + 1 ))
    echo "  item $count: [$item]"
done
echo "  total: $count"
EOF

cat > ask.sh << 'EOF'
#!/usr/bin/env bash
read -r -p "Your name? " name
read -r -p "Your age? " age
echo "Hello $name, next year you will be $(( age + 1 ))."
EOF

cat > confirm.sh << 'EOF'
#!/usr/bin/env bash
read -r -p "Delete everything? [y/N] " answer
if [[ "$answer" == [yY]* ]]; then
    echo "OK, deleting (just pretending!)."
else
    echo "Cancelled. Nothing was touched."
fi
EOF

cat > mkproject.sh << 'EOF'
#!/usr/bin/env bash
# mkproject.sh - create a project skeleton
# Usage: mkproject.sh NAME [PARENT_DIR]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 NAME [PARENT_DIR]" >&2
    exit 2
fi

name="$1"
parent="${2:-$PWD/projects}"
target="$parent/$name"

if [ -e "$target" ]; then
    echo "Error: $target already exists" >&2
    exit 1
fi

mkdir -p "$target"/{src,docs,tests}
echo "# $name" > "$target/README.md"
echo "Created project at: $target"
EOF
chmod +x ./*.sh
echo "Helper scripts written: $(ls *.sh | tr '\n' ' ')"
echo ""

# --- PART 1: positional parameters -------------------------
echo "== Part 1: \$0 \$1 \$2 \$# =="
echo "Running: ./args.sh Asha 25"
./args.sh Asha 25
echo ""

# --- PART 2: "$@" and quotes -------------------------------
echo "== Part 2: an argument with a space (quoting!) =="
echo "Running: ./args.sh one \"two words\" three"
./args.sh one "two words" three
echo ""
echo "Notice: \"\$@\" kept 'two words' together; \"\$*\" glued everything into ONE string."
echo ""

# --- PART 3: shift -----------------------------------------
echo "== Part 3: shift =="
echo "Running: ./shiftdemo.sh a b c d"
./shiftdemo.sh a b c d
echo ""

# --- PART 4: defaults --------------------------------------
echo "== Part 4: default values \${1:-stranger} =="
./hello.sh
./hello.sh Ravi
echo ""

# --- PART 5: usage message + validation --------------------
echo "== Part 5: usage message and validation =="
echo "-- correct use --"
./add.sh 7 5
echo "exit code: $?"
echo "-- missing argument --"
./add.sh 7
echo "exit code: $?   (2 = misuse)"
echo "-- not a number --"
./add.sh 7 apples
echo "exit code: $?"
echo ""

# --- PART 6: looping over "$@" -----------------------------
echo "== Part 6: for item in \"\$@\" (preview of Lesson 13) =="
echo "Running: ./each.sh alpha \"beta gamma\" delta"
./each.sh alpha "beta gamma" delta
echo ""

# --- PART 7: read with here-strings ------------------------
echo "== Part 7: read, with here-strings (<<<) =="
read -r first last <<< "Asha Rao"
echo "two words into two variables : first=[$first] last=[$last]"
read -r a b <<< "one two three four"
echo "extra words go to the last   : a=[$a] b=[$b]"
read -r trimmed <<< "   lots of space   "
echo "leading/trailing space trimmed: [$trimmed]"
echo ""

# --- PART 8: scripts that ask questions --------------------
echo "== Part 8: scripts that ask questions =="
echo "Real use: you type the answers. Here we feed them through a pipe."
echo "-- ask.sh with input 'Asha' and '29' --"
printf 'Asha\n29\n' | ./ask.sh
echo "(No prompts appeared: 'read -p' shows its prompt only when a person is at the keyboard.)"
echo ""
echo "-- confirm.sh, answering y --"
echo y | ./confirm.sh
echo "-- confirm.sh, answering n --"
echo n | ./confirm.sh
echo "-- confirm.sh, just pressing Enter (default = No) --"
echo "" | ./confirm.sh
echo ""

# --- PART 9: reading a file line by line -------------------
echo "== Part 9: read a file line by line =="
printf 'alpha\nbeta\ngamma\n' > list.txt
while IFS= read -r line; do
    echo "  line: $line"
done < list.txt
echo ""

# --- PART 10: a real mini tool -----------------------------
echo "== Part 10: mkproject.sh =="
./mkproject.sh
echo "exit code: $?"
./mkproject.sh myapp
ls -R projects/myapp
./mkproject.sh myapp
echo "exit code: $?   (1 = it already existed, so it refused)"
echo ""

# --- PART 11: is a human at the keyboard? ------------------
echo "== Part 11: interactive or not? =="
if [ -t 0 ]; then
    read -r -p "Type your name and press Enter: " who
    echo "Nice to meet you, ${who:-friend}!"
else
    echo "(Input is not a terminal, so the interactive prompt is skipped.)"
fi
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

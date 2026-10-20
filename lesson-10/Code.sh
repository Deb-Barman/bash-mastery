#!/usr/bin/env bash
# ==========================================================
# Lesson 10 - Code.sh
# Topic : variables, quoting, $( ), $(( )), defaults,
#         export, special variables, readonly, unset, set -u
# Run   : bash Code.sh
# Safe  : the file demo happens ONLY inside
#         ~/bash-practice/lesson10-demo (cleaned up after).
# ==========================================================

DEMO="$HOME/bash-practice/lesson10-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- PART 1: assignment and use ----------------------------
echo "== Part 1: variables =="
name="Asha"
city="Pune"
count=5
echo "Name: $name, City: $city, Count: $count"
echo "Length of name: ${#name} characters"
echo ""

# --- PART 2: braces ----------------------------------------
echo "== Part 2: \${braces} =="
fruit="apple"
echo "Two ${fruit}s       <- braces let text touch the name"
echo "Two $fruits         <- Bash looked for a variable named 'fruits' (empty!)"
echo ""

# --- PART 3: three kinds of quoting ------------------------
echo "== Part 3: quoting =="
full="Asha Rao"
echo "double quotes : Hello $full"
echo 'single quotes : Hello $full'
echo "backslash     : Hello \$full"
echo "price         : it costs \$5"
echo "mixing        : She said 'hi' and he said \"bye\""
echo ""

# --- PART 4: word splitting (the #1 beginner bug) ----------
echo "== Part 4: why quoting matters =="
file="my report.txt"
echo "-- count the words Bash sees (each [..] = one argument) --"
echo "unquoted:"
printf '  [%s]\n' $file
echo "quoted:"
printf '  [%s]\n' "$file"
echo ""

touch "my report.txt" other.txt
echo "-- delete with an unquoted variable --"
echo "Trying: rm \$file   (really: rm my report.txt)"
rm $file 2>&1
echo "Is 'my report.txt' still there? $(ls | grep -c 'my report.txt') (1 = yes, it survived the mistake)"
echo "-- delete with a quoted variable --"
rm "$file"
echo "Is 'my report.txt' still there? $(ls | grep -c 'my report.txt') (0 = deleted correctly)"
echo ""

echo "-- globbing surprise with an unquoted *  --"
pattern="*"
echo "unquoted echo \$pattern : $(echo $pattern)"
echo "quoted   echo \"\$pattern\": $(echo "$pattern")"
echo ""

# --- PART 5: command substitution --------------------------
echo "== Part 5: \$( ) command substitution =="
today=$(date +%F)
echo "Today: $today"
items=$(ls | wc -l)
echo "Items in this folder: $items"
echo "Nested: current folder is called '$(basename "$(pwd)")'"
echo ""

# --- PART 6: arithmetic ------------------------------------
echo "== Part 6: \$(( )) arithmetic =="
a=7
b=3
echo "$a + $b = $(( a + b ))"
echo "$a - $b = $(( a - b ))"
echo "$a * $b = $(( a * b ))"
echo "$a / $b = $(( a / b ))   <- whole numbers only! decimals are cut off"
echo "$a % $b = $(( a % b ))   <- remainder"
echo "$a ** 2 = $(( a ** 2 ))   <- power"
total=$(( a * b + 1 ))
(( total++ ))
(( total += 10 ))
echo "total after math: $total"
echo "Decimals with awk: $(awk -v a=$a -v b=$b 'BEGIN {printf "%.2f", a/b}')"
echo "Dice roll (1-6)  : $(( RANDOM % 6 + 1 ))   <- changes every run"
echo ""

# --- PART 7: defaults and checks ---------------------------
echo "== Part 7: defaults =="
unset BACKUP_DIR
echo "BACKUP_DIR is unset. Using default: ${BACKUP_DIR:-$HOME/backups}"
echo "...but BACKUP_DIR itself is still: [${BACKUP_DIR}]"
echo "With := the variable IS assigned: ${BACKUP_DIR:=$HOME/backups}"
echo "Now BACKUP_DIR is: [$BACKUP_DIR]"
greeting="hello"
echo "\${greeting:+set}   -> [${greeting:+it is set}]"
echo "\${missing:+set}    -> [${missing:+it is set}]  (empty because 'missing' is unset)"
echo ""

echo "-- \${var:?message} stops a script when a value is required --"
( : "${API_KEY:?API_KEY must be set}" ) 2>&1
echo "(the line above is the error message; exit status $?)"
echo ""

# --- PART 8: export and child processes --------------------
echo "== Part 8: export =="
color="blue"
echo "Before export: $(bash -c 'echo "child sees: [$color]"')"
export color
echo "After  export: $(bash -c 'echo "child sees: [$color]"')"
echo "One-shot variable: $(MODE=debug bash -c 'echo "MODE inside = $MODE"')"
echo "...and in my shell MODE is: [${MODE}]"
echo ""

# --- PART 9: built-in variables ----------------------------
echo "== Part 9: built-in variables =="
echo "HOME      = $HOME"
echo "USER      = ${USER:-$(whoami)}"
echo "PWD       = $PWD"
echo "SHELL     = ${SHELL:-unknown}"
echo "BASH_VERSION = $BASH_VERSION"
echo "Script name \$0 = $0"
echo "Process id \$\$ = $$"
echo "This is line \$LINENO = $LINENO"
echo "Seconds since script started (\$SECONDS) = $SECONDS"
echo ""

# --- PART 10: readonly, unset, set -u ----------------------
echo "== Part 10: readonly, unset, set -u =="
( readonly PI=3.14159; PI=3 ) 2>&1
echo "(readonly protected PI from change)"
temp="data"
unset temp
echo "After unset, temp = [${temp}]"
echo ""
echo "-- set -u turns typos into errors --"
( set -u; echo "Value: $undefined_variable" ) 2>&1
echo "(Bash refused to use a variable that was never set)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

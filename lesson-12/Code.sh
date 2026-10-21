#!/usr/bin/env bash
# ==========================================================
# Lesson 12 - Code.sh
# Topic : if/elif/else, [ ] vs [[ ]], (( )), file tests,
#         && || !, case, and the classic traps
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson12-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson12-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- HELPER SCRIPTS (so we can run one decision many times) --
cat > grade.sh << 'EOF'
#!/usr/bin/env bash
score="$1"
if (( score >= 90 )); then
    echo "score $score -> A"
elif (( score >= 75 )); then
    echo "score $score -> B"
elif (( score >= 50 )); then
    echo "score $score -> C"
else
    echo "score $score -> Fail"
fi
EOF

cat > ftype.sh << 'EOF'
#!/usr/bin/env bash
path="$1"
if [[ ! -e "$path" ]]; then
    echo "$path -> does not exist"
elif [[ -L "$path" ]]; then
    echo "$path -> symbolic link"
elif [[ -d "$path" ]]; then
    echo "$path -> directory"
elif [[ -f "$path" && ! -s "$path" ]]; then
    echo "$path -> regular file, EMPTY"
elif [[ -f "$path" ]]; then
    echo "$path -> regular file with content"
fi
EOF

cat > kind.sh << 'EOF'
#!/usr/bin/env bash
case "$1" in
    *.jpg|*.jpeg|*.png) echo "$1 -> image" ;;
    *.mp3|*.wav)        echo "$1 -> audio" ;;
    *.sh)               echo "$1 -> shell script" ;;
    *.tar.gz|*.zip)     echo "$1 -> archive" ;;
    *)                  echo "$1 -> unknown type" ;;
esac
EOF

cat > answer.sh << 'EOF'
#!/usr/bin/env bash
case "$1" in
    [yY]|[yY][eE][sS]) echo "'$1' -> Yes!" ;;
    [nN]|[nN][oO])     echo "'$1' -> No." ;;
    "")                echo "(empty) -> You typed nothing." ;;
    *)                 echo "'$1' -> I don't understand." ;;
esac
EOF
chmod +x ./*.sh

# --- PART 1: a command as the condition --------------------
echo "== Part 1: the condition is a command's exit code =="
printf 'Delhi\nPune\nGoa\n' > cities.txt
if grep -q "Pune" cities.txt; then
    echo "grep -q found Pune (exit code 0 = true)"
fi
if grep -q "Paris" cities.txt; then
    echo "found Paris"
else
    echo "grep -q did NOT find Paris (non-zero = false)"
fi
if ! grep -q "Paris" cities.txt; then
    echo "'!' flips it: Paris is NOT in the file"
fi
echo ""

# --- PART 2: numbers ---------------------------------------
echo "== Part 2: numbers =="
age=20
if [ "$age" -ge 18 ]; then
    echo "[ \$age -ge 18 ]  -> adult (the classic test command)"
fi
if [[ $age -ge 18 ]]; then
    echo "[[ \$age -ge 18 ]] -> adult ([[ ]] version)"
fi
if (( age >= 18 )); then
    echo "(( age >= 18 ))   -> adult (friendly arithmetic version)"
fi
n=7
if (( n % 2 == 0 )); then echo "$n is even"; else echo "$n is odd"; fi
echo ""

# --- PART 3: strings ---------------------------------------
echo "== Part 3: strings =="
name="Asha"
[[ $name == "Asha" ]] && echo "name equals Asha"
[[ $name != "Ravi" ]] && echo "name is not Ravi"
empty=""
[[ -z $empty ]] && echo "'empty' has zero length (-z)"
[[ -n $name ]] && echo "'name' is non-empty (-n)"
file="holiday.txt"
if [[ $file == *.txt ]]; then
    echo "$file matches the glob *.txt"
fi
if [[ "apple" < "banana" ]]; then
    echo "\"apple\" sorts before \"banana\" (text comparison)"
fi
echo ""

# --- PART 4: elif chain ------------------------------------
echo "== Part 4: if / elif / else (grade.sh) =="
./grade.sh 95
./grade.sh 82
./grade.sh 60
./grade.sh 30
echo ""

# --- PART 5: file tests ------------------------------------
echo "== Part 5: file tests (ftype.sh) =="
touch empty.txt
echo "some text" > full.txt
mkdir folder
ln -s full.txt shortcut
./ftype.sh nothing-here
./ftype.sh empty.txt
./ftype.sh full.txt
./ftype.sh folder
./ftype.sh shortcut
echo ""
if [[ -x grade.sh ]]; then echo "grade.sh is executable (-x)"; fi
if [[ full.txt -nt empty.txt || full.txt -ot empty.txt ]]; then
    echo "-nt / -ot compare modification times"
fi
echo ""

# --- PART 6: combining tests -------------------------------
echo "== Part 6: && || ! =="
x=5
if [[ $x -gt 0 && $x -lt 10 ]]; then
    echo "$x is between 1 and 9 (AND)"
fi
answer="Y"
if [[ $answer == y || $answer == Y ]]; then
    echo "answer is y or Y (OR)"
fi
if [[ -f full.txt ]] && grep -q "text" full.txt; then
    echo "file exists AND contains 'text' (grep only ran because the first test passed)"
fi
echo ""

# --- PART 7: && and || shortcuts + the trap ----------------
echo "== Part 7: && / || as shortcuts =="
[[ -d folder ]] && echo "folder exists"
[[ -d missing-dir ]] || echo "missing-dir does not exist (the || branch ran)"
[[ -d newdir ]] || mkdir newdir
echo "newdir created only because it was missing: $(ls -d newdir)"
echo ""
echo "-- the trap: A && B || C is NOT if/else --"
true && false || echo "C ran, even though A (true) succeeded, because B (false) failed!"
echo ""

# --- PART 8: case ------------------------------------------
echo "== Part 8: case (kind.sh and answer.sh) =="
./kind.sh photo.JPG
./kind.sh photo.png
./kind.sh song.mp3
./kind.sh run.sh
./kind.sh backup.zip
./kind.sh notes.docx
echo "-- answers --"
./answer.sh y
./answer.sh YES
./answer.sh no
./answer.sh ""
./answer.sh maybe
echo ""
echo "(Note: photo.JPG fell to 'unknown' because case patterns are case-sensitive.)"
echo ""

# --- PART 9: classic mistakes ------------------------------
echo "== Part 9: classic mistakes =="
echo "-- 1) unquoted empty variable inside [ ] --"
unset blank
( [ $blank = "a" ] ) 2>&1
echo "   ^ error because [ ] saw:  [ = a ]"
echo "-- 2) the same test with [[ ]] or quotes is fine --"
[[ $blank == "a" ]] || echo "   [[ ]] handled the empty variable, result: not equal"
[ "$blank" = "a" ] || echo "   quoted [ ] also fine, result: not equal"
echo "-- 3) numbers vs text --"
a="05"
if [[ $a == 5 ]]; then echo "equal as text"; else echo "\"05\" == 5 is FALSE as text"; fi
if (( a == 5 )); then echo "\"05\" == 5 is TRUE as numbers (use (( )) for numbers)"; fi
echo "-- 4) exit code of a test --"
[ 1 -eq 1 ]; echo "[ 1 -eq 1 ] exit code: $?"
[ 1 -eq 2 ]; echo "[ 1 -eq 2 ] exit code: $?"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

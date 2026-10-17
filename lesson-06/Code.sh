#!/usr/bin/env bash
# ==========================================================
# Lesson 6 - Code.sh
# Topic : * ? [ ] {a,b} {1..5}, quoting, hidden files,
#         nullglob, globstar, extglob
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson6-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson6-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- BUILD SAMPLE FILES (using brace expansion!) -----------
touch a.txt b.txt c.txt notes.txt
touch report{1,2,10}.txt
touch photo1.jpg photo2.png
touch data{1..3}.csv
touch script.sh README.md Makefile
touch .hidden
touch "File With Space.txt"
mkdir -p sub/deeper
touch sub/one.txt sub/deeper/two.txt

echo "Working in: $(pwd)"
echo "Files created. Now let's match them with patterns."
echo ""

# --- PART 1: see what Bash expands (echo preview) ----------
echo "== Part 1: Bash expands the pattern FIRST =="
echo "echo *.txt   ->" *.txt
echo "(Bash replaced *.txt with real names before echo ran.)"
echo ""

# --- PART 2: * ---------------------------------------------
echo "== Part 2: * (any characters) =="
echo "*.csv      -> " *.csv
echo "report*    -> " report*
echo "*s*        -> " *s*
echo "a*         -> " a*
echo ""

# --- PART 3: ? ---------------------------------------------
echo "== Part 3: ? (exactly one character) =="
echo "report?.txt  -> " report?.txt
echo "report??.txt -> " report??.txt
echo "?.txt        -> " ?.txt
echo ""

# --- PART 4: [ ] -------------------------------------------
echo "== Part 4: [ ] (one character from a set) =="
echo "data[12].csv    -> " data[12].csv
echo "[a-c].txt       -> " [a-c].txt
echo "[!a-b].txt      -> " [!a-b].txt
echo "photo[0-9].*    -> " photo[0-9].*
echo "[[:upper:]]*    -> " [[:upper:]]*
echo ""

# --- PART 5: brace expansion (it INVENTS text) -------------
echo "== Part 5: {} brace expansion =="
echo "{a,b,c}              -> " {a,b,c}
echo "file{1,2,3}.txt      -> " file{1,2,3}.txt
echo "{1..5}               -> " {1..5}
echo "{a..e}               -> " {a..e}
echo "{01..05}             -> " {01..05}
echo "{10..6}              -> " {10..6}
echo "{0..20..5}           -> " {0..20..5}
echo "{2026..2027}-{01,02} -> " {2026..2027}-{01,02}
echo ""
echo "Big difference: braces invent names even if no such file exists:"
echo "nofile{1,2}.xyz -> " nofile{1,2}.xyz
echo "...but a glob only matches files that REALLY exist:"
echo "nofile*.xyz     -> " nofile*.xyz "(no match: the pattern stays as plain text)"
echo ""

echo "Rename trick: cp notes.txt{,.bak}"
cp notes.txt{,.bak}
ls notes*
echo "Rename extension: mv script.{sh,bash}"
mv script.{sh,bash}
ls script*
echo ""

# --- PART 6: hidden files ----------------------------------
echo "== Part 6: hidden files =="
echo "* does not show .hidden:"
echo *
echo "ls -A shows it:"
ls -A | head -n 3
echo "Names matched by *  : $(printf '%s\n' * | wc -l)"
shopt -s dotglob
echo "After 'shopt -s dotglob', * also matches .hidden:"
echo "Names matched by *  : $(printf '%s\n' * | wc -l)"
shopt -u dotglob
echo ""

# --- PART 7: quoting turns magic off -----------------------
echo "== Part 7: quotes protect the *  =="
echo *.csv
echo "*.csv"
echo '*.csv'
echo \*.csv
echo ""

# --- PART 8: quoting variables -----------------------------
echo "== Part 8: always quote variables =="
name="File With Space.txt"
echo "ls \$name (no quotes) breaks into 3 words:"
ls $name 2>&1 | head -n 3
echo "ls \"\$name\" (quoted) works:"
ls "$name"
echo ""

# --- PART 9: nullglob --------------------------------------
echo "== Part 9: when nothing matches =="
echo "Default: the pattern stays as text -> " *.nothing
shopt -s nullglob
echo "With nullglob: it becomes empty    -> [" *.nothing "]"
shopt -u nullglob
echo ""

# --- PART 10: globstar (**) --------------------------------
echo "== Part 10: ** (recursive) =="
shopt -s globstar
echo "**/*.txt (every .txt at any depth):"
printf '  %s\n' **/*.txt
shopt -u globstar
echo ""

# --- PART 11: extglob --------------------------------------
echo "== Part 11: extglob =="
# Gotcha: Bash must know extglob is ON *before it reads* a line that uses
# patterns like @(a|b). So we run these lines in a tiny helper Bash that
# starts with extglob already on (-O extglob). Details in Code.md.
bash -O extglob -c '
  echo "*.@(jpg|png)    -> " *.@(jpg|png)
  echo "report!(1).txt  -> " report!(1).txt
  echo "!(*.txt)        -> " !(*.txt)
'
echo ""

# --- PART 12: safe deleting with a preview ------------------
echo "== Part 12: preview BEFORE deleting =="
echo "1) Preview what *.csv matches:"
echo *.csv
echo "2) Looks right, so delete:"
rm -v data*.csv
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

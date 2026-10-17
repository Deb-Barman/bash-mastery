#!/usr/bin/env bash
# ==========================================================
# Lesson 5 - Code.sh
# Topic : > >> < 2> 2>&1 &> /dev/null | tee xargs
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson5-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson5-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

echo "Working in: $(pwd)"
echo ""

# --- PART 1: > (overwrite) and >> (append) -----------------
echo "== Part 1: > and >> =="
echo "first"  > out.txt          # create / overwrite
echo "second" >> out.txt         # append
echo "third"  >> out.txt         # append
cat out.txt
echo "-- now overwrite with > --"
echo "only me" > out.txt
cat out.txt
echo ""

# --- PART 2: < (input from a file) -------------------------
echo "== Part 2: < =="
printf 'banana\napple\ncherry\n' > fruits.txt
echo "wc -l fruits.txt   -> $(wc -l fruits.txt)"
echo "wc -l < fruits.txt -> $(wc -l < fruits.txt)"
echo "sort < fruits.txt:"
sort < fruits.txt
echo ""

# --- PART 3: the error stream (2>) -------------------------
echo "== Part 3: stdout vs stderr =="
echo "-- 1) error appears on screen --"
ls /nonexistent-folder
echo "-- 2) error goes to a file (2>) --"
ls /nonexistent-folder 2> errors.txt
echo "(screen is quiet) errors.txt contains:"
cat errors.txt
echo ""

# --- PART 4: separate files for output and errors ----------
echo "== Part 4: split streams =="
ls fruits.txt /nonexistent-folder > good.txt 2> bad.txt
echo "good.txt: $(cat good.txt)"
echo "bad.txt : $(cat bad.txt)"
echo ""

# --- PART 5: 2>&1 and &> (merge) ---------------------------
echo "== Part 5: merging streams =="
ls fruits.txt /nonexistent-folder > all.txt 2>&1
echo "all.txt (both streams, classic form):"
cat all.txt
echo ""
ls fruits.txt /nonexistent-folder &> all2.txt
echo "all2.txt (Bash shortcut &>) has $(wc -l < all2.txt) lines"
echo ""

echo "-- order matters! --"
echo "Right order  (> file 2>&1): errors go to the file"
ls /nonexistent-folder > right.txt 2>&1
echo "  right.txt has $(wc -l < right.txt) line(s)"
echo "Wrong order  (2>&1 > file): error still hits the screen:"
ls /nonexistent-folder 2>&1 > wrong.txt
echo "  wrong.txt has $(wc -l < wrong.txt) line(s)"
echo ""

# --- PART 6: /dev/null -------------------------------------
echo "== Part 6: /dev/null (the black hole) =="
echo "Hiding errors:"
ls /nonexistent-folder 2> /dev/null
echo "(nothing printed)"
echo "Hiding everything, then checking success with \$?:"
ls fruits.txt > /dev/null 2>&1
echo "  exit code for an existing file: $?   (0 = success)"
ls /nonexistent-folder > /dev/null 2>&1
echo "  exit code for a missing file : $?   (non-zero = failure)"
echo ""

# --- PART 7: pipes -----------------------------------------
echo "== Part 7: pipes =="
echo "Items in this folder:"
ls | wc -l
echo "First two files alphabetically:"
ls | sort | head -n 2
echo ""

printf 'red\nblue\nred\ngreen\nblue\nred\n' > colors.txt
echo "Which color appears most? (sort | uniq -c | sort -rn)"
sort colors.txt | uniq -c | sort -rn
echo ""

echo "-- pipes carry only stdout --"
echo "Without merging, the error skips the pipe:"
ls /nonexistent-folder 2> /dev/null | wc -l
echo "With |& the error text goes through too:"
ls /nonexistent-folder |& wc -l
echo ""

# --- PART 8: tee -------------------------------------------
echo "== Part 8: tee (screen AND file) =="
echo "tee copies the list into listing.txt AND passes it to the next command:"
ls -1 | tee listing.txt | wc -l
echo "...so wc counted it, and listing.txt was saved too. Its first 3 lines:"
head -n 3 listing.txt
echo ""

# --- PART 9: xargs -----------------------------------------
echo "== Part 9: xargs (pipe -> arguments) =="
echo "alpha beta gamma" | xargs mkdir
echo "Made folders: $(ls -d alpha beta gamma | tr '\n' ' ')"
touch "has space.tmp" plain.tmp
echo "Safe delete preview (echo first!):"
find . -name "*.tmp" -print0 | xargs -0 echo rm
find . -name "*.tmp" -print0 | xargs -0 rm
echo "Remaining .tmp files: $(find . -name '*.tmp' | wc -l)"
echo ""

# --- PART 10: here-document and here-string ----------------
echo "== Part 10: here-doc and here-string =="
cat << 'EOF' > config.txt
name=Deb
mode=learning
EOF
echo "config.txt:"
cat config.txt
echo "Here-string: grep 'Deb' <<< 'Hello Deb'"
grep "Deb" <<< "Hello Deb"
echo ""

# --- PART 11: noclobber (overwrite protection) -------------
echo "== Part 11: noclobber =="
set -o noclobber
echo "new" > config.txt 2>&1 || echo "(Blocked! > refused to overwrite config.txt)"
echo "forced" >| config.txt
echo "Forced with >| -> config.txt now says: $(cat config.txt)"
set +o noclobber
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

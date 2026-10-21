#!/usr/bin/env bash
# ==========================================================
# Lesson 13 - Code.sh
# Topic : for, C-style for, while, until, break, continue,
#         reading files line by line, bulk rename, traps
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson13-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson13-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- PART 1: for over a list -------------------------------
echo "== Part 1: for over a list =="
for fruit in apple banana cherry; do
    echo "I like $fruit"
done
echo "-- a range --"
for n in {1..5}; do
    printf '%s ' "$n"
done
echo
echo "-- a range with a step: {10..0..2} --"
for n in {10..0..2}; do
    printf '%s ' "$n"
done
echo
echo "-- quoted items stay whole --"
for item in "red apple" "green pear"; do
    echo "item: [$item]"
done
echo ""

# --- PART 2: for over files --------------------------------
echo "== Part 2: for over files (glob) =="
printf 'a\nb\nc\n' > one.txt
printf 'x\ny\n' > two.txt
echo "single line" > "my notes.txt"
for file in *.txt; do
    echo "$file has $(wc -l < "$file") line(s)"
done
echo ""

# --- PART 3: bulk rename -----------------------------------
echo "== Part 3: bulk rename .txt -> .md =="
echo "Before: $(printf '[%s] ' *.txt)"
for f in *.txt; do
    mv -- "$f" "${f%.txt}.md"
done
echo "After : $(printf '[%s] ' *.md)"
echo "(Note 'my notes.md': quoting made spaces safe.)"
echo ""

# --- PART 4: C-style for -----------------------------------
echo "== Part 4: C-style for =="
for (( i = 1; i <= 5; i++ )); do
    printf '%s ' "$i"
done
echo
echo "-- counting down by 3 --"
for (( i = 10; i > 0; i -= 3 )); do
    printf '%s ' "$i"
done
echo
echo "-- running total --"
total=0
for (( i = 1; i <= 10; i++ )); do
    (( total += i ))
done
echo "1+2+...+10 = $total"
echo ""

# --- PART 5: while -----------------------------------------
echo "== Part 5: while =="
count=1
while (( count <= 3 )); do
    echo "Round $count"
    (( count++ ))
done
echo ""

# --- PART 6: until -----------------------------------------
echo "== Part 6: until =="
n=1
until (( n > 3 )); do
    echo "n = $n"
    (( n++ ))
done
echo ""

# --- PART 7: break and continue ----------------------------
echo "== Part 7: break and continue =="
echo "Odd numbers, stopping after 7:"
for n in {1..10}; do
    if (( n % 2 == 0 )); then continue; fi     # skip even numbers
    if (( n > 7 )); then break; fi             # stop the whole loop
    printf '%s ' "$n"
done
echo
echo "-- break 2 leaves BOTH loops --"
for a in 1 2 3; do
    for b in 1 2 3; do
        if (( a * b == 4 )); then
            echo "found a=$a b=$b, leaving both loops"
            break 2
        fi
    done
done
echo ""

# --- PART 8: reading a file line by line -------------------
echo "== Part 8: while read =="
cat > people.csv << 'EOF'
name,city,age
Asha,Delhi,29
Ravi,Pune,34
Mina,Delhi,41
EOF
echo "-- plain lines --"
while IFS= read -r line; do
    echo "  line: $line"
done < people.csv
echo "-- split on commas, skip the header --"
{
    read -r _header
    while IFS=, read -r name city age; do
        echo "  $name lives in $city and is $age"
    done
} < people.csv
echo ""

# --- PART 9: the subshell trap -----------------------------
echo "== Part 9: variables vanish after 'cmd | while' =="
count=0
cat people.csv | while IFS= read -r line; do
    (( count++ ))
done
echo "After cat | while : count = $count   <- the loop ran in a subshell, so count was lost"
count=0
while IFS= read -r line; do
    (( count++ ))
done < people.csv
echo "After done < file  : count = $count   <- correct"
count=0
while IFS= read -r line; do
    (( count++ ))
done < <(cat people.csv)
echo "After done < <(cmd): count = $count   <- also correct (process substitution)"
echo ""

# --- PART 10: the empty-glob trap and nullglob -------------
echo "== Part 10: the empty glob trap =="
echo "No .zip files exist. Default behaviour keeps the pattern as TEXT:"
for z in *.zip; do
    echo "  loop saw: [$z]"
done
shopt -s nullglob
echo "With nullglob the loop simply runs zero times:"
for z in *.zip; do
    echo "  loop saw: [$z]"
done
echo "  (nothing printed above = correct)"
shopt -u nullglob
echo ""

# --- PART 11: a classic: FizzBuzz --------------------------
echo "== Part 11: FizzBuzz (1-15) =="
for n in {1..15}; do
    if (( n % 15 == 0 )); then   printf 'FizzBuzz '
    elif (( n % 3 == 0 )); then  printf 'Fizz '
    elif (( n % 5 == 0 )); then  printf 'Buzz '
    else                         printf '%s ' "$n"
    fi
done
echo
echo ""

# --- PART 12: multiplication table with printf -------------
echo "== Part 12: a 4x4 multiplication table =="
for (( row = 1; row <= 4; row++ )); do
    for (( col = 1; col <= 4; col++ )); do
        printf '%4d' $(( row * col ))
    done
    echo
done
echo ""

# --- PART 13: counting with seq ----------------------------
echo "== Part 13: seq with a variable limit =="
limit=4
for n in $(seq 1 "$limit"); do
    printf '%s ' "$n"
done
echo "   (use seq or (( )) when the limit is a variable; {1..\$limit} does not work)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

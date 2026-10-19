#!/usr/bin/env bash
# ==========================================================
# Lesson 7 - Code.sh
# Topic : sort, uniq, cut, tr, sed, awk, and pipelines
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson7-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson7-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- SAMPLE DATA -------------------------------------------
cat > people.csv << 'EOF'
name,city,age,score
Asha,Delhi,29,88
Ravi,Pune,34,72
Mina,Delhi,41,95
Karan,Goa,25,60
Sita,Pune,38,81
Tom,Delhi,31,77
EOF
printf '10\n9\n100\n1\n' > numbers.txt
printf 'pear\napple\npear\nfig\napple\npear\n' > fruits.txt

echo "Sample data created. people.csv looks like:"
cat people.csv
echo ""

# --- PART 1: sort ------------------------------------------
echo "== Part 1: sort =="
echo "-- numbers.txt, plain sort (text order, WRONG for numbers) --"
sort numbers.txt | tr '\n' ' '; echo
echo "-- sort -n (numeric, correct) --"
sort -n numbers.txt | tr '\n' ' '; echo
echo "-- sort -nr (biggest first) --"
sort -nr numbers.txt | tr '\n' ' '; echo
echo "-- fruits: sort -u (sorted, unique) --"
sort -u fruits.txt | tr '\n' ' '; echo
echo "-- people by score, highest first (skip header) --"
tail -n +2 people.csv | sort -t, -k4 -nr
echo "-- by city, then score high-to-low --"
tail -n +2 people.csv | sort -t, -k2,2 -k4,4nr
echo ""

# --- PART 2: uniq ------------------------------------------
echo "== Part 2: uniq =="
echo "-- without sort, uniq misses non-adjacent duplicates --"
uniq fruits.txt | tr '\n' ' '; echo
echo "-- sort | uniq --"
sort fruits.txt | uniq | tr '\n' ' '; echo
echo "-- sort | uniq -c (counts) --"
sort fruits.txt | uniq -c
echo "-- only duplicated lines (-d) --"
sort fruits.txt | uniq -d | tr '\n' ' '; echo
echo "-- only lines that appear once (-u) --"
sort fruits.txt | uniq -u
echo ""

# --- PART 3: cut -------------------------------------------
echo "== Part 3: cut =="
echo "-- names (field 1) --"
cut -d, -f1 people.csv | tr '\n' ' '; echo
echo "-- name and score (fields 1,4) --"
cut -d, -f1,4 people.csv | head -n 3
echo "-- fields 2 to 4 --"
cut -d, -f2-4 people.csv | head -n 3
echo "-- first 3 characters of each line --"
cut -c1-3 people.csv | tr '\n' ' '; echo
echo ""

# --- PART 4: tr --------------------------------------------
echo "== Part 4: tr =="
echo "hello world" | tr a-z A-Z
echo "hello world" | tr -d 'aeiou'
echo "a     b      c" | tr -s ' '
echo "red,green,blue" | tr ',' '\n'
echo "abc" | tr 'a-y' 'b-z'
echo ""

# --- PART 5: sed -------------------------------------------
echo "== Part 5: sed =="
echo "-- replace first Delhi on each line --"
sed 's/Delhi/Mumbai/' people.csv | head -n 3
echo "-- g = replace every match on a line (a -> A) --"
echo "banana" | sed 's/a/A/g'
echo "-- print only lines 2-3 --"
sed -n '2,3p' people.csv
echo "-- print only lines containing Pune --"
sed -n '/Pune/p' people.csv
echo "-- delete the header line --"
sed '1d' people.csv | head -n 2
echo "-- in-place edit with a backup (-i.bak) --"
sed -i.bak 's/Goa/Panaji/' people.csv
grep -n "Panaji" people.csv
echo "backup kept as: $(ls people.csv.bak)"
echo "-- different separator for paths --"
echo "/usr/bin/python" | sed 's|/usr/bin|/opt/bin|'
echo ""

# --- PART 6: awk -------------------------------------------
echo "== Part 6: awk =="
echo "-- name and score (skip header with NR>1) --"
awk -F, 'NR>1 {print $1, $4}' people.csv
echo "-- names of people with score > 80 --"
awk -F, 'NR>1 && $4>80 {print $1}' people.csv
echo "-- total score --"
awk -F, 'NR>1 {sum += $4} END {print sum}' people.csv
echo "-- average score (1 decimal) --"
awk -F, 'NR>1 {sum += $4} END {printf "%.1f\n", sum/(NR-1)}' people.csv
echo "-- neat columns with printf --"
awk -F, 'NR>1 {printf "%-8s %-8s %3d\n", $1, $2, $4}' people.csv
echo "-- people per city (sorted) --"
awk -F, 'NR>1 {count[$2]++} END {for (c in count) print c, count[c]}' people.csv | sort
echo "-- number of fields on the first line (NF) --"
awk -F, 'NR==1 {print NF}' people.csv
echo ""

# --- PART 7: real pipelines --------------------------------
echo "== Part 7: pipelines =="
echo "Which city has the most people?"
tail -n +2 people.csv | cut -d, -f2 | sort | uniq -c | sort -rn | head -n 1
echo ""
echo "People over 30, alphabetically:"
awk -F, 'NR>1 && $3>30 {print $1}' people.csv | sort
echo ""
echo "Top 2 scores:"
tail -n +2 people.csv | sort -t, -k4 -nr | head -n 2 | cut -d, -f1,4
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

#!/usr/bin/env bash
# ==========================================================
# Lesson 15 - Code.sh
# Topic : indexed arrays, "${arr[@]}", mapfile, recipes,
#         associative arrays, declare -p
# Run   : bash Code.sh
# Needs : Bash 4+ (associative arrays). Checked below.
# Safe  : file demos happen ONLY inside
#         ~/bash-practice/lesson15-demo (cleaned up after).
# ==========================================================

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This lesson needs Bash 4 or newer (you have $BASH_VERSION)."
    echo "On macOS: brew install bash   then run:  /opt/homebrew/bin/bash Code.sh"
    exit 1
fi

DEMO="$HOME/bash-practice/lesson15-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- PART 1: why arrays ------------------------------------
echo "== Part 1: why arrays? =="
files_string="my report.txt notes.txt"
echo "A plain string, unquoted loop:"
for f in $files_string; do
    echo "  [$f]"
done
files_array=("my report.txt" "notes.txt")
echo "A real array, quoted loop:"
for f in "${files_array[@]}"; do
    echo "  [$f]"
done
echo ""

# --- PART 2: reading ---------------------------------------
echo "== Part 2: reading elements =="
fruits=(apple banana cherry date)
echo "fruits[0]           = ${fruits[0]}"
echo "fruits[2]           = ${fruits[2]}"
echo "last element [-1]   = ${fruits[-1]}"
echo "all  [@]            = ${fruits[@]}"
echo "count #[@]          = ${#fruits[@]}"
echo "indices ![@]        = ${!fruits[@]}"
echo "length of banana    = ${#fruits[1]}"
echo "slice [@]:1:2       = ${fruits[@]:1:2}"
echo "from index 2 [@]:2  = ${fruits[@]:2}"
echo "\$fruits (no index)  = $fruits   <- only element 0!"
echo ""

# --- PART 3: the golden rule -------------------------------
echo "== Part 3: \"\${arr[@]}\" vs \"\${arr[*]}\" vs unquoted =="
items=("a b" "c")
echo "\"\${items[@]}\" -> $(printf '[%s]' "${items[@]}")   2 items (correct)"
echo "\"\${items[*]}\" -> $(printf '[%s]' "${items[*]}")   1 big string"
echo "unquoted       -> $(printf '[%s]' ${items[@]})   3 items (broken apart!)"
echo ""

# --- PART 4: changing --------------------------------------
echo "== Part 4: changing arrays =="
nums=(10 20 30)
nums+=(40)
nums+=(50 60)
echo "after append       : ${nums[*]}"
nums[1]=99
echo "after nums[1]=99   : ${nums[*]}"
unset 'nums[0]'
echo "after unset nums[0]: ${nums[*]}   indices now: ${!nums[*]}   <- a gap at 0!"
nums=("${nums[@]}")
echo "after re-compacting: ${nums[*]}   indices now: ${!nums[*]}"
echo ""

# --- PART 5: looping ---------------------------------------
echo "== Part 5: looping =="
for fruit in "${fruits[@]}"; do
    printf '%s ' "$fruit"
done
echo
for i in "${!fruits[@]}"; do
    echo "  $i: ${fruits[$i]}"
done
echo ""

# --- PART 6: filling arrays from sources -------------------
echo "== Part 6: filling arrays =="
touch a.txt b.txt "c d.txt" x.log
globbed=(*.txt)
echo "glob (*.txt)     : ${#globbed[@]} items -> $(printf '[%s]' "${globbed[@]}")"

read -r -a words <<< "one two three"
echo "read -a          : ${#words[@]} items -> $(printf '[%s]' "${words[@]}")"

IFS=, read -r -a parts <<< "red,green,blue"
echo "split on commas  : ${#parts[@]} items -> $(printf '[%s]' "${parts[@]}")"

printf 'first line\nsecond line\nthird line\n' > lines.txt
mapfile -t lines < lines.txt
echo "mapfile (file)   : ${#lines[@]} items -> $(printf '[%s]' "${lines[@]}")"

mapfile -t listing < <(ls)
echo "mapfile (command): ${#listing[@]} items"

set -- "arg one" "arg two" "arg three"
args=("$@")
echo "copy of \$@       : ${#args[@]} items -> $(printf '[%s]' "${args[@]}")"
echo ""

# --- PART 7: recipes ---------------------------------------
echo "== Part 7: recipes =="
arr=(pear apple fig apple banana)

echo -n "join with commas : "
( IFS=,; echo "${arr[*]}" )

mapfile -t sorted < <(printf '%s\n' "${arr[@]}" | sort)
echo "sorted           : ${sorted[*]}"

mapfile -t unique < <(printf '%s\n' "${arr[@]}" | sort -u)
echo "unique           : ${unique[*]}"

contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ $item == "$needle" ]] && return 0
    done
    return 1
}
contains "fig" "${arr[@]}"   && echo "contains fig    : yes"
contains "kiwi" "${arr[@]}"  || echo "contains kiwi   : no"

numbers=(4 19 7 12 3)
max=${numbers[0]}
for n in "${numbers[@]}"; do
    (( n > max )) && max=$n
done
echo "largest of ${numbers[*]} : $max"

big=()
for n in "${numbers[@]}"; do
    (( n > 5 )) && big+=("$n")
done
echo "filter (> 5)     : ${big[*]}"

sum=0
for n in "${numbers[@]}"; do (( sum += n )); done
echo "sum              : $sum"
echo ""

# --- PART 8: arrays and functions --------------------------
echo "== Part 8: arrays and functions =="
print_all() {
    local item
    echo "print_all got $# items:"
    for item in "$@"; do
        echo "  - $item"
    done
}
print_all "${files_array[@]}"
echo ""

# --- PART 9: associative arrays ----------------------------
echo "== Part 9: associative arrays (dictionaries) =="
declare -A color=([apple]=red [banana]=yellow [grape]=purple)
color[lime]=green
echo "color[apple]  = ${color[apple]}"
echo "number of pairs = ${#color[@]}"
echo "keys (sorted):"
for key in $(printf '%s\n' "${!color[@]}" | sort); do
    echo "  $key -> ${color[$key]}"
done
if [[ -v color[apple] ]]; then echo "key 'apple' exists"; fi
if [[ -v color[kiwi] ]]; then echo "key 'kiwi' exists"; else echo "key 'kiwi' does not exist"; fi
unset 'color[banana]'
echo "after deleting banana: ${#color[@]} pairs"
echo ""

echo "-- counting words with an associative array --"
declare -A count
for word in red blue red green blue red; do
    (( count[$word]++ ))
done
for w in $(printf '%s\n' "${!count[@]}" | sort); do
    echo "  $w: ${count[$w]}"
done
echo ""

# --- PART 10: debugging with declare -p --------------------
echo "== Part 10: declare -p =="
declare -p fruits
declare -p count | sed 's/\[/ [/g' | cut -c1-70
echo ""

# --- PART 11: a common bug --------------------------------
echo "== Part 11: arr=\$(cmd) makes a STRING, not an array =="
wrong=$(printf 'one\ntwo\nthree\n')
echo "wrong : ${#wrong[@]} element(s) (a single string)"
mapfile -t right < <(printf 'one\ntwo\nthree\n')
echo "right : ${#right[@]} element(s)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

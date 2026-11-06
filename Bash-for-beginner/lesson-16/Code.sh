#!/usr/bin/env bash
# ==========================================================
# Lesson 16 - Code.sh
# Topic : string manipulation with ${...}, printf, split/join
# Run   : bash Code.sh
# Needs : Bash 4+ (for ${var^^} and ${var,,}).
# Safe  : the file-renaming demo works ONLY inside
#         ~/bash-practice/lesson16-demo (cleaned up after).
# ==========================================================

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This lesson needs Bash 4 or newer (you have $BASH_VERSION)."
    exit 1
fi

s="Hello, World"
path="/home/asha/docs/report.final.txt"

# --- PART 1: length and substrings -------------------------
echo "== Part 1: length and substrings =="
echo "s                 = $s"
echo "length \${#s}      = ${#s}"
echo "\${s:0:5}          = ${s:0:5}"
echo "\${s:7}            = ${s:7}"
echo "\${s: -5} (last 5) = ${s: -5}"
echo "\${s:(-5):3}       = ${s:(-5):3}"
echo ""

# --- PART 2: remove a prefix (# and ##) --------------------
echo "== Part 2: remove from the FRONT (# shortest, ## longest) =="
echo "path = $path"
echo "\${path#/home/}   = ${path#/home/}"
echo "\${path#*/}       = ${path#*/}"
echo "\${path##*/}      = ${path##*/}      <- basename"
echo ""

# --- PART 3: remove a suffix (% and %%) --------------------
echo "== Part 3: remove from the END (% shortest, %% longest) =="
echo "\${path%.txt}     = ${path%.txt}"
echo "\${path%.*}       = ${path%.*}"
echo "\${path%%.*}      = ${path%%.*}"
echo "\${path%/*}       = ${path%/*}      <- dirname"
echo ""

# --- PART 4: file name cookbook ----------------------------
echo "== Part 4: file name cookbook =="
f="photo.final.jpeg"
echo "file                 = $f"
echo "extension  \${f##*.}  = ${f##*.}"
echo "no ext     \${f%.*}   = ${f%.*}"
echo "new ext    \${f%.jpeg}.jpg = ${f%.jpeg}.jpg"
echo "up to 1st dot \${f%%.*} = ${f%%.*}"
echo "Same as basename/dirname, with no extra process:"
echo "  basename $path -> $(basename "$path")   vs   ${path##*/}"
echo "  dirname  $path -> $(dirname "$path")   vs   ${path%/*}"
echo ""

# --- PART 5: replace ---------------------------------------
echo "== Part 5: replace =="
x="one two two three"
echo "x                  = $x"
echo "first   \${x/two/2}   = ${x/two/2}"
echo "all     \${x//two/2}  = ${x//two/2}"
echo "spaces  \${x// /_}    = ${x// /_}"
echo "delete  \${x//two}    = ${x//two}"
echo "at start \${x/#one/1} = ${x/#one/1}"
echo "at end   \${x/%three/3} = ${x/%three/3}"
echo ""

# --- PART 6: case ------------------------------------------
echo "== Part 6: case =="
name="asha RAO"
echo "name          = $name"
echo "\${name^^}     = ${name^^}"
echo "\${name,,}     = ${name,,}"
echo "\${name^}      = ${name^}"
echo "\${name,}      = ${name,}"
answer="YES"
if [[ ${answer,,} == y* ]]; then echo "case-insensitive check: '$answer' starts with y"; fi
echo ""

# --- PART 7: contains / starts / ends ----------------------
echo "== Part 7: contains, starts with, ends with =="
[[ $s == *World* ]] && echo "'$s' contains World"
[[ $s == Hello* ]]  && echo "'$s' starts with Hello"
[[ $s == *World ]]  && echo "'$s' ends with World"
[[ $s != *xyz* ]]   && echo "'$s' does not contain xyz"
echo ""

# --- PART 8: trimming --------------------------------------
echo "== Part 8: trimming whitespace =="
text="   padded text   "
echo "original      : [$text]"
read -r trimmed <<< "$text"
echo "read trick    : [$trimmed]"
trimmed=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$text")
echo "sed           : [$trimmed]"
# The extglob version (bash -O extglob makes the helper shell understand +( ))
bash -O extglob -c '
  text="   padded text   "
  t="${text##+([[:space:]])}"
  t="${t%%+([[:space:]])}"
  echo "extglob       : [$t]"
'
echo ""

# --- PART 9: split and join --------------------------------
echo "== Part 9: split and join =="
csv="red,green,blue"
IFS=, read -r -a parts <<< "$csv"
echo "split into ${#parts[@]} parts; parts[1] = ${parts[1]}"
echo -n "joined with '-'   : "
( IFS=-; echo "${parts[*]}" )
echo "before first comma: ${csv%%,*}"
echo "after first comma : ${csv#*,}"
echo "after last comma  : ${csv##*,}"
line="name=Asha"
echo "key=value line '$line' -> key='${line%%=*}' value='${line#*=}'"
echo ""

# --- PART 10: printf ---------------------------------------
echo "== Part 10: printf formatting =="
printf '[%5s]\n'   "ab"
printf '[%-5s]\n'  "ab"
printf '[%05d]\n'  42
printf '[%.2f]\n'  3.14159
printf '[%8.2f]\n' 3.14159
printf '[%x]\n'    255
printf '%s is %d years old\n' "Asha" 29
echo "-- a neat table --"
printf '%-10s %5s %8s\n' "ITEM" "QTY" "PRICE"
printf '%-10s %5d %8.2f\n' "apples"  12  3.5
printf '%-10s %5d %8.2f\n' "bananas" 6   1.25
printf '%-10s %5d %8.2f\n' "cherries" 100 12
echo "-- printf -v stores the result in a variable --"
printf -v padded '%03d' 7
echo "padded = $padded"
echo "-- a line of dashes --"
printf '%.0s-' {1..30}; echo
echo "-- repeat with printf and tr --"
line=$(printf '%*s' 20 '' | tr ' ' '=')
echo "$line"
echo "-- %q makes text shell-safe --"
printf '%q\n' "has spaces & stuff"
echo "-- date without the 'date' command --"
printf 'today is %(%Y-%m-%d)T\n' -1
echo ""

# --- PART 11: escapes --------------------------------------
echo "== Part 11: escapes with \$'...' =="
tab=$'\t'
echo "a${tab}b   <- a tab between a and b"
nl=$'\n'
echo "line1${nl}line2"
echo ""

# --- PART 12: recipes --------------------------------------
echo "== Part 12: recipes =="
title="My Holiday Photos (2026)!"
slug="${title,,}"
slug="${slug//[^a-z0-9]/-}"
echo "slug : $title  ->  $slug"

url="https://www.example.com/path/page.html?x=1"
rest="${url#*://}"
host="${rest%%/*}"
echo "host : $url  ->  $host"

echo "zero-padded names:"
for i in {1..3}; do printf '  file%03d.txt\n' "$i"; done
echo ""

# --- PART 13: a real use: tidy file names in a sandbox -----
echo "== Part 13: tidy messy file names =="
DEMO="$HOME/bash-practice/lesson16-demo"
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1
touch "My Report FINAL.TXT" "Holiday Photo 01.JPG" "Budget 2026 (draft).XLSX"
echo "Before: $(printf '[%s] ' *)"
for old in *; do
    new="${old,,}"            # lowercase
    new="${new// /_}"         # spaces -> underscores
    new="${new//[()]/}"       # remove parentheses
    mv -- "$old" "$new"
done
echo "After : $(printf '[%s] ' *)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

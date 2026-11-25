#!/usr/bin/env bash
# ==========================================================
# Lesson 25 - Code.sh
# Topic : the order of expansions, brace/tilde expansion,
#         parameter expansion (defaults, indirection, case,
#         slicing), word splitting, extended globs
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson25-demo
#         and cleans up after itself.
# Needs : Bash 4.4+ (a few lines use Bash 5.1 and are guarded)
# ==========================================================
# shellcheck disable=SC2034,SC2051,SC2086,SC2154   # intentional: this lesson shows the pitfalls

DEMO="$HOME/bash-practice/lesson25-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

show() { printf '   %-34s -> %s\n' "$1" "$2"; }

# --- PART 1: the ORDER matters ------------------------------
echo "== Part 1: expansion order =="
x=3
show 'echo {1..3}'            "$(echo {1..3})"
show 'echo {1..$x}  (x=3)'    "$(echo {1..$x})"
show 'eval echo {1..$x}'      "$(eval echo "{1..$x}")"
show 'echo {a,b}{1,2}'        "$(echo {a,b}{1,2})"
show 'echo {01..05}'          "$(echo {01..05})"
show 'echo {1..10..3}'        "$(echo {1..10..3})"
show 'echo {e..a}'            "$(echo {e..a})"
echo "   (brace expansion runs BEFORE variables, so {1..\$x} fails)"
echo ""

# --- PART 2: braces build things ----------------------------
echo "== Part 2: brace expansion builds file trees =="
mkdir -p proj/{src,docs,tests/unit}
touch proj/src/{main,util}.py proj/docs/{intro,usage}.md
cp proj/src/main.py{,.bak}        # {,.bak} = main.py main.py.bak
find proj -type f | sort
echo ""

# --- PART 3: tilde ------------------------------------------
echo "== Part 3: tilde =="
show '~'      "$(echo ~)"
show '~+  (pwd)' "$(echo ~+ | sed "s#$HOME#~#")"
cd proj || exit 1
cd ..
show '~-  (OLDPWD)' "$(echo ~- | sed "s#$HOME#~#")"
echo ""

# --- PART 4: defaults ---------------------------------------
echo "== Part 4: default values =="
unset name
empty=""
set_val="Asha"
show '${name:-guest}   (unset)'     "${name:-guest}"
show '${empty:-guest}  (empty)'     "${empty:-guest}"
show '${empty-guest}   (empty,no :)' "[${empty-guest}]"
show '${set_val:-guest}'            "${set_val:-guest}"
show '${set_val:+is set}'           "${set_val:+is set}"
show '${name:+is set}  (unset)'     "[${name:+is set}]"
echo "   before := : name='${name-UNSET}'"
: "${name:=saved-default}"
echo "   after  := : name='$name'"
(
    unset must
    echo "-- ${must:?must be provided} --" 2>&1
) 2>&1 | sed 's/^/   error shown: /'
echo ""

# --- PART 5: indirection and names --------------------------
echo "== Part 5: indirection =="
colour="blue"
ptr="colour"
show '${!ptr}  (value of the variable named in ptr)' "${!ptr}"
app_name="demo"; app_port=8080; app_debug=1
show '${!app_*}  (names starting app_)' "${!app_*}"
declare -A scores=([asha]=90 [ravi]=75)
show '${!scores[@]}  (keys, sorted here)' "$(printf '%s ' "${!scores[@]}" | tr ' ' '\n' | sort | tr '\n' ' ')"
fruits=(apple banana cherry date)
show '${!fruits[@]}  (indexes)'   "${!fruits[*]}"
show '${#fruits[@]}  (count)'     "${#fruits[@]}"
show '${#colour}     (length)'    "${#colour}"
echo ""

# --- PART 6: case and transformations -----------------------
echo "== Part 6: case and transforms =="
word="hello World"
show '${word^^}  UPPER'  "${word^^}"
show '${word,,}  lower'  "${word,,}"
show '${word^}   first'  "${word^}"
show '${word~~}  swap'   "${word~~}"
if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )); then
    q="it's a \"test\""
    show '${q@Q}  quoted for reuse'  "${q@Q}"
    show '${word@U} / ${word@L}'     "${word@U} / ${word@L}"
    show '${word@a} attributes'      "[$(declare -r ro=1; echo "${ro@a}")]"
else
    echo "   (Bash 5.1+ needed for @Q @U @L, skipped)"
fi
echo ""

# --- PART 7: slicing ----------------------------------------
echo "== Part 7: slicing =="
s="0123456789"
show '${s:2}'        "${s:2}"
show '${s:2:3}'      "${s:2:3}"
show '${s: -3}  (space before -)' "${s: -3}"
show '${s:0:-2}'     "${s:0:-2}"
show '${fruits[@]:1:2}'  "${fruits[*]:1:2}"
set -- one two three four
show '${@:2}  (from the 2nd arg)'  "${*:2}"
show '${@: -1}  (last arg)'        "${*: -1}"
echo ""

# --- PART 8: pattern edit review ----------------------------
echo "== Part 8: remove / replace patterns =="
path="/home/asha/report.final.tar.gz"
show '${path##*/}   basename'   "${path##*/}"
show '${path%/*}    dirname'    "${path%/*}"
show '${path#*.}    ext (all)'  "${path#*.}"
show '${path##*.}   ext (last)' "${path##*.}"
show '${path/asha/ravi}  first' "${path/asha/ravi}"
show '${path//a/A}  all'        "${path//a/A}"
echo ""

# --- PART 9: word splitting ---------------------------------
echo "== Part 9: word splitting and IFS =="
list="a b  c"
count() { echo "$#"; }
show 'count $list     (unquoted)' "$(count $list)"
show 'count "$list"   (quoted)'   "$(count "$list")"
csv="red,green,blue"
IFS=, read -r -a parts <<< "$csv"
show 'IFS=, read -a'   "${#parts[@]} parts: ${parts[*]}"
( IFS=:; set -- a b c; show '"$*" with IFS=:' "$*" )
show '"$@" vs "$*" count' "$(set -- 'a b' c; echo "$# args; \"\$*\" is 1 word: [$*]")"
echo ""

# --- PART 10: globbing and extglob --------------------------
echo "== Part 10: globbing =="
touch a.txt b.txt c.md .hidden "my file.txt"
show 'echo *'            "$(echo *)"
show 'echo *.txt'        "$(echo *.txt)"
show 'echo *.nomatch'    "$(echo *.nomatch)"
shopt -s nullglob
show 'nullglob: *.nomatch' "[$(echo *.nomatch)]"
shopt -u nullglob
shopt -s dotglob
show 'dotglob: *'        "$(echo * | tr ' ' ',')"
shopt -u dotglob
shopt -s extglob
show 'extglob: !(*.txt)' "$(echo !(*.txt))"
show 'extglob: +(a|b).txt' "$(echo +(a|b).txt)"
show 'extglob: @(a|c).*' "$(echo @(a|c).*)"
shopt -u extglob
shopt -s globstar
show 'globstar: proj/**/*.py' "$(echo proj/**/*.py)"
shopt -u globstar
echo ""

# --- PART 11: a safe eval alternative: printf -v ------------
echo "== Part 11: build variable names safely =="
for i in 1 2 3; do
    printf -v "item_$i" '%s' "value-$i"
done
show 'item_1 item_2 item_3' "$item_1 $item_2 $item_3"
for i in 1 2 3; do
    ref="item_$i"
    printf '   %s = %s\n' "$ref" "${!ref}"
done
echo ""

# --- CLEANUP ------------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

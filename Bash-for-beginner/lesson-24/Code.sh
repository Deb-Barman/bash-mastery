#!/usr/bin/env bash
# ==========================================================
# Lesson 24 - Code.sh
# Topic : mastery: debugging (PS4, stack traces), performance
#         (builtins vs forks), portability (sh vs bash),
#         testing (mini framework + the main guard), security
#         (injection, option-like file names), style linting,
#         install pattern
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson24-demo
#         and cleans up after itself. "Dangerous" examples use
#         harmless echo commands.
# Needs : Bash 4+. (Bash 5 for the microsecond timer; handled.)
# ==========================================================

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This lesson needs Bash 4 or newer (you have $BASH_VERSION)."
    exit 1
fi

DEMO="$HOME/bash-practice/lesson24-demo"
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# ==========================================================
# PART 1: debugging with a useful PS4
# ==========================================================
echo "== Part 1: set -x with a helpful PS4 =="
cat > traced.sh << 'EOF'
#!/usr/bin/env bash
add() {
    local a=$1 b=$2
    echo $(( a + b ))
}
total=$(add 2 3)
echo "total = $total"
EOF
echo "-- plain bash -x --"
bash -x traced.sh 2>&1 | head -n 8 | sed 's/^/   /'
echo "-- with PS4 showing file:line:function (PS4 is set at the top of the traced file) --"
{
    echo "PS4='+ \${BASH_SOURCE##*/}:\${LINENO}:\${FUNCNAME[0]:-main}: '"
    cat traced.sh
} > traced-ps4.sh
bash -x traced-ps4.sh 2>&1 | head -n 8 | sed 's/^/   /'
echo "   Now every line tells you WHICH file, WHICH line and WHICH function it came from."
echo ""

# ==========================================================
# PART 2: a stack trace on error
# ==========================================================
echo "== Part 2: a stack trace when something fails =="
cat > stacktrace.sh << 'EOF'
#!/usr/bin/env bash
set -eEuo pipefail

on_error() {
    local status=$? i
    echo "ERROR: command '$BASH_COMMAND' failed with status $status" >&2
    echo "Stack trace (innermost first):" >&2
    for (( i = 0; i < ${#FUNCNAME[@]} - 1; i++ )); do
        echo "   at ${FUNCNAME[i + 1]}() called from line ${BASH_LINENO[i]}" >&2
    done
}
trap on_error ERR

level_three() { ls /definitely/not/here; }
level_two()   { level_three; }
level_one()   { level_two; }

level_one
EOF
bash stacktrace.sh 2>&1 | sed 's/^/   /'
echo ""

# ==========================================================
# PART 3: performance, builtins vs forks
# ==========================================================
echo "== Part 3: performance: builtins vs starting new processes =="
now_us() {                                   # microseconds since the epoch
    if [[ -n ${EPOCHREALTIME:-} ]]; then
        local t=${EPOCHREALTIME/./}
        echo "$t"
    else
        echo $(( $(date +%s) * 1000000 ))
    fi
}
bench() {                                    # bench "label" COUNT command...
    local label=$1 n=$2 t0 t1 i
    shift 2
    t0=$(now_us)
    for (( i = 0; i < n; i++ )); do
        "$@" > /dev/null
    done
    t1=$(now_us)
    printf '   %-34s %6d ms  (%d runs)\n' "$label" $(( (t1 - t0) / 1000 )) "$n"
}

path="/home/asha/docs/report.final.txt"
fn_basename()   { basename "$path"; }
fn_expansion()  { echo "${path##*/}"; }
fn_expr()       { expr 7 \* 6; }
fn_arith()      { echo $(( 7 * 6 )); }
fn_date()       { date +%s; }
fn_printf_time(){ printf '%(%s)T\n' -1; }

N=500
echo "(Each pair does the same job $N times: forking a program vs using Bash itself.)"
bench "basename (starts a program)"    $N fn_basename
bench "\${path##*/} (built in)"         $N fn_expansion
bench "expr 7 * 6 (starts a program)"  $N fn_expr
bench "\$(( 7 * 6 )) (built in)"        $N fn_arith
bench "date +%s (starts a program)"    $N fn_date
bench "printf '%(%s)T' (built in)"     $N fn_printf_time

echo "-- summing 20,000 numbers: a Bash loop vs awk --"
seq 1 20000 > numbers.txt
t0=$(now_us)
sum=0
while IFS= read -r n; do
    (( sum += n ))
done < numbers.txt
t1=$(now_us)
printf '   Bash while-read loop : sum=%s in %d ms\n' "$sum" $(( (t1 - t0) / 1000 ))
t0=$(now_us)
sum=$(awk '{s += $1} END {print s}' numbers.txt)
t1=$(now_us)
printf '   awk                  : sum=%s in %d ms\n' "$sum" $(( (t1 - t0) / 1000 ))
echo "   Rule: Bash is great glue. For bulk text/number crunching, hand the work to awk/sed/sort."
echo ""

# ==========================================================
# PART 4: portability
# ==========================================================
echo "== Part 4: portability (sh vs bash) =="
echo "'sh' on this machine is: $(readlink -f "$(command -v sh)" 2> /dev/null || echo unknown)"
cat > bashism.sh << 'EOF'
if [[ "abc" == a* ]]; then echo "[[ ]] works"; fi
arr=(one two three)
echo "array element: ${arr[1]}"
EOF
echo "-- running Bash-only syntax with bash --"
bash bashism.sh 2>&1 | sed 's/^/   /'
echo "-- running the same file with sh (may fail if sh is dash) --"
sh bashism.sh 2>&1 | sed 's/^/   /' | head -n 3
echo "   (If you saw errors, that's why '#!/bin/sh' scripts must avoid Bash-only features.)"
echo "-- a POSIX-friendly version of the same idea --"
cat > posix.sh << 'EOF'
case "abc" in
    a*) echo "case pattern works everywhere" ;;
esac
set -- one two three
echo "second positional: $2"
EOF
sh posix.sh 2>&1 | sed 's/^/   /'
echo "-- GNU or BSD? Check before using flags that differ --"
if date --version > /dev/null 2>&1; then echo "   date : GNU (supports -d)"; else echo "   date : BSD/macOS (use -j -f ...)"; fi
if sed --version > /dev/null 2>&1; then echo "   sed  : GNU (-i without suffix OK)"; else echo "   sed  : BSD/macOS (-i needs a suffix argument)"; fi
echo ""

# ==========================================================
# PART 5: testing, with the "main guard"
# ==========================================================
echo "== Part 5: testing =="
cat > textlib.sh << 'EOF'
#!/usr/bin/env bash
# textlib.sh - small functions we want to test

slugify() {
    local s="${1,,}"
    s="${s//[^a-z0-9]/-}"
    s=$(tr -s '-' <<< "$s")
    s="${s#-}"
    echo "${s%-}"
}

is_number() { [[ ${1:-} =~ ^-?[0-9]+$ ]]; }

max() {
    local m=$1 n
    shift
    for n in "$@"; do (( n > m )) && m=$n; done
    echo "$m"
}

main() {
    echo "textlib running as a program: $(slugify "${1:-Hello World}")"
}

# THE MAIN GUARD: run main only when executed, NOT when sourced
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
EOF
chmod +x textlib.sh
echo "-- executed: main runs --"
./textlib.sh "Bash Rocks!" | sed 's/^/   /'
echo "-- sourced: nothing runs, but the functions become available --"
source ./textlib.sh
echo "   slugify is now a $(type -t slugify)"

# a tiny test framework
PASS=0
FAIL=0
assert_eq() {                                # assert_eq "description" EXPECTED ACTUAL
    if [[ $2 == "$3" ]]; then
        PASS=$(( PASS + 1 ))
        printf '   PASS  %s\n' "$1"
    else
        FAIL=$(( FAIL + 1 ))
        printf '   FAIL  %s\n         expected: [%s]\n         actual  : [%s]\n' "$1" "$2" "$3"
    fi
}
assert_status() {                            # assert_status "description" EXPECTED_STATUS command...
    local desc=$1 expected=$2 actual
    shift 2
    "$@" > /dev/null 2>&1
    actual=$?
    assert_eq "$desc" "$expected" "$actual"
}

echo "-- running the tests --"
assert_eq "slugify simple"            "hello-world"   "$(slugify "Hello World")"
assert_eq "slugify punctuation"       "my-photos-2026" "$(slugify "My Photos (2026)!")"
assert_eq "slugify trims dashes"      "abc"           "$(slugify "--abc--")"
assert_status "is_number accepts 42"  0  is_number 42
assert_status "is_number accepts -7"  0  is_number -7
assert_status "is_number rejects 4x"  1  is_number 4x
assert_status "is_number rejects ''"  1  is_number ""
assert_eq "max of several"            "19"            "$(max 4 19 7 12)"
assert_eq "max of one"                "5"             "$(max 5)"
echo "-- one test that FAILS on purpose, to show what a failure report looks like --"
assert_eq "max with negatives (wrong expectation)" "-1" "$(max -5 -3 -9)"
echo "-- result: $PASS passed, $FAIL failed --"
echo "   (-3 is the correct answer, so that last 'failure' is the test being wrong,"
echo "    not the function. Always ask: is the code wrong, or is the test?)"
echo ""

# ==========================================================
# PART 6: security
# ==========================================================
echo "== Part 6: security: injection and option-like names =="
echo "-- 1) eval on user input runs whatever is inside --"
user_input='report; echo INJECTED-COMMAND-RAN'
echo "   input: $user_input"
echo -n "   unsafe  (eval \"echo \$input\"): "
eval "echo $user_input"
echo -n "   safe    (printf '%s' \"\$input\") : "
printf '%s\n' "$user_input"

echo "-- 2) unquoted variables split and glob --"
mkdir -p lab && cd lab || exit 1
touch "a b.txt" c.txt
name="a b.txt"
echo "   unquoted  : $(printf '[%s]' $name)"
echo "   quoted    : $(printf '[%s]' "$name")"

echo "-- 3) file names that look like options --"
touch -- "-l" "-n"
echo "   files here: $(printf '[%s]' *)"
echo "   'ls *' treats -l as an OPTION:"
ls * 2>&1 | head -n 3 | sed 's/^/      /'
echo "   'ls ./*' and 'ls -- *' are safe:"
ls ./* | head -n 3 | sed 's/^/      /'
rm -- "-l" "-n" "a b.txt" c.txt
cd .. || exit 1

echo "-- 4) predictable temp names vs mktemp --"
echo "   unsafe: /tmp/myapp.tmp (anyone can pre-create it or symlink it)"
safe=$(mktemp)
echo "   safe  : $safe (unique, created with mode $(stat -c %a "$safe"))"
rm -f "$safe"

echo "-- 5) private files: umask 077 --"
( umask 077; touch private.txt; echo "   new file permissions with umask 077: $(stat -c %a private.txt)" )
echo "-- 6) printf %q makes any text safe to reuse in a shell command --"
printf '   %q\n' 'name with spaces & $pecial; chars'
echo ""

# ==========================================================
# PART 7: a tiny style linter
# ==========================================================
echo "== Part 7: a tiny style linter =="
cat > bad.sh << 'EOF'
function backup {
    files=`ls *.txt`
    for f in $files; do
        if [ $f = "x" ]; then rm $f; fi
    done
    echo $[1+2]
}
EOF
cat > good.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

backup() {
    local f
    for f in ./*.txt; do
        [[ $f == "./x.txt" ]] && rm -- "$f"
    done
    echo $(( 1 + 2 ))
}

backup
EOF
lint() {                                     # lint FILE: print style problems
    local f=$1 problems=0 n
    check() {                                # check "message" 'grep -E pattern'
        local out
        out=$(grep -n -E "$2" "$f" || true)
        if [[ -n $out ]]; then
            echo "   $f: $1"
            echo "$out" | sed 's/^/        line /'
            problems=$(( problems + 1 ))
        fi
    }
    head -n 1 "$f" | grep -q '^#!' || { echo "   $f: missing shebang on line 1"; problems=$(( problems + 1 )); }
    grep -q 'set -[a-z]*e[a-z]*u\|set -euo' "$f" || { echo "   $f: no 'set -euo pipefail'"; problems=$(( problems + 1 )); }
    check "backticks: use \$( )"                     '`'
    check "'function' keyword: use name() { }"        '^function '
    check "old arithmetic \$[ ]: use \$(( ))"          '\$\['
    check "single [ ]: prefer [[ ]]"                   '(^|[ ;])\[ [^[]'
    check "parsing ls output: use a glob"              '=`?\$?\(?ls '
    n=$problems
    (( n == 0 )) && echo "   $f: no problems found"
    return 0
}
lint bad.sh
lint good.sh
if command -v shellcheck > /dev/null 2>&1; then
    echo "-- shellcheck says about bad.sh --"
    shellcheck bad.sh 2>&1 | grep -E '^In|SC[0-9]+' | head -n 8 | sed 's/^/   /'
else
    echo "(shellcheck is not installed here: install it, it's the best linter you can get.)"
fi
echo ""

# ==========================================================
# PART 8: the install pattern
# ==========================================================
echo "== Part 8: installing a tool (the install command) =="
PREFIX="$DEMO/fake-usr-local"
mkdir -p "$PREFIX"
install -D -m 755 textlib.sh "$PREFIX/bin/textlib"
install -D -m 644 good.sh   "$PREFIX/share/examples/good.sh"
echo "installed into $PREFIX:"
(cd "$PREFIX" && find . -type f | sort | while read -r f; do printf '   %s  %s\n' "$(stat -c %A "$f")" "$f"; done)
echo "   (A real Makefile would offer 'make install PREFIX=/usr/local', 'make test', 'make lint'.)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Congratulations: you finished the Bash course! 🎓"

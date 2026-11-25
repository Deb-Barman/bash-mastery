#!/usr/bin/env bash
# ==========================================================
# Lesson 26 - Code.sh
# Topic : arithmetic in Bash: (( )), $(( )), bases, bit
#         operations, decimals with awk/bc, random numbers,
#         integer limits, and practical math functions
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson26-demo
#         and cleans up after itself.
# Needs : Bash 4+ (awk required; bc optional)
# ==========================================================
# shellcheck disable=SC2034,SC2004,SC2154   # intentional: lesson shows both styles

DEMO="$HOME/bash-practice/lesson26-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

show() { printf '   %-34s -> %s\n' "$1" "$2"; }

# --- PART 1: three ways to do math -------------------------
echo "== Part 1: (( )), \$(( )), let, declare -i =="
a=17; b=5
show '$(( a + b ))'      "$(( a + b ))"
show '$(( a - b ))'      "$(( a - b ))"
show '$(( a * b ))'      "$(( a * b ))"
show '$(( a / b ))  integer' "$(( a / b ))"
show '$(( a % b ))  remainder' "$(( a % b ))"
show '$(( a ** 2 )) power' "$(( a ** 2 ))"
show '$(( -17 / 5 )) toward zero' "$(( -17 / 5 ))"
show '$(( -17 % 5 )) sign follows left' "$(( -17 % 5 ))"
(( a += 3 ))
show '(( a += 3 )) then a' "$a"
(( a++ ))
show '(( a++ )) then a' "$a"
(( b > 3 )) && echo "   (( b > 3 )) is true: exit status $?"
(( b > 30 )) || echo "   (( b > 30 )) is false: exit status 1"
show 'ternary (( b>3 ? 100 : 0 ))' "$(( b > 3 ? 100 : 0 ))"
let "c = a * 2"
show 'let "c = a * 2"'   "$c"
declare -i d
d="6*7"
show 'declare -i d; d="6*7"' "$d"
e="6*7"
show 'plain e="6*7" stays text' "$e"
echo ""

# --- PART 2: variables inside (( )) ------------------------
echo "== Part 2: no \$ needed, strings become 0 =="
x=10
show '$(( x * 2 ))  no $ needed' "$(( x * 2 ))"
word="hello"
show '$(( word + 1 ))  text is 0' "$(( word + 1 ))"
unset nothing
show '$(( nothing + 1 )) unset is 0' "$(( nothing + 1 ))"
echo ""

# --- PART 3: number bases ----------------------------------
echo "== Part 3: bases =="
show '2#1010  (binary)'   "$(( 2#1010 ))"
show '8#17    (octal)'    "$(( 8#17 ))"
show '16#ff   (hex)'      "$(( 16#ff ))"
show '0xFF    (hex)'      "$(( 0xFF ))"
show '36#zz   (base 36)'  "$(( 36#zz ))"
show 'printf %x 255'      "$(printf '%x' 255)"
show 'printf %o 255'      "$(printf '%o' 255)"
show 'printf %X 255'      "$(printf '%X' 255)"
show 'printf %08d 42'     "$(printf '%08d' 42)"
to_bin() {                      # to_bin NUMBER
    local n=$1 out=""
    (( n == 0 )) && { echo 0; return; }
    while (( n > 0 )); do
        out="$(( n % 2 ))$out"
        (( n /= 2 ))
    done
    echo "$out"
}
show 'to_bin 10'  "$(to_bin 10)"
show 'to_bin 255' "$(to_bin 255)"
n="08"
show 'octal trap: 10#$n for "08"' "$(( 10#$n + 1 ))"
( (( n + 1 )) ) 2>&1 | sed 's/^/   without 10#: /'
echo ""

# --- PART 4: bit operations --------------------------------
echo "== Part 4: bits =="
show '12 & 10  (and)'  "$(( 12 & 10 ))"
show '12 | 10  (or)'   "$(( 12 | 10 ))"
show '12 ^ 10  (xor)'  "$(( 12 ^ 10 ))"
show '~5       (not)'  "$(( ~5 ))"
show '1 << 4   (shift left)'  "$(( 1 << 4 ))"
show '256 >> 3 (shift right)' "$(( 256 >> 3 ))"
READ=4; WRITE=2; EXEC=1
perm=$(( READ | WRITE ))
show 'perm = READ|WRITE'      "$perm"
(( perm & WRITE )) && echo "   WRITE bit is set"
(( perm & EXEC ))  || echo "   EXEC bit is NOT set"
(( perm |= EXEC ));  show 'set EXEC:    perm |= 1'   "$perm"
(( perm &= ~WRITE )); show 'clear WRITE: perm &= ~2'  "$perm"
(( perm ^= READ ));  show 'toggle READ:  perm ^= 4'   "$perm"
echo ""

# --- PART 5: decimals --------------------------------------
echo "== Part 5: Bash has NO decimals =="
show '$(( 10 / 3 ))  wrong for decimals' "$(( 10 / 3 ))"
show 'awk  10/3  (2 places)'  "$(awk 'BEGIN { printf "%.2f", 10 / 3 }')"
show 'awk  sqrt(2)'           "$(awk 'BEGIN { printf "%.4f", sqrt(2) }')"
show 'awk  2 ^ 0.5'           "$(awk 'BEGIN { printf "%.4f", 2 ^ 0.5 }')"
if command -v bc > /dev/null 2>&1; then
    show 'bc   scale=3; 10/3'  "$(echo 'scale=3; 10/3' | bc)"
    show 'bc -l  s(1) sine'    "$(echo 's(1)' | bc -l | cut -c1-8)"
else
    echo "   (bc is not installed, awk covers the same ground)"
fi
price=19.99; qty=3
show 'total = price * qty (awk)' "$(awk -v p="$price" -v q="$qty" 'BEGIN { printf "%.2f", p * q }')"
if awk -v a=0.1 -v b=0.2 'BEGIN { exit !(a + b == 0.3) }'; then
    echo "   0.1 + 0.2 == 0.3 : true"
else
    echo "   0.1 + 0.2 == 0.3 : FALSE (float rounding exists in every language)"
fi
if awk -v a=3.7 -v b=3.14 'BEGIN { exit !(a > b) }'; then
    echo "   compare decimals: 3.7 > 3.14 is true (done by awk)"
fi
echo ""

# --- PART 6: random numbers --------------------------------
echo "== Part 6: random numbers =="
ok=yes
for _ in 1 2 3 4 5 6 7 8 9 10; do
    r=$(( RANDOM % 6 + 1 ))
    (( r >= 1 && r <= 6 )) || ok=no
done
show '10 dice rolls all in 1..6?'  "$ok"
RANDOM=42; first="$RANDOM $RANDOM $RANDOM"
RANDOM=42; second="$RANDOM $RANDOM $RANDOM"
[[ $first == "$second" ]] && show 'same seed, same sequence?' "yes (seed 42)"
if [[ -n ${SRANDOM:-} ]]; then
    show 'SRANDOM (32-bit, Bash 5.1+)' "available"
fi
if command -v shuf > /dev/null 2>&1; then
    show 'shuf -i 1-10 -n 3 (3 distinct)' "$(shuf -i 1-10 -n 3 | sort -n | wc -l) numbers"
fi
echo ""

# --- PART 7: integer limits --------------------------------
echo "== Part 7: 64-bit limits =="
show '2 ** 62'           "$(( 2 ** 62 ))"
show '2 ** 63  overflows' "$(( 2 ** 63 ))"
show '2 ** 64  wraps to'  "$(( 2 ** 64 ))"
show 'max = 2**63 - 1'    "$(( 9223372036854775807 ))"
echo "   (for bigger numbers use bc or python3: Bash integers are 64-bit)"
echo ""

# --- PART 8: practical math functions ----------------------
echo "== Part 8: useful functions =="
gcd() {                         # gcd A B
    local a=$1 b=$2 t
    while (( b != 0 )); do
        t=$b
        b=$(( a % b ))
        a=$t
    done
    echo "$a"
}
factorial() {                   # factorial N
    local n=$1 f=1 i
    for (( i = 2; i <= n; i++ )); do
        (( f *= i ))
    done
    echo "$f"
}
is_prime() {                    # is_prime N  (exit status)
    local n=$1 i
    (( n < 2 )) && return 1
    for (( i = 2; i * i <= n; i++ )); do
        (( n % i == 0 )) && return 1
    done
    return 0
}
human() {                       # human BYTES  -> 1.5 MB
    awk -v b="$1" 'BEGIN {
        split("B KB MB GB TB", u, " "); i = 1
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i]
    }'
}
percent() {                     # percent PART TOTAL
    awk -v p="$1" -v t="$2" 'BEGIN { printf "%.1f%%", p * 100 / t }'
}
show 'gcd 48 18'        "$(gcd 48 18)"
show 'factorial 10'     "$(factorial 10)"
primes=""
for n in {1..30}; do is_prime "$n" && primes="$primes $n"; done
show 'primes up to 30'  "${primes# }"
show 'human 1536'       "$(human 1536)"
show 'human 5242880'    "$(human 5242880)"
show 'human 999'        "$(human 999)"
show 'percent 45 180'   "$(percent 45 180)"
echo ""

# --- PART 9: FizzBuzz and SECONDS --------------------------
echo "== Part 9: loops with math =="
line=""
for (( i = 1; i <= 15; i++ )); do
    if   (( i % 15 == 0 )); then line="$line FizzBuzz"
    elif (( i % 3  == 0 )); then line="$line Fizz"
    elif (( i % 5  == 0 )); then line="$line Buzz"
    else line="$line $i"
    fi
done
echo "  $line"
SECONDS=0
sleep 1
show 'SECONDS after sleep 1'  "$SECONDS (at least 1)"
echo ""

# --- PART 10: sum a column ---------------------------------
echo "== Part 10: sums and averages from a file =="
printf '%s\n' 12 7 30 5 46 > numbers.txt
sum=0; count=0
while read -r n; do
    (( sum += n, count++ ))
done < numbers.txt
show 'sum (Bash loop)'    "$sum"
show 'count'              "$count"
show 'average (awk)'      "$(awk '{ s += $1 } END { printf "%.1f", s / NR }' numbers.txt)"
show 'max (awk)'          "$(awk 'NR == 1 || $1 > m { m = $1 } END { print m }' numbers.txt)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

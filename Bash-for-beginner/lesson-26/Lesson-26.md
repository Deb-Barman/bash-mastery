# Lesson 26 — Arithmetic & Math

**Level 7 · Shell Internals · Time: ~70 minutes**

---

## 🎯 What you will learn

- The three arithmetic tools: `$(( ))`, `(( ))`, and `let` / `declare -i`
- All operators, including increments, ternary and bit operations
- Number **bases** (binary, octal, hex) and the famous octal trap
- Decimals: Bash cannot do them, so you use `awk` or `bc`
- Random numbers: `RANDOM`, `SRANDOM`, `shuf`
- 64-bit limits and overflow
- Reusable math functions: gcd, factorial, prime test, human-readable sizes, percentages

> Bash does **integer** math only. For everything else you call a helper tool. Knowing which one to use is the skill.

---

## 1. Three ways to calculate

| Syntax | What it does | Use it for |
|--------|--------------|------------|
| `$(( expr ))` | **returns the value** | `total=$(( a + b ))` |
| `(( expr ))` | runs the math, sets the **exit status** (0 if non-zero result, 1 if zero) | `if (( n > 5 ))`, `(( i++ ))` |
| `let "x = expr"` | old style, like `(( ))` | rare; you will see it in old scripts |
| `declare -i x` | variable that always evaluates assignments as math | `declare -i d; d="6*7"` → `42` |

```bash
a=17; b=5
echo $(( a + b ))          # 22     (no $ needed inside)
(( a += 3 ))               # a is now 20
if (( a > b )); then echo "bigger"; fi
total=$(( a * b ))
```

Remember: `$(( ))` **gives** a value, `(( ))` **tests or changes** one.

> 🐍 **Python bridge:** in Python `a + b` is just code. In Bash, `a + b` alone would try to run a command called `a`. Math must live inside `$(( ))` or `(( ))`.

---

## 2. Operators

| Operator | Meaning | Example → result |
|----------|---------|-------------------|
| `+ - * /` | basic | `17 / 5` → `3` (integer!) |
| `%` | remainder | `17 % 5` → `2` |
| `**` | power | `17 ** 2` → `289` |
| `++ --` | add / subtract 1 | `(( i++ ))` |
| `+= -= *= /= %=` | update in place | `(( n *= 2 ))` |
| `< <= > >= == !=` | comparison (gives 1 or 0) | `(( a >= b ))` |
| `&& \|\| !` | logic | `(( a > 1 && b < 9 ))` |
| `cond ? x : y` | ternary | `$(( n > 3 ? 100 : 0 ))` |
| `,` | several expressions | `(( sum += n, count++ ))` |

Negative numbers: division **truncates toward zero** (`-17 / 5` → `-3`) and the remainder takes the sign of the left number (`-17 % 5` → `-2`). Python's `//` and `%` behave differently here (`-17 // 5` is `-4`).

> 🐍 **Python bridge:** Bash `/` is Python `int(a / b)` (truncate), not `a // b` (floor). `**` is the same in both. Bash has no `and` / `or`; it uses `&&` and `||`.

### Inside math, text becomes numbers

```bash
x=10
echo $(( x * 2 ))        # 20   (variables need no $)
echo $(( word + 1 ))     # 1    (an unknown name counts as 0, silently!)
```

A typo in a variable name gives `0`, not an error, so check inputs before calculating.

---

## 3. Number bases

```bash
echo $(( 2#1010 ))       # 10    binary
echo $(( 8#17 ))         # 15    octal
echo $(( 16#ff ))        # 255   hex  (same as 0xff)
echo $(( 36#zz ))        # 1295  any base up to 64
printf '%x\n' 255        # ff    decimal → hex
printf '%o\n' 255        # 377   decimal → octal
printf '%08d\n' 42       # 00000042
```

### 🚨 The octal trap

A number that starts with `0` is **octal**. So `08` and `09` are errors:

```bash
n=08
echo $(( n + 1 ))        # error: value too great for base
echo $(( 10#$n + 1 ))    # 9   ✅ force base 10
```

This bites every time you parse dates and times (`date +%m` returns `08`). Rule: **use `10#$n`** for numbers read from text.

Binary output has no `printf` letter, so write a small function (see `Code.sh`) or use `bc`: `echo 'obase=2; 10' | bc`.

> 🐍 **Python bridge:** `int("ff", 16)` ↔ `$(( 16#ff ))`, `hex(255)` ↔ `printf '%x' 255`, `bin(10)` has no direct Bash twin.

---

## 4. Bit operations

| Operator | Meaning | `12 op 10` |
|----------|---------|------------|
| `&` | AND | `8` |
| `\|` | OR | `14` |
| `^` | XOR | `6` |
| `~` | NOT (flip all bits) | `~5` → `-6` |
| `<<` `>>` | shift left / right | `1 << 4` → `16` |

The practical use is **flags**: pack several yes/no options in one number (just like Linux file permissions).

```bash
READ=4; WRITE=2; EXEC=1
perm=$(( READ | WRITE ))        # 6   set two flags
(( perm & WRITE )) && echo "can write"   # test a flag
(( perm |= EXEC ))              # set a flag    → 7
(( perm &= ~WRITE ))            # clear a flag  → 5
(( perm ^= READ ))              # toggle a flag → 1
```

That is exactly how `chmod 755` works: `7 = 4+2+1`.

---

## 5. Decimals: Bash has none

```bash
echo $(( 10 / 3 ))              # 3   (not 3.33)
```

Choose a helper:

| Tool | Example | When |
|------|---------|------|
| **`awk`** | `awk 'BEGIN { printf "%.2f\n", 10/3 }'` | almost always available, great for formatting |
| **`bc`** | `echo 'scale=3; 10/3' \| bc` | arbitrary precision, `-l` adds `sqrt`, `s()`, `l()` |
| **`python3`** | `python3 -c 'import math; print(math.pi)'` | heavy maths |

Pass Bash variables to `awk` with `-v`, never by pasting them into the program text:

```bash
price=19.99; qty=3
awk -v p="$price" -v q="$qty" 'BEGIN { printf "%.2f\n", p * q }'   # 59.97
```

Comparing decimals: let `awk` decide and use its exit status.

```bash
if awk -v a="$x" -v b="$y" 'BEGIN { exit !(a > b) }'; then echo "x is bigger"; fi
```

Floating-point is never exact in **any** language: `0.1 + 0.2 == 0.3` is false in Python too. Round or compare with a tolerance when it matters.

---

## 6. Random numbers

```bash
echo $RANDOM                   # 0 to 32767
echo $(( RANDOM % 6 + 1 ))     # a dice roll: 1 to 6
echo $SRANDOM                  # 32-bit random (Bash 5.1+)
shuf -i 1-49 -n 6              # 6 different numbers from 1 to 49 (lottery)
shuf -n 1 names.txt            # one random line from a file
RANDOM=42                      # seed: the same sequence every time (useful in tests)
```

`$RANDOM` is **not secure**. For passwords or tokens use `openssl rand -hex 16` or `head -c 16 /dev/urandom | xxd -p`.

> 🐍 **Python bridge:** `random.randint(1, 6)` ↔ `$(( RANDOM % 6 + 1 ))`, `random.sample(range(1,50), 6)` ↔ `shuf -i 1-49 -n 6`, `random.seed(42)` ↔ `RANDOM=42`, `secrets.token_hex(16)` ↔ `openssl rand -hex 16`.

---

## 7. Limits: 64-bit integers

```bash
echo $(( 2 ** 62 ))   # 4611686018427387904
echo $(( 2 ** 63 ))   # -9223372036854775808   ← overflow wraps around, NO error
echo $(( 2 ** 64 ))   # 0
```

Largest value: `9223372036854775807`. Bash will **not** warn you when it wraps. For bigger numbers use `bc` or Python (which has unlimited integers).

---

## 8. Practical math functions

```bash
gcd() {                        # greatest common divisor
    local a=$1 b=$2 t
    while (( b != 0 )); do t=$b; b=$(( a % b )); a=$t; done
    echo "$a"
}

is_prime() {                   # returns exit status 0 for primes
    local n=$1 i
    (( n < 2 )) && return 1
    for (( i = 2; i * i <= n; i++ )); do
        (( n % i == 0 )) && return 1
    done
    return 0                   # explicit success: do not rely on the loop's last status
}

human() {                      # 1536 → 1.5 KB
    awk -v b="$1" 'BEGIN {
        split("B KB MB GB TB", u, " "); i = 1
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i]
    }'
}

percent() { awk -v p="$1" -v t="$2" 'BEGIN { printf "%.1f%%", p * 100 / t }'; }
```

The system also has `numfmt`: `numfmt --to=iec 5242880` → `5.0M`.

Other handy built-ins: `SECONDS` (seconds since the shell or script started; set it to `0` to time something), `printf '%.2f'` for rounding display, and C-style loops: `for (( i=0; i<10; i++ ))`.

---

## 9. Sum and average from a file

```bash
sum=0; count=0
while read -r n; do (( sum += n, count++ )); done < numbers.txt
echo "sum=$sum count=$count"
awk '{ s += $1 } END { printf "avg=%.1f\n", s / NR }' numbers.txt
```

For big files `awk` is much faster than a Bash loop. Use Bash for small, logic-heavy work, and `awk` for column maths.

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `echo 10 / 3` | prints text `10 / 3` | `echo $(( 10 / 3 ))` |
| `echo $(( 10 / 3 ))` expecting 3.33 | prints `3` | `awk` or `bc` |
| `n=08; $(( n + 1 ))` | octal error | `$(( 10#$n + 1 ))` |
| typo in variable name inside `$(( ))` | silently `0` | validate input first |
| `(( i++ ))` when `i=0` | exit status 1 (the value was 0), kills a script with `set -e` | `i=$(( i + 1 ))` or `(( ++i ))` |
| `[ $a > $b ]` | redirects output to a file named `$b` | `(( a > b ))` or `[ "$a" -gt "$b" ]` |
| float in `$(( 1.5 + 1 ))` | syntax error | `awk` |
| `$RANDOM` for passwords | predictable | `openssl rand` |
| huge factorials | overflow wraps silently | `bc` or Python |
| `-17 % 5` expecting 3 | gives `-2` | add the divisor: `$(( (x % m + m) % m ))` |

---

## ✅ Summary

- `$(( ))` returns a value; `(( ))` changes or tests; both use **integers only**
- Variables inside need no `$`; unknown names silently become `0`
- Bases: `2#` `8#` `16#` or `0x`; force base 10 with `10#$n` to avoid the octal trap
- Bits: `& | ^ ~ << >>` pack flags into one number
- Decimals → `awk` (pass values with `-v`) or `bc`
- `RANDOM` is fast but not secure; `shuf` picks random items; `openssl rand` makes secrets
- Integers are 64-bit and wrap silently on overflow
- Build small functions (`gcd`, `human`, `percent`) and reuse them

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

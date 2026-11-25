# Lesson 26 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson26-demo`, deleted at the end. Needs Bash 4+ and `awk`. `bc` and `shuf` are used only if they exist. The helper `show` prints `expression -> result` in two aligned columns, the same as Lesson 25.

---

## Part 1: three ways to do math

| Line | Result | Lesson |
|------|--------|--------|
| `$(( a + b ))` with 17 and 5 | `22` | returns a value |
| `a / b` | `3` | integer division |
| `a % b` | `2` | remainder |
| `a ** 2` | `289` | power |
| `-17 / 5` | `-3` | truncates **toward zero** (Python's `//` would give `-4`) |
| `-17 % 5` | `-2` | the sign follows the left number |
| `(( a += 3 ))`, `(( a++ ))` | `20`, then `21` | changes the variable in place |
| `(( b > 3 )) && ...` | exit status `0` | `(( ))` as a **test** |
| `$(( b > 3 ? 100 : 0 ))` | `100` | ternary operator |
| `let "c = a * 2"` | `42` | old style, same result |
| `declare -i d; d="6*7"` | `42` | an integer variable evaluates the text as math. A plain `e="6*7"` stays text |

---

## Part 2: variables inside math

`$(( x * 2 ))` needs no `$` before `x`. A text value (`word=hello`) or an unset name counts as **0**, so `$(( word + 1 ))` is `1`, with no error. That is convenient and dangerous: validate inputs first (Lesson 19 regexes).

---

## Part 3: bases

- `2#1010` → 10, `8#17` → 15, `16#ff` and `0xFF` → 255, `36#zz` → 1295
- `printf '%x'` / `'%o'` / `'%X'` convert **to** hex / octal; `%08d` pads with zeros
- `to_bin()` has no `printf` letter to lean on, so it divides by 2 repeatedly and prepends each remainder:

```bash
while (( n > 0 )); do
    out="$(( n % 2 ))$out"
    (( n /= 2 ))
done
```

- The octal trap: `n=08` then `$(( n + 1 ))` fails with `value too great for base`. The script runs that in a subshell `( ... ) 2>&1 | sed` so you can **see** the error without stopping. `10#$n` forces decimal and returns `9`.

---

## Part 4: bits

`12` is `1100`, `10` is `1010` in binary.

| Op | Binary work | Result |
|----|-------------|--------|
| `12 & 10` | `1000` | 8 |
| `12 \| 10` | `1110` | 14 |
| `12 ^ 10` | `0110` | 6 |
| `~5` | flips every bit | -6 |
| `1 << 4` | move 4 places left | 16 |
| `256 >> 3` | move 3 places right | 32 |

The flag demo uses `READ=4 WRITE=2 EXEC=1`. `perm & WRITE` **tests**, `perm |= EXEC` **sets**, `perm &= ~WRITE` **clears**, `perm ^= READ` **toggles**. The values go `6 → 7 → 5 → 1`.

---

## Part 5: decimals

`$(( 10 / 3 ))` is `3`. For decimals the script uses `awk`:

```bash
awk 'BEGIN { printf "%.2f", 10 / 3 }'
awk -v p="$price" -v q="$qty" 'BEGIN { printf "%.2f", p * q }'
```

`BEGIN { ... }` runs without reading any file. `-v p="$price"` passes a **Bash** variable into `awk` safely. `bc` (if installed) does `scale=3; 10/3` → `3.333`.

The comparison trick: `awk ... 'BEGIN { exit !(a > b) }'`. In `awk`, a true expression is `1`; `!` flips it so the exit status is `0` (success) when it is true, which is what `if` expects.

`0.1 + 0.2 == 0.3` is **false** in awk, Python, JavaScript, everywhere. That is how binary floating point works.

---

## Part 6: random

Tests are written so they pass every time even though numbers are random:

- ten rolls of `RANDOM % 6 + 1` must all be between 1 and 6, and the script prints `yes`
- `RANDOM=42` **seeds** the generator; setting it again gives the same three numbers, so the script prints that the sequences match (the actual numbers differ between Bash versions, so the script does not print them)
- `SRANDOM` exists in Bash 5.1+; `shuf -i 1-10 -n 3` picks three distinct numbers

---

## Part 7: 64-bit limits

`2 ** 62` is fine. `2 ** 63` wraps to `-9223372036854775808` and `2 ** 64` wraps to `0`, **silently**. The maximum is `9223372036854775807`.

---

## Part 8: the function toolbox

| Function | Idea |
|----------|------|
| `gcd A B` | Euclid's algorithm: replace `(a, b)` with `(b, a % b)` until `b` is 0 |
| `factorial N` | C-style `for` loop with `(( f *= i ))` |
| `is_prime N` | trial division up to `i * i <= n`; returns an **exit status** so you can write `is_prime 7 && echo yes` |
| `human BYTES` | `awk` divides by 1024 until the number fits, then prints with the right unit |
| `percent PART TOTAL` | `awk` multiplies by 100 and formats with one decimal |

Results: `gcd 48 18` = 6, `factorial 10` = 3628800, primes up to 30 are `2 3 5 7 11 13 17 19 23 29`, `human 1536` = `1.5 KB`, `human 5242880` = `5.0 MB`, `percent 45 180` = `25.0%`.

`is_prime` ends with an explicit `return 0`. Without it the function would return the status of the **last command it ran**, which is the failed `(( n % i == 0 ))` test (status 1), and every prime would look like a failure. Always write the success `return 0` yourself.

---

## Part 9: FizzBuzz and `SECONDS`

FizzBuzz checks `% 15` first, then `% 3`, then `% 5`. Order matters: if you test 3 first, 15 prints `Fizz`. `SECONDS=0; sleep 1; echo $SECONDS` shows Bash's built-in stopwatch (it prints `1`).

---

## Part 10: sums from a file

Bash loop: `(( sum += n, count++ ))` (the comma runs two expressions) gives `sum=100 count=5`. `awk` computes the average `20.0` and the maximum `46`. `NR` is awk's **line counter**; `NR == 1 || $1 > m` initialises the maximum on the first line.

---

## 🧪 Experiments

1. Change `a / b` to `$(( -17 / 5 ))` and `$(( 17 / -5 ))`. Compare with Python's `-17 // 5`.
2. Run `echo $(( 08 + 1 ))` and then `echo $(( 10#08 + 1 ))`.
3. Put `set -e` at the top and see what happens with `(( i++ ))` when `i=0`.
4. Add a function `lcm A B` using `gcd` (`a * b / gcd`).
5. Make `human` accept a second argument for the number of decimals.
6. Roll two dice 1000 times, count how often the sum is 7 (`declare -A` from Lesson 15).
7. Write `bin2dec` using `$(( 2#$1 ))` and validate input with a regex.
8. 🐍 Port `is_prime` and `gcd` to Python and compare the length of the code.

---

## ✅ New words in this file

`$(( ))` `(( ))` `let` `declare -i` · `+ - * / % **` · `++ -- += -=` · `? :` · `2#` `8#` `16#` `0x` `10#` · `& | ^ ~ << >>` · `awk -v` · `bc -l` `scale=` · `RANDOM` `SRANDOM` `shuf` · `SECONDS` · `printf %x %o %08d %.2f` · `NR`

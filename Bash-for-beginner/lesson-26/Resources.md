# Lesson 26 — Resources

## 📋 Cheat Sheet

| Syntax | Meaning |
|--------|---------|
| `$(( expr ))` | value of the math expression |
| `(( expr ))` | run math / test (exit 0 if result is non-zero) |
| `let "x = x + 1"` | old style |
| `declare -i n` | integer variable |
| `+ - * / % **` | arithmetic (integer; `/` truncates toward zero) |
| `++ -- += -= *= /= %=` | update |
| `< <= > >= == !=` | comparison |
| `&& \|\| !` | logic |
| `c ? a : b` | ternary |
| `& \| ^ ~ << >>` | bit operations |
| `2#1010` `8#17` `16#ff` `0xff` | bases |
| `10#$n` | force decimal (avoids the octal trap) |
| `printf '%x %o %X %08d %.2f'` | hex, octal, HEX, padded, rounded |

**Decimals and big numbers**

```bash
awk -v a="$x" -v b="$y" 'BEGIN { printf "%.2f\n", a / b }'
echo 'scale=4; 22/7' | bc
echo '2^200' | bc                 # huge integers
awk -v a=3.7 -v b=3.14 'BEGIN { exit !(a > b) }' && echo bigger
numfmt --to=iec 5242880            # 5.0M
```

**Random**

```bash
$(( RANDOM % 6 + 1 ))     # dice
shuf -i 1-49 -n 6         # 6 distinct numbers
shuf -n 1 file            # random line
openssl rand -hex 16      # secure token
RANDOM=42                 # seed
```

**Handy variables:** `SECONDS` (stopwatch) · `$RANDOM` · `$SRANDOM` (Bash 5.1+)

---

## 🏋️ Exercises

Set up:

```bash
mkdir -p ~/bash-practice/ex26 && cd ~/bash-practice/ex26
printf '%s\n' 12 7 30 5 46 > numbers.txt
printf 'apple 3 0.50\nbanana 12 0.25\ncherry 7 2.00\n' > shop.txt
```

**Level A: Easy**
1. Print `17 * 23` using `$(( ))`.
2. Put `100` in `n`, add `50` using `(( ))`, print `n`.
3. Print the remainder of `100 / 7`.
4. Print `2` to the power `10`.

**Level B: Medium**
5. Print `255` in hex and in octal, and `0xFF` as a decimal number.
6. Print a random number from 1 to 100.
7. Given `m=09`, print `m + 1` correctly.
8. Print `22/7` with 4 decimals using `awk`, and again using `bc`.
9. Use `(( ))` to print "even" or "odd" for a variable `n`.
10. Add up the numbers in `numbers.txt` with a Bash loop, then with `awk`.

**Level C: Challenge**
11. Write `clamp VALUE MIN MAX` that prints VALUE limited to the range.
12. From `shop.txt` (name, quantity, price) print the **total cost** with 2 decimals.
13. Use bit flags `A=1 B=2 C=4 D=8`: set `A` and `C`, test `D`, toggle `B`, and print the final number.
14. Write `bin2dec STRING` that validates the input (only 0 and 1) and prints the decimal number.
15. Write `leap_year YEAR` that returns exit status 0 for leap years (divisible by 4, except centuries unless divisible by 400).
16. Write `hms SECONDS` so `hms 3725` prints `01:02:05`.
17. (Think!) Why can `(( i++ ))` stop a script that uses `set -e`?
18. (Think!) Why does `echo $(( 10 / 4 ))` print `2`, and how do you get `2.5`?
19. (Think!) What do `-17 % 5` give in Bash and `-17 % 5` give in Python?
20. 🐍 Translate to Python: `round(22/7, 2)`, `int("ff", 16)`, `random.randint(1, 100)`. Then write the Bash versions.

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
echo $(( 17 * 23 ))                         # 391

# 2
n=100; (( n += 50 )); echo "$n"             # 150

# 3
echo $(( 100 % 7 ))                         # 2

# 4
echo $(( 2 ** 10 ))                         # 1024

# 5
printf '%x\n' 255                           # ff
printf '%o\n' 255                           # 377
echo $(( 0xFF ))                            # 255

# 6
echo $(( RANDOM % 100 + 1 ))

# 7
m=09
echo $(( 10#$m + 1 ))                       # 10

# 8
awk 'BEGIN { printf "%.4f\n", 22/7 }'       # 3.1429
echo 'scale=4; 22/7' | bc                   # 3.1428  (bc truncates, awk rounds)

# 9
n=7
if (( n % 2 == 0 )); then echo even; else echo odd; fi

# 10
sum=0
while read -r x; do (( sum += x )); done < numbers.txt
echo "$sum"                                 # 100
awk '{ s += $1 } END { print s }' numbers.txt

# 11
clamp() {
    local v=$1 lo=$2 hi=$3
    (( v < lo )) && v=$lo
    (( v > hi )) && v=$hi
    echo "$v"
}
clamp 150 0 100      # 100
clamp -5 0 100       # 0

# 12
awk '{ total += $2 * $3 } END { printf "%.2f\n", total }' shop.txt    # 18.50
# 3*0.50 + 12*0.25 + 7*2.00 = 1.5 + 3 + 14

# 13
A=1; B=2; C=4; D=8
flags=0
(( flags |= A | C ))             # set A and C → 5
(( flags & D )) && echo "D on" || echo "D off"
(( flags ^= B ))                 # toggle B → 7
echo "$flags"                    # 7

# 14
bin2dec() {
    [[ $1 =~ ^[01]+$ ]] || { echo "not binary: $1" >&2; return 1; }
    echo $(( 2#$1 ))
}
bin2dec 1101          # 13
bin2dec 1201          # error

# 15
leap_year() {
    local y=$1
    (( y % 400 == 0 || (y % 4 == 0 && y % 100 != 0) ))
}
leap_year 2024 && echo leap      # leap
leap_year 1900 || echo common    # common

# 16
hms() {
    local s=$1
    printf '%02d:%02d:%02d\n' $(( s / 3600 )) $(( s % 3600 / 60 )) $(( s % 60 ))
}
hms 3725             # 01:02:05

# 17
# i++ returns the OLD value. When i is 0 the expression's value is 0, and (( 0 ))
# has exit status 1 (false). set -e treats that as a failure and exits. Use
# i=$(( i + 1 )) or (( ++i )) or (( i++ )) || true.

# 18
# Bash only does integers; 10 / 4 truncates to 2. Use awk:
awk 'BEGIN { print 10 / 4 }'                # 2.5

# 19
# Bash: -2 (sign follows the left operand). Python: 3 (result follows the right operand).
# To get Python-style: echo $(( (x % m + m) % m ))

# 20
# Python: round(22/7, 2)        Bash: awk 'BEGIN { printf "%.2f\n", 22/7 }'
# Python: int("ff", 16)         Bash: echo $(( 16#ff ))
# Python: random.randint(1,100) Bash: echo $(( RANDOM % 100 + 1 ))
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `value too great for base` | number with a leading `0` is octal | `10#$n` |
| `syntax error: operand expected` | empty variable or text in math | validate; use `${n:-0}` |
| `10 / 3` shows `3` | integer maths | `awk` / `bc` |
| `echo 5+3` prints `5+3` | no math context | `echo $(( 5 + 3 ))` |
| `[: integer expression expected` | `[ ]` got a non-number | check with `[[ $n =~ ^-?[0-9]+$ ]]` |
| script exits on `(( i++ ))` | `set -e` and value 0 | `(( ++i ))` or `i=$((i+1))` |
| `[ $a > $b ]` creates a file | `>` is a redirect | `(( a > b ))` |
| negative result looks wrong | truncation toward zero | formula with `+ m` |
| big number turns negative | 64-bit overflow | `bc` or Python |
| `0.1 + 0.2` not `0.3` | floating-point | round or compare with tolerance |

---

## 💡 Habits of pro coders

1. **Use `(( ))` for conditions** and `$(( ))` for values: never `expr`.
2. **Validate numbers** from users and files before calculating.
3. **Use `10#$n`** for numbers read from text.
4. **Use `awk -v`** for decimals, never paste variables into program text.
5. **Do not use `RANDOM` for secrets.**
6. **Prefer `(( ++i ))`** in scripts that use `set -e`.
7. **Put maths in small functions** with clear names and test them.

## 📚 Extra resources

- **`man bash`**, search `ARITHMETIC EVALUATION`
- **mywiki.wooledge.org/ArithmeticExpression**
- **`man bc`**, **`man awk`** (GNU awk manual: gnu.org/software/gawk/manual)
- **`man numfmt`**, **`man shuf`**
- **exercism.org/tracks/bash**: small maths exercises

## 🧠 Self-check

1. What is the difference between `$(( ))` and `(( ))`?
2. Why is `n=08; echo $(( n + 1 ))` an error, and what is the fix?
3. How do you test if bit 2 of a number is set?
4. What do you use for `7 / 2 = 3.5`, and how do you pass variables safely?
5. What happens at `2 ** 63`? Does Bash warn you?
6. Why is `$RANDOM` unsuitable for passwords?

## ➡️ Next: Lesson 27 — File Descriptors & Redirection Mastery (`exec`, here-docs, process substitution, FIFOs)

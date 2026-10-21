# Lesson 12 — Resources

## 📋 Cheat Sheet

**Shape**

```bash
if [[ condition ]]; then
    ...
elif (( n > 5 )); then
    ...
else
    ...
fi
```

| Kind | Tests |
|------|-------|
| **String** (`[[ ]]`) | `==` `!=` `-z` (empty) `-n` (not empty) `<` `>` `== pat*` `=~ regex` |
| **Number** | `-eq -ne -lt -le -gt -ge` in `[[ ]]` · or `(( a >= b ))` |
| **File** | `-e` exists · `-f` file · `-d` dir · `-L` link · `-r -w -x` · `-s` non-empty · `-nt` `-ot` |
| **Logic** | `&&` `\|\|` `!` · inside `[[ ]]` or between commands |
| **Command** | `if cmd; then` → exit code 0 = true · `if ! cmd; then` |

**`case`**

```bash
case "$x" in
    a|b)  echo "a or b" ;;
    [0-9]*) echo "starts with digit" ;;
    *)    echo "other" ;;
esac
```

**Shortcuts:** `[[ -d $d ]] || mkdir -p "$d"` · `cd "$d" || exit 1` · `cmd && echo ok`

**Rules of thumb:** `[[ ]]` for text/files · `(( ))` for numbers · always quote in `[ ]` · spaces inside brackets · `A && B || C` ≠ if/else · leading zero = octal in `(( ))`

---

## 🏋️ Exercises

Work in `~/bash-practice/ex12`.

**Level A: Easy**
1. `adult.sh AGE`: print `adult` if AGE ≥ 18, else `minor`.
2. `empty.sh TEXT`: print `empty` if the argument is empty, else `has text`.
3. `isdir.sh PATH`: print `directory`, `file`, or `missing`.
4. `even.sh N`: print `even` or `odd`.

**Level B: Medium**
5. `size.sh N`: print `small` (<10), `medium` (10 to 99), `large` (100 or more).
6. `ext.sh FILE`: using `case`, print `script` for `.sh`/`.bash`, `text` for `.txt`/`.md`, `image` for `.png`/`.jpg`, otherwise `unknown`.
7. `needs.sh CMD`: print `CMD is installed` or `CMD is missing` (hint: `command -v`).
8. `between.sh N`: succeed silently and print `ok` if 1 ≤ N ≤ 100; otherwise print an error to stderr and exit 1.
9. `touch-if-missing.sh FILE`: create FILE only if it doesn't exist, using one `||` line.
10. `yesno.sh`: ask `Continue? [y/N]`, treat `y`, `Y`, `yes`, `YES` as yes, everything else as no (use `case`).

**Level C: Challenge**
11. `leap.sh YEAR`: print `leap` or `not leap`. (Divisible by 4 and not by 100, or divisible by 400.)
12. `fizz.sh N`: print `FizzBuzz` if N divisible by 3 and 5, `Fizz` if by 3, `Buzz` if by 5, else N.
13. `safe-rm.sh FILE`: refuse (exit 1) if FILE is missing, is a directory, or is not writable; otherwise ask for confirmation, then delete.
14. `grade2.sh SCORE`: like the lesson's `grade.sh`, but validate input first (must be a whole number from 0 to 100) with usage and exit 2.
15. (Think!) What's printed? `false && echo A || echo B` and `true || echo A && echo B`.
16. (Think!) Why is `if [ $name = "Asha" ]` risky when `name` is empty or has spaces? Give two fixes.
17. (Think!) What does `(( 08 == 8 ))` do, and how do you fix it?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1  adult.sh
#!/usr/bin/env bash
if (( $1 >= 18 )); then echo adult; else echo minor; fi

# 2  empty.sh
#!/usr/bin/env bash
if [[ -z $1 ]]; then echo empty; else echo "has text"; fi

# 3  isdir.sh
#!/usr/bin/env bash
if [[ -d $1 ]]; then echo directory
elif [[ -f $1 ]]; then echo file
else echo missing
fi

# 4  even.sh
#!/usr/bin/env bash
if (( $1 % 2 == 0 )); then echo even; else echo odd; fi

# 5  size.sh
#!/usr/bin/env bash
n=$1
if (( n < 10 )); then echo small
elif (( n < 100 )); then echo medium
else echo large
fi

# 6  ext.sh
#!/usr/bin/env bash
case "$1" in
    *.sh|*.bash)  echo script ;;
    *.txt|*.md)   echo text ;;
    *.png|*.jpg)  echo image ;;
    *)            echo unknown ;;
esac

# 7  needs.sh
#!/usr/bin/env bash
if command -v "$1" > /dev/null 2>&1; then
    echo "$1 is installed"
else
    echo "$1 is missing"
fi

# 8  between.sh
#!/usr/bin/env bash
n=$1
if (( n >= 1 && n <= 100 )); then
    echo ok
else
    echo "error: $n is not between 1 and 100" >&2
    exit 1
fi

# 9  touch-if-missing.sh
#!/usr/bin/env bash
[[ -e $1 ]] || touch "$1"

# 10 yesno.sh
#!/usr/bin/env bash
read -r -p "Continue? [y/N] " a
case "$a" in
    [yY]|[yY][eE][sS]) echo "Continuing" ;;
    *)                 echo "Stopped" ;;
esac

# 11 leap.sh
#!/usr/bin/env bash
y=$1
if (( (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 )); then
    echo leap
else
    echo "not leap"
fi

# 12 fizz.sh
#!/usr/bin/env bash
n=$1
if (( n % 15 == 0 )); then echo FizzBuzz
elif (( n % 3 == 0 )); then echo Fizz
elif (( n % 5 == 0 )); then echo Buzz
else echo "$n"
fi

# 13 safe-rm.sh
#!/usr/bin/env bash
f="$1"
if [[ ! -e $f ]]; then echo "no such file: $f" >&2; exit 1; fi
if [[ -d $f ]]; then echo "$f is a directory" >&2; exit 1; fi
if [[ ! -w $f ]]; then echo "$f is not writable" >&2; exit 1; fi
read -r -p "Delete $f? [y/N] " a
if [[ $a == [yY]* ]]; then rm -- "$f"; echo deleted; else echo cancelled; fi

# 14 grade2.sh
#!/usr/bin/env bash
if [[ $# -ne 1 || ! $1 =~ ^[0-9]+$ ]] || (( 10#$1 > 100 )); then
    echo "Usage: $0 SCORE   (whole number 0-100)" >&2
    exit 2
fi
score=$((10#$1))
if (( score >= 90 )); then echo A
elif (( score >= 75 )); then echo B
elif (( score >= 50 )); then echo C
else echo Fail
fi

# 15
# false && echo A || echo B   -> B   (false short-circuits &&, then || runs)
# true  || echo A && echo B   -> B   (|| skips A; && then runs B because the
#                                     last command that ran, "true", succeeded)

# 16
# Empty: [ = "Asha" ] → "unary operator expected". With spaces
# ("Asha Rao") it becomes [ Asha Rao = "Asha" ] → "too many arguments".
# Fixes:  [ "$name" = "Asha" ]    or    [[ $name == "Asha" ]]

# 17
# A leading 0 means OCTAL, and 8 is not an octal digit → error
# "value too great for base". Force base 10:   (( 10#08 == 8 ))
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `[: unary operator expected` | unquoted empty variable in `[ ]` | `[[ ]]` or `"$var"` |
| `[: too many arguments` | unquoted variable with spaces | quote it |
| `integer expression expected` | `-eq` with non-numbers | validate with `=~ ^[0-9]+$` |
| `syntax error near unexpected token 'fi'` | missing `then` or `;` | `if cond; then` |
| `command not found: [[x` | missing spaces | `[[ $x == y ]]` |
| a file named `5` appeared | `[ $x > 5 ]` redirected | `(( x > 5 ))` |
| wrong branch runs | `A && B \|\| C` used as if/else | real `if` |
| `value too great for base` | number with leading `0` (08, 09) | `10#$n` |
| `case` didn't match `.JPG` | patterns are case-sensitive | add pattern, or `${var,,}`, or `shopt -s nocasematch` |
| `elif`/`else` never runs | earlier branch was broader | order: most specific first |

---

## 💡 Habits of pro coders

1. **`[[ ]]` for text and files, `(( ))` for numbers.**
2. **Validate input first**, then compare.
3. **Guard clauses:** handle errors early with `exit`, so the main logic isn't buried in nested ifs.
4. **Specific before general** in `elif` chains and `case`.
5. **Always end `case` with `*)`**, even if it just reports "unknown".
6. **Test with `grep -q`, `command -v`, `[[ -f ]]`**: quiet tests, no noise.
7. **Never `A && B || C` for if/else.**

## 📚 Extra resources

- **`help test`**, **`help [[`**, **`help case`**: built-in docs
- **mywiki.wooledge.org/BashFAQ/031**: `[` vs `[[` vs `test`
- **mywiki.wooledge.org/BashPitfalls**: the classic traps list
- **shellcheck.net:** flags `A && B || C`, unquoted variables, wrong test syntax

## 🧠 Self-check

1. What does `if` actually check?
2. Why prefer `[[ ]]` over `[ ]`?
3. When do you use `(( ))`?
4. What does `*)` do in a `case`?
5. Why isn't `A && B || C` the same as if/else?
6. What happens to `08` in `(( ))`?

## ➡️ Next: Lesson 13 — Loops (`for`, `while`, `until`, `break`, `continue`)

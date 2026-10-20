# Lesson 10 — Resources

## 📋 Cheat Sheet

**Basics**

| Goal | Syntax |
|------|--------|
| Assign | `name="value"` (no spaces around `=`) |
| Use | `"$name"` or `"${name}"` |
| Length | `${#name}` |
| Command output | `x=$(command)` |
| Math | `$(( a + b ))` · `(( n++ ))` · `(( n += 5 ))` |
| Decimals | `awk 'BEGIN{print 7/3}'` |
| Constant | `readonly NAME=value` |
| Delete | `unset name` |
| Share with children | `export name` |
| One command only | `NAME=value command` |

**Quoting**

| Style | Expands `$var` / `$( )`? | Keeps spaces together? |
|-------|-------------------------|------------------------|
| `"double"` | yes | yes ✅ |
| `'single'` | no | yes |
| none | yes | **no** ⚠️ (splits + globs) |

**Default / check forms**

| Form | Meaning |
|------|---------|
| `${v:-d}` | value of `v`, or `d` if unset/empty |
| `${v:=d}` | same, and assigns `d` to `v` |
| `${v:+a}` | `a` if `v` is set and non-empty, else nothing |
| `${v:?msg}` | error + stop if unset/empty |

**Operators in `$(( ))`:** `+ - * / % **` · comparison `< > <= >= == !=` (result 1/0)

**Handy built-ins:** `$HOME` `$USER` `$PWD` `$OLDPWD` `$PATH` `$RANDOM` `$SECONDS` `$LINENO` `$$` `$?` `$0` `$BASH_VERSION`

**Safety line:** `set -u` makes unset variables an error.

---

## 🏋️ Exercises

**Level A: Easy**
1. Create variables `first` and `last`, then print `Hello, <first> <last>!`
2. Store today's date (format `YYYY-MM-DD`) in a variable and print it.
3. Make `n=10` and print `n squared is 100` using math (not typing 100).
4. Print the length of the text `Bash is fun` stored in a variable.

**Level B: Medium**
5. Print `I have 3 apples` where `fruit=apple` and `n=3` (note the plural **s** touching the variable).
6. Set `file="my notes.txt"`, `touch` it, and delete it using the **quoted** variable.
7. Print `Hello, stranger` using a default when `NAME` is unset; then set `NAME=Ravi` and print `Hello, Ravi` with the **same** command.
8. Compute the average of 10, 20, 33 **with decimals** (two places).
9. Prove that a normal variable isn't visible to a child, but becomes visible after `export`.
10. Count how many items are in your home folder and print `Home has N items`.

**Level C: Challenge**
11. Write a script `greet.sh` that takes the name from an environment variable `GREET_NAME`, **stops with an error message** if it's missing, otherwise prints `Welcome, <name>`.
12. Make a backup folder name like `backup-2026-10-11-143005` (date and time) in a variable and create that folder under `/tmp`.
13. Use `printf '[%s]\n'` to show that `x="a   b"` gives two arguments unquoted and one quoted.
14. Make a constant `LIMIT=5` that can't be changed, and show the error when you try.
15. (Think!) What does `rm -rf "$DIR/"*` do if `DIR` is empty? What two protections would you add?
16. (Think!) Why does `echo "$a+$b"` print `3+4` rather than `7`? Fix it.

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
first="Asha"; last="Rao"
echo "Hello, $first $last!"

# 2
today=$(date +%F)
echo "$today"

# 3
n=10
echo "n squared is $(( n * n ))"

# 4
text="Bash is fun"
echo "${#text}"                           # 11

# 5
fruit=apple; n=3
echo "I have $n ${fruit}s"                # braces keep the "s" out of the name

# 6
file="my notes.txt"
touch "$file"
rm "$file"

# 7
unset NAME
echo "Hello, ${NAME:-stranger}"           # Hello, stranger
NAME=Ravi
echo "Hello, ${NAME:-stranger}"           # Hello, Ravi

# 8
awk 'BEGIN {printf "%.2f\n", (10+20+33)/3}'       # 21.00
# or with variables:
awk -v a=10 -v b=20 -v c=33 'BEGIN {printf "%.2f\n", (a+b+c)/3}'

# 9
v="hello"
bash -c 'echo "[$v]"'                     # []
export v
bash -c 'echo "[$v]"'                     # [hello]

# 10
items=$(ls ~ | wc -l)
echo "Home has $items items"

# 11  (greet.sh)
#!/usr/bin/env bash
: "${GREET_NAME:?GREET_NAME must be set}"
echo "Welcome, $GREET_NAME"
# Run:  GREET_NAME=Asha ./greet.sh     and     ./greet.sh   (error)

# 12
stamp=$(date +%Y-%m-%d-%H%M%S)
dir="/tmp/backup-$stamp"
mkdir -p "$dir"
echo "$dir"

# 13
x="a   b"
printf '[%s]\n' $x          # [a] [b]
printf '[%s]\n' "$x"        # [a   b]

# 14
readonly LIMIT=5
LIMIT=6                      # bash: LIMIT: readonly variable

# 15
# If DIR is empty, "$DIR/"* becomes "/"*  → rm -rf /*  → tries to delete
# EVERYTHING on the system (as far as your permissions allow). Protections:
#   set -u                       # (doesn't help for empty, but catches unset)
#   : "${DIR:?DIR must be set}"  # refuses to run if DIR is unset OR empty
#   [ -d "$DIR" ] || exit 1      # check it's a real directory
# and use "rm -ri" / a preview with ls first.

# 16
# Inside quotes, + is just a character, so Bash prints 3+4.
echo $(( a + b ))            # 7
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `x: command not found` | `x = 5` (spaces) | `x=5` |
| `rm: cannot remove 'my'` | unquoted variable with a space | `"$file"` |
| `[: too many arguments` | unquoted variable in a test (`[ $x = a ]`) | `[ "$x" = a ]` (Lesson 12) |
| variable prints blank | typo in name, or in a child process | check spelling; `export` for children |
| `echo '$name'` shows `$name` | single quotes | use double quotes |
| `7/3` shows `2` | integer math | `awk` / `bc` |
| `syntax error in expression` | text inside `$(( ))` that isn't a number | check variable values with `echo` |
| `unbound variable` | you used `set -u` and the name was misspelled (good!) | fix the name |
| value has odd extra characters | CRLF in a file you read (`\r`) | `tr -d '\r'` |

---

## 💡 Habits of pro coders

1. **Quote every variable expansion:** `"$var"`, `"$(cmd)"`, `"${arr[@]}"`.
2. `set -u` (and later `set -euo pipefail`) in every script.
3. **Constants at the top** of the script, uppercase, `readonly` when appropriate.
4. **Defaults for settings:** `dir="${BACKUP_DIR:-$HOME/backups}"`.
5. **Guard dangerous variables** before `rm`, `mv`, `cp`: `: "${DIR:?}"`.
6. **Use `printf '[%s]\n'`** to inspect what a variable really contains.
7. **Descriptive names:** `backup_dir`, not `d`.

## 📚 Extra resources

- **mywiki.wooledge.org/Quotes** and **/BashPitfalls**: the best explanations of quoting traps
- **`man bash`** → "PARAMETERS" and "EXPANSION"
- **shellcheck.net:** flags unquoted variables (SC2086)
- **explainshell.com:** decode `${var:-default}` forms
- **Google Shell Style Guide:** naming and quoting conventions

## 🧠 Self-check

1. Why must there be no spaces around `=` in an assignment?
2. What is the difference between `"$x"`, `'$x'` and `$x`?
3. What does `${name:-guest}` do? How is `:=` different?
4. Why does `echo $(( 7 / 3 ))` print `2`?
5. When does a child process see your variable?
6. What does `set -u` protect you from?

## ➡️ Next: Lesson 11 — User Input & Arguments (`read`, `$1`, `$@`, `$#`, `shift`, usage messages)

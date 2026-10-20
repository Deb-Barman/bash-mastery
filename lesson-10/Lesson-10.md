# Lesson 10 — Variables & Quoting

**Level 3 · Real Scripting · Time: ~75 minutes**

---

## 🎯 What you will learn

- Store and reuse values in **variables**
- The one rule that causes 80% of beginner bugs: **quote your variables**
- Single quotes vs double quotes vs no quotes
- Capture command output with `$( )`
- Do math with `$(( ))`
- Default values and safety checks (`${var:-default}`)
- `export`, environment variables, and what child programs see
- Useful built-in variables (`$HOME`, `$PWD`, `$RANDOM`, `$$`...)
- `readonly`, `unset`, and `set -u`

> Variables are the memory of your script. Quoting is the seatbelt. Learn both properly **now**; every later lesson depends on them.

---

## 1. What is a variable?

A **box with a name** that holds text.

```bash
name="Asha"           # put "Asha" in the box called name
echo "$name"         # take it out: Asha
```

### Rules for assignment

```bash
city="Pune"      # ✅ NO spaces around =
city = "Pune"    # ❌ Bash thinks "city" is a command
count=5              # ✅ numbers are just text that looks like numbers
$count=6             # ❌ never put $ on the left
```

**Names:** letters, digits, underscore; can't start with a digit.
`my_var` ✅ · `_x2` ✅ · `2nd` ❌ · `my-var` ❌ (hyphen not allowed)

**Convention:**
- `lower_case` for your script's own variables
- `UPPER_CASE` for constants and environment variables (`PATH`, `HOME`, `BACKUP_DIR`)

---

## 2. Using a variable: `$name` and `${name}`

```bash
fruit="apple"
echo "I like $fruit"          # I like apple
echo "Two ${fruit}s"          # Two apples
echo "Two $fruits"            # Two        <- Bash looked for a variable called "fruits"!
```

Use braces `${...}` whenever letters, digits, or underscores come right after the name.

---

## 3. 🔑 Quoting: the most important section

Three ways Bash can see text:

| Style | Example | `$var` expanded? | spaces kept together? |
|-------|---------|------------------|-----------------------|
| **no quotes** | `echo $name` | yes | **no** (splits into words + globs `*`) |
| **"double quotes"** | `echo "$name"` | **yes** | **yes** |
| **'single quotes'** | `echo '$name'` | **no** (literal) | yes |

```bash
name="Asha Rao"
echo "Hello $name"       # Hello Asha Rao
echo 'Hello $name'       # Hello $name
echo \$name              # $name  (backslash protects one character)
```

### Why unquoted variables are dangerous

```bash
file="my report.txt"
rm $file                 # ❌ becomes: rm my report.txt   (TWO files!)
rm "$file"               # ✅ one file
```

And worse, **globbing** (Lesson 6) can also fire:

```bash
pattern="*"
echo $pattern            # prints every file name in the folder!
echo "$pattern"          # prints: *
```

A handy way to *see* how many words Bash made:

```bash
printf '[%s]\n' $file      # [my]  [report.txt]    <- 2 words
printf '[%s]\n' "$file"    # [my report.txt]       <- 1 word
```

### 🔒 The rule

> **Always write `"$var"` with double quotes.** Leave quotes off only when you *deliberately* want splitting or globbing, which is rare.

Mixing quote types:

```bash
echo "She said 'hi'"                # single inside double: fine
echo 'He said "hi"'                 # double inside single: fine
echo "Price: \$5"                   # escape a $ inside double quotes
echo "Today is $(date +%A)"         # command substitution works inside double quotes
```

---

## 4. Command substitution: `$( )`

Run a command and **use its output as a value**:

```bash
today=$(date +%F)
echo "Today: $today"                # Today: 2026-10-11

count=$(ls | wc -l)
echo "There are $count items"

files_here="$(ls -1 | head -n 3)"   # quotes keep the line breaks
```

Nesting works: `echo "Folder: $(basename "$(pwd)")"`

> The old style used backticks `` `date` ``. Avoid them: they're hard to read and can't nest cleanly. Always use `$( )`.

Two details:
- `$(...)` removes trailing newlines from the output.
- Put **quotes around the whole thing** when you use the result: `"$(date)"`.

---

## 5. Arithmetic: `$(( ))`

Bash does **whole-number** math:

```bash
a=7; b=3
echo $(( a + b ))       # 10
echo $(( a - b ))       # 4
echo $(( a * b ))       # 21
echo $(( a / b ))       # 2        (integer division: decimals are cut off!)
echo $(( a % b ))       # 1        (remainder)
echo $(( a ** 2 ))      # 49       (power)

total=$(( a * b + 1 ))  # store the result
(( total++ ))           # add 1 (no $ needed inside (( )))
(( total += 10 ))
echo "$total"
```

Inside `$(( ))`, you can write variable names **without** the `$`.

For decimals use `awk` or `bc`:

```bash
awk 'BEGIN {print 7/3}'                 # 2.33333
echo "scale=2; 7/3" | bc                # 2.33   (if bc is installed)
awk -v a=7 -v b=3 'BEGIN {printf "%.2f\n", a/b}'
```

---

## 6. Defaults and checks: `${var:-...}`

When a variable may be empty or unset:

| Form | Meaning |
|------|---------|
| `${var:-default}` | use `default` if `var` is unset **or empty** (var unchanged) |
| `${var:=default}` | same, but also **assign** it to `var` |
| `${var:?message}` | **stop with an error** if unset or empty |
| `${var:+alt}` | use `alt` only if `var` **is** set and non-empty |
| `${#var}` | the **length** of the text |

```bash
echo "Hello, ${USER_NAME:-stranger}"       # Hello, stranger
backup_dir="${BACKUP_DIR:-$HOME/backups}"  # a setting with a safe default
: "${API_KEY:?API_KEY must be set}"        # script stops if missing
name="Asha"; echo "${#name}"                # 4
```

(`:` is a do-nothing command, handy to trigger the check.)

---

## 7. Shell variables vs environment variables

- A normal variable lives **only in this shell**.
- `export` makes it an **environment variable**: **child programs** inherit a copy.

```bash
color="blue"
bash -c 'echo "child sees: [$color]"'     # child sees: []
export color
bash -c 'echo "child sees: [$color]"'     # child sees: [blue]
```

Setting a variable for **one command only**:

```bash
LANG=C sort file.txt          # LANG=C applies to this one sort
DEBUG=1 ./myscript.sh         # script sees DEBUG, your shell doesn't keep it
```

See them:

```bash
env | head          # all environment variables
printenv HOME       # one of them
```

Remember: a child can **never** change the parent's variables (Lesson 9).

---

## 8. Built-in variables worth knowing

| Variable | Meaning |
|----------|---------|
| `$HOME` | your home folder |
| `$USER` | your username |
| `$PWD` | current folder |
| `$OLDPWD` | previous folder (`cd -` uses it) |
| `$PATH` | where commands are searched |
| `$SHELL` | your login shell |
| `$HOSTNAME` | computer name |
| `$RANDOM` | a random number 0 to 32767 (new each time) |
| `$SECONDS` | seconds since this shell started |
| `$LINENO` | the current line number in the script |
| `$$` | the current process id (PID) |
| `$?` | exit code of the last command |
| `$0` | the script's name (Lesson 11: `$1`, `$2`, `$@`...) |
| `$BASH_VERSION` | Bash's version |

```bash
echo $(( RANDOM % 6 + 1 ))     # a dice roll, 1 to 6
echo "Process id: $$"
```

---

## 9. `readonly` and `unset`

```bash
readonly PI=3.14159       # a constant: can't be changed
PI=3                      # bash: PI: readonly variable

name="Asha"
unset name                # delete the variable
echo "[${name}]"          # []
```

---

## 10. Catching typos: `set -u`

By default, an **undefined variable silently becomes empty**. That's how scripts have deleted the wrong folder:

```bash
rm -rf "$BACKUP_DIR/"     # if BACKUP_DIR is unset... this becomes: rm -rf "/"  😱
```

Turn on protection near the top of scripts:

```bash
set -u                    # using an unset variable = ERROR, script stops
```

(Combined protections `set -euo pipefail` are Lesson 17.)

---

## 11. Common mistakes (study this table!)

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `x = 5` | `x: command not found` | `x=5` |
| `echo $x` with spaces/`*` in value | splitting or surprise globbing | `echo "$x"` |
| `'$name'` expecting a value | prints `$name` | use double quotes |
| `$count=5` | `5=5`-style error | `count=5` |
| `echo "$a+$b"` | prints `3+4` | `echo $(( a + b ))` |
| `a=$b c=5` style tricks | confusing | one assignment per line |
| `echo "Two $fruits"` | empty | `${fruit}s` |
| `7/3` gives `2` | integer math | use `awk` or `bc` |
| `my-var=1` | `command not found` | `my_var=1` |
| `name = $(whoami)` | spaces around `=` | `name=$(whoami)` |

---

## ✅ Summary

- `var=value` (no spaces) · use `"$var"` (always quoted) · `${var}` next to text
- `"double"` expands, `'single'` is literal, no quotes = split + glob (usually a bug)
- `$(command)` captures output · `$(( math ))` does integer math
- `${var:-default}`, `${var:?msg}`, `${#var}`
- `export` shares a variable with child programs
- `readonly` for constants · `set -u` catches typos

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

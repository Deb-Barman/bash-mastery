# Lesson 11 — User Input & Arguments

**Level 3 · Real Scripting · Time: ~70 minutes**

---

## 🎯 What you will learn

- Make scripts **flexible**: they take input instead of hard-coding values
- **Arguments**: `./script.sh Asha 25` → `$1`, `$2`, `$#`, `$@`
- `shift` to walk through arguments
- **Interactive input** with `read` (prompts, defaults, passwords)
- Validating input and writing a proper **usage message**
- Three input channels: arguments, `read`/stdin, environment

> A script with hard-coded values is a note to self. A script that takes input is a **tool**.

---

## 1. Three ways a script gets input

| Channel | Example | Best for |
|---------|---------|----------|
| **Arguments** | `./backup.sh ~/photos /mnt/usb` | what to work on |
| **stdin / `read`** | the script asks "Continue? y/n" or reads a pipe | questions, piped data |
| **Environment** | `DEBUG=1 ./backup.sh` | settings and secrets |

---

## 2. Arguments: positional parameters

Words you type after the script name:

```bash
./greet.sh Asha 25
```

Inside the script:

| Variable | Meaning | Value above |
|----------|---------|-------------|
| `$0` | the script's name | `./greet.sh` |
| `$1` | first argument | `Asha` |
| `$2` | second argument | `25` |
| `$3`... `$9` | third to ninth | (empty) |
| `${10}` | tenth and beyond (braces required!) | |
| `$#` | **how many** arguments | `2` |
| `$@` | **all** arguments (list) | `Asha 25` |
| `$*` | all arguments (one string) | `Asha 25` |

```bash
#!/usr/bin/env bash
echo "Hello, $1! You are $2 years old."
echo "I received $# arguments."
```

```bash
./greet.sh Asha 25        # Hello, Asha! You are 25 years old.
./greet.sh "Asha Rao" 25  # quotes make "Asha Rao" ONE argument
```

> **Tip:** the shell splits arguments at spaces. Anyone running your script must quote values that contain spaces.

---

## 3. `"$@"` vs `"$*"` (use `"$@"`)

```bash
./show.sh one "two words" three
```

```bash
printf '<%s>\n' "$@"     # <one>  <two words>  <three>    ✅ 3 items, spaces preserved
printf '<%s>\n' "$*"     # <one two words three>          one big string
printf '<%s>\n' $@       # <one> <two> <words> <three>    ❌ unquoted: broken apart
```

**Rule:** to pass or loop over all arguments, write **`"$@"`**, with quotes, always.

Looping over arguments (preview of Lesson 13):

```bash
for file in "$@"; do
    echo "Processing: $file"
done
```

---

## 4. Default values

```bash
name="${1:-stranger}"          # use $1, or "stranger" if none given
folder="${2:-$HOME/Downloads}"
echo "Hello, $name! Working in $folder"
```

---

## 5. Checking arguments + usage message

Always check that you received what you need, and explain how to use the script if not:

```bash
#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 NAME [AGE]" >&2
    exit 2
fi

echo "Hello, $1!"
```

(`if` is Lesson 12. Read it as: "if the argument count is less than 1, print usage and stop.")

Rules for a good usage message:

1. Goes to **stderr** (`>&2`)
2. Uses `$0` so it shows the real script name
3. Shows `[optional]` and `REQUIRED` parts
4. Exit code **2** ("misuse")

Test comparison operators (for numbers): `-eq` equal · `-ne` not equal · `-lt` less · `-le` ≤ · `-gt` greater · `-ge` ≥

---

## 6. `shift`: consume arguments one by one

`shift` drops `$1`; everything moves down.

```bash
# ./s.sh a b c d
echo "$1"        # a
shift
echo "$1"        # b      ($# went from 4 to 3)
shift 2          # drop two at once
echo "$1"        # d
```

Typical use: take a **command word** first, then process the rest:

```bash
action="$1"; shift
echo "Action: $action, files: $*"
```

---

## 7. Validating input

Never trust input. Check numbers:

```bash
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: '$1' is not a whole number" >&2
    exit 2
fi
```

Check a file or folder exists:

```bash
[ -f "$1" ] || { echo "No such file: $1" >&2; exit 1; }   # -f = is a regular file
[ -d "$2" ] || { echo "No such folder: $2" >&2; exit 1; } # -d = is a directory
```

(`[ ]` tests are Lesson 12.)

---

## 8. `read`: asking questions

```bash
read name                     # waits; whatever you type goes into $name
echo "Hello, $name"
```

Always use **`-r`** (raw: don't treat backslash as an escape) and a **prompt**:

```bash
read -r -p "What is your name? " name
echo "Nice to meet you, $name!"
```

| Option | Purpose | Example |
|--------|---------|---------|
| `-r` | keep backslashes literally (**always use**) | `read -r x` |
| `-p "text"` | show a prompt | `read -r -p "Age: " age` |
| `-s` | **silent**: don't echo typing (passwords) | `read -r -s -p "Password: " pw` |
| `-n 1` | accept just **1 character** (no Enter) | `read -r -n 1 -p "Continue? " key` |
| `-t 5` | give up after 5 seconds | `read -r -t 5 -p "Quick! " x` |
| `-a arr` | split words into an array (Lesson 15) | `read -r -a words` |

After `read -s`, print a blank line (`echo`), since the Enter wasn't shown.

### Multiple variables

```bash
read -r first last <<< "Asha Rao"       # first=Asha  last=Rao
read -r a b <<< "one two three four"    # a=one       b="two three four" (the last variable gets the rest)
```

`<<<` (here-string, Lesson 5) feeds a string as input.

### Default answer

```bash
read -r -p "Folder [$HOME/backup]: " dir
dir="${dir:-$HOME/backup}"              # empty answer → default
```

### Yes/No confirmation

```bash
read -r -p "Delete everything? [y/N] " answer
if [[ "$answer" == [yY]* ]]; then
    echo "Deleting..."
else
    echo "Cancelled."
fi
```

The capital **N** in `[y/N]` tells the user that **No is the default** (safer).

---

## 9. Reading files and pipes line by line

```bash
while IFS= read -r line; do
    echo "Line: $line"
done < names.txt
```

or from a pipe:

```bash
cat names.txt | while IFS= read -r line; do echo "Hi $line"; done
```

- `IFS=` stops Bash from trimming spaces at line ends
- `-r` keeps backslashes
- `while ... done < file` is a loop (Lesson 13)

Careful: variables set inside a `while` that is on the **right side of a pipe** disappear afterwards (it runs in a subshell). Use `done < file` to avoid that.

---

## 10. Is a person at the keyboard? `[ -t 0 ]`

```bash
if [ -t 0 ]; then
    read -r -p "Your name: " name       # interactive: ask
else
    read -r name                         # input came from a pipe/file
fi
```

Tip: `read -p` prompts are shown **only when input is a terminal**. In `echo x | script`, no prompt appears.

---

## 11. Putting it together: `mkproject.sh`

```bash
#!/usr/bin/env bash
# mkproject.sh - create a project skeleton
# Usage: ./mkproject.sh NAME [PARENT_DIR]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 NAME [PARENT_DIR]" >&2
    exit 2
fi

name="$1"
parent="${2:-$HOME/projects}"
target="$parent/$name"

if [ -e "$target" ]; then
    echo "Error: $target already exists" >&2
    exit 1
fi

mkdir -p "$target"/{src,docs,tests}
echo "# $name" > "$target/README.md"
echo "Created project at $target"
```

Run: `./mkproject.sh myapp` or `./mkproject.sh myapp /tmp`.

---

## ⚠️ Gotchas

1. **Quote `"$1"`** just like any variable: filenames with spaces!
2. `$10` means `$1` followed by `0`. Use `${10}`.
3. `"$@"` (list) vs `"$*"` (one string): use `"$@"`.
4. **Check `$#`** before using `$1`; with `set -u` a missing argument is an error.
5. Missing `-r` in `read` makes `\` disappear from the input.
6. Pipe into `while read`: variables you set inside vanish afterwards (subshell).
7. **Never put passwords in arguments:** `ps` shows arguments to other users. Use `read -s` or an environment variable / file.

---

## ✅ Summary

- `$1 $2 ... ${10}`, `$#` count, `"$@"` all (quoted!), `$0` script name
- `shift` consumes arguments; `${1:-default}` gives defaults
- Print **usage to stderr** and `exit 2` when arguments are wrong
- `read -r -p "Prompt: " var` for questions; `-s` secrets; `-n 1` single key
- Validate input: numbers (`=~ ^[0-9]+$`), files (`-f`), folders (`-d`)
- `[ -t 0 ]` tells you if a human is typing

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

> 🎉 After Lesson 11, you can write real tools that take input. **Lesson 12** teaches `if`, `case` and tests, the decision-making you've been previewing.

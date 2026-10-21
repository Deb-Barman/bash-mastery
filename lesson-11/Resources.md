# Lesson 11 — Resources

## 📋 Cheat Sheet

**Positional parameters**

| Symbol | Meaning |
|--------|---------|
| `$0` | script name |
| `$1` ... `$9`, `${10}` | arguments |
| `$#` | number of arguments |
| `"$@"` | all arguments, each kept separate ✅ |
| `"$*"` | all arguments as one string |
| `shift` / `shift N` | drop first 1 / N arguments |
| `${1:-default}` | `$1` or a default |
| `${1:?message}` | require `$1` or stop |

**Number tests (inside `[ ]`):** `-eq` · `-ne` · `-lt` · `-le` · `-gt` · `-ge`
**File tests:** `-e` exists · `-f` regular file · `-d` directory · `-r` readable · `-w` writable · `-x` executable · `-s` not empty

**`read` options:** `-r` (always) · `-p "prompt"` · `-s` silent · `-n 1` one key · `-t 5` timeout · `-a arr` into array

**Patterns**

```bash
# usage check
[ "$#" -ge 1 ] || { echo "Usage: $0 FILE" >&2; exit 2; }

# number check
[[ "$1" =~ ^[0-9]+$ ]] || { echo "not a number" >&2; exit 2; }

# loop over all arguments
for arg in "$@"; do echo "$arg"; done

# yes/no
read -r -p "Sure? [y/N] " a; [[ "$a" == [yY]* ]] || exit 0

# file line by line
while IFS= read -r line; do echo "$line"; done < file.txt

# password prompt
read -r -s -p "Password: " pw; echo
```

**Exit codes:** `0` ok · `1` error · `2` usage error

---

## 🏋️ Exercises

Work in `~/bash-practice/ex11`.

**Level A: Easy**
1. `hi.sh`: print `Hello, <first argument>!`
2. Make it use `stranger` when no argument is given.
3. `count.sh`: print how many arguments it got.
4. `second.sh`: print only the second argument.

**Level B: Medium**
5. `add3.sh`: take three whole numbers and print their sum. Show a usage message (stderr, exit 2) if there aren't exactly three.
6. `ask.sh`: ask for a name and a favourite colour (with prompts), then print `<name> likes <colour>`.
7. `each.sh`: print every argument on its own line with its position (`1: apple`) and keep `"two words"` together.
8. `exists.sh FILE`: print `FILE exists` or `FILE is missing`. Exit 0 or 1 accordingly.
9. `sure.sh`: ask `Continue? [y/N]` and print `Continuing` only for `y`/`Y`/`yes`.
10. `first-last.sh`: use `shift` so that `./first-last.sh a b c d` prints `first=a` and `rest=b c d`.

**Level C: Challenge**
11. `backup.sh SRC [DEST]`: check that `SRC` is an existing folder; DEST defaults to `~/backups`; create DEST; copy SRC into it as `SRC-YYYY-MM-DD`; print what happened. Use proper usage and exit codes.
12. `login.sh`: ask for a username (normal) and a password (**silent**), then print `Welcome, <user>` (never print the password!).
13. `sum-file.sh FILE`: read a file of numbers (one per line) and print their total, using `while read`.
14. `calc.sh 12 + 5`: support `+`, `-`, `*`, `/` (hint: `case`, or `if`) and print the result. Error message for anything else. (Note: `*` as an argument must be quoted by the caller: `calc.sh 3 '*' 4`. Why?)
15. (Think!) Why does `./script.sh *` behave differently from `./script.sh '*'`?
16. (Think!) Why is passing a password as an argument (`./login.sh me secret`) a bad idea?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
mkdir -p ~/bash-practice/ex11 && cd ~/bash-practice/ex11

# 1 + 2   hi.sh
#!/usr/bin/env bash
echo "Hello, ${1:-stranger}!"

# 3   count.sh
#!/usr/bin/env bash
echo "$# arguments"

# 4   second.sh
#!/usr/bin/env bash
echo "$2"

# 5   add3.sh
#!/usr/bin/env bash
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 N1 N2 N3" >&2
    exit 2
fi
echo $(( $1 + $2 + $3 ))

# 6   ask.sh
#!/usr/bin/env bash
read -r -p "Your name? " name
read -r -p "Favourite colour? " colour
echo "$name likes $colour"

# 7   each.sh
#!/usr/bin/env bash
n=0
for arg in "$@"; do
    n=$(( n + 1 ))
    echo "$n: $arg"
done
# ./each.sh apple "two words" pear

# 8   exists.sh
#!/usr/bin/env bash
if [ -e "$1" ]; then
    echo "$1 exists"
    exit 0
else
    echo "$1 is missing"
    exit 1
fi

# 9   sure.sh
#!/usr/bin/env bash
read -r -p "Continue? [y/N] " a
if [[ "$a" == [yY]* ]]; then
    echo "Continuing"
fi

# 10  first-last.sh
#!/usr/bin/env bash
first="$1"
shift
echo "first=$first"
echo "rest=$*"

# 11  backup.sh
#!/usr/bin/env bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 SRC [DEST]" >&2
    exit 2
fi
src="$1"
dest="${2:-$HOME/backups}"
if [ ! -d "$src" ]; then
    echo "Error: '$src' is not a folder" >&2
    exit 1
fi
mkdir -p "$dest"
target="$dest/$(basename "$src")-$(date +%F)"
cp -r "$src" "$target"
echo "Backed up '$src' to '$target'"

# 12  login.sh
#!/usr/bin/env bash
read -r -p "Username: " user
read -r -s -p "Password: " pw
echo
echo "Welcome, $user"          # never echo "$pw"!

# 13  sum-file.sh
#!/usr/bin/env bash
total=0
while IFS= read -r n; do
    total=$(( total + n ))
done < "$1"
echo "$total"

# 14  calc.sh
#!/usr/bin/env bash
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 NUM OP NUM   (quote * like '*')" >&2
    exit 2
fi
case "$2" in
    +) echo $(( $1 + $3 )) ;;
    -) echo $(( $1 - $3 )) ;;
    '*') echo $(( $1 * $3 )) ;;
    /) echo $(( $1 / $3 )) ;;
    *) echo "Unknown operator: $2" >&2; exit 2 ;;
esac
# A bare * on the command line is a GLOB: Bash replaces it with the file names
# in the folder BEFORE the script starts, so the script would get many arguments.
# case/esac is explained in Lesson 12.

# 15
# ./script.sh *   → Bash expands * into all file names: many arguments.
# ./script.sh '*' → the script receives one argument: the character *.

# 16
# Arguments are visible to every user via `ps`, and saved in your shell
# history. Use read -s, an environment variable, or a protected file (chmod 600).
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `unbound variable` on `$1` | used `set -u` and no argument was given | check `$#` first, or `${1:-}` |
| filename with spaces breaks | `$1` unquoted | `"$1"` |
| `$10` shows the first argument + `0` | needs braces | `${10}` |
| `[: too many arguments` | unquoted variable in `[ ]` | quote: `[ "$x" = y ]` |
| `integer expression expected` | comparing text with `-eq` | validate with `[[ $x =~ ^[0-9]+$ ]]` first |
| prompt text doesn't appear | input is piped / `-p` not used | prompts need a terminal; or use `echo -n` + `read` |
| backslashes vanish in input | no `-r` | always `read -r` |
| variable empty after `cmd \| while read` | the loop ran in a subshell | `while ...; done < file` |
| script waits forever | `read` with no input source (cron, CI) | test `[ -t 0 ]`, or use `read -t` |

---

## 💡 Habits of pro coders

1. **Check argument count first**, then print a clear usage line to stderr.
2. **Quote everything:** `"$1"`, `"$@"`.
3. **Validate** (number? exists? writable?) before doing real work.
4. **Defaults for the optional, errors for the required** (`${2:-x}` / `${1:?msg}`).
5. **Never hide the destructive:** ask for confirmation and default to *No*.
6. **Never print or pass secrets:** use `read -s`, environment variables or files with `chmod 600`.
7. **Support both worlds:** arguments for automation, prompts only when `[ -t 0 ]`.

## 📚 Extra resources

- **`help read`**, **`help shift`**, **`help test`** (built-in help, Lesson 4)
- **mywiki.wooledge.org/BashGuide/Parameters** and **/BashFAQ/001** (reading files line by line)
- **Google Shell Style Guide**: usage messages and argument handling
- **shellcheck.net:** warns about unquoted `$@`, `read` without `-r`, and more
- Preview of **Lesson 18:** `getopts` for professional `--flags`

## 🧠 Self-check

1. What are `$0`, `$1` and `$#`?
2. What's the difference between `"$@"` and `"$*"`? Which should you use?
3. What does `shift` do?
4. Why use `read -r`? What do `-p`, `-s`, `-n 1` do?
5. Why should usage messages go to stderr with exit code 2?
6. Why use `[y/N]` with a capital N?

## ➡️ Next: Lesson 12 — Conditions (`if`, `[[ ]]`, `case`, exit codes, `&&`/`||`)

> 🎉 **Lessons 7 to 11 complete.** You can now process text, control permissions, write scripts, use variables correctly, and take input. Lesson 12 teaches decisions, the last big piece before loops and functions.

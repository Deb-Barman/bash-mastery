# Lesson 10 — Code Explained (line by line)

**Run it:**

```bash
bash Code.sh
```

Safe: the only files it makes live in `~/bash-practice/lesson10-demo` (deleted at the end). Some values (dice roll, process id, your home folder) differ on every machine and every run.

---

## Part 1: variables

```bash
name="Asha"
city="Pune"
count=5
echo "Name: $name, City: $city, Count: $count"
echo "Length of name: ${#name} characters"
```

Assignment has **no spaces around `=`**. Even the number `5` is stored as text. `${#name}` gives the **length** (4).

---

## Part 2: braces

```bash
echo "Two ${fruit}s"      # Two apples
echo "Two $fruits"        # Two
```

With `$fruits`, Bash reads the **longest valid name** (`fruits`), finds nothing, and prints an empty string. The braces tell Bash exactly where the name ends.

---

## Part 3: quoting

| Line | Output | Why |
|------|--------|-----|
| `echo "Hello $full"` | `Hello Asha Rao` | double quotes **expand** |
| `echo 'Hello $full'` | `Hello $full` | single quotes are **literal** |
| `echo "Hello \$full"` | `Hello $full` | backslash escapes one `$` |
| `echo "...\$5"` | `it costs $5` | otherwise `$5` would be read as a variable |
| `"She said 'hi' ... \"bye\""` | both quote kinds appear | one kind can sit inside the other |

---

## Part 4: why quoting matters (the big one)

```bash
file="my report.txt"
printf '  [%s]\n' $file       # unquoted
printf '  [%s]\n' "$file"     # quoted
```

`printf '[%s]\n'` prints each **argument** inside brackets, so you can *see* how many arguments Bash created:

- unquoted: `[my]` and `[report.txt]`: **two** arguments
- quoted: `[my report.txt]`: **one**

Then the real consequence:

```bash
touch "my report.txt" other.txt
rm $file            # runs: rm my report.txt
```

`rm` complains it can't find `my` or `report.txt` (they don't exist), and **our real file survives**, which is lucky. In a folder that also had a file called `report.txt`, the unquoted version would have **silently deleted the wrong file**. The quoted version `rm "$file"` deletes exactly the one we meant.

```bash
pattern="*"
echo $pattern        # prints file names (Bash globbed the *)
echo "$pattern"      # prints: *
```

Unquoted variables are also subject to **globbing** (Lesson 6). A variable that happens to contain `*` can turn into a list of files.

> **Make a habit:** type the quotes the moment you type the `$`.

---

## Part 5: command substitution

```bash
today=$(date +%F)
items=$(ls | wc -l)
echo "Nested: ... '$(basename "$(pwd)")'"
```

`$(...)` runs the command and **replaces itself with its output**. The nested version reads inside-out: `pwd` gives the full path, `basename` keeps the last part. Notice the **inner quotes** inside the outer ones: that's allowed and good practice for `$( )`.

---

## Part 6: arithmetic

```bash
echo "$a / $b = $(( a / b ))"      # 7 / 3 = 2
```

Bash math is **integer only**: 7 ÷ 3 = 2 (the `.33` is cut off).

```bash
total=$(( a * b + 1 ))    # 22
(( total++ ))             # 23
(( total += 10 ))         # 33
```

`(( ... ))` without a leading `$` **does** math but doesn't produce a value; it's used for updates like `total++`. The printed result is 33.

```bash
awk -v a=$a -v b=$b 'BEGIN {printf "%.2f", a/b}'     # 2.33
```

`-v name=value` passes shell values into awk as variables. `BEGIN { }` runs before reading any input, so awk can be used as a **calculator**.

```bash
$(( RANDOM % 6 + 1 ))
```

`$RANDOM` is 0 to 32767; `% 6` leaves 0 to 5; `+ 1` gives 1 to 6, a dice roll.

---

## Part 7: defaults

```bash
unset BACKUP_DIR
echo "...Using default: ${BACKUP_DIR:-$HOME/backups}"    # uses default
echo "...still: [${BACKUP_DIR}]"                          # still empty
echo "... ${BACKUP_DIR:=$HOME/backups}"                   # assigns it
echo "Now: [$BACKUP_DIR]"                                 # now it has the value
```

- `:-` **uses** a fallback but changes nothing
- `:=` **uses and stores** the fallback

```bash
${greeting:+it is set}     # greeting has a value → prints "it is set"
${missing:+it is set}      # missing is unset     → prints nothing
```

`:+` is the opposite of `:-`: "use this only if the variable has a value."

```bash
( : "${API_KEY:?API_KEY must be set}" ) 2>&1
```

- `:` is a command that does nothing. We use it only to trigger the expansion.
- `${API_KEY:?message}` **aborts** with the message if `API_KEY` is unset or empty.
- The parentheses run it in a **subshell** so the abort doesn't kill our demo.

In a real script, this line at the top says "I refuse to run without this setting", a great defensive habit.

---

## Part 8: export

```bash
color="blue"
bash -c 'echo "child sees: [$color]"'    # [] (child doesn't know it)
export color
bash -c 'echo "child sees: [$color]"'    # [blue]
```

Single quotes around the child's command are essential: they stop **our** shell from expanding `$color`, so the **child** does it.

```bash
MODE=debug bash -c 'echo "MODE inside = $MODE"'
echo "...in my shell MODE is: [${MODE}]"
```

`NAME=value command` sets a variable **for that one command only**. Afterwards our shell doesn't know `MODE`.

---

## Part 9: built-in variables

| Variable | Value you see |
|----------|---------------|
| `$HOME`, `$PWD`, `$SHELL` | your home, current folder, login shell |
| `${USER:-$(whoami)}` | `USER`, or fall back to `whoami` if it's unset (some containers don't set it) |
| `$0` | the script's name, e.g. `Code.sh` |
| `$$` | this script's process id (different every run) |
| `$LINENO` | the **current line number** |
| `$SECONDS` | seconds the script has been running |

(`$LINENO` is wonderful in error messages: `echo "failed at line $LINENO"`.)

---

## Part 10: readonly, unset, set -u

```bash
( readonly PI=3.14159; PI=3 ) 2>&1
```

`readonly` locks a variable. The second assignment fails with `PI: readonly variable`. The subshell `( )` contains the failure so our demo continues.

```bash
unset temp
echo "[${temp}]"       # []
```

`unset` deletes the variable.

```bash
( set -u; echo "Value: $undefined_variable" ) 2>&1
# line 147: undefined_variable: unbound variable
```

With `set -u`, using a variable that was never set is an **error**, not a silent empty string. Add `set -u` near the top of your scripts, and a typo like `$BACKUP_DRI` stops the script instead of causing damage.

---

## 🧪 Experiments

1. Delete the quotes in `rm "$file"` and run with a `report.txt` present.
2. Change `fruit` to `pear` and watch Part 2.
3. Print `${name^^}` (UPPERCASE) and `${name,,}` (lowercase): a preview of Lesson 16.
4. Make a variable with several spaces, `x="a    b"`, and compare `echo $x` with `echo "$x"`.
5. Try `echo $(( 10 / 4 ))` and `awk 'BEGIN {print 10/4}'`.
6. In your terminal: `export GREETING=hi; bash -c 'echo $GREETING'`, then `unset GREETING` and repeat.

---

## ✅ New words in this file

`var=value` · `"$var"` · `${var}` · `${#var}` · `${var:-x}` · `${var:=x}` · `${var:+x}` · `${var:?msg}` · `$(cmd)` · `$(( ))` · `(( ))` · `export` · `readonly` · `unset` · `set -u` · `$RANDOM` · `$$` · `$0` · `$LINENO` · `$SECONDS` · `awk -v`

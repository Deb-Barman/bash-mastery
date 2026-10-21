# Lesson 12 — Conditions: Making Decisions

**Level 3 · Real Scripting · Time: ~75 minutes**

---

## 🎯 What you will learn

- `if` / `elif` / `else` / `fi`
- What a **condition** really is in Bash (an exit code!)
- Test strings, numbers and files with `[ ]` and `[[ ]]`
- Combine tests with `&&`, `||`, `!`
- Do number comparisons the readable way with `(( ))`
- Choose between many options with `case`
- Avoid the classic traps (spaces, quotes, `A && B || C`)

> Until now your scripts ran straight down. Today they learn to **decide**.

---

## 1. The shape of `if`

```bash
if CONDITION; then
    commands
elif OTHER_CONDITION; then
    commands
else
    commands
fi
```

- `then` must follow the condition (on the same line after `;`, or on the next line)
- `fi` is `if` backwards: it closes the block
- `elif` and `else` are optional
- Indent the inside by 4 spaces. It isn't required, but unreadable code is a bug magnet

---

## 2. 🔑 A condition is just a command's exit code

In Bash, `if` doesn't check "true/false". It runs a command and looks at its **exit code** (Lesson 9):

- exit code **0** = success = "true" → the `then` branch runs
- **anything else** = failure = "false" → `else` branch

So **any command** can be a condition:

```bash
if grep -q "Pune" cities.txt; then       # -q = quiet: only the exit code matters
    echo "Found Pune"
fi

if mkdir backup 2>/dev/null; then
    echo "Created backup folder"
else
    echo "Could not create it (maybe it exists)"
fi

if ! ping -c1 -W1 8.8.8.8 > /dev/null 2>&1; then     # ! negates
    echo "Offline"
fi
```

---

## 3. The test commands: `[ ]` and `[[ ]]`

`[ ... ]` is really a **command** (named `[`, also `test`). `[[ ... ]]` is Bash's smarter keyword version.

```bash
[ "$age" -ge 18 ]        # test command: succeeds (0) if true
[[ $age -ge 18 ]]        # Bash version: safer and more powerful
```

**Prefer `[[ ]]` in Bash scripts.** It doesn't word-split unquoted variables, supports `&&`/`||` inside, pattern matching and regex. Use `[ ]` only when you need POSIX `sh` compatibility.

### ⚠️ Spaces are mandatory

```bash
[[ $x == 5 ]]     # ✅
[[$x==5]]         # ❌ command not found
[ "$a" = "b" ]    # ✅ spaces inside the brackets and around =
```

---

## 4. String tests

| Test | True when |
|------|-----------|
| `[[ $a == $b ]]` or `[ "$a" = "$b" ]` | equal |
| `[[ $a != $b ]]` | not equal |
| `[[ -z $a ]]` | **z**ero length: empty |
| `[[ -n $a ]]` | **n**on-empty |
| `[[ $a < $b ]]` | sorts before (alphabetical) |
| `[[ $a == pat* ]]` | matches the **glob** pattern (don't quote the pattern) |
| `[[ $a =~ regex ]]` | matches a regular expression (Lesson 19) |

```bash
name="Asha"
if [[ $name == "Asha" ]]; then echo "Hi Asha"; fi
if [[ $file == *.txt ]]; then echo "A text file"; fi     # glob match
if [[ -z $answer ]]; then echo "You typed nothing"; fi
```

Single `=` and double `==` mean the same inside tests. Use `==` in `[[ ]]`.

---

## 5. Number tests

Inside `[ ]` / `[[ ]]` numbers use **letters**, not symbols:

| Test | Meaning |
|------|---------|
| `-eq` | equal |
| `-ne` | not equal |
| `-lt` / `-le` | less than / less or equal |
| `-gt` / `-ge` | greater than / greater or equal |

```bash
if [[ $age -ge 18 ]]; then echo "adult"; fi
```

(Why not `>`? Inside `[ ]`, `>` means *redirect to a file*! Inside `[[ ]]` it compares **text**. Never use `<` `>` for numbers there.)

### The friendly way: `(( ))`

`(( ))` does **arithmetic** and uses normal symbols:

```bash
if (( age >= 18 )); then echo "adult"; fi
if (( score > 50 && score <= 100 )); then echo "pass"; fi
if (( count % 2 == 0 )); then echo "even"; fi
```

No `$` needed inside. Use `(( ))` for numbers and `[[ ]]` for text and files.

---

## 6. File tests

| Test | True when `FILE`... |
|------|---------------------|
| `-e` | exists (anything) |
| `-f` | is a regular **f**ile |
| `-d` | is a **d**irectory |
| `-L` | is a symbolic link |
| `-r` / `-w` / `-x` | is readable / writable / executable by you |
| `-s` | exists and is **not empty** |
| `A -nt B` / `A -ot B` | A is newer / older than B |

```bash
if [[ -f "$config" ]]; then
    source "$config"
else
    echo "Missing config: $config" >&2
    exit 1
fi

[[ -d "$dir" ]] || mkdir -p "$dir"       # create if missing
```

---

## 7. Combining conditions

```bash
if [[ $age -ge 18 && $country == "IN" ]]; then ...     # AND
if [[ $ans == y || $ans == Y ]]; then ...              # OR
if [[ ! -e $file ]]; then ...                          # NOT
if (( a > 0 )) && (( b > 0 )); then ...                # two tests, AND
if [[ -f $f ]] && grep -q "TODO" "$f"; then ...        # short-circuit: grep only runs if file exists
```

`&&` and `||` **short-circuit**: the second part runs only if needed.

---

## 8. Shortcuts: `&&` and `||` without `if`

```bash
[[ -d $dir ]] || mkdir -p "$dir"                 # "if not a dir, make it"
[[ -f $f ]] && echo "found $f"                   # "if it's a file, say so"
cd "$dir" || exit 1                              # "if cd fails, stop"
```

### ⚠️ The trap: `A && B || C` is NOT if/else

```bash
true && false || echo "C ran!"       # prints "C ran!" even though A was true
```

`C` runs if **A fails OR B fails**. For real if/else, use `if ...; then ...; else ...; fi`.

---

## 9. `case`: many choices, one variable

Cleaner than a long `elif` chain when you compare one value against **patterns**:

```bash
case "$answer" in
    [yY]|[yY][eE][sS])
        echo "Yes!"
        ;;
    [nN]|[nN][oO])
        echo "No."
        ;;
    "")
        echo "You typed nothing."
        ;;
    *)
        echo "I don't understand '$answer'."
        ;;
esac
```

- Each branch: `pattern) commands ;;`
- `|` means "or"
- Patterns are **globs** (`*.txt`, `[0-9]*`, `y*`)
- `*)` is the catch-all default, always put it **last**
- `esac` is `case` backwards

File type by extension:

```bash
case "$file" in
    *.jpg|*.jpeg|*.png) echo "image" ;;
    *.mp3|*.wav)        echo "audio" ;;
    *.sh)               echo "shell script" ;;
    *)                  echo "unknown" ;;
esac
```

Use `case` for: command words (`start|stop|restart`), file extensions, menu choices, option parsing (Lesson 18).

---

## 10. Common mistakes

| Mistake | What happens | Fix |
|---------|--------------|-----|
| `[ $x = a ]` with empty `x` | `unary operator expected` | `[[ $x == a ]]` or `[ "$x" = a ]` |
| `[ $a -gt $b ]` with text | `integer expression expected` | validate numbers first |
| `if [ $x > 5 ]` | creates a file named `5`! | `(( x > 5 ))` or `-gt` |
| `[[$x==1]]` | command not found | spaces everywhere |
| `if x == 1` | `x: command not found` | `if [[ $x == 1 ]]` |
| `A && B || C` as if/else | `C` runs when `B` fails | use real `if` |
| `=` for numbers: `[[ $a = 05 ]]` | compares text: `5` ≠ `05` | `(( a == 5 ))` |
| forgot `then` / `fi` / `;;` | syntax error | `bash -n script.sh` |
| quoting the glob: `[[ $f == "*.txt" ]]` | literal text match | leave the pattern unquoted |
| `-eq` on decimals | error | Bash has integers only; use `awk`/`bc` |

---

## ✅ Summary

- `if COMMAND; then ... elif ...; else ...; fi`: the condition is the **exit code** (0 = true)
- `[[ ]]` for strings and files, `(( ))` for numbers
- String: `==`, `!=`, `-z`, `-n`, pattern `==*.txt`; Number: `-eq -ne -lt -le -gt -ge` or `(( ))`
- File: `-e -f -d -r -w -x -s`
- `&&`, `||`, `!`: combine and negate; `A && B || C` isn't if/else
- `case` + patterns + `;;` + `*)` for multi-way choices

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

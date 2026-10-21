# Lesson 11 — Code Explained (line by line)

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson11-demo` (deleted at the end). Today's script **writes eight tiny helper scripts**, then runs each with different input so you can watch arguments and `read` in action.

> **Run it in a normal terminal** and Part 11 will really ask for your name. If you run it with no keyboard attached (for example `bash Code.sh < /dev/null`, which is how I tested), that part is skipped automatically.

---

## The helper scripts (written with here-documents)

All use `<< 'EOF'` with quotes, so `$1`, `$#` and friends are saved **as text** into the helper files and expanded only when those helpers run. After writing them: `chmod +x ./*.sh` makes all of them executable at once (`./*.sh` is a glob; the `./` prefix is the safe habit).

---

## Part 1: positional parameters

```bash
./args.sh Asha 25
```

Inside `args.sh`:

| Line | Prints |
|------|--------|
| `$0` | `./args.sh`: the name used to run it |
| `[$1]`, `[$2]` | `[Asha]`, `[25]` |
| `$#` | `2` |
| `printf '  <%s>\n' "$@"` | each argument on its own line, in `< >` |
| `printf '  <%s>\n' "$*"` | **one** line: all arguments glued with spaces |

Inside the echo text you see `\$0` and `\"\$@\"`: backslashes stop the *helper script's own echo* from expanding them, so it prints the symbols literally for teaching.

---

## Part 2: arguments with spaces

```bash
./args.sh one "two words" three
```

The **caller** quotes `"two words"`, making it **one** argument: `$#` is `3`, and `$2` is `[two words]`.

Look at the two outputs: `"$@"` gives three separate `< >` items (correct), while `"$*"` gives one blob `<one two words three>`. This is the reason for the rule **always use `"$@"`**.

---

## Part 3: shift

```bash
./shiftdemo.sh a b c d
```

| Moment | `$#` | `$*` |
|--------|------|------|
| start | 4 | `a b c d` |
| after `shift` | 3 | `b c d` (we saved `a` in `first` before shifting) |
| after `shift 2` | 1 | `d` |

`shift` throws `$1` away and renumbers the rest. Save `$1` into a variable **before** shifting if you still need it.

---

## Part 4: defaults

```bash
name="${1:-stranger}"
```

No argument → `Hello, stranger!`. With `Ravi` → `Hello, Ravi!`. The default is applied if `$1` is **unset or empty**.

---

## Part 5: a polite, safe script (`add.sh`)

```bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 NUM1 NUM2" >&2
    exit 2
fi
```

Read as English: **"If the number of arguments is not 2, print usage (to stderr) and exit with code 2."** `-ne` = "not equal" for **numbers**. Exit code `2` conventionally means "wrong usage."

```bash
if ! [[ "$1" =~ ^-?[0-9]+$ && "$2" =~ ^-?[0-9]+$ ]]; then
```

- `[[ ... ]]` is Bash's improved test
- `=~` matches a **regular expression** (Lesson 19), here `^-?[0-9]+$`: "optional minus, then one or more digits, nothing else"
- `&&` inside `[[ ]]` means both must match
- `!` negates: "if it is **not** the case that both are numbers"

Then the math: `$(( $1 + $2 ))`. We only reach it after validation, so `apples + 7` can't produce confusing results.

The three runs show exit codes `0`, `2` (missing argument), and `2` (not a number).

---

## Part 6: loop over all arguments

```bash
for item in "$@"; do
    count=$(( count + 1 ))
    echo "  item $count: [$item]"
done
```

A taste of Lesson 13: `for` repeats once per argument. Because we wrote `"$@"`, `"beta gamma"` stays a single item.

---

## Part 7: `read` and here-strings

```bash
read -r first last <<< "Asha Rao"
read -r a b <<< "one two three four"
read -r trimmed <<< "   lots of space   "
```

- `<<<` feeds a string into `read`
- Words are split between variables **in order**. The **last** variable receives everything left over: `b="two three four"`
- With one variable, `read` trims leading and trailing whitespace: `[lots of space]`

---

## Part 8: scripts that ask questions

```bash
printf 'Asha\n29\n' | ./ask.sh
```

We **pretend to be the person** by piping two lines of answers in. In `ask.sh`:

```bash
read -r -p "Your name? " name
```

When input comes from a pipe, Bash **does not print the `-p` prompt**, so you only see the final greeting. Run `./ask.sh` yourself later (after the demo, with the cleanup commented out) to see the prompts appear.

`age + 1` works because `$(( ))` reads variable names directly: `29 + 1 = 30`.

### confirm.sh

```bash
if [[ "$answer" == [yY]* ]]; then
```

`[yY]*` is a **glob** (Lesson 6): "starts with y or Y". So `y`, `Y`, `yes`, `Yes` all count. Everything else, including an empty Enter, means **No**. We tested `y`, `n`, and Enter. That's the "safe default" idea behind `[y/N]`.

---

## Part 9: read a file line by line

```bash
while IFS= read -r line; do
    echo "  line: $line"
done < list.txt
```

- `while ... do ... done` repeats while `read` succeeds (it fails at the end of the file)
- `< list.txt` after `done` feeds the file into the loop
- `IFS=` keeps spaces at the beginning and end of each line
- `-r` keeps backslashes

This is **the** standard pattern for processing a file line by line.

---

## Part 10: `mkproject.sh`: a mini real tool

```bash
./mkproject.sh                 # no name → usage, exit 2
./mkproject.sh myapp           # creates projects/myapp/{src,docs,tests} + README.md
./mkproject.sh myapp           # again → "already exists", exit 1 (refuses to overwrite)
```

It uses everything from this lesson: argument check, default parent folder (`${2:-$PWD/projects}`), a safety check (`[ -e "$target" ]` = "does it exist?"), brace expansion, and distinct exit codes. (In the lesson text the default was `$HOME/projects`. Here it's `$PWD/projects` so the demo stays inside its sandbox.)

`ls -R` prints the new tree; the empty `docs`, `src`, `tests` folders appear as empty sections.

---

## Part 11: human or pipe?

```bash
if [ -t 0 ]; then
```

`-t 0` is true when **file descriptor 0 (stdin) is a terminal**. A real user at the keyboard → ask. A pipe or file → skip. Professional scripts use this to avoid hanging while waiting for input that will never come (for example in automated jobs).

---

## 🧪 Experiments

1. Comment out the cleanup, then run `./ask.sh` yourself and watch the prompts.
2. Run `./args.sh *.sh` and see the glob expand into several arguments.
3. Call `./add.sh -3 10` and `./add.sh 3.5 2` (what happens, and why?).
4. Change `shiftdemo.sh` to use `shift 3` when only 2 arguments are given. Read the error.
5. Make `confirm.sh` also accept `yes`/`no` in capitals (hint: it already does for `y`).
6. Write `rename.sh OLD NEW` that renames a file, with a usage message and a check that OLD exists.

---

## ✅ New words in this file

`$0` · `$1`-`${10}` · `$#` · `"$@"` · `"$*"` · `shift` · `${1:-default}` · `read -r -p` · `<<<` · `IFS=` · `while read ... done < file` · `[ -t 0 ]` · `[ "$#" -ne 2 ]` · `-eq -ne -lt -gt` · `=~` · `[[ ]]` · `[ -e/-f/-d ]` · `exit 2`

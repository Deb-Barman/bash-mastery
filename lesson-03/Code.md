# Lesson 3 — Code Explained (line by line)

This file explains `Code.sh`. Keep both open side by side.

**Run it:**

```bash
bash Code.sh
```

Safe by design: it builds sample files in `~/bash-practice/lesson3-demo`, uses them, then deletes the folder.

> Needs GNU tools (Linux, WSL, Git Bash). On macOS, `touch -d "40 days ago"` fails. That's OK: only the "older than 30 days" line is affected.

---

## The setup

```bash
DEMO="$HOME/bash-practice/lesson3-demo"
if [ -d "$DEMO" ]; then rm -r "$DEMO"; fi
mkdir -p "$DEMO/logs" "$DEMO/notes" "$DEMO/data"
cd "$DEMO" || exit 1
```

Same safe pattern as Lesson 2: variable, clean start, guarded `cd`.

`mkdir -p` accepts **several paths** at once, so three folders are made in one line.

---

## Building sample files

### A multi-line file with a "here-document"

```bash
cat > logs/app.log << 'EOF'
...lines...
EOF
```

New idea! A **here-document** (`<< 'EOF'`) means: *"everything until the line `EOF` is the input."*

| Piece | Meaning |
|-------|---------|
| `cat >` | write to a file (like `echo >`) |
| `<< 'EOF'` | start reading typed text |
| `EOF` | the end marker (any word works, but `EOF` is the tradition) |

The quotes around `'EOF'` stop Bash from changing special characters inside. Super useful for creating files from scripts.

### `printf` for short files

```bash
printf 'Buy milk\nTODO: learn grep\nCall mom\n' > notes/todo.txt
```

`printf` is like `echo` but `\n` reliably means "new line."

### An old file and a big file

```bash
touch -d "40 days ago" logs/old.log
```

`touch -d` sets the file's modified date, so we can test `find -mtime`.

```bash
dd if=/dev/zero of=data/big.bin bs=1024 count=2048 2> /dev/null
```

Creates a 2 MB file filled with zeros: `2048 blocks × 1024 bytes`. The `2> /dev/null` hides dd's chatter. (`/dev/null` is a black hole; Lesson 5 explains.)

---

## Part 1: head and tail

```bash
head -n 3 logs/app.log      # first 3 lines
tail -n 2 logs/app.log      # last 2 lines
```

The `-n` number says how many lines. Without it you get 10.

---

## Part 2: wc

```bash
wc -l logs/app.log     # prints: 12 logs/app.log
wc -w logs/app.log     # prints: 69 logs/app.log
```

`-l` lines, `-w` words. The file name is printed after the number. (In Part 6 you will see how to get **just the number**.)

---

## Part 3: find

```bash
find . -name "*.txt"
```

| Piece | Meaning |
|-------|---------|
| `.` | start here and look in all subfolders |
| `-name` | match by file name |
| `"*.txt"` | `*` = anything. Quotes make `find` do the matching, not Bash |

```bash
find . -type d          # directories only (note the "." is the folder itself)
find . -size +1M        # bigger than 1 MB → finds big.bin
find . -name "*.log" -mtime +30    # AND: .log files AND older than 30 days
```

Two tests side by side mean **both must be true**. Only `old.log` qualifies.

---

## Part 4: grep

```bash
grep "ERROR" logs/app.log        # print matching lines
grep -c "ERROR" logs/app.log     # count: 3
grep -n "ERROR" logs/app.log     # prefix with line number
grep -v "DEBUG" logs/app.log | head -n 4
grep -i "SERVER" logs/app.log    # matches "server" despite capitals
```

`-v` **inverts**: show lines that do *not* match. The `| head -n 4` keeps the demo short (the pipe is explained in Part 6).

---

## Part 5: grep across files

```bash
grep -rn "TODO" .
```

- `-r` look inside every file under `.`
- `-n` show line numbers
- Output format: `file:line:text`

```bash
grep -rl "TODO" .
```

`-l` prints only **file names**, once each.

```bash
grep -w "cat" notes/ideas.txt
```

Matches `cat` only as a **whole word**. Notice that `Category of cat` still appears: the line **contains the whole word `cat` at the end**. Only a line with `cat` *only* inside `Category` would be skipped. Try `grep -w "cate"` to see it return nothing.

---

## Part 6: pipes

```bash
cat logs/app.log | grep "ERROR" | wc -l
```

Read it as a factory line:

```
cat (show file) ──▶ grep (keep ERROR lines) ──▶ wc -l (count lines)  →  3
```

Notice `wc -l` printed only `3` this time, not `3 filename`. When `wc` reads from a pipe, it has no file name to print. Remember this trick: **pipe in → clean number out.**

```bash
ls logs | wc -l       # how many items?
```

---

## Part 7: find + grep together

```bash
grep -l "grep" $(find . -name "*.txt")
```

`$(find ...)` runs `find` first and pastes its results as arguments to `grep`.

> ⚠️ **Limitation:** if any file name contains spaces, this breaks, because Bash splits the pasted result at the spaces. The safe pro version is:
> ```bash
> find . -name "*.txt" -exec grep -l "grep" {} +
> ```
> `-exec ... {} +` hands the files to `grep` correctly, spaces and all. Try it in an experiment below.

---

## Cleanup

```bash
cd "$HOME" || exit 1
rm -r "$DEMO"
```

Step out, then delete only that exact folder.

---

## 🧪 Experiments

1. Comment out the cleanup, run the script, then explore with `cd ~/bash-practice/lesson3-demo && ls -R`.
2. Change `ERROR` to `INFO` in the grep commands.
3. Add `-i` to `grep "error"` and compare results with and without it.
4. Replace Part 7 with the safer `find ... -exec grep -l "grep" {} +` version.
5. Try `less logs/app.log` (interactive). Press `/ERROR`, then `n` for next match, then `q` to quit.
6. Run `tail -f logs/app.log` in one terminal and, in a second terminal, run `echo "new line" >> logs/app.log` to watch it appear live.

---

## ✅ New words in this file

`here-document (<< EOF)` · `printf` · `touch -d` · `dd` · `/dev/null` · `find -name/-type/-size/-mtime` · `grep -i/-n/-c/-v/-r/-l/-w` · `|` · `$( )`

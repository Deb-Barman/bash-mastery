# Lesson 3 — Resources

## 📋 Cheat Sheet

| Command | What it does | Example |
|---------|-------------|---------|
| `less` | read page by page (`q` quits) | `less big.log` |
| `head -n N` | first N lines | `head -n 5 f.txt` |
| `tail -n N` | last N lines | `tail -n 5 f.txt` |
| `tail -f` | follow a file live | `tail -f app.log` |
| `wc -l/-w/-c` | count lines / words / bytes | `wc -l f.txt` |
| `find` | find files | `find . -name "*.txt"` |
| `grep` | find text in files | `grep -rn "TODO" .` |

**`find` tests:** `-name` `-iname` (any case) · `-type f` files · `-type d` folders · `-size +1M` · `-mtime -7` (last 7 days) · `-mtime +30` (older than 30 days)

**`grep` options:** `-i` ignore case · `-n` line numbers · `-c` count · `-v` invert · `-r` recursive · `-l` file names only · `-w` whole word · `-E` extended patterns (Lesson 19)

**`less` keys:** `Space` next · `b` back · `/text` search · `n` next match · `g`/`G` start/end · `q` quit

**Pipe pattern:** `command | grep "word" | wc -l` → "how many lines have this word?"

---

## 🏋️ Exercises

Create practice material first:

```bash
mkdir -p ~/bash-practice/ex3 && cd ~/bash-practice/ex3
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do echo "line $i: apple banana" >> fruit.txt; done
echo "line 13: cherry" >> fruit.txt
echo "Apple pie recipe" > recipe.txt
mkdir sub && echo "apple inside sub" > sub/deep.txt
touch empty.log
```

**Level A: Easy**
1. Show the first 3 lines of `fruit.txt`.
2. Show the last 2 lines of `fruit.txt`.
3. How many lines does `fruit.txt` have? (Show only the count with `wc`.)
4. Find all `.txt` files here and in sub-folders.

**Level B: Medium**
5. Show every line in `fruit.txt` that contains `cherry`.
6. Show every line that contains `apple`, with line numbers.
7. Count the lines in `fruit.txt` that contain `banana`.
8. Search for `apple` in **all files** (here and in `sub`), **ignoring case**, and print only the **file names**.
9. Find only **directories** in this folder tree.

**Level C: Challenge**
10. Show every line of `fruit.txt` that does **not** contain `banana`.
11. In one pipeline, print how many files named `*.txt` exist here (including sub-folders).
12. Show only lines 4 to 6 of `fruit.txt`. (Hint: `head` then `tail`.)
13. Find files **modified in the last day** that end with `.txt`.
14. (Think!) Why is `find . -name *.txt` risky without quotes?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
head -n 3 fruit.txt

# 2
tail -n 2 fruit.txt

# 3
wc -l < fruit.txt       # "<" feeds the file in, so only the number prints
# or: wc -l fruit.txt   (prints the number AND the file name)

# 4
find . -name "*.txt"

# 5
grep "cherry" fruit.txt

# 6
grep -n "apple" fruit.txt

# 7
grep -c "banana" fruit.txt

# 8
grep -ril "apple" .

# 9
find . -type d

# 10
grep -v "banana" fruit.txt

# 11
find . -name "*.txt" | wc -l

# 12
head -n 6 fruit.txt | tail -n 3

# 13
find . -name "*.txt" -mtime -1

# 14
# If a file matching *.txt exists in the current folder, Bash replaces
# *.txt with that file name BEFORE find runs, so find searches for the
# wrong thing (or errors with "paths must precede expression").
# Quotes keep the * for find to interpret.
```

</details>

---

## 🐞 Common beginner errors

| Message / problem | Cause | Fix |
|-------------------|-------|-----|
| `grep` prints nothing | case mismatch or no match | try `-i`; check spelling |
| `find: paths must precede expression` | unquoted `*.txt` expanded by Bash | quote it: `"*.txt"` |
| `Permission denied` flood from `find /` | searching protected system areas | search `~` or `.` instead; add `2>/dev/null` (Lesson 5) |
| Screen stuck in `less` | you didn't quit | press `q` |
| `tail -f` never ends | that is its job | `Ctrl+C` |
| `grep: dir: Is a directory` | forgot `-r` | `grep -r` |
| Wrong count with `grep -c` | it counts **lines**, not occurrences | one line with 3 matches counts as 1 |

---

## 💡 Habits of pro coders

1. **Look before you leap:** `wc -l` and `head` a file before opening it fully.
2. **Narrow `find`** with `-type f` and `-name` so output stays small.
3. **Dry-run deletes:** `find ... -print` first, then `-delete`.
4. **Use `grep -rn` on code folders** to find where something is defined.
5. **Pipe into `less`** when output is long: `grep -rn "TODO" . | less`.

## 📚 Extra resources

- **`man grep`, `man find`:** deep manuals (Lesson 4 teaches reading them)
- **explainshell.com:** paste `grep -rn "TODO" .` and see each flag explained
- **OverTheWire Bandit levels 5 to 12:** need `find`, `grep`, `wc` for real
- **regex101.com:** preview for Lesson 19, patterns made visual

## 🧠 Self-check

1. When do you use `find` and when `grep`?
2. What does `tail -f` do and how do you stop it?
3. What is the difference between `grep -c` and `wc -l`?
4. What does `grep -v` do?
5. Why preview with `-print` before `-delete`?

## ➡️ Next: Lesson 4 — Help Yourself (`man`, `--help`, `type`, `which`, history, Tab completion)

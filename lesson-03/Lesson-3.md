# Lesson 3 — Reading & Finding

**Level 1 · Survival · Time: ~60 minutes**

---

## 🎯 What you will learn

- Read long files without flooding the screen (`less`, `head`, `tail`)
- Count lines, words and characters (`wc`)
- Find files by name, type, size or age (`find`)
- Search **inside** files for text (`grep`)
- Combine them with the pipe `|` (a first taste)

> Do this lesson in `~/bash-practice`. `Code.sh` builds its own sample files, so you can follow along even with an empty folder.

---

## 1. Why this lesson matters

Real computers have **thousands** of files and some files have **millions** of lines (logs, data, code). You cannot open each by hand.

> Finding things is the #1 skill that makes Bash feel like a superpower.

---

## 2. `less` — read a long file, page by page

```bash
less bigfile.txt
```

Inside `less`:

| Key | Action |
|-----|--------|
| `Space` or `f` | next page |
| `b` | previous page |
| `↑` `↓` | one line |
| `g` / `G` | jump to start / end |
| `/word` | **search** forward for `word` |
| `n` / `N` | next / previous match |
| `q` | **quit** (most important key!) |

`less` never edits the file. It is perfectly safe for reading.

---

## 3. `head` and `tail` — start and end of a file

```bash
head file.txt          # first 10 lines
head -n 3 file.txt     # first 3 lines
tail file.txt          # last 10 lines
tail -n 3 file.txt     # last 3 lines
tail -f app.log        # FOLLOW: watch new lines arrive live
```

`tail -f` is a favourite of server engineers. Stop it with `Ctrl+C`.

---

## 4. `wc` — word count

```bash
wc file.txt        # lines, words, bytes
wc -l file.txt     # only lines
wc -w file.txt     # only words
wc -c file.txt     # only bytes
```

Quick use: "how many lines in this log?" → `wc -l app.log`

---

## 5. `find` — find files and folders

Format:

```
find WHERE  WHAT-TO-MATCH  [WHAT-TO-DO]
```

```bash
find . -name "notes.txt"        # by exact name, starting from here (.)
find . -name "*.txt"            # all .txt files (quotes are important!)
find . -iname "*.jpg"           # ignore upper/lower case
find . -type f                  # only files
find . -type d                  # only directories
find . -size +1M                # bigger than 1 megabyte
find . -mtime -7                # modified in the last 7 days
find . -name "*.log" -mtime +30 # .log files older than 30 days
```

Search **a specific place**:

```bash
find ~/Documents -name "*.pdf"
```

Do something with each result (preview, don't delete yet!):

```bash
find . -name "*.tmp" -print     # just show them (default)
find . -name "*.tmp" -delete    # ⚠️ delete them. Run -print FIRST!
```

**Golden rule:** always run the command with `-print` and *read the list* before adding `-delete`.

---

## 6. `grep` — search INSIDE files

`find` finds **files**. `grep` finds **text inside** files.

```bash
grep "error" app.log            # lines containing "error"
grep -i "error" app.log         # ignore case: Error, ERROR, error
grep -n "error" app.log         # show line numbers
grep -c "error" app.log         # COUNT matching lines
grep -v "debug" app.log         # lines that DON'T contain "debug"
grep -w "cat" file.txt          # whole word only (not "category")
```

Search many files:

```bash
grep -r "TODO" .                # search every file under here (-r recursive)
grep -rn "TODO" . --include="*.sh"   # only .sh files, with line numbers
grep -l "password" *.txt        # only print the FILE NAMES that match
```

---

## 7. The pipe `|` — a first taste

The pipe sends the output of one command into the next:

```bash
cat app.log | grep "ERROR" | wc -l
```

Read it left to right: *show the log → keep ERROR lines → count them.*

```bash
ls | wc -l                 # how many items in this folder?
history | grep "cd"        # which cd commands did I run?
ls -l | less               # scroll a long listing
```

You will master pipes in Lesson 5. For now, enjoy how powerful they are.

---

## 8. Putting it together

| Question | Command |
|----------|---------|
| "How long is this file?" | `wc -l file` |
| "What's at the top?" | `head file` |
| "What happened most recently?" | `tail file` |
| "Where is that PDF?" | `find ~ -iname "*.pdf"` |
| "Which files mention 'invoice'?" | `grep -rl "invoice" .` |
| "How many errors today?" | `grep -c "ERROR" app.log` |
| "Which files are huge?" | `find . -size +100M` |

---

## ⚠️ Gotchas

1. **Quote patterns:** `find . -name "*.txt"`. Without quotes, Bash may expand `*.txt` too early.
2. `grep` is **case-sensitive** unless you use `-i`.
3. `grep` matches **lines**, not words. It prints the whole line.
4. `find` with no options lists *everything*. Always narrow it.
5. Permission errors from `find /` are normal. Search your own folders instead.

---

## ✅ Summary

- `less` reads, `head`/`tail` peek at ends, `wc -l` counts lines
- `find` locates **files** (by name, type, size, age)
- `grep` locates **text** inside files (`-i -n -c -v -r -l`)
- `|` connects commands into mini machines
- Preview before you delete: `-print` before `-delete`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

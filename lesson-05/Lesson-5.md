# Lesson 5 — Pipes & Redirection

**Level 2 · Power Tools · Time: ~60 minutes**

---

## 🎯 What you will learn

- The three **streams** every command has: input, output, errors
- Redirect output to files (`>`, `>>`)
- Redirect input from files (`<`)
- Handle errors separately (`2>`, `2>&1`, `&>`)
- Throw output away (`/dev/null`)
- Connect commands with pipes (`|`)
- Watch **and** save at once (`tee`)

> This is the idea that makes Unix special: **small tools, joined together, do big jobs.**

---

## 1. The three streams

Every command has three "pipes" attached:

```
              ┌───────────────┐
 keyboard ──▶ │               │ ──▶ stdout (1)  normal output → screen
   stdin (0)  │    COMMAND    │
              │               │ ──▶ stderr (2)  error messages → screen
              └───────────────┘
```

| Name | Number | Default | Meaning |
|------|--------|---------|---------|
| **stdin** | `0` | keyboard | where input comes from |
| **stdout** | `1` | screen | where normal output goes |
| **stderr** | `2` | screen | where error messages go |

Errors and normal output both show on the screen, but they are **two separate streams**. That is why you can split them.

---

## 2. Output to a file: `>` and `>>`

```bash
echo "first" > out.txt       # create or OVERWRITE
echo "second" >> out.txt     # APPEND
ls -l > listing.txt          # save any command's output
date >> log.txt              # add a timestamp line to a log
```

⚠️ `>` **destroys** the old content immediately, even if the command then fails.

Protect against accidents:

```bash
set -o noclobber             # now > refuses to overwrite existing files
echo "x" >| out.txt          # >| forces an overwrite when you really mean it
set +o noclobber             # turn protection off again
```

---

## 3. Input from a file: `<`

```bash
wc -l < out.txt              # the file is fed INTO wc
sort < names.txt
```

Difference you saw in Lesson 3:

```bash
wc -l out.txt     # prints: 2 out.txt   (knows the file name)
wc -l < out.txt   # prints: 2           (just a stream, no name)
```

---

## 4. Errors: `2>`

```bash
ls /nonexistent                  # prints an error on screen
ls /nonexistent 2> errors.txt    # error goes to file, screen stays clean
ls /nonexistent 2>> errors.txt   # append errors
```

Both streams, split into different files:

```bash
command > out.txt 2> err.txt
```

Both streams into the **same** file:

```bash
command > all.txt 2>&1           # classic form
command &> all.txt               # Bash shortcut
```

### How to read `2>&1`

> "Send stream **2** (errors) to wherever stream **1** (output) currently goes."

**Order matters!**

```bash
command > all.txt 2>&1     # ✅ both in all.txt
command 2>&1 > all.txt     # ❌ errors still go to the screen
```

(First form: point 1 at the file, then point 2 at wherever 1 points. Second form: point 2 at the screen (where 1 is *now*), and only then move 1 to the file.)

---

## 5. The black hole: `/dev/null`

`/dev/null` is a special file that **swallows everything** written to it.

```bash
command > /dev/null            # hide normal output
command 2> /dev/null           # hide errors
command > /dev/null 2>&1       # hide EVERYTHING (silent run)
command &> /dev/null           # same, shorter
```

Typical use: search a big area without a flood of "Permission denied":

```bash
find / -name "*.conf" 2> /dev/null
```

Or run something just to test whether it **succeeds**:

```bash
if grep -q "word" file.txt; then echo "found"; fi     # -q = quiet
```

---

## 6. Pipes `|`: output → input

```bash
command1 | command2
```

The stdout of `command1` becomes the stdin of `command2`. No temporary file needed.

```bash
ls | wc -l                          # how many items?
cat app.log | grep ERROR            # only ERROR lines
history | tail -n 5                 # the last 5 commands
ps aux | grep bash                  # find running programs
```

Chain as many as you like, like an assembly line:

```bash
cat words.txt | sort | uniq -c | sort -rn | head -n 3
```

Read it left to right: *read → sort → count duplicates → sort by count, biggest first → top 3.* (You'll learn `sort` and `uniq` fully in Lesson 7.)

### Pipes only carry **stdout**

```bash
ls /nonexistent | wc -l      # the ERROR still shows on screen; wc counts 0
ls /nonexistent 2>&1 | wc -l # now the error text goes through the pipe too
ls /nonexistent |& wc -l     # Bash shortcut for 2>&1 |
```

---

## 7. `tee`: see it AND save it

`tee` is a T-junction: it copies the stream to the screen **and** to a file.

```bash
ls -l | tee listing.txt              # prints and saves (overwrite)
ls -l | tee -a listing.txt           # prints and appends
make 2>&1 | tee build.log            # watch a build live AND keep a log
```

---

## 8. `xargs`: turn a pipe into arguments (preview)

Some commands (like `rm`, `mkdir`) don't read stdin. `xargs` converts lines of input into arguments:

```bash
echo "a b c" | xargs mkdir           # same as: mkdir a b c
find . -name "*.tmp" | xargs rm      # ⚠️ careful: spaces in names break this
find . -name "*.tmp" -print0 | xargs -0 rm   # ✅ safe with spaces
```

Always preview with `echo` first: `... | xargs echo rm`.

---

## 9. Here-documents and here-strings (quick recap)

```bash
cat << 'EOF' > config.txt       # multi-line text into a file
name=Deb
mode=learning
EOF

grep "Deb" <<< "Hello Deb"      # <<< feeds a single string as input
```

---

## 10. Quick table

| Symbol | Meaning |
|--------|---------|
| `>` | stdout → file (overwrite) |
| `>>` | stdout → file (append) |
| `<` | file → stdin |
| `2>` | stderr → file |
| `2>&1` | stderr → same place as stdout |
| `&>` | both → file |
| `\|` | stdout → next command |
| `\|&` | stdout+stderr → next command |
| `/dev/null` | black hole |
| `tee` | copy to screen and file |

---

## ⚠️ Gotchas

1. `>` erases first. Never `command > file` where `file` is also an **input** of the same command (`sort a.txt > a.txt` leaves `a.txt` empty!). Use a second file or `sponge`/a temp file.
2. Redirection belongs **after** the command. `> file echo hi` works but looks strange. Keep it tidy.
3. `2>&1` order matters (see above).
4. A pipe's later commands only see **stdout**, unless you merge errors.
5. `sudo echo hi > /root/file` fails: the redirect is done by **your** shell, not by `sudo`. Use `echo hi | sudo tee /root/file`.

---

## ✅ Summary

- Every command has stdin (0), stdout (1), stderr (2)
- `>` overwrite · `>>` append · `<` input · `2>` errors · `&>` both
- `/dev/null` silences things; `tee` splits a stream
- `|` chains small tools into powerful pipelines
- Always think: **where does each stream go?**

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

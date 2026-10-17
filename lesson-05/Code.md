# Lesson 5 — Code Explained (line by line)

This file explains `Code.sh`. Keep both open side by side.

**Run it:**

```bash
bash Code.sh
```

Safe by design: everything happens in `~/bash-practice/lesson5-demo`, which is deleted at the end.

> Some numbers (like "9 items in this folder") may differ slightly on your machine. What matters is the **idea** behind each result.

---

## The setup

```bash
DEMO="$HOME/bash-practice/lesson5-demo"
if [ -d "$DEMO" ]; then rm -r "$DEMO"; fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1
```

Same safe pattern as before: variable, fresh start, guarded `cd`.

---

## Part 1: `>` and `>>`

```bash
echo "first"  > out.txt     # create / overwrite
echo "second" >> out.txt    # append
echo "third"  >> out.txt    # append
```

After these three lines, `out.txt` has 3 lines. Then:

```bash
echo "only me" > out.txt
```

One `>` wipes everything and writes just this line. That is the danger of `>`.

---

## Part 2: `<`

```bash
printf 'banana\napple\ncherry\n' > fruits.txt
```

`printf` with `\n` makes 3 lines.

```bash
echo "wc -l fruits.txt   -> $(wc -l fruits.txt)"
echo "wc -l < fruits.txt -> $(wc -l < fruits.txt)"
```

Compare the two results:

- `3 fruits.txt`: `wc` opened the file itself and knows its name
- `3`: `wc` only sees a stream of data, so there's no name to print

```bash
sort < fruits.txt
```

`sort` reads from the file via stdin and prints the sorted lines.

---

## Part 3: stderr with `2>`

```bash
ls /nonexistent-folder
```

Prints an error on screen. **That error is on stream 2 (stderr), not stream 1.**

```bash
ls /nonexistent-folder 2> errors.txt
```

Now the screen stays silent and the error sits in `errors.txt`. Proof that errors really are a separate stream.

---

## Part 4: splitting streams

```bash
ls fruits.txt /nonexistent-folder > good.txt 2> bad.txt
```

`ls` is asked about two things: one exists, one doesn't.

| Stream | Goes to | Contains |
|--------|---------|----------|
| stdout (1) | `good.txt` | `fruits.txt` |
| stderr (2) | `bad.txt` | the error message |

Professionals do this to keep a clean results file separate from a problem log.

---

## Part 5: merging with `2>&1` and `&>`

```bash
ls fruits.txt /nonexistent-folder > all.txt 2>&1
```

Read right to left as instructions executed **left to right**:

1. `> all.txt`: stream 1 now points at `all.txt`
2. `2>&1`: stream 2 now points to wherever stream 1 points, so also `all.txt`

Result: both in `all.txt`. (The order of lines can differ because errors are printed immediately while normal output is buffered. That's normal.)

```bash
ls fruits.txt /nonexistent-folder &> all2.txt
```

`&>` is the short Bash form of the same thing.

### Order matters!

```bash
ls /nonexistent-folder > right.txt 2>&1      # error saved in right.txt
ls /nonexistent-folder 2>&1 > wrong.txt      # error still on screen
```

In the wrong order, stream 2 is pointed at the **screen** (where stream 1 is *at that moment*), and only afterwards is stream 1 moved to the file. You can see it in the output: the error appears on screen and `wrong.txt` is empty.

**Memory trick:** `> file 2>&1`: "file first, then copy."

---

## Part 6: `/dev/null`

```bash
ls /nonexistent-folder 2> /dev/null
```

The error is thrown into the black hole. Nothing prints.

```bash
ls fruits.txt > /dev/null 2>&1
echo "exit code: $?"
```

New idea: **`$?`** holds the **exit code** of the last command.

| Code | Meaning |
|------|---------|
| `0` | success |
| non-zero (1, 2, ...) | failure |

This is how scripts "ask" whether something worked, even after hiding all the output. (Lesson 12 uses this heavily.)

---

## Part 7: pipes

```bash
ls | wc -l
```

`ls` prints names → `wc -l` counts them. No file needed.

```bash
ls | sort | head -n 2
```

Three commands: list → sort A-Z → keep two.

```bash
sort colors.txt | uniq -c | sort -rn
```

| Step | Does |
|------|------|
| `sort colors.txt` | puts same words next to each other |
| `uniq -c` | collapses neighbors and **c**ounts them |
| `sort -rn` | sort **n**umerically, **r**everse (biggest first) |

`uniq` only merges **adjacent** duplicates. That is why the first `sort` is essential. This "sort | uniq -c | sort -rn" pattern is one of the most famous in Unix. You'll use it for log analysis (Lesson 23).

```bash
ls /nonexistent-folder 2> /dev/null | wc -l     # 0
ls /nonexistent-folder |& wc -l                  # 1
```

A pipe carries **stdout only**. In the first line the error is thrown away, so `wc` counts 0 lines. `|&` pushes the error through the pipe too, so `wc` counts 1 line.

---

## Part 8: tee

```bash
ls -1 | tee listing.txt | wc -l
```

`tee` copies its input into `listing.txt` **and** passes it onward, here to `wc -l`. (`-1` prints one name per line.)

Afterwards `head -n 3 listing.txt` proves the file really was saved.

---

## Part 9: xargs

```bash
echo "alpha beta gamma" | xargs mkdir
```

`mkdir` doesn't read stdin, so `xargs` converts the words into arguments: `mkdir alpha beta gamma`.

```bash
touch "has space.tmp" plain.tmp
find . -name "*.tmp" -print0 | xargs -0 echo rm      # preview
find . -name "*.tmp" -print0 | xargs -0 rm           # real thing
```

| Piece | Meaning |
|-------|---------|
| `-print0` | `find` separates names with a hidden NUL character instead of a space/newline |
| `xargs -0` | `xargs` splits on that NUL character |

Together they handle names with spaces correctly. The preview with `echo` shows exactly what `rm` would run. **Always preview first.**

---

## Part 10: here-doc and here-string

```bash
cat << 'EOF' > config.txt
name=Deb
mode=learning
EOF
```

Typed text up to `EOF` becomes the file. Great for creating config files from scripts.

```bash
grep "Deb" <<< "Hello Deb"
```

`<<<` feeds one string as input, with no `echo ... |` needed.

---

## Part 11: noclobber

```bash
set -o noclobber
echo "new" > config.txt 2>&1 || echo "(Blocked! ...)"
echo "forced" >| config.txt
set +o noclobber
```

- `set -o noclobber`: `>` now **refuses** to overwrite existing files
- the first `>` fails, so the `||` branch runs (the error text is shown, that's expected)
- `>|` forces an overwrite when you really mean it
- `set +o noclobber` turns the protection off again

Many careful users keep `set -o noclobber` in `~/.bashrc`.

---

## Cleanup

```bash
cd "$HOME" || exit 1
rm -r "$DEMO"
```

---

## 🧪 Experiments

1. Comment out the cleanup, run, and open the files: `cat all.txt`, `cat wrong.txt`.
2. Swap the order in Part 5's "right" example to the wrong one and compare.
3. Run `ls /nonexistent 2>&1 | tee both.txt` and inspect `both.txt`.
4. Add `echo "one more" >> out.txt` right after Part 1's overwrite and see the result.
5. Make a file with 10 random words. Find the most common one using the sort/uniq pipeline.
6. Try `sort fruits.txt > fruits.txt` in a scratch folder. Look at what happened (the file is empty!). Why?

---

## ✅ New words in this file

`>` · `>>` · `<` · `<<<` · `2>` · `2>&1` · `&>` · `|&` · `/dev/null` · `$?` · `tee` · `xargs` · `-print0` · `sort` · `uniq -c` · `noclobber` · `>|`

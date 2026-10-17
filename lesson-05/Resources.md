# Lesson 5 — Resources

## 📋 Cheat Sheet

| Symbol | Meaning | Example |
|--------|---------|---------|
| `>` | stdout → file (overwrite) | `ls > list.txt` |
| `>>` | stdout → file (append) | `date >> log.txt` |
| `<` | file → stdin | `sort < names.txt` |
| `<<<` | string → stdin | `grep a <<< "banana"` |
| `2>` | stderr → file | `cmd 2> err.txt` |
| `2>&1` | stderr → where stdout goes | `cmd > all.txt 2>&1` |
| `&>` | both → file | `cmd &> all.txt` |
| `\|` | stdout → next command | `ls \| wc -l` |
| `\|&` | stdout+stderr → next command | `cmd \|& less` |
| `/dev/null` | black hole | `cmd > /dev/null 2>&1` |
| `tee` | screen **and** file | `cmd \| tee out.txt` |
| `tee -a` | same, but append | `cmd \| tee -a out.txt` |
| `xargs` | lines → arguments | `echo a b \| xargs mkdir` |
| `$?` | exit code of the last command | `echo $?` |

**Streams:** `0` stdin · `1` stdout · `2` stderr

**The order rule:** `cmd > file 2>&1` ✅ · `cmd 2>&1 > file` ❌

**Famous pipeline:** `sort file | uniq -c | sort -rn | head`

**Silent run:** `cmd > /dev/null 2>&1` or `cmd &> /dev/null`

---

## 🏋️ Exercises

Work in `~/bash-practice/ex5`. Set up first:

```bash
mkdir -p ~/bash-practice/ex5 && cd ~/bash-practice/ex5
printf 'pear\napple\npear\nfig\napple\npear\n' > fruits.txt
```

**Level A: Easy**
1. Save the output of `ls -l` into `listing.txt`.
2. Append today's date to `listing.txt`.
3. Count the lines in `fruits.txt` and print **only the number**.
4. Show `fruits.txt` sorted A to Z.

**Level B: Medium**
5. Run `ls fruits.txt /nope` so that the normal output goes to `ok.txt` and the error goes to `err.txt`.
6. Run the same command but put **both** streams into `both.txt`.
7. Run it again, hiding **all** output, then print its exit code.
8. Find out how many **different** fruits are in `fruits.txt`. (Hint: `sort -u` or `uniq`.)
9. Show how many times each fruit appears, most frequent first.

**Level C: Challenge**
10. Show and save at the same time: print the sorted fruits on screen and save them to `sorted.txt`.
11. Show the **top 2** most frequent fruits only.
12. Create the folders `a1 a2 a3` using `echo` and `xargs`.
13. Create `my notes.tmp` and `x.tmp`. Delete **all** `.tmp` files safely (spaces!), previewing with `echo` first.
14. (Think!) Why does `sort fruits.txt > fruits.txt` destroy the file? Give a safe version.
15. (Think!) Why does `sudo echo hi > /root/test.txt` fail with "Permission denied", and what works instead?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
ls -l > listing.txt

# 2
date >> listing.txt

# 3
wc -l < fruits.txt

# 4
sort fruits.txt

# 5
ls fruits.txt /nope > ok.txt 2> err.txt

# 6
ls fruits.txt /nope > both.txt 2>&1
# or: ls fruits.txt /nope &> both.txt

# 7
ls fruits.txt /nope > /dev/null 2>&1
echo $?                      # 2 (non-zero = something failed)

# 8
sort -u fruits.txt | wc -l   # 3
# or: sort fruits.txt | uniq | wc -l

# 9
sort fruits.txt | uniq -c | sort -rn

# 10
sort fruits.txt | tee sorted.txt

# 11
sort fruits.txt | uniq -c | sort -rn | head -n 2

# 12
echo "a1 a2 a3" | xargs mkdir

# 13
touch "my notes.tmp" x.tmp
find . -name "*.tmp" -print0 | xargs -0 echo rm     # preview
find . -name "*.tmp" -print0 | xargs -0 rm          # do it

# 14
# Bash opens (and EMPTIES) fruits.txt for the ">" BEFORE sort starts reading,
# so sort reads an empty file. Safe versions:
sort fruits.txt > sorted.tmp && mv sorted.tmp fruits.txt
# or use sort's own output option:
sort -o fruits.txt fruits.txt

# 15
# The redirection ">" is done by YOUR shell (not root), before sudo runs.
# Make sudo do the writing:
echo hi | sudo tee /root/test.txt > /dev/null
```

</details>

---

## 🐞 Common beginner errors

| Problem | Cause | Fix |
|---------|-------|-----|
| File became empty | `>` where you meant `>>`, or reading and writing the same file | use `>>`; write to a temp file then `mv` |
| Error still on screen | wrong `2>&1` order or forgot `2>` | `cmd > file 2>&1` |
| `wc` prints a name too | file given as argument | use `wc -l < file` or a pipe |
| `uniq -c` counts look wrong | input not sorted | `sort` first |
| `xargs` breaks on names with spaces | default splitting | `-print0` with `xargs -0` |
| `Permission denied` with `sudo cmd > file` | redirect isn't run by sudo | `cmd \| sudo tee file` |
| `cannot overwrite existing file` | `noclobber` is on | use `>\|` or `set +o noclobber` |

---

## 💡 Habits of pro coders

1. **Think in streams:** "where does stdout go? where does stderr go?"
2. **Preview destructive pipelines** with `echo` (`... | xargs echo rm`) before the real run.
3. **Keep errors in a log:** `cmd > out.log 2> err.log`.
4. **Use `-print0 | xargs -0`** whenever file names come from `find`.
5. **Build pipelines step by step:** run the first command alone, then add `| next`, and check each stage.

## 📚 Extra resources

- **`man bash`**, then search `/REDIRECTION`: the official rules
- **Bash Hackers Wiki** (wiki.bash-hackers.org): "Redirection tutorial"
- **explainshell.com:** paste a full pipeline and see every part labelled
- **OverTheWire Bandit levels 10 to 15:** practice pipelines for real
- **`man tee`, `man xargs`, `man uniq`**

## 🧠 Self-check

1. What are stdin, stdout and stderr, and what numbers do they have?
2. What is the difference between `>` and `>>`?
3. Why is `cmd 2>&1 > file` different from `cmd > file 2>&1`?
4. What does `/dev/null` do, and why is it useful?
5. Why must you `sort` before `uniq`?
6. What problem does `tee` solve?

## ➡️ Next: Lesson 6 — Wildcards & Globbing (`*`, `?`, `[a-z]`, `{a,b}`, safe quoting)

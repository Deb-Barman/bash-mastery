# Lesson 13 — Resources

## 📋 Cheat Sheet

```bash
for x in a b c; do ...; done            # list
for n in {1..10}; do ...; done          # range  ({1..10..2} step)
for f in *.txt; do ...; done            # files (glob)
for arg in "$@"; do ...; done           # arguments
for (( i=0; i<n; i++ )); do ...; done   # counter
while COND; do ...; done                # while true
until COND; do ...; done                # until true
while IFS= read -r line; do ...; done < file         # file lines
while IFS=, read -r a b c; do ...; done < file.csv   # CSV fields
while ...; do ...; done < <(command)                 # command output, keeps variables
```

| Keyword | Meaning |
|---------|---------|
| `break` / `break N` | leave 1 / N loops |
| `continue` | next round |
| `shift` | drop `$1` (loop over args manually) |
| `seq 1 "$n"` | numbers up to a variable |
| `shopt -s nullglob` | no-match globs become empty |
| `select` | numbered menu |

**Safe file loop template**

```bash
shopt -s nullglob
for f in ./*.txt; do
    [[ -f $f ]] || continue
    echo "Processing: $f"
done
```

**Never:** `for f in $(ls)` · unquoted `$f` · `cmd | while` when you need the variables later

---

## 🏋️ Exercises

Work in `~/bash-practice/ex13`.

**Level A: Easy**
1. Print the numbers 1 to 10, one per line.
2. Print `Hello, <name>` for `Asha`, `Ravi` and `Mina`.
3. Print every `.txt` file name in the folder (create a few first).
4. Count down from 5 to 1, then print `Liftoff!`.

**Level B: Medium**
5. Print the sum of 1 to 100.
6. Print only the odd numbers from 1 to 20.
7. Create `file01.txt` ... `file10.txt` with a loop (zero-padded).
8. Rename every `.txt` file in a folder to `.bak`.
9. For each file in the folder print `<name>: <N> lines`.
10. Loop over the arguments of a script `show.sh` and print `arg 1: ...`, `arg 2: ...` (spaces in arguments must survive).

**Level C: Challenge**
11. Read `people.csv` (`name,city,age`) and print only people **older than 30**, skipping the header.
12. Keep asking `Guess the number (1-10):` until the player guesses a secret number (use `$(( RANDOM % 10 + 1 ))`); count the tries.
13. Print a right triangle of stars of height 5 (nested loops).
14. Print all prime numbers from 2 to 50.
15. Write `cleanup.sh` that deletes every `*.tmp` file in the current folder safely (nullglob, quotes, preview first), and prints how many were deleted.
16. (Think!) Why does `for f in $(ls)` break, and what's the safe version?
17. (Think!) Why is `count` still 0 after `cat file | while read -r l; do ((count++)); done`? How do you fix it?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
for n in {1..10}; do echo "$n"; done

# 2
for name in Asha Ravi Mina; do echo "Hello, $name"; done

# 3
shopt -s nullglob
for f in *.txt; do echo "$f"; done

# 4
for (( i = 5; i >= 1; i-- )); do echo "$i"; done
echo "Liftoff!"

# 5
sum=0
for n in {1..100}; do (( sum += n )); done
echo "$sum"                                  # 5050

# 6
for n in {1..20}; do
    (( n % 2 == 1 )) && echo "$n"
done
# or: for n in {1..20..2}; do echo "$n"; done

# 7
for n in {1..10}; do touch "$(printf 'file%02d.txt' "$n")"; done
# or: touch file{01..10}.txt

# 8
for f in *.txt; do mv -- "$f" "${f%.txt}.bak"; done

# 9
for f in *; do
    [[ -f $f ]] && echo "$f: $(wc -l < "$f") lines"
done

# 10  show.sh
#!/usr/bin/env bash
i=0
for arg in "$@"; do
    (( i++ ))
    echo "arg $i: $arg"
done

# 11
{
    read -r _header
    while IFS=, read -r name city age; do
        (( age > 30 )) && echo "$name ($age)"
    done
} < people.csv

# 12
secret=$(( RANDOM % 10 + 1 ))
tries=0
while true; do
    read -r -p "Guess the number (1-10): " guess
    (( tries++ ))
    if [[ $guess == "$secret" ]]; then
        echo "Correct! It took $tries tries."
        break
    fi
    echo "No, try again."
done

# 13
for (( i = 1; i <= 5; i++ )); do
    row=""
    for (( j = 1; j <= i; j++ )); do row+="*"; done
    echo "$row"
done

# 14
for (( n = 2; n <= 50; n++ )); do
    is_prime=1
    for (( d = 2; d * d <= n; d++ )); do
        if (( n % d == 0 )); then is_prime=0; break; fi
    done
    (( is_prime )) && printf '%s ' "$n"
done
echo

# 15  cleanup.sh
#!/usr/bin/env bash
shopt -s nullglob
files=( ./*.tmp )
if (( ${#files[@]} == 0 )); then
    echo "No .tmp files."
    exit 0
fi
echo "Would delete: ${files[*]}"
read -r -p "Delete them? [y/N] " a
if [[ $a == [yY]* ]]; then
    rm -- "${files[@]}"
    echo "Deleted ${#files[@]} file(s)."
fi
# (arrays are Lesson 15; the idea: collect the matches, count them, then delete)

# 16
# $(ls) output is split on spaces/newlines, so "my file.txt" becomes two words,
# and ls output isn't reliable for odd names. Safe:  for f in *; do ... "$f" ...; done

# 17
# Each side of a pipe runs in a subshell, so the loop's count is lost.
# Fix:   while read -r l; do (( count++ )); done < file
# or:    while read -r l; do (( count++ )); done < <(cat file)
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| loop runs once with `*.txt` | no match, glob kept literally | `shopt -s nullglob` or `[[ -e $f ]] \|\| continue` |
| names with spaces split | `for f in $(ls)` / unquoted `$f` | `for f in *`, `"$f"` |
| infinite loop | counter never updated | `(( i++ ))`; test the condition |
| `{1..$n}` prints literally | braces expand before variables | `seq 1 "$n"` or `for (( ))` |
| variable lost after loop | `cmd \| while` subshell | `done < file` / `done < <(cmd)` |
| last line of file skipped | file lacks a final newline | `while read -r l \|\| [[ -n $l ]]; do` |
| `syntax error near 'done'` | missing `do`, `;`, or `done` | `bash -n` |
| off-by-one | `<` vs `<=` | trace the first and last round by hand |
| `mv: target is not a directory` | unquoted `$f` with spaces | quote it |

---

## 💡 Habits of pro coders

1. **Glob, don't parse `ls`.**
2. **Quote every `"$var"`** in the loop body.
3. **`nullglob` or an existence check** before looping over globs.
4. **`--` before filenames** passed to `mv`/`rm`/`cp`.
5. **Preview first:** `echo mv ...` in the loop, then remove the `echo`.
6. **Small loops, clear names:** `for file in`, not `for x in`.
7. **Avoid pipes into `while`** when you need the results afterwards.

## 📚 Extra resources

- **`help for`**, **`help while`**, **`help break`**
- **mywiki.wooledge.org/BashGuide/TestsAndConditionals** and **/BashFAQ/001**
- **mywiki.wooledge.org/ParsingLs**: why you never parse `ls`
- **shellcheck.net:** warns about `for f in $(ls)` (SC2045) and unquoted variables

## 🧠 Self-check

1. What are three kinds of lists a `for` loop can walk through?
2. When do you use `for (( ))` instead of `for ... in`?
3. What's the difference between `break` and `continue`?
4. Why does `cmd | while read` lose variables?
5. What does `nullglob` fix?
6. Why doesn't `{1..$n}` work?

## ➡️ Next: Lesson 14 — Functions (`local`, return values, reusable code, `main`)

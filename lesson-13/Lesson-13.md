# Lesson 13 — Loops: Do It Again, and Again

**Level 3 · Real Scripting · Time: ~75 minutes**

---

## 🎯 What you will learn

- `for` loops: over lists, files, ranges, and arguments
- C-style `for (( ))` loops
- `while` and `until` loops
- `break` and `continue`
- Loop through **file lines** safely (`while read`)
- Bulk-process files: rename, convert, count
- The big loop traps (spaces in names, `for x in $(ls)`, empty globs)

> This is the lesson where Bash becomes a **robot worker**: 10,000 files, one loop, one second.

---

## 1. `for`: once per item

```bash
for fruit in apple banana cherry; do
    echo "I like $fruit"
done
```

Read: *"For each word in the list, put it in `fruit`, run the block."*

Shape:

```bash
for VAR in LIST; do
    commands using "$VAR"
done
```

The list can come from many places:

```bash
for n in 1 2 3; do echo "$n"; done            # typed words
for n in {1..5}; do echo "$n"; done           # brace expansion (Lesson 6)
for n in {10..0..2}; do echo "$n"; done       # 10 8 6 4 2 0
for f in *.txt; do echo "$f"; done            # a glob: every .txt file
for arg in "$@"; do echo "$arg"; done         # all script arguments
for line in "red green" "blue"; do ... done   # quoted items stay whole
```

---

## 2. Looping over files (the #1 real-world use)

```bash
for file in *.txt; do
    echo "Processing: $file"
    wc -l "$file"
done
```

Rules that keep you safe:

1. **Quote** `"$file"` everywhere (spaces in names!)
2. Use a **glob** (`*.txt`), not `$(ls)`
3. Handle the "no match" case (see §8)

### Bulk rename

```bash
for f in *.jpeg; do
    mv -- "$f" "${f%.jpeg}.jpg"        # strip .jpeg, add .jpg (Lesson 16 explains ${f%...})
done
```

### Add a date prefix to every `.pdf`

```bash
today=$(date +%F)
for f in *.pdf; do
    mv -- "$f" "$today-$f"
done
```

---

## 3. C-style `for`: when you need a counter

```bash
for (( i = 1; i <= 5; i++ )); do
    echo "Number $i"
done
```

Three parts: **start** `i = 1` · **keep going while** `i <= 5` · **after each round** `i++`.

```bash
for (( i = 10; i > 0; i -= 3 )); do echo "$i"; done     # 10 7 4 1
```

---

## 4. `while`: repeat as long as a condition is true

```bash
count=1
while (( count <= 3 )); do
    echo "Round $count"
    (( count++ ))
done
```

The condition is the same kind you learned in Lesson 12 (any command's exit code).

```bash
while ! ping -c1 -W1 8.8.8.8 > /dev/null 2>&1; do      # wait until the network is up
    echo "Waiting for network..."
    sleep 2
done
```

### Infinite loop with `break`

```bash
while true; do
    read -r -p "Type 'quit' to stop: " word
    if [[ $word == quit ]]; then
        break
    fi
    echo "You typed: $word"
done
```

---

## 5. `until`: the mirror image

`until` repeats **until** the condition becomes true:

```bash
n=1
until (( n > 3 )); do
    echo "n = $n"
    (( n++ ))
done
```

Same as `while ! (( n > 3 ))`. Pick whichever reads more naturally.

---

## 6. `break` and `continue`

| Command | Effect |
|---------|--------|
| `break` | leave the loop **now** |
| `continue` | skip the rest of **this round**, start the next |
| `break 2` | leave **two** nested loops |

```bash
for n in {1..10}; do
    if (( n % 2 == 0 )); then continue; fi    # skip even numbers
    if (( n > 7 )); then break; fi            # stop after 7
    echo "$n"                                  # 1 3 5 7
done
```

---

## 7. 🔑 Reading a file line by line

```bash
while IFS= read -r line; do
    echo "Got: $line"
done < names.txt
```

- `IFS=` keeps leading/trailing spaces
- `-r` keeps backslashes
- `< names.txt` feeds the file into the loop

Split each line into fields:

```bash
while IFS=, read -r name city age; do        # IFS=, → split on commas
    echo "$name lives in $city and is $age"
done < people.csv
```

Skip the header line:

```bash
{ read -r _header; while IFS=, read -r name city; do ...; done; } < people.csv
```

(Or `tail -n +2 people.csv | while ...`, but see the pipe warning in §9.)

---

## 8. Looping over command output

```bash
for user in $(cut -d: -f1 /etc/passwd); do ...    # ❌ breaks on spaces; only OK for simple words
```

**Safer** options:

```bash
while IFS= read -r line; do ...; done < <(some_command)    # process substitution: keeps variables
find . -name "*.log" -print0 | while IFS= read -r -d '' f; do ...; done   # any filename, even with newlines
```

`< <(command)` feeds a command's output into the loop **without** a pipe. We'll use it more in Lesson 15.

---

## 9. Loop traps to avoid

### ❌ `for f in $(ls)`

```bash
for f in $(ls); do ... done        # splits "my file.txt" into "my" and "file.txt"
for f in *; do ... done            # ✅ the glob handles any name
```

### ❌ The empty-glob trap

If no `.txt` file exists, `*.txt` stays as the literal text `*.txt`:

```bash
for f in *.txt; do rm "$f"; done   # tries to remove a file called "*.txt"
```

Fix: guard, or switch on `nullglob`:

```bash
shopt -s nullglob          # a glob with no match becomes an empty list: the loop runs 0 times
for f in *.txt; do ...; done
# or:   [[ -e $f ]] || continue
```

### ❌ Variables vanish after `cmd | while read`

```bash
count=0
cat file | while read -r line; do (( count++ )); done
echo "$count"                      # 0!   the loop ran in a subshell
```

Use `while ...; done < file` or `done < <(cmd)` instead.

### ❌ Forgetting the quotes

```bash
for f in *.txt; do rm $f; done          # breaks on "my notes.txt"
for f in *.txt; do rm -- "$f"; done     # ✅
```

### ❌ Off-by-one

`{1..5}` has 5 items. `for (( i=0; i<5; i++ ))` runs 5 times (0 to 4). Count carefully.

---

## 10. `select`: instant menus

```bash
PS3="Choose a fruit: "
select fruit in apple banana quit; do
    case "$fruit" in
        quit) break ;;
        "")   echo "Invalid choice" ;;
        *)    echo "You picked $fruit" ;;
    esac
done
```

Bash prints a numbered menu and loops until `break`.

---

## 11. Handy companions

```bash
seq 1 5                   # 1 2 3 4 5 (works with variables: seq 1 "$n")
seq 0 5 20                # 0 5 10 15 20
sleep 1                   # wait one second
printf '%s\n' {1..3}      # one per line
printf '%02d ' {1..5}     # 01 02 03 04 05   (zero padding)
```

Prefer `{1..5}` for fixed numbers; for `{1..$n}` it doesn't work (braces expand before variables), so use `seq` or `for (( ))`.

---

## ✅ Summary

- `for x in LIST; do ...; done`: lists, globs `*.txt`, ranges `{1..5}`, `"$@"`
- `for (( i=0; i<n; i++ ))` when you need a counter
- `while COND` / `until COND`; `break`, `continue`
- File lines: `while IFS= read -r line; do ...; done < file`; split with `IFS=,`
- Never `for f in $(ls)`; quote `"$f"`; use `nullglob`; avoid `cmd | while` when you need variables afterwards

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

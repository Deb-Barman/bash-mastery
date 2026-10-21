# Lesson 13 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson13-demo`, deleted at the end.

---

## Part 1: `for` over lists

```bash
for fruit in apple banana cherry; do
    echo "I like $fruit"
done
```

The loop variable `fruit` takes each word in turn. `printf '%s ' "$n"` prints each number followed by a space **without** a newline, and a plain `echo` afterwards ends the line. `{10..0..2}` is brace expansion with a step.

```bash
for item in "red apple" "green pear"; do echo "item: [$item]"; done
```

Quoted items stay **whole**: two iterations, not four.

---

## Part 2: `for` over files

```bash
for file in *.txt; do
    echo "$file has $(wc -l < "$file") line(s)"
done
```

- `*.txt` expands to the matching names **before** the loop starts
- `wc -l < "$file"` gives just the number (no name), as you learned in Lesson 5
- Notice `my notes.txt` works: the quotes around `"$file"` keep the space inside one argument

---

## Part 3: bulk rename

```bash
for f in *.txt; do
    mv -- "$f" "${f%.txt}.md"
done
```

`${f%.txt}` means "the value of `f` with `.txt` **removed from the end**" (Lesson 16 explains this fully). Then we add `.md`. So `one.txt` becomes `one.md`.

- `--` after `mv` means "no more options": protects names that start with `-`
- Both arguments are quoted

`printf '[%s] ' *.txt` is a neat trick to **see** every name inside brackets.

---

## Part 4: C-style `for`

```bash
for (( i = 1; i <= 5; i++ )); do ... done
```

| Part | Meaning |
|------|---------|
| `i = 1` | runs once at the start |
| `i <= 5` | checked before **every** round; loop stops when false |
| `i++` | runs after every round |

The running total uses `(( total += i ))`: add `i` to `total` each time → 55.

---

## Parts 5 and 6: `while` and `until`

```bash
while (( count <= 3 )); do ... (( count++ )); done
until (( n > 3 )); do ... (( n++ )); done
```

They print the same thing. `while` runs **while** the test is true; `until` runs **until** it becomes true. **Don't forget the counter update**, or you create an endless loop (`Ctrl+C` stops it).

---

## Part 7: `break` and `continue`

```bash
for n in {1..10}; do
    if (( n % 2 == 0 )); then continue; fi
    if (( n > 7 )); then break; fi
    printf '%s ' "$n"
done
```

Trace it: 1 prints; 2 is even → `continue` (skip); 3 prints; ... 7 prints; 8 is even → `continue`; 9 is odd and `> 7` → `break` → loop ends. Output: `1 3 5 7`.

`break 2` jumps out of **both** loops. The demo stops when `a * b == 4`, first at `a=2 b=2`.

---

## Part 8: reading files line by line

```bash
while IFS= read -r line; do ... done < people.csv
```

Every line (header too) arrives in `line`.

```bash
{
    read -r _header
    while IFS=, read -r name city age; do ... done
} < people.csv
```

- `{ ...; } < file` gives the **whole group** one input stream
- the first `read` swallows the header into `_header`
- the `while` then continues from line 2
- `IFS=,` splits each line at commas into `name`, `city`, `age`

---

## Part 9: the subshell trap

Three versions count the lines of the file (4):

| Version | Result | Why |
|---------|--------|-----|
| `cat file \| while read ...` | `0` ❌ | each side of a pipe runs in a **subshell**; the changed `count` dies with it |
| `while read ...; done < file` | `4` ✅ | no pipe, same shell |
| `done < <(cat file)` | `4` ✅ | **process substitution** `<( )` acts like a file |

Whenever you "lose" a variable after a loop, check for a pipe before `while`.

---

## Part 10: the empty-glob trap

With no `.zip` files, `*.zip` stays as the literal text `*.zip`, so the loop runs once with `z='*.zip'`. A script that then runs `rm "$z"` or `cat "$z"` would act on a file that doesn't exist.

`shopt -s nullglob` makes an unmatched glob expand to **nothing**, so the loop runs **zero times**. Turn it back off with `shopt -u nullglob` if later code relies on the default.

---

## Parts 11 to 13: classics

- **FizzBuzz** checks `% 15` first (the most specific case), the same ordering lesson as Lesson 12
- **Multiplication table:** a loop inside a loop; `printf '%4d'` right-aligns each number in 4 columns; `echo` ends each row
- **`seq 1 "$limit"`**: `{1..$limit}` does **not** work because brace expansion happens *before* variables are expanded. Use `seq` or `for (( ))`

---

## 🧪 Experiments

1. Change the rename loop to turn `.md` files back into `.txt`.
2. Make Part 4 count **up to 20 by 5s**.
3. Remove the quotes around `"$f"` in Part 3 and run again with `my notes.txt` present. Read the errors.
4. Add `echo "Header skipped"` before the second loop in Part 8.
5. Write a `while` loop that doubles a number until it passes 1000, then prints it.
6. Make a loop that creates `file01.txt` to `file10.txt` (hint: `printf '%02d'`).

---

## ✅ New words in this file

`for ... in` · `for (( ))` · `while` · `until` · `break` · `continue` · `break 2` · `while IFS= read -r` · `IFS=,` · `{ ...; } < file` · `<( )` · `shopt -s nullglob` · `seq` · `printf '%4d'` · `${f%.txt}`

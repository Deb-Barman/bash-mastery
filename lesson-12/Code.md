# Lesson 12 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson12-demo` and removes it at the end. The script writes four small helper scripts (`grade.sh`, `ftype.sh`, `kind.sh`, `answer.sh`), so each decision can be run with many different inputs.

---

## The helper scripts

### `grade.sh`: `if / elif / else`

```bash
if (( score >= 90 )); then      echo "A"
elif (( score >= 75 )); then    echo "B"
elif (( score >= 50 )); then    echo "C"
else                            echo "Fail"
fi
```

Bash checks from the top and runs the **first** branch whose condition is true, then skips the rest. That's why the order matters: `95` is also `>= 50`, but it matches `>= 90` first.

### `ftype.sh`: file tests in order

It asks, in order: does it exist? is it a symlink? a directory? an **empty** regular file (`-f` and **not** `-s`)? a regular file with content? Putting the symlink test **before** the directory test matters, because a link to a folder passes `-d` too. Always test the most specific thing first.

### `kind.sh`: `case` with patterns

`*.jpg|*.jpeg|*.png) ... ;;` means "any name ending in jpg **or** jpeg **or** png". `*)` at the end catches everything else.

### `answer.sh`: `case` for user answers

`[yY]|[yY][eE][sS])` matches `y`, `Y`, `yes`, `YES`, `Yes`... `""` matches the empty string. Ending with `*)` guarantees there is always a reply.

---

## Part 1: a command as a condition

```bash
if grep -q "Pune" cities.txt; then
```

`grep -q` prints nothing; it only **exits 0 if found** and 1 if not. `if` looks at that exit code. `! grep -q ...` flips the result.

---

## Part 2: three ways to test a number

```bash
[ "$age" -ge 18 ]      # classic test command
[[ $age -ge 18 ]]      # Bash keyword
(( age >= 18 ))        # arithmetic
```

All three give the same answer. For **numbers**, `(( ))` reads best. `(( n % 2 == 0 ))` checks for even numbers (remainder 0).

---

## Part 3: strings

```bash
[[ $name == "Asha" ]] && echo "..."
[[ -z $empty ]]        # zero length
[[ $file == *.txt ]]   # glob match: the pattern is NOT quoted
[[ "apple" < "banana" ]]   # text order
```

`[[ A && B ]]` style one-liners (`test && action`) are a compact way to write a short `if`.

---

## Part 5: file tests

`ln -s full.txt shortcut` creates a **symbolic link** (a shortcut to another file). `ftype.sh` reports `symbolic link` for it even though it points at a regular file.

`-nt` / `-ot` ("newer than" / "older than") compare modification times; the demo line is only there to show the syntax.

---

## Part 6: combining

```bash
[[ $x -gt 0 && $x -lt 10 ]]            # AND inside one [[ ]]
[[ $answer == y || $answer == Y ]]      # OR
[[ -f full.txt ]] && grep -q "text" full.txt
```

The last one **short-circuits**: if the file doesn't exist, `grep` never runs, which avoids a confusing error.

---

## Part 7: `&&` / `||` shortcuts and the trap

```bash
[[ -d newdir ]] || mkdir newdir        # "make it if it's missing"
```

```bash
true && false || echo "C ran!"
```

Read left to right: `true` succeeds → run `false` → `false` **fails** → so `||` runs the echo. The echo ran although the first test passed. So `A && B || C` means *"(A and B) or C"*, not "if A then B else C". When B can fail, write a real `if`.

---

## Part 8: case is case-sensitive

`photo.JPG` didn't match `*.jpg`, so it landed in `*)`. Fixes: add `*.JPG` to the pattern, or lowercase the value first (`${file,,}`, Lesson 16), or `shopt -s nocasematch` for the whole `case`.

---

## Part 9: classic mistakes, live

```bash
unset blank
[ $blank = "a" ]
# [: =: unary operator expected
```

Unquoted, `$blank` disappears, so `[` sees only `= a` and complains. With `[[ ]]` or quotes (`"$blank"`) it works. This is the #1 reason to prefer `[[ ]]`.

```bash
a="05"
[[ $a == 5 ]]      # text: "05" is not "5" → false
(( a == 5 ))       # numbers: 5 == 5 → true
```

⚠️ One more arithmetic trap: a number with a **leading zero** is read as **octal**. `(( 010 == 8 ))` is true, and `(( 08 == 8 ))` is an **error** ("value too great for base"). If you read numbers like `08` from dates or files, force base 10: `(( 10#$n == 8 ))`.

```bash
[ 1 -eq 1 ]; echo $?     # 0
[ 1 -eq 2 ]; echo $?     # 1
```

Proof that tests are just commands with exit codes.

---

## 🧪 Experiments

1. Add a `*.JPG` pattern to `kind.sh` (or use `shopt -s nocasematch`) and re-run.
2. Make `grade.sh` print `Invalid` for scores above 100 or below 0.
3. Run `./grade.sh abc` and read the error. How would you validate input first?
4. Add a `ftype.sh` branch for "not readable" (`! -r`).
5. Change `[ $blank = "a" ]` to `[ "$blank" = "a" ]` in Part 9 and compare.
6. Write `leapyear.sh YEAR` (divisible by 4, but not by 100 unless by 400).

---

## ✅ New words in this file

`if/elif/else/fi` · `[ ]` · `[[ ]]` · `(( ))` · `-eq -ne -lt -le -gt -ge` · `==` `!=` `-z` `-n` · `-e -f -d -L -r -w -x -s -nt -ot` · `&&` `||` `!` · `case ... esac` · `;;` · `*)` · `grep -q` · `ln -s`

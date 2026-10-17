# Lesson 6 — Code Explained (line by line)

This file explains `Code.sh`. Keep both open side by side.

**Run it:**

```bash
bash Code.sh
```

Safe by design: it works only in `~/bash-practice/lesson6-demo` and removes it at the end.

> **Order of results:** Bash sorts matches using your computer's language settings. On some machines `a.txt` comes before `File With Space.txt`; on mine it's the other way round. Both are correct. Never depend on the order of a glob unless you sort explicitly.

---

## The setup: building files with braces

```bash
touch a.txt b.txt c.txt notes.txt
touch report{1,2,10}.txt
touch data{1..3}.csv
touch .hidden
touch "File With Space.txt"
mkdir -p sub/deeper
```

Braces create many files with one line:

- `report{1,2,10}.txt` → `report1.txt report2.txt report10.txt`
- `data{1..3}.csv` → `data1.csv data2.csv data3.csv`
- `"File With Space.txt"` is a deliberately awkward name, so we can see why quoting matters
- `.hidden` starts with a dot (a hidden file)

---

## Part 1: expansion happens first

```bash
echo "echo *.txt   ->" *.txt
```

Notice `*.txt` is **outside** the quotes. Bash replaces it with the list of matching names, and `echo` just prints them. `echo` never sees a `*`. **Bash did the matching.**

---

## Part 2: `*`

```bash
echo "*.csv      -> " *.csv
echo "report*    -> " report*
echo "*s*        -> " *s*
echo "a*         -> " a*
```

- `*.csv` → ends in `.csv`
- `report*` → starts with `report` (all three report files)
- `*s*` → has an `s` somewhere (notes, script, `data1.csv` because `.csv` has an `s`, and `sub`)
- `a*` → starts with `a`

Notice: the `*s*` result surprised you? Good, that's the point of previewing with `echo`.

---

## Part 3: `?`

```bash
report?.txt     # exactly ONE character between "report" and ".txt"
report??.txt    # exactly TWO characters
?.txt           # one-character base name
```

`report?.txt` matches `report1.txt` and `report2.txt` but **not** `report10.txt` (that has two characters). `report??.txt` matches only `report10.txt`.

---

## Part 4: `[ ]`

```bash
data[12].csv        # data1.csv and data2.csv (not data3)
[a-c].txt           # a.txt, b.txt, c.txt
[!a-b].txt          # one char that is NOT a or b → c.txt
photo[0-9].*        # photo, one digit, dot, anything
[[:upper:]]*        # starts with a capital letter
```

The last one matches `File With Space.txt`, `Makefile`, `README.md`.

---

## Part 5: braces (they invent text)

```bash
echo {a,b,c}                 # a b c
echo {1..5}                  # 1 2 3 4 5
echo {01..05}                # 01 02 03 04 05  (zero padded)
echo {10..6}                 # counts down
echo {0..20..5}              # 0 5 10 15 20   (step 5)
echo {2026..2027}-{01,02}    # combos: 4 results
```

Combining two brace groups gives **every combination** (like a multiplication table).

### Braces vs globs: the key demo

```bash
echo nofile{1,2}.xyz     # nofile1.xyz nofile2.xyz  → INVENTED, files don't exist
echo nofile*.xyz         # stays as nofile*.xyz     → glob finds nothing real
```

**Braces do not look at your disk. Globs do.**

### Practical tricks

```bash
cp notes.txt{,.bak}
```

Expands to `cp notes.txt notes.txt.bak` (the empty part before the comma means "nothing added"). A very fast way to make a backup.

```bash
mv script.{sh,bash}
```

Expands to `mv script.sh script.bash`: renames the extension.

---

## Part 6: hidden files

```bash
echo *                       # .hidden is NOT in the list
ls -A | head -n 3            # but ls -A shows it
```

```bash
printf '%s\n' * | wc -l      # counts matches: 18
shopt -s dotglob
printf '%s\n' * | wc -l      # now 19 (.hidden included)
shopt -u dotglob
```

- `printf '%s\n' *` prints **one name per line**, even names with spaces
- `wc -l` counts those lines
- `shopt -s` turns a Bash option **on**, `shopt -u` turns it **off**

> **Why not `echo * | wc -w`?** `wc -w` counts **words**, so `File With Space.txt` would count as three. I made exactly this mistake while writing the script, which shows how sneaky spaces are! One name per line + `wc -l` is the reliable way.

---

## Part 7: quotes switch off the magic

```bash
echo *.csv        # expands to names
echo "*.csv"      # literal
echo '*.csv'      # literal
echo \*.csv       # literal (backslash protects one character)
```

---

## Part 8: quote your variables

```bash
name="File With Space.txt"
ls $name        # unquoted → 3 separate words
ls "$name"      # quoted → 1 argument
```

Without quotes, Bash splits at spaces, and `ls` looks for three files named `File`, `With`, `Space.txt` and fails. **Quote variables every time.** (Full lesson in Lesson 10.)

---

## Part 9: when nothing matches

```bash
echo *.nothing              # prints: *.nothing (default behaviour)
shopt -s nullglob
echo "[" *.nothing "]"      # prints: [ ]  (the pattern vanished)
shopt -u nullglob
```

`nullglob` makes "no match" mean "empty list", which is what loops (Lesson 13) usually want.

---

## Part 10: `**` (globstar)

```bash
shopt -s globstar
printf '  %s\n' **/*.txt
```

`**/` means "any number of folders deep." You see `sub/one.txt` and `sub/deeper/two.txt` plus the top-level files. `printf '  %s\n'` prints each result on its own indented line.

---

## Part 11: extglob (and a real-world gotcha)

```bash
bash -O extglob -c '
  echo "*.@(jpg|png)    -> " *.@(jpg|png)
  echo "report!(1).txt  -> " report!(1).txt
  echo "!(*.txt)        -> " !(*.txt)
'
```

**Why a helper `bash -O extglob -c '...'`?** Bash must know `extglob` is **on before it reads** a line that uses `@(...)` or `!(...)`. In a script, `shopt -s extglob` on an earlier line is enough when the script actually runs, but `bash -n Code.sh` (syntax check) and tools like ShellCheck read the whole file without running `shopt`, and then report a syntax error. Putting those lines in a small helper Bash that starts with extglob on (`-O extglob`) avoids the problem.

In your **own scripts**, the usual way is a `shopt -s extglob` line near the top (above any code that uses the patterns, and not inside the same function/`if` block).

What the results mean:

| Pattern | Matches |
|---------|---------|
| `*.@(jpg\|png)` | `.jpg` **or** `.png` |
| `report!(1).txt` | `report` + anything **except exactly** `1` + `.txt` → `report10.txt`, `report2.txt` |
| `!(*.txt)` | everything that does **not** end in `.txt` |

---

## Part 12: preview, then delete

```bash
echo *.csv        # 1) look first
rm -v data*.csv   # 2) then delete, verbosely
```

This two-step habit prevents disasters. `-v` makes `rm` print each file it removes.

---

## 🧪 Experiments

1. Comment out the cleanup, run the script, and try your own patterns in `~/bash-practice/lesson6-demo`: `ls [a-c]*`, `ls *[0-9].*`, `ls ?????.txt`.
2. Change `report?.txt` to `report[0-9].txt`, then `report[0-9][0-9].txt`.
3. Create `touch -- -weird.txt` and try `ls *.txt`, then `ls ./*.txt`.
4. Write `echo {a,b}{1,2,3}` and predict all six results before running it.
5. In your terminal: `mkdir -p ~/bash-practice/months/{2026..2027}/{01..12}` and look with `ls -R`.
6. Try `shopt -s failglob` then `echo *.nothing` to see the error instead of silent text.

---

## ✅ New words in this file

`*` · `?` · `[ ]` · `[!...]` · `[[:upper:]]` · `{a,b}` · `{1..5}` · `{01..05}` · `{0..20..5}` · `shopt -s/-u` · `dotglob` · `nullglob` · `globstar` · `extglob` · `bash -O` · `printf '%s\n'`

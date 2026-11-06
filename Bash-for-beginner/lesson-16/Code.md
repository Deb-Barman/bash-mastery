# Lesson 16 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Needs Bash 4+ (the script checks). Almost everything is pure string work and creates nothing. Only Part 13 creates files, in `~/bash-practice/lesson16-demo` (deleted at the end). The date in Part 10 is today's date on your machine.

> Output lines use `\${...}` in the script's `echo` text so you see the **expression** on the left and its **result** on the right.

---

## Part 1: substrings

| Expression | Result | Meaning |
|------------|--------|---------|
| `${s:0:5}` | `Hello` | start at 0, take 5 |
| `${s:7}` | `World` | from 7 to the end |
| `${s: -5}` | `World` | last 5 (**the space matters**) |
| `${s:(-5):3}` | `Wor` | start 5 from the end, take 3 |

Counting starts at 0. In `Hello, World`, index 5 is the comma, 6 is the space, 7 is `W`.

---

## Parts 2 and 3: `#` strips the front, `%` strips the end

Take `path=/home/asha/docs/report.final.txt`:

| Expression | Result | Why |
|------------|--------|-----|
| `${path#/home/}` | `asha/docs/report.final.txt` | removes that exact front text |
| `${path#*/}` | `home/asha/...` | **shortest** match of `*/`: just the leading `/` |
| `${path##*/}` | `report.final.txt` | **longest** match of `*/`: everything through the last `/` |
| `${path%.*}` | `.../report.final` | **shortest** `.*` from the end: only `.txt` |
| `${path%%.*}` | `/home/asha/docs/report` | **longest** `.*`: from the first dot to the end |
| `${path%/*}` | `/home/asha/docs` | removes the last `/` and the file name |

Memory trick: **one symbol = shortest, two symbols = longest**; `#` works from the left, `%` from the right.

---

## Part 4: the file name cookbook

`${f##*.}` = extension, `${f%.*}` = name without extension, `${f%.jpeg}.jpg` = swap the extension. The last lines prove that `${path##*/}` equals `basename` and `${path%/*}` equals `dirname`, **without starting a new process**. In a loop over thousands of files, that is a large speed-up.

---

## Part 5: replace

`/` replaces the **first** match, `//` **all** matches. `${x// /_}` swaps every space for an underscore, `${x//two}` (no replacement part) **deletes** all matches. `#` and `%` after the first slash anchor the match to the start or the end.

---

## Part 6: case

`^^` all upper, `,,` all lower, `^` first letter upper, `,` first letter lower. In the demo, `${answer,,} == y*` lets the user type `YES`, `Yes`, or `yes`. This is the standard way to make a check case-insensitive.

---

## Part 7: contains, starts, ends

The right side of `==` inside `[[ ]]` is a **glob**: `*World*` = contains, `Hello*` = starts with, `*World` = ends with. Leave the pattern **unquoted**, otherwise it is matched literally.

---

## Part 8: trimming

Three ways, same result:

1. `read -r trimmed <<< "$text"`: `read` trims both ends of a single line
2. `sed 's/^[[:space:]]*//; s/[[:space:]]*$//'`: classic, works everywhere
3. extglob: `${text##+([[:space:]])}` removes leading whitespace, `${t%%+([[:space:]])}` the trailing. It runs inside a small `bash -O extglob -c '...'` helper so the script stays valid when checked with `bash -n`, exactly as in Lesson 6.

---

## Part 9: split and join

```bash
IFS=, read -r -a parts <<< "$csv"      # split on commas into an array
( IFS=-; echo "${parts[*]}" )          # join with dashes
```

`${csv%%,*}` = before the **first** comma, `${csv#*,}` = after the first comma, `${csv##*,}` = after the **last** comma. `key=value` splitting uses the same idea: `${line%%=*}` and `${line#*=}`.

---

## Part 10: printf

| Format | Result | Meaning |
|--------|--------|---------|
| `%5s` | `[   ab]` | width 5, right-aligned |
| `%-5s` | `[ab   ]` | left-aligned |
| `%05d` | `[00042]` | zero-padded integer |
| `%.2f` | `[3.14]` | 2 decimals |
| `%8.2f` | `[    3.14]` | width 8 with 2 decimals |
| `%x` | `[ff]` | hexadecimal |

The table uses `%-10s %5d %8.2f` for each row, so columns line up whatever the values are.

Tricks shown:

- `printf -v padded '%03d' 7` stores `007` in a variable (no `$( )` needed)
- `printf '%.0s-' {1..30}` prints one dash for each of 30 arguments (`%.0s` prints **zero** characters of the argument, then `-` is literal text)
- `printf '%*s' 20 ''` prints 20 spaces; `tr ' ' '='` changes them into `=`
- `%q` quotes text so it's safe to reuse in a shell command
- `%(%Y-%m-%d)T -1` prints the date with the **built-in** formatter

---

## Part 11: escapes

`$'\t'` and `$'\n'` give real tab and newline characters. Inside plain quotes `"\t"` is just a backslash and a `t`.

---

## Part 12: recipes

```bash
slug="${title,,}"
slug="${slug//[^a-z0-9]/-}"
```

`[^a-z0-9]` means "any character that is **not** a letter or digit", and every such character becomes `-`. So `My Holiday Photos (2026)!` becomes `my-holiday-photos--2026--`. You'd usually squeeze repeated dashes afterwards (`tr -s -`).

URL host: strip `https://` with `${url#*://}`, then keep everything before the first `/` with `${rest%%/*}`.

---

## Part 13: tidy messy file names

```bash
for old in *; do
    new="${old,,}"
    new="${new// /_}"
    new="${new//[()]/}"
    mv -- "$old" "$new"
done
```

Lowercase → spaces to underscores → delete `(` and `)`. So `Budget 2026 (draft).XLSX` becomes `budget_2026_draft.xlsx`. Quotes everywhere, `--` before names, and it only runs inside the sandbox. Combine this with the loop skills from Lesson 13 for real clean-ups. Always **preview with `echo mv ...` first** on real folders.

---

## 🧪 Experiments

1. Print the extension of `archive.tar.gz` with `${f##*.}` and `${f#*.}`: what's the difference?
2. Make Part 13 also replace `-` with `_` and drop the apostrophes.
3. Print your `$PWD` folder name with `${PWD##*/}`.
4. Print `printf '%s\n' "${PATH//:/$'\n'}"`: PATH, one folder per line, no `tr`.
5. Pad numbers 1 to 12 to width 2 and print them on one line.
6. Extract `user` and `host` from `asha@example.com`.

---

## ✅ New words in this file

`${#s}` · `${s:i:n}` · `${s: -n}` · `#` `##` `%` `%%` · `${s/a/b}` `${s//a/b}` `${s//a}` · `${s^^}` `${s,,}` `${s^}` · `[[ s == *x* ]]` · `printf %5s %-5s %05d %.2f %x %q %*s %(...)T` · `printf -v` · `$'\t'` · `IFS=, read -ra` · `read -r x <<< "$s"`

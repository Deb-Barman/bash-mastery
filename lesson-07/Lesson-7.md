# Lesson 7 — Text Tools

**Level 2 · Power Tools · Time: ~70 minutes**

---

## 🎯 What you will learn

- Sort data (`sort`)
- Remove or count duplicates (`uniq`)
- Slice columns (`cut`)
- Translate, delete, squeeze characters (`tr`)
- Find-and-replace and edit streams (`sed`)
- Small programs that read columns (`awk`)
- Combine them into real **data-analysis pipelines**

> In Unix, **almost everything is text**: logs, CSVs, configs, command output. If you master text tools, you can analyze anything without opening a spreadsheet.

---

## 1. The idea: filters

All these commands are **filters**: they read text from a file or from a pipe, change it, and print the result. They don't change the original file unless you tell them to.

```
text in ──▶ [ filter ] ──▶ text out
```

You chain them with `|` (Lesson 5).

We'll use this sample file, `people.csv`:

```
name,city,age,score
Asha,Delhi,29,88
Ravi,Pune,34,72
Mina,Delhi,41,95
Karan,Goa,25,60
Sita,Pune,38,81
Tom,Delhi,31,77
```

---

## 2. `sort`

```bash
sort names.txt            # A to Z
sort -r names.txt         # reverse
sort -n numbers.txt       # NUMERIC order (1, 9, 10, 100)
sort -nr numbers.txt      # biggest first
sort -u names.txt         # sort and drop duplicates
sort -h sizes.txt         # human sizes (2K, 10M, 1G)
```

**Why `-n` matters:** plain `sort` is alphabetical, so `100` comes before `9`. Always use `-n` for numbers.

Sorting by a **column** (field):

```bash
sort -t, -k4 -n people.csv       # -t, = fields are separated by commas
                                 # -k4 = sort by field 4
sort -t, -k2,2 -k4,4nr people.csv  # by city, then by score (high first)
```

---

## 3. `uniq` (needs **sorted** input!)

`uniq` only collapses **neighbouring** duplicates, so sort first.

```bash
sort fruits.txt | uniq        # remove duplicates
sort fruits.txt | uniq -c     # count each (the famous one)
sort fruits.txt | uniq -d     # show only duplicated lines
sort fruits.txt | uniq -u     # show only lines that appear once
```

The classic "most common" recipe:

```bash
sort file | uniq -c | sort -rn | head
```

---

## 4. `cut`: extract columns

```bash
cut -d, -f1 people.csv         # -d, = delimiter is comma; -f1 = field 1
cut -d, -f1,3 people.csv       # fields 1 and 3
cut -d, -f2-4 people.csv       # fields 2 to 4
cut -c1-3 people.csv           # characters 1 to 3
cut -d: -f1 /etc/passwd        # usernames on a Linux system
```

`cut` is simple and fast, but it can't handle quoted CSV fields (like `"Smith, John"`). For tricky data, use `awk` or a real CSV tool.

---

## 5. `tr`: translate characters

`tr` works on **characters**, not words, and reads only from a pipe or `<`.

```bash
echo "hello" | tr a-z A-Z          # HELLO
echo "hello world" | tr -d 'aeiou' # hll wrld   (delete characters)
echo "a    b     c" | tr -s ' '    # a b c      (squeeze repeats)
echo "a,b,c" | tr ',' '\n'         # one item per line
echo "hello" | tr 'a-y' 'b-z'      # shift letters (simple cipher)
tr -d '\r' < windows.txt > unix.txt   # remove Windows line endings
```

---

## 6. `sed`: the stream editor

`sed` edits text as it flows by. Its best-known command: **substitute**.

```bash
sed 's/Delhi/Mumbai/' people.csv        # replace first match on each line
sed 's/a/A/g' people.csv                # g = every match on the line
sed 's/ *$//' file                      # trim trailing spaces
sed 's|/usr/bin|/opt/bin|' file         # any character can be the separator
```

Pick lines:

```bash
sed -n '2,3p' people.csv       # print only lines 2 to 3  (-n = silent, p = print)
sed -n '/Pune/p' people.csv    # print lines containing Pune
sed '1d' people.csv            # delete line 1 (remove header)
sed '/Goa/d' people.csv        # delete lines containing Goa
```

Edit the file **itself** (careful):

```bash
sed -i.bak 's/Delhi/Mumbai/' people.csv   # edits in place and keeps people.csv.bak
```

> `-i` without a backup suffix is risky and works differently on macOS. **Always use `-i.bak`** while learning.

---

## 7. `awk`: tiny programs for columns

`awk` reads each line, splits it into fields (`$1`, `$2`, ...), and runs your code.

```bash
awk '{print $1}' file                  # first word of each line
awk -F, '{print $1, $4}' people.csv    # -F, = separator is comma
awk -F, 'NR>1 {print $1}' people.csv   # NR = line number: skip the header
awk -F, '$4 > 80' people.csv           # print lines where score is above 80
awk -F, 'NR>1 && $4>80 {print $1}' people.csv   # names of high scorers
```

Variables you will use all the time:

| Name | Meaning |
|------|---------|
| `$0` | the whole line |
| `$1`, `$2`... | field 1, field 2... |
| `NF` | number of fields on this line |
| `NR` | current line number |
| `END { }` | code that runs after the last line |

**Totals and averages:**

```bash
awk -F, 'NR>1 {sum += $4} END {print sum}' people.csv
awk -F, 'NR>1 {sum += $4} END {print sum/(NR-1)}' people.csv
awk -F, 'NR>1 {printf "%-8s %3d\n", $1, $4}' people.csv   # formatted output
```

**Count per group** (a "pivot table" in one line):

```bash
awk -F, 'NR>1 {count[$2]++} END {for (c in count) print c, count[c]}' people.csv
```

(Order of `for (c in count)` is not guaranteed, so pipe to `sort` if you need order.)

---

## 8. Which tool when?

| Need | Use |
|------|-----|
| order lines | `sort` |
| remove / count duplicates | `sort \| uniq -c` |
| pick columns (simple) | `cut` |
| change / delete characters | `tr` |
| find and replace text | `sed 's/old/new/g'` |
| conditions, math, reformat columns | `awk` |

---

## 9. Putting it together

"Which city has the most people?"

```bash
tail -n +2 people.csv | cut -d, -f2 | sort | uniq -c | sort -rn | head -n 1
```

`tail -n +2` = start from line 2 (skips the header).

"Names of people over 30, alphabetically":

```bash
awk -F, 'NR>1 && $3>30 {print $1}' people.csv | sort
```

---

## ⚠️ Gotchas

1. `uniq` without `sort` misses duplicates that aren't next to each other.
2. `sort` without `-n` orders numbers as text.
3. `sed -i` edits the real file. Keep a backup (`-i.bak`).
4. `sed` and `tr` and `awk` expect **single quotes** around programs. Double quotes let Bash change `$1` before awk sees it.
5. Different systems: macOS uses BSD versions of `sed`, `sort`, `date`; some options differ. This lesson sticks to the portable ones.
6. For real CSV with quoted commas, use tools like `csvkit` or Python.

---

## ✅ Summary

- `sort -n` / `sort -u` / `sort -t, -k`
- `sort | uniq -c | sort -rn` = frequency table
- `cut -d, -f` slices columns
- `tr` swaps/deletes/squeezes characters
- `sed 's/old/new/g'`, `sed -n 'Np'`, `sed -i.bak`
- `awk -F, '{...}'` for fields, conditions, sums, per-group counts

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

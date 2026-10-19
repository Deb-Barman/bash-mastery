# Lesson 7 — Code Explained (line by line)

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson7-demo`, deleted at the end.

---

## The setup

```bash
cat > people.csv << 'EOF'
name,city,age,score
Asha,Delhi,29,88
...
EOF
```

A here-document (Lesson 5) creates the sample CSV. Two more files, `numbers.txt` and `fruits.txt`, are made with `printf`.

> **Header line:** The first line of `people.csv` is `name,city,age,score`, a header, not a person. Many commands below skip it with `tail -n +2` or `NR>1`.

---

## Part 1: sort

```bash
sort numbers.txt | tr '\n' ' '; echo
```

- `sort numbers.txt` prints one number per line
- `tr '\n' ' '` swaps new lines for spaces so the result fits on **one line** (just to keep the demo short)
- `; echo` prints the final new line

Results:

| Command | Output | Why |
|---------|--------|-----|
| `sort` | `1 10 100 9` | alphabetical: `"1"`, `"10"`, `"100"`, `"9"` |
| `sort -n` | `1 9 10 100` | true numeric order |
| `sort -nr` | `100 10 9 1` | numeric, reversed |

```bash
tail -n +2 people.csv | sort -t, -k4 -nr
```

- `tail -n +2` prints from **line 2 onward** (removes the header)
- `-t,` the field separator is a comma
- `-k4` sort by field 4 (score)
- `-nr` numeric, reverse

```bash
sort -t, -k2,2 -k4,4nr
```

Two sort keys: first by field 2 only (`-k2,2`, the city), and ties are broken by field 4 numerically, descending (`-k4,4nr`). The `,2` and `,4` mean "just this field", not "from here to the end of the line".

---

## Part 2: uniq

```bash
uniq fruits.txt                    # pear apple pear fig apple pear (unchanged!)
sort fruits.txt | uniq             # apple fig pear
sort fruits.txt | uniq -c          # counts
sort fruits.txt | uniq -d          # only duplicates
sort fruits.txt | uniq -u          # only singles
```

`uniq` alone returned all 6 words because **no two neighbours were equal**. Sorting puts equal lines together first. Always `sort | uniq`.

---

## Part 3: cut

```bash
cut -d, -f1 people.csv         # name Asha Ravi ...   (note: includes "name" header)
cut -d, -f1,4 people.csv       # name,score  Asha,88 ...
cut -d, -f2-4 people.csv       # fields 2 to 4
cut -c1-3 people.csv           # first 3 characters: nam Ash Rav ...
```

`-d,` is the delimiter and `-f` picks the fields. `-c` picks characters by position.

---

## Part 4: tr

```bash
echo "hello world" | tr a-z A-Z          # HELLO WORLD
echo "hello world" | tr -d 'aeiou'       # hll wrld
echo "a     b      c" | tr -s ' '        # a b c
echo "red,green,blue" | tr ',' '\n'      # one per line
echo "abc" | tr 'a-y' 'b-z'              # bcd
```

`tr` maps characters **one-to-one** by position: `a→b`, `b→c`, ... That is why `abc` becomes `bcd`. `-d` deletes the listed characters, `-s` squeezes runs into one.

---

## Part 5: sed

```bash
sed 's/Delhi/Mumbai/' people.csv
```

Format `s/OLD/NEW/`: substitute. Without `g`, only the **first** match **per line** changes.

```bash
echo "banana" | sed 's/a/A/g'      # bAnAnA
```

`g` = global (every match on the line).

```bash
sed -n '2,3p' people.csv           # lines 2 to 3
sed -n '/Pune/p' people.csv        # lines matching Pune
sed '1d' people.csv                # delete line 1
```

- `-n` turns off automatic printing
- `p` prints a line, `d` deletes it
- `2,3` and `/Pune/` are **addresses** (which lines to act on)

```bash
sed -i.bak 's/Goa/Panaji/' people.csv
grep -n "Panaji" people.csv
ls people.csv.bak
```

`-i.bak` edits the file **in place** and saves the original as `people.csv.bak`. After this edit, **Goa is Panaji in later parts of the demo**, so you see `Panaji` in the awk results. That's the edit working.

```bash
echo "/usr/bin/python" | sed 's|/usr/bin|/opt/bin|'
```

When the text contains `/`, use another separator (`|`) so you don't have to escape every slash.

---

## Part 6: awk

```bash
awk -F, 'NR>1 {print $1, $4}' people.csv
```

| Piece | Meaning |
|-------|---------|
| `-F,` | fields are separated by commas |
| `NR>1` | condition: only when line number is above 1 (skip header) |
| `{print $1, $4}` | action: print field 1 and field 4 |

Pattern: `condition { action }`.

```bash
awk -F, 'NR>1 && $4>80 {print $1}' people.csv       # names with score above 80
awk -F, 'NR>1 {sum += $4} END {print sum}' people.csv
```

- `sum += $4` adds each score (awk variables start at 0)
- `END { }` runs once after the last line: prints `473`

```bash
awk -F, 'NR>1 {sum += $4} END {printf "%.1f\n", sum/(NR-1)}' people.csv
```

`NR` at the end equals the total number of lines (7), so `NR-1` = 6 people. `%.1f` = one decimal, giving `78.8`.

```bash
awk -F, 'NR>1 {printf "%-8s %-8s %3d\n", $1, $2, $4}' people.csv
```

`printf` formats columns: `%-8s` = text, left-aligned, 8 wide; `%3d` = whole number, 3 wide.

```bash
awk -F, 'NR>1 {count[$2]++} END {for (c in count) print c, count[c]}' people.csv | sort
```

`count[$2]++` is an **associative array** (like a dictionary): the key is the city, the value is how many times we saw it. At the end we loop through all keys. Awk doesn't promise an order, so we pipe to `sort`.

```bash
awk -F, 'NR==1 {print NF}' people.csv     # 4
```

`NF` = number of fields on the line.

---

## Part 7: pipelines

```bash
tail -n +2 people.csv | cut -d, -f2 | sort | uniq -c | sort -rn | head -n 1
```

Step by step (try running each prefix yourself):

1. `tail -n +2 people.csv`: skip header
2. `| cut -d, -f2`: keep only the city column
3. `| sort`: group equal cities
4. `| uniq -c`: count each
5. `| sort -rn`: biggest first
6. `| head -n 1`: keep the winner → `3 Delhi`

**Build pipelines one stage at a time**, running after each `|` to check the output. That is how professionals do it.

---

## 🧪 Experiments

1. Remove `sort` before `uniq -c` and compare.
2. Change `$4>80` to `$4>=77` or `$3<30`.
3. Print the oldest person: `tail -n +2 people.csv | sort -t, -k3 -nr | head -n 1`.
4. Use awk to print a line like `Asha scored 88` for each person.
5. Use `sed` to add the text `City: ` before every city name in field 2 (hint: `sed 's/,\([A-Z]\)/,City: \1/'` once you know regex; or try it with awk).
6. Make a `words.txt` with 10 words and find the most frequent using the famous pipeline.

---

## ✅ New words in this file

`sort -n/-r/-u/-t/-k` · `uniq -c/-d/-u` · `cut -d -f -c` · `tr -d/-s` · `sed s///g` · `sed -n 'Np'` · `sed -i.bak` · `awk -F` · `NR` · `NF` · `END` · `printf` · `tail -n +2`

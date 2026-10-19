# Lesson 7 — Resources

## 📋 Cheat Sheet

| Tool | Common use | Example |
|------|-----------|---------|
| `sort` | order lines | `sort -n nums.txt` |
| `sort -r` / `-u` / `-h` | reverse / unique / human sizes | `sort -u f.txt` |
| `sort -t, -k4 -nr` | by column 4, numeric, high first | `sort -t, -k4 -nr f.csv` |
| `uniq -c` | count duplicates (sorted input!) | `sort f \| uniq -c` |
| `uniq -d` / `-u` | only duplicated / only unique | `sort f \| uniq -d` |
| `cut -d, -f1,3` | columns 1 and 3 | `cut -d, -f1,3 f.csv` |
| `cut -c1-5` | characters 1 to 5 | `cut -c1-5 f` |
| `tr a-z A-Z` | to upper case | `echo hi \| tr a-z A-Z` |
| `tr -d 'x'` | delete characters | `tr -d '\r' < in > out` |
| `tr -s ' '` | squeeze repeated spaces | `tr -s ' '` |
| `sed 's/a/b/g'` | replace all a with b | `sed 's/cat/dog/g' f` |
| `sed -n '2,5p'` | print lines 2 to 5 | `sed -n '2,5p' f` |
| `sed '1d'` | delete line 1 | `sed '1d' f` |
| `sed -i.bak ...` | edit file, keep backup | `sed -i.bak 's/a/b/' f` |
| `awk -F, '{print $2}'` | print column 2 | `awk -F, '{print $2}' f` |
| `awk 'NR>1'` | skip header | `awk 'NR>1' f` |
| `awk '$3>10'` | filter by column value | `awk -F, '$3>10' f` |
| `awk '{s+=$1} END{print s}'` | sum a column | |
| `tail -n +2` | everything from line 2 | `tail -n +2 f` |

**Pro recipes**

```bash
sort f | uniq -c | sort -rn | head          # most common lines
cut -d: -f1 /etc/passwd | sort              # all usernames (Linux)
tr ',' '\n' <<< "a,b,c"                     # split into lines
awk -F, 'NR>1 {s+=$4} END {print s/(NR-1)}' f.csv   # average
sed -n '10,20p' file                        # lines 10 to 20
```

---

## 🏋️ Exercises

Set up:

```bash
mkdir -p ~/bash-practice/ex7 && cd ~/bash-practice/ex7
cat > sales.csv << 'EOF'
item,region,qty,price
pen,east,10,5
book,west,3,120
pen,west,7,5
lamp,east,2,450
book,east,4,120
pen,east,12,5
EOF
printf 'b\na\nc\na\nb\na\n' > letters.txt
```

**Level A: Easy**
1. Sort `letters.txt` and remove duplicates.
2. Count how many times each letter appears.
3. Print only the `item` column of `sales.csv` (including the header).
4. Turn `hello world` into `HELLO WORLD` using `tr`.

**Level B: Medium**
5. Print `sales.csv` without its header.
6. Print only the items and regions (fields 1 and 2), without the header.
7. Replace every `east` with `EAST` in the **output** (don't change the file).
8. Print rows where `qty` is greater than 5 (header excluded).
9. Which item appears most often in the file? (items only, no header)

**Level C: Challenge**
10. Calculate the total number of units sold (sum of `qty`).
11. Calculate the total revenue: sum of `qty × price` for all rows.
12. Show revenue **per item**, biggest first. (awk array + sort)
13. Replace `west` with `WEST` **in the file itself**, keeping a backup.
14. Show the most expensive row only (by `price`).
15. (Think!) Why does `sort -n` give a different order from `sort` for the numbers `5 20 100`?
16. (Think!) Why is this wrong, and what's the fix?  
    `awk "{print $1}" file.txt`

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
sort -u letters.txt

# 2
sort letters.txt | uniq -c

# 3
cut -d, -f1 sales.csv

# 4
echo "hello world" | tr a-z A-Z

# 5
tail -n +2 sales.csv
# or: sed '1d' sales.csv   |   awk 'NR>1' sales.csv

# 6
tail -n +2 sales.csv | cut -d, -f1,2

# 7
sed 's/east/EAST/g' sales.csv

# 8
awk -F, 'NR>1 && $3>5' sales.csv

# 9
tail -n +2 sales.csv | cut -d, -f1 | sort | uniq -c | sort -rn | head -n 1

# 10
awk -F, 'NR>1 {s+=$3} END {print s}' sales.csv                  # 38

# 11
awk -F, 'NR>1 {s+=$3*$4} END {print s}' sales.csv               # 1885
# (10*5)+(3*120)+(7*5)+(2*450)+(4*120)+(12*5) = 50+360+35+900+480+60

# 12
awk -F, 'NR>1 {r[$1]+=$3*$4} END {for (i in r) print i, r[i]}' sales.csv | sort -k2 -nr
# lamp 900 / book 840 / pen 145

# 13
sed -i.bak 's/west/WEST/g' sales.csv

# 14
tail -n +2 sales.csv | sort -t, -k4 -nr | head -n 1             # lamp,east,2,450

# 15
# Plain sort compares character by character: "100" < "20" < "5".
# sort -n compares the numeric values: 5 < 20 < 100.

# 16
# Double quotes let BASH replace $1 (with its own first argument, usually
# empty) before awk ever runs. Use single quotes so awk sees $1:
awk '{print $1}' file.txt
```

</details>

---

## 🐞 Common beginner errors

| Problem | Cause | Fix |
|---------|-------|-----|
| `uniq` doesn't remove duplicates | input not sorted | `sort \| uniq` |
| `100` sorts before `9` | text sort | `sort -n` |
| header row in your results | forgot to skip it | `tail -n +2` or `awk 'NR>1'` |
| `awk` prints blank / wrong field | double quotes or wrong `-F` | single quotes; right separator |
| `sed -i` fails on macOS | BSD sed needs a suffix argument | `sed -i.bak ...` works on both |
| `cut` breaks on `"Smith, John"` | quoted commas | use `awk` with care, or `csvkit` / Python |
| file became empty after `sort f > f` | read and write same file | `sort -o f f` or a temp file |
| `tr` ignores a filename | `tr` reads only stdin | `tr ... < file` |

---

## 💡 Habits of pro coders

1. **Build pipelines one stage at a time**, checking each output.
2. **Use `sed -i.bak`**, never bare `-i` on important files.
3. **`awk` single quotes**, always.
4. **Skip headers explicitly** (`NR>1`) instead of hoping they don't matter.
5. **Sort before `uniq`**, `sort -n` for numbers.
6. For huge files, these tools stream line by line, so they're fast and use little memory.

## 📚 Extra resources

- **`man sort`**, **`man awk`**, **`man sed`**
- **grymoire.com/Unix/Awk.html** and **/Sed.html**: friendly, classic tutorials
- **"The AWK Programming Language"**: short classic book
- **regex101.com:** preview for Lesson 19 (regular expressions with `sed -E` and `grep -E`)
- **explainshell.com:** paste any of the pipelines above

## 🧠 Self-check

1. Why must you `sort` before `uniq`?
2. What is the difference between `cut` and `awk` for columns?
3. What does `sed 's/a/b/'` do without `g`?
4. How do you edit a file with `sed` and keep a backup?
5. What are `NR` and `NF` in awk?
6. Why use single quotes with awk?

## ➡️ Next: Lesson 8 — Permissions & Users (`ls -l`, `chmod`, `chown`, `sudo`, `umask`)

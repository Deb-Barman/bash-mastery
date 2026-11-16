# Lesson 19 — Regular Expressions

**Level 4 · Professional · Time: ~80 minutes**

---

## 🎯 What you will learn

- What a **regular expression** (regex) is and how it differs from a glob
- The building blocks: `.`, anchors, character classes, quantifiers, groups, alternation
- Use regex with `grep -E`, `sed -E`, `awk`, and Bash's own `[[ =~ ]]`
- Capture parts of a match (`\1`, `BASH_REMATCH`)
- Ready-made patterns: numbers, dates, IPs, emails
- The traps: greedy matching, quoting, BRE vs ERE

> A glob matches **file names**. A regex matches **patterns inside text**. Once you know it, you can find, check, extract and rewrite almost any text.

---

## 1. Regex vs glob (do not mix them up!)

| Meaning | Glob (file names, Lesson 6) | Regex (text, today) |
|---------|-----------------------------|---------------------|
| any text | `*` | `.*` |
| any one character | `?` | `.` |
| one of a set | `[abc]` | `[abc]` |
| starts with `a` | `a*` | `^a` |
| literal dot | `.` | `\.` |

Same symbols, **different meanings**. Where each is used:

- **glob:** shell commands (`ls *.txt`), `case`, `[[ $x == *.txt ]]`
- **regex:** `grep`, `sed`, `awk`, `[[ $x =~ regex ]]`

---

## 2. The building blocks

| Pattern | Matches | Example |
|---------|---------|---------|
| `abc` | the exact text | `cat` in "concatenate" |
| `.` | any one character | `c.t` → cat, cut, c7t |
| `\.` | a real dot | `3\.14` |
| `^` | start of the line | `^Error` |
| `$` | end of the line | `done$` |
| `[abc]` | one of a, b, c | `gr[ae]y` → gray, grey |
| `[a-z]` `[0-9]` | a range | `[A-Za-z]` |
| `[^0-9]` | **not** a digit | |
| `[[:digit:]]` | a digit (POSIX class) | also `[:alpha:]` `[:alnum:]` `[:space:]` `[:upper:]` `[:lower:]` `[:punct:]` |
| `*` | 0 or more of the previous | `ab*` → a, ab, abbb |
| `+` | 1 or more | `[0-9]+` |
| `?` | 0 or 1 | `colou?r` |
| `{3}` `{2,4}` `{2,}` | exact / range / at least | `[0-9]{3}` |
| `( )` | group (and capture) | `(ab)+` |
| `a\|b` | alternation: a **or** b (plain pipe in ERE) | `cat\|dog` |
| `\b` | word boundary (GNU) | `\bcat\b` |
| `\1` | what group 1 matched (back-reference) | `(.)\1` → double letters |

Inside `[ ]` most special characters become literal: `[.*+]` matches `.`, `*` or `+`. To include `]` put it first; `-` put it last: `[]a-]`.

---

## 3. Two dialects: BRE and ERE

- **BRE** (basic): the default for `grep` and `sed`. `+ ? | ( ) { }` must be written with a backslash: `a\+`, `\(ab\)`, `a\|b`
- **ERE** (extended): the sane one. Write `+ ? | ( ) { }` plainly

**Rule: use ERE.** `grep -E` · `sed -E` · `awk` (ERE already) · Bash `=~` (ERE).

(`egrep` = old name of `grep -E`.)

---

## 4. `grep` with regex

```bash
grep -E '^[0-9]+$' file          # lines that are only digits
grep -E 'cat|dog' file           # lines with cat OR dog
grep -E -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' file    # -o prints ONLY the matching part (IP-like)
grep -E -i 'error|fail' log      # case-insensitive
grep -E -v '^(#|$)' config       # drop comment lines and blank lines
grep -E -c 'ERROR' log           # count matching lines
grep -E -w 'cat' file            # whole word
grep -E -n 'TODO' *.sh           # with line numbers
grep -q -E 'x' file && echo "found"   # quiet: only the exit status
grep -P '\d+(?=px)' css          # PCRE (GNU only): \d, lookahead; NOT available on macOS grep
```

Tip: always put the regex in **single quotes** so the shell doesn't touch `$`, `\`, `*`.

---

## 5. `sed -E` with regex: search and replace

```bash
sed -E 's/[0-9]+/N/' file                 # first number on each line → N
sed -E 's/[0-9]+/N/g' file                # every number
sed -E 's/^[[:space:]]+//' file           # trim leading spaces
sed -E 's/(\w+)@(\w+)\.com/\2 at \1/' file   # use captured groups \1 \2
sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})/\3\/\2\/\1/' dates   # 2026-10-11 → 11/10/2026
sed -E '/^#/d; /^$/d' file                # delete comments and blank lines
sed -n -E '/start/,/end/p' file           # print the range between two patterns
```

`&` in the replacement means "the whole match": `sed -E 's/[0-9]+/<&>/g'`.

---

## 6. `awk` with regex

```bash
awk '/error/' log                          # lines matching
awk '$3 ~ /^[0-9]+$/ {print $1}' file      # field 3 matches the regex
awk '$2 !~ /^#/' file                      # field 2 does NOT match
awk -F, '$1 ~ /^A/ {n++} END {print n}' people.csv
```

---

## 7. Regex inside Bash: `[[ string =~ regex ]]`

```bash
if [[ $age =~ ^[0-9]+$ ]]; then echo "number"; fi
```

### Capture groups: `BASH_REMATCH`

```bash
date="2026-10-11"
if [[ $date =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "year  = ${BASH_REMATCH[1]}"
    echo "month = ${BASH_REMATCH[2]}"
    echo "day   = ${BASH_REMATCH[3]}"
    echo "whole = ${BASH_REMATCH[0]}"
fi
```

### 🔑 Quoting rule for `=~`

- **Do not quote** the regex (quotes make it a literal string).
- For complicated patterns, **store it in a variable first**, then use it unquoted:

```bash
re='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
if [[ $email =~ $re ]]; then echo "looks like an email"; fi
```

---

## 8. Greedy vs lazy

Quantifiers are **greedy**: they take as much as possible.

```bash
echo '<b>bold</b> and <i>it</i>' | sed -E 's/<.*>//'         # deletes almost everything
echo '<b>bold</b> and <i>it</i>' | sed -E 's/<[^>]*>//g'     # ✅ "anything except >" is the standard trick
```

ERE has no lazy `.*?`. Use "not the end character": `[^>]*`, `[^"]*`. (PCRE via `grep -P` has `.*?`.)

---

## 9. Pattern cookbook

| Task | ERE |
|------|-----|
| whole number | `^[0-9]+$` |
| signed integer | `^-?[0-9]+$` |
| decimal | `^-?[0-9]+(\.[0-9]+)?$` |
| date `YYYY-MM-DD` (shape only) | `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` |
| time `HH:MM` | `^([01][0-9]\|2[0-3]):[0-5][0-9]$` |
| IPv4 (shape only) | `^([0-9]{1,3}\.){3}[0-9]{1,3}$` |
| simple email | `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$` |
| hex colour | `^#[0-9A-Fa-f]{6}$` |
| Indian mobile (10 digits, starts 6-9) | `^[6-9][0-9]{9}$` |
| URL start | `^https?://` |
| blank line | `^[[:space:]]*$` |
| comment line | `^[[:space:]]*#` |
| log level | `\[(INFO\|WARN\|ERROR)\]` |

⚠️ These check **shape**, not truth. `999.999.999.999` passes the IPv4 shape. Validate the numbers afterwards if it matters. Emails are famously impossible to validate perfectly with regex; keep it simple.

---

## 10. Everyday recipes

```bash
# extract every IP address from a log
grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log | sort | uniq -c | sort -rn | head

# count error levels
grep -E -o '\[(INFO|WARN|ERROR)\]' app.log | sort | uniq -c

# mask all digits in a card-like number
echo "4111 2222 3333 4444" | sed -E 's/[0-9]/X/g'

# find lines with repeated words ("the the")
grep -E -n '\b([A-Za-z]+) \1\b' essay.txt

# strip comments and blank lines from a config
grep -E -v '^[[:space:]]*(#|$)' app.conf

# rename photo_2026-10-11.jpg → 2026_10_11.jpg
for f in photo_*.jpg; do
    [[ $f =~ ^photo_([0-9]{4})-([0-9]{2})-([0-9]{2})\.jpg$ ]] &&
        mv -- "$f" "${BASH_REMATCH[1]}_${BASH_REMATCH[2]}_${BASH_REMATCH[3]}.jpg"
done
```

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `grep '+'` / `grep 'a|b'` in BRE | `+` and `|` are literal | `grep -E` |
| `\d`, `\w`, `\s` in ERE | not supported by POSIX `grep -E` (GNU often accepts `\w \s` but not `\d`) | `[0-9]`, `[[:alnum:]_]`, `[[:space:]]` |
| forgetting anchors | `[0-9]+` matches inside `abc123def` | `^[0-9]+$` |
| `.` for a dot | matches any character | `\.` |
| quoting the regex in `=~` | literal match | unquoted or variable |
| regex in double quotes with `$` | shell expands it | single quotes |
| `grep -P` on macOS | not supported | `brew install grep` (ggrep) or ERE |
| `{n,m}` in old `mawk` | may not work | use `gawk`, or repeat the class |
| mixing glob and regex | wrong results | `*.txt` (glob) vs `.*\.txt$` (regex) |
| greedy `.*` eats too much | too long a match | `[^x]*` |

---

## ✅ Summary

- Regex = pattern language for **text**; glob = pattern language for **file names**
- Building blocks: `.` `^` `$` `[ ]` `[^ ]` `* + ? {n,m}` `( )` `|` `\.`
- Use **ERE**: `grep -E`, `sed -E`, `awk`, `[[ =~ ]]`
- Capture groups: `\1` (sed) and `${BASH_REMATCH[1]}` (Bash)
- Single-quote patterns; don't quote the regex in `=~`; anchor with `^ $`
- Patterns check **shape**; validate meaning separately

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

> 🏁 **Level 4 complete after this lesson.**

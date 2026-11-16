# Lesson 19 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson19-demo`, deleted at the end. The script builds three sample files: `app.log`, `config.conf` and `essay.txt`.

---

## Part 1: `grep -E` on a log

| Command | What it shows |
|---------|---------------|
| `grep -E 'ERROR\|WARN'` | alternation: lines with either word |
| `grep -E -c 'ERROR'` | count: 3 |
| `'^[0-9]{4}-...$'` style start + end anchors | lines starting with a date **and** ending in a digit |
| `grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}'` | `-o` prints **only the match**: the four IP addresses |
| `... \| sort \| uniq -c \| sort -rn` | frequency table: `192.168.1.20` appears twice |
| `grep -E -o '\[(INFO\|WARN\|ERROR)\]'` | log levels counted |

Pipe characters shown as `\|` here are only escaped for this markdown table; in the script they're plain `|`.

`([0-9]{1,3}\.){3}` means: **1 to 3 digits followed by a literal dot, repeated exactly 3 times**, then `[0-9]{1,3}` for the last number.

---

## Part 2: the tiny regex tester

```bash
check() {
    local re="$1" s
    shift
    for s in "$@"; do
        if [[ $s =~ $re ]]; then ... match ... else ... no match ...; fi
    done
}
check '^[0-9]+$' 123 12a "" -5
```

A function from Lesson 14 that tests one regex against many strings, using Bash's `=~`. The regex is passed in a **variable** and used **unquoted**, the rule from the lesson. Use it to experiment: it is a free regex lab.

Highlights:

| Regex | Lesson |
|-------|--------|
| `^[0-9]+$` | digits only; `-5` fails (no minus allowed), empty fails (`+` needs one) |
| `^-?[0-9]+(\.[0-9]+)?$` | optional minus, optional decimal part; `7.` fails (a dot needs digits after it) |
| `^colou?r$` | `u?` = optional `u` |
| `^[A-Z][a-z]{2,}$` | one capital + at least 2 lowercase letters |
| `^[6-9][0-9]{9}$` | 10 digits, first digit 6 to 9 |
| `^#[0-9A-Fa-f]{6}$` | a hex colour |

The anchor demo shows `[0-9]+` matching inside `abc123def`, while `^[0-9]+$` rejects it. **Anchors turn "contains" into "is exactly".**

---

## Part 3: validation patterns

- Dates: only the **shape** (`2026-1-1` fails because the month needs 2 digits)
- Times: `([01][0-9]|2[0-3]):[0-5][0-9]` accepts 09:30 and 23:59, rejects 24:00
- Email: simple but useful; stored in `re_email`, then used as `check "$re_email" ...`
- IPv4: `999.1.1.1` **passes**: regex checks shape, not value ranges. If it matters, split on dots and compare each number to 255

---

## Part 4: `BASH_REMATCH`

```bash
if [[ $date_text =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "year: ${BASH_REMATCH[1]}"
```

After a successful `=~`, the array `BASH_REMATCH` holds: index **0** = the whole match; **1, 2, 3...** = each `( )` group in order. That is how you take text apart without `sed` or `awk`.

The second example parses a log line:

```bash
[[ $line =~ \[([A-Z]+)\]\ (.*)\ from\ ([0-9.]+)$ ]]
```

Inline regexes escape special characters with backslashes (`\[`, `\]`, and `\ ` for a literal space). The groups capture the **level**, the **message**, and the **source IP**. A variable-based regex (`re='...'`) avoids this escaping hassle, and is usually cleaner.

---

## Part 5: `sed -E`

- `s/[0-9]/X/g` masks every digit: `4111 2222...` → `XXXX XXXX...`
- `s/^([0-9]{4})-([0-9]{2})-([0-9]{2})/\3\/\2\/\1/` reorders groups: `2026-10-10` → `10/10/2026`
- `<&>` : `&` is the **whole match**
- `s/^([^@]+)@(.+)$/\2 (\1)/` reorders an email: `[^@]+` = "one or more characters that aren't `@`"
- **Greedy vs careful:** `s/<.*>//` deletes from the **first** `<` to the **last** `>` (everything). `s/<[^>]*>//g` deletes each tag separately, so the text remains

---

## Part 6: cleaning a config

```bash
grep -E -v '^[[:space:]]*(#|$)' config.conf
```

`-v` inverts. The regex matches lines that are (optional spaces then `#`) **or** completely empty after optional spaces. Result: only the three real settings.

---

## Part 7: back-references

```bash
grep -E -n '\b([A-Za-z]+) \1\b' essay.txt
```

`([A-Za-z]+)` captures a word, ` \1` demands the **same word again**. Finds `the the` and `was was`. (`\b` = word boundary, a GNU extension.)

---

## Part 8: `awk`

- `$3 ~ /ERROR/` tests whether field 3 matches the regex
- `/\[INFO\]/ {i++}` runs the action for every matching line; the counters are printed in `END`

---

## Part 9: `grep -P`

PCRE adds `\d` and lookahead `(?= percent)`: "digits **followed by** ' percent' (without including it in the match)". `.*?` is a **lazy** quantifier. Both aren't available in ERE and `grep -P` itself is missing on macOS, so the script checks first.

---

## Part 10: rename with captures

The loop matches each file name against a regex, and `${BASH_REMATCH[n]}` rebuilds the new name: `photo_2026-10-11.jpg` → `2026_10_11.jpg`. `notes.txt` doesn't match so it is untouched. Quote the names in `mv`.

---

## 🧪 Experiments

1. Use `check` on your own regexes. Try `'^(\+91)?[6-9][0-9]{9}$'` for phone numbers.
2. Add a `grep -E -o` that extracts all email addresses from a text file.
3. Write a regex for passwords: 8+ characters with at least one digit (hint: two `grep -E` tests, or `[[ =~ ]]` twice).
4. Change `s/<[^>]*>//g` to remove only `<b>` tags.
5. Use `sed -E 's/\b(\w)/\u\1/g'` (GNU) to capitalise every word.
6. Make Part 10 handle `IMG_20261011.jpg` → `2026-10-11.jpg`.

---

## ✅ New words in this file

`grep -E -o -c -v -w -P` · `sed -E` · `&` · `\1` · `awk ~ !~` · `[[ =~ ]]` · `BASH_REMATCH` · `( )` groups · `{n,m}` · `[^…]` · `[[:class:]]` · `\b` · `(?=…)` · lazy `.*?`

# Lesson 19 — Resources

## 📋 Cheat Sheet

| Pattern | Meaning |
|---------|---------|
| `.` | any character |
| `\.` | a literal dot |
| `^` `$` | start / end of line |
| `[abc]` `[a-z]` `[^0-9]` | set / range / negated set |
| `[[:digit:]]` `[[:alpha:]]` `[[:alnum:]]` `[[:space:]]` `[[:upper:]]` `[[:lower:]]` | classes |
| `*` `+` `?` | 0+ / 1+ / 0 or 1 |
| `{n}` `{n,}` `{n,m}` | exactly / at least / between |
| `( )` | group (captures) |
| `a\|b` (plain `\|` in ERE) | a or b |
| `\1` | back-reference |
| `\b` | word boundary (GNU) |

**Tools**

| Tool | Example |
|------|---------|
| `grep -E` | `grep -E '^[0-9]+$' f` |
| `grep -E -o` | print only the match |
| `grep -E -v` | invert |
| `grep -E -c` | count matching lines |
| `grep -P` | PCRE (`\d`, lookahead, lazy) · GNU only |
| `sed -E 's/(a)(b)/\2\1/g'` | replace with groups; `&` = whole match |
| `awk '$2 ~ /re/'` | field matches |
| `[[ $s =~ re ]]` | Bash; groups in `${BASH_REMATCH[n]}` |

**Rules:** use ERE (`-E`) · single-quote patterns · don't quote the regex in `=~` (use a variable) · anchor with `^ $` · greedy `.*` → use `[^x]*`

**Cookbook**

```
integer      ^-?[0-9]+$
decimal      ^-?[0-9]+(\.[0-9]+)?$
date         ^[0-9]{4}-[0-9]{2}-[0-9]{2}$
time         ^([01][0-9]|2[0-3]):[0-5][0-9]$
IPv4 shape   ^([0-9]{1,3}\.){3}[0-9]{1,3}$
email        ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$
hex colour   ^#[0-9A-Fa-f]{6}$
blank line   ^[[:space:]]*$
comment      ^[[:space:]]*#
```

---

## 🏋️ Exercises

Set up:

```bash
mkdir -p ~/bash-practice/ex19 && cd ~/bash-practice/ex19
cat > data.txt << 'EOF'
apple 12
banana 7
cherry 105
grape
42
id: A-1001
id: B-2002
contact: asha@example.com, ravi@mail.org
visit https://example.com/page and http://test.org
2026-10-11 meeting at 14:30
EOF
```

**Level A: Easy**
1. Show lines that start with a digit.
2. Show lines that end with a number.
3. Show lines containing `apple` or `grape`.
4. Show lines that are **only** digits.

**Level B: Medium**
5. Print only the numbers (digits) that appear in `data.txt`, one per match.
6. Print the ID codes (`A-1001`, `B-2002`) only.
7. Print all email addresses, one per line.
8. Print all URLs (`http` or `https`).
9. Replace every `https?://` in the output with nothing (don't change the file).
10. Check in Bash whether the variable `v` holds a time like `14:30`.

**Level C: Challenge**
11. Reformat `2026-10-11` into `11-10-2026` with `sed -E`.
12. Using `[[ =~ ]]` and `BASH_REMATCH`, split `14:30` into `hour=14`, `minute=30`.
13. Validate a password: at least 8 characters, at least one digit, at least one capital letter. Write `valid_password STRING`.
14. Extract the **domain** from each email in the file (`example.com`, `mail.org`).
15. Remove all HTML tags from `<p>Hello <b>big</b> world</p>`.
16. Find doubled letters in words (`aa`, `ll`) in a text with a back-reference.
17. (Think!) Why does `grep '[0-9]+'` find almost nothing, but `grep -E '[0-9]+'` works?
18. (Think!) Why is `[[ $x =~ "^[0-9]+$" ]]` a bug?
19. (Think!) A regex says `^([0-9]{1,3}\.){3}[0-9]{1,3}$` accepts `999.999.999.999`. How would you fully validate an IP?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
grep -E '^[0-9]' data.txt

# 2
grep -E '[0-9]$' data.txt

# 3
grep -E 'apple|grape' data.txt

# 4
grep -E '^[0-9]+$' data.txt

# 5
grep -E -o '[0-9]+' data.txt

# 6
grep -E -o '[A-Z]-[0-9]+' data.txt

# 7
grep -E -o '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' data.txt

# 8
grep -E -o 'https?://[^ ]+' data.txt

# 9
grep -E -o 'https?://[^ ]+' data.txt | sed -E 's#^https?://##'

# 10
v="14:30"
[[ $v =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] && echo "time" || echo "not a time"

# 11
echo "2026-10-11" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})$/\3-\2-\1/'

# 12
t="14:30"
if [[ $t =~ ^([0-9]{2}):([0-9]{2})$ ]]; then
    hour=${BASH_REMATCH[1]} minute=${BASH_REMATCH[2]}
    echo "hour=$hour minute=$minute"
fi

# 13
valid_password() {
    local p="$1"
    (( ${#p} >= 8 )) && [[ $p =~ [0-9] ]] && [[ $p =~ [A-Z] ]]
}
valid_password "Secret123" && echo ok
valid_password "short1A"   || echo "too short"

# 14
grep -E -o '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' data.txt | sed -E 's/.*@//'

# 15
echo '<p>Hello <b>big</b> world</p>' | sed -E 's/<[^>]*>//g'

# 16
echo "a little balloon" | grep -E -o '([a-z])\1'          # tt ll oo

# 17
# Basic regex (BRE) treats + as a literal plus sign, so '[0-9]+' looks for a
# digit followed by a "+" character. With -E (ERE), + means "one or more".

# 18
# Quoting the right-hand side makes Bash treat it as a literal string, not a
# regex. Use  [[ $x =~ ^[0-9]+$ ]]   or   re='^[0-9]+$'; [[ $x =~ $re ]]

# 19
# Regex checks the shape. Split on dots and test the numbers:
ip="999.1.1.1"
IFS=. read -r a b c d <<< "$ip"
for n in "$a" "$b" "$c" "$d"; do
    (( 10#$n <= 255 )) || { echo "invalid: $n > 255"; break; }
done
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `grep 'a+'` finds nothing | BRE: `+` literal | `grep -E 'a+'` |
| `\d` matches nothing | not in ERE | `[0-9]` (or `grep -P`) |
| matches too much | no anchors | `^…$` |
| `.` matches `x` when you meant a dot | unescaped | `\.` |
| `[[ $x =~ "re" ]]` always false | quoted regex | unquote / variable |
| `sed` greedy deletion | `.*` | `[^>]*` |
| `grep -P: invalid option` | macOS `grep` | `brew install grep` or use ERE |
| shell expands `*` in the pattern | pattern not quoted | single quotes |
| `-o` prints nothing | pattern needs a match, `-E` forgotten | add `-E` |
| `\b` not working | BSD tools | use `[[:space:]]` or GNU tools |

---

## 💡 Habits of pro coders

1. **Use ERE** and **single quotes**.
2. **Anchor** validation patterns.
3. **Build regexes step by step** and test them on examples (and non-examples).
4. **Store complex regexes in variables** with a comment saying what they match.
5. **Regex checks shape, code checks meaning.**
6. **Prefer `[^x]*` to `.*`** when you can.
7. **Use regex101.com** (choose the "POSIX ERE" or "PCRE" flavour) to visualize.

## 📚 Extra resources

- **regex101.com:** interactive tester with explanations
- **regexr.com** and **regexlearn.com**: learn by playing
- **`man 7 regex`**, **`man grep`**
- **rexegg.com:** deep reference
- **grymoire.com/Unix/Sed.html:** sed with regex

## 🧠 Self-check

1. What's the difference between a glob and a regex? Give two symbols that differ.
2. What do `^`, `$`, `[^0-9]`, `{2,4}` and `( )` mean?
3. Why use `grep -E` instead of plain `grep`?
4. How do you read a captured group in `sed` and in Bash?
5. Why shouldn't you quote the regex in `[[ $x =~ … ]]`?
6. What does "greedy" mean and how do you avoid it?

## ➡️ Next: Lesson 20 — Processes & Jobs (`&`, `wait`, `jobs`, `kill`, `nohup`, parallel work)

> 🏁 **Level 4 complete!** You write Bash like a professional: arrays, strings, error handling, argument parsing and regex.

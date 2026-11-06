# Lesson 16 — Resources

## 📋 Cheat Sheet

| Goal | Syntax | Example (`s="Hello, World"`) |
|------|--------|------------------------------|
| Length | `${#s}` | `12` |
| Substring | `${s:i:n}` | `${s:0:5}` → `Hello` |
| From index | `${s:7}` | `World` |
| Last n | `${s: -5}` | `World` |
| Remove front (short) | `${s#pat}` | `${s#*, }` → `World` |
| Remove front (long) | `${s##pat}` | |
| Remove end (short) | `${s%pat}` | `${s%, *}` → `Hello` |
| Remove end (long) | `${s%%pat}` | |
| Replace first | `${s/a/b}` | |
| Replace all | `${s//a/b}` | `${s//l/L}` → `HeLLo, WorLd` |
| Delete matches | `${s//a}` | |
| Replace at start / end | `${s/#a/b}` / `${s/%a/b}` | |
| UPPER / lower | `${s^^}` / `${s,,}` | |
| Capitalize first | `${s^}` | |

**File names**

| Want | Use |
|------|-----|
| file name | `${path##*/}` |
| folder | `${path%/*}` |
| extension | `${f##*.}` |
| name without extension | `${f%.*}` |
| change extension | `${f%.txt}.md` |
| before first dot | `${f%%.*}` |

**Tests (`[[ ]]`)**: `*x*` contains · `x*` starts · `*x` ends

**Split/join:** `IFS=, read -ra a <<< "$s"` · `( IFS=,; echo "${a[*]}" )`

**printf:** `%s %d %f %x %q` · `%5s %-5s %05d %.2f %8.2f` · `printf -v var` · `printf '%(%F)T\n' -1` · `printf '%.0s-' {1..20}`

**Escapes:** `$'\t'` tab · `$'\n'` newline

---

## 🏋️ Exercises

**Level A: Easy**
1. For `word="programming"`, print its length and its first 3 letters.
2. Print `word` in upper case.
3. For `file="holiday.jpg"`, print the extension and the name without the extension.
4. Replace every `m` in `word` with `M`.

**Level B: Medium**
5. For `path="/var/log/nginx/access.log"`, print the file name and the folder using only `${...}`.
6. Print `path` with `/var/log` replaced by `/tmp`.
7. For `email="asha@example.com"`, print the user part and the domain part.
8. Convert `"hello world from bash"` to `"hello_world_from_bash"`.
9. Check whether `url="https://example.com"` starts with `https://` (print yes/no).
10. Print the number `7` as `007` and `3.14159` as `3.14`, using `printf`.

**Level C: Challenge**
11. Rename every `*.JPEG` file in a folder to lowercase `.jpg`, e.g. `Photo One.JPEG` → `photo one.jpg` (spaces may stay). Create test files first.
12. Turn `"Hello, World! 2026"` into a slug: lowercase, only `a-z0-9` and single dashes, no dashes at the ends.
13. Print a 3-row table of name / qty / price, columns aligned, with the price to 2 decimals.
14. Parse `"user=asha;role=admin;id=7"` into an associative array and print `role`.
15. Print the string `Bash` reversed without using `rev` (loop over characters).
16. (Think!) Why does `${s:-3}` not give the last 3 characters? What does it do?
17. (Think!) What's the difference between `${f%.*}` and `${f%%.*}` for `a.tar.gz`?
18. (Think!) Why is `printf '%s\n' "$var"` safer than `echo $var`?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
word="programming"
echo "${#word}"; echo "${word:0:3}"           # 11 / pro

# 2
echo "${word^^}"                              # PROGRAMMING

# 3
file="holiday.jpg"
echo "${file##*.}"; echo "${file%.*}"         # jpg / holiday

# 4
echo "${word//m/M}"                           # prograMMing

# 5
path="/var/log/nginx/access.log"
echo "${path##*/}"; echo "${path%/*}"         # access.log / /var/log/nginx

# 6
echo "${path/\/var\/log/\/tmp}"               # /tmp/nginx/access.log
# or with another delimiter trick: echo "/tmp${path#/var/log}"

# 7
email="asha@example.com"
echo "${email%@*}"; echo "${email#*@}"        # asha / example.com

# 8
s="hello world from bash"; echo "${s// /_}"

# 9
url="https://example.com"
[[ $url == https://* ]] && echo yes || echo no

# 10
printf '%03d\n' 7; printf '%.2f\n' 3.14159    # 007 / 3.14

# 11
shopt -s nullglob
for f in *.JPEG; do mv -- "$f" "${f%.JPEG}.jpg"; done
# (to lowercase the whole name: new="${f,,}"; mv -- "$f" "${new%.jpeg}.jpg")

# 12
t="Hello, World! 2026"
slug="${t,,}"
slug="${slug//[^a-z0-9]/-}"
slug=$(tr -s '-' <<< "$slug")      # squeeze repeated dashes
slug="${slug#-}"; slug="${slug%-}" # trim dashes at the ends
echo "$slug"                       # hello-world-2026

# 13
printf '%-10s %5s %8s\n' NAME QTY PRICE
printf '%-10s %5d %8.2f\n' apple 12 3.5 pear 6 1.25 plum 100 12
# (printf reuses the format for each group of 3 arguments)

# 14
declare -A kv
IFS=';' read -r -a pairs <<< "user=asha;role=admin;id=7"
for p in "${pairs[@]}"; do kv[${p%%=*}]=${p#*=}; done
echo "${kv[role]}"                       # admin

# 15
w="Bash"; r=""
for (( i = ${#w} - 1; i >= 0; i-- )); do r+="${w:i:1}"; done
echo "$r"                                # hsaB

# 16
# ${s:-3} is the "use default" feature: value of s, or the text "3" if s is
# unset/empty. For the last 3 characters write ${s: -3} (with a space).

# 17
# a.tar.gz:  ${f%.*}  → a.tar   (shortest match: removes just ".gz")
#            ${f%%.*} → a       (longest match: removes ".tar.gz")

# 18
# echo can swallow -n / -e and interpret backslashes, and an unquoted $var is
# split and globbed. printf '%s\n' "$var" prints the text exactly as stored.
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `bad substitution` | Bash 3.2 (`^^`/`,,`), or a typo like `${s,}` on old Bash | install Bash 4+, or use `tr` |
| `${s:-3}` returns the default | missing space | `${s: -3}` |
| `${f%.*}` strips too little/much | `%` vs `%%` | shortest vs longest; test with `echo` |
| `#` removes from the wrong end | mixed up | `#` = front, `%` = end |
| regex doesn't work in `${s/…/…}` | these are globs | `sed -E` or `[[ =~ ]]` |
| `${s//\//-}` confusing | slash as pattern | escape it, or use `${s//[\/]/-}` |
| `printf` prints `0` for text | `%d` with non-number | validate input; use `%s` |
| `printf '%d' 08` error | octal | `$((10#08))` |
| output has literal `\n` | used `echo` without `-e` | `printf '...\n'` |
| `${var%.*}` on a dotless name leaves it unchanged | no match | check `[[ $f == *.* ]]` |

---

## 💡 Habits of pro coders

1. **Use built-in expansion in loops**; save `sed`/`awk`/`basename` for complex cases.
2. **`printf` over `echo`** for variables.
3. **Always quote** the expansion: `"${var//a/b}"`.
4. **Test with `echo "${…}"` on sample values** before touching real files.
5. **Normalise case** (`${x,,}`) before comparing user input.
6. **Don't parse paths by hand** when `basename`/`dirname`/`realpath` are clearer for one-offs.

## 📚 Extra resources

- **`man bash`** → "Parameter Expansion" (the definitive list)
- **mywiki.wooledge.org/BashGuide/Parameters** and **/BashFAQ/100** (string manipulation)
- **wiki.bash-hackers.org/syntax/pe**: parameter expansion with diagrams
- **`help printf`**, **`man 3 printf`** for all format codes
- **explainshell.com:** limited for `${…}`, so use `echo` experiments

## 🧠 Self-check

1. How do you get a file's extension and its name without extension?
2. What's the difference between `#` and `##`? `%` and `%%`?
3. How do you replace all spaces with underscores?
4. How do you test whether a string contains / starts with / ends with something?
5. Why is the space in `${s: -3}` required?
6. What does `%05d` do?

## ➡️ Next: Lesson 17 — Error Handling (`set -euo pipefail`, `trap`, cleanup, logging, retries)

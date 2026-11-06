# Lesson 16 — String Manipulation

**Level 4 · Professional · Time: ~75 minutes**

---

## 🎯 What you will learn

- Cut, trim, and replace text **inside Bash**, with no external programs
- The `${var...}` family: length, substring, `#` `##` `%` `%%`, `/` `//`, case change
- File name tricks: extension, name, folder, `basename` and `dirname` without forking
- Split and join strings
- Format text with `printf` (padding, zeros, decimals, tables)
- Test for "contains / starts with / ends with"

> Calling `sed`, `cut` or `basename` starts a new process every time. In a loop over 10,000 files, built-in string operations are **hundreds of times faster** and need no pipes.

---

## 1. The big picture: parameter expansion

Everything today is written as `${variable<operator>...}`. Learn the pattern, not 20 separate tricks:

| Operator | Meaning | Mnemonic |
|----------|---------|----------|
| `${#v}` | length | `#` = "count" |
| `${v:start:len}` | substring | `:` = "from..." |
| `${v#pat}` / `${v##pat}` | remove from the **front** | `#` is on the left of `$` on a US keyboard |
| `${v%pat}` / `${v%%pat}` | remove from the **end** | `%` is on the right |
| `${v/pat/rep}` / `${v//pat/rep}` | replace first / all | like `sed s///` |
| `${v^^}` / `${v,,}` | UPPER / lower | `^` up, `,` down |

Patterns here are **globs** (`*`, `?`, `[a-z]`), not regex (Lesson 19).

We'll use these in the examples:

```bash
s="Hello, World"
path="/home/asha/docs/report.final.txt"
```

---

## 2. Length and substrings

```bash
echo "${#s}"            # 12
echo "${s:0:5}"         # Hello       (start at 0, take 5)
echo "${s:7}"           # World       (from index 7 to the end)
echo "${s: -5}"         # World       (last 5 chars; the SPACE before - is required!)
echo "${s:(-5):3}"      # Wor         (parentheses work too)
```

Without the space, `${s:-5}` means "default value 5". That's a different feature (Lesson 10).

---

## 3. Remove a prefix: `#` and `##`

`#` = remove the **shortest** match from the **front**; `##` = the **longest**.

```bash
echo "${path#/home/}"      # asha/docs/report.final.txt
echo "${path#*/}"          # home/asha/docs/report.final.txt   (shortest: just the first /)
echo "${path##*/}"         # report.final.txt                  (longest: everything up to the LAST /)
```

`${path##*/}` is **basename**: the file name with no folders.

---

## 4. Remove a suffix: `%` and `%%`

`%` = remove the **shortest** match from the **end**; `%%` = the **longest**.

```bash
echo "${path%.txt}"        # /home/asha/docs/report.final
echo "${path%.*}"          # /home/asha/docs/report.final      (shortest ".*": just the last extension)
echo "${path%%.*}"         # /home/asha/docs/report            (longest: from the FIRST dot onward)
echo "${path%/*}"          # /home/asha/docs                   (that's dirname!)
```

### The file name cookbook

```bash
f="photo.final.jpeg"
echo "${f##*.}"                  # jpeg          extension
echo "${f%.*}"                   # photo.final   name without extension
echo "${f%.jpeg}.jpg"            # photo.final.jpg   change extension
echo "${f%%.*}"                  # photo         name up to the first dot
file="${path##*/}"               # basename
dir="${path%/*}"                 # dirname
```

---

## 5. Replace: `/` and `//`

```bash
x="one two two three"
echo "${x/two/2}"          # one 2 two three   (first match only)
echo "${x//two/2}"         # one 2 2 three     (ALL matches)
echo "${x// /_}"           # one_two_two_three (spaces → underscores)
echo "${x//two}"           # one  three        (no replacement = delete)
echo "${x/#one/1}"         # 1 two two three   (# = must match at the START)
echo "${x/%three/3}"       # one two two 3     (% = must match at the END)
```

---

## 6. Change case

```bash
name="asha RAO"
echo "${name^^}"           # ASHA RAO     (all upper)
echo "${name,,}"           # asha rao     (all lower)
echo "${name^}"            # Asha RAO     (first letter upper)
echo "${name,}"            # asha RAO     (first letter lower)
```

Useful for case-insensitive comparisons: `[[ ${answer,,} == y* ]]`.

---

## 7. Contains / starts with / ends with

Use `[[ ]]` with unquoted glob patterns (Lesson 12):

```bash
[[ $s == *World* ]]    && echo "contains World"
[[ $s == Hello* ]]     && echo "starts with Hello"
[[ $s == *World ]]     && echo "ends with World"
[[ $s != *xyz* ]]      && echo "does not contain xyz"
```

For case-insensitive matching: `[[ ${s,,} == *world* ]]`.

---

## 8. Trimming whitespace

```bash
text="   padded text   "

# 1) the extglob way
shopt -s extglob
trimmed="${text##+([[:space:]])}"       # trim the front
trimmed="${trimmed%%+([[:space:]])}"    # trim the end

# 2) the read trick
read -r trimmed <<< "$text"              # trims both ends (single line only)

# 3) with an external tool
trimmed=$(echo "$text" | xargs)         # also squeezes inner spaces in some cases
trimmed=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$text")
```

(Enable `extglob` **before** the lines that use `+( )` are read; see the Lesson 6 gotcha.)

---

## 9. Split and join

```bash
csv="red,green,blue"

IFS=, read -r -a parts <<< "$csv"         # split → array (red green blue)
echo "${parts[1]}"                         # green

( IFS=-; echo "${parts[*]}" )              # join → red-green-blue

echo "$csv" | tr ',' '\n'                   # one per line
first="${csv%%,*}"                          # red     (before the first comma)
rest="${csv#*,}"                            # green,blue (after the first comma)
last="${csv##*,}"                           # blue    (after the last comma)
```

Key = value pairs:

```bash
line="name=Asha"
key="${line%%=*}"       # name
value="${line#*=}"      # Asha
```

---

## 10. `printf`: precise formatting

`printf FORMAT args...`, where the format has **placeholders** (`%s` text, `%d` integer, `%f` decimal).

```bash
printf '%s\n' "plain text"            # always add \n yourself
printf '%5s|\n'  "ab"                  #    ab|     width 5, right-aligned
printf '%-5s|\n' "ab"                  # ab   |     left-aligned
printf '%05d\n' 42                     # 00042      zero-padded number
printf '%.2f\n' 3.14159                # 3.14       two decimals
printf '%x\n' 255                      # ff         hexadecimal
printf '%8.2f|\n' 3.14159              #     3.14|
printf '%s is %d years old\n' "Asha" 29
printf '%-10s %5d\n' "apples" 12       # a neat table row
```

### Handy tricks

```bash
printf -v padded '%03d' 7             # store the result in a variable: padded=007
printf '%s\n' "${arr[@]}"             # one array element per line
printf '%*s\n' 20 ""                  # 20 spaces
printf '%.0s-' {1..20}; echo          # a line of 20 dashes
printf '%q\n' "has spaces & stuff"    # shell-safe quoting: has\ spaces\ \&\ stuff
printf '%(%Y-%m-%d)T\n' -1            # today's date, no 'date' process needed (-1 = now)
```

**Prefer `printf` over `echo`** for anything with variables: `echo` mishandles text like `-n` or backslashes.

---

## 11. Special characters and escapes

```bash
tab=$'\t'                             # $'...' understands \t \n \r \\ \'
echo "a${tab}b"
nl=$'\n'
echo "line1${nl}line2"
echo -e "a\tb"                        # works, but not portable; prefer printf
printf 'a\tb\n'
```

---

## 12. Recipes

### Make a safe file name ("slug")

```bash
title="My Holiday Photos (2026)!"
slug="${title,,}"                     # lower
slug="${slug//[^a-z0-9]/-}"           # anything not a-z or 0-9 → dash
echo "$slug"                          # my-holiday-photos--2026--
```

### Pull a domain out of a URL

```bash
url="https://www.example.com/path/page.html?x=1"
rest="${url#*://}"        # www.example.com/path/page.html?x=1
host="${rest%%/*}"        # www.example.com
echo "$host"
```

### Zero-pad a counter

```bash
for i in {1..3}; do printf 'file%03d.txt\n' "$i"; done    # file001.txt file002.txt file003.txt
```

### Repeat a character

```bash
line=$(printf '%*s' 30 '' | tr ' ' '=')
echo "$line"                          # ==============================
```

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `${s:-3}` for "last 3 chars" | default-value feature! | `${s: -3}` (space) |
| using regex in `${s/pat/rep}` | patterns are **globs** | `sed -E` or `[[ =~ ]]` (Lesson 19) |
| forgetting quotes: `${s/ /_}` unquoted in commands | word splitting | `"${s// /_}"` |
| `echo $var` with `-n` or `\` in the data | wrong output | `printf '%s\n' "$var"` |
| `%` vs `#` mixed up | wrong end trimmed | `#` = **front**, `%` = **end** |
| `${f%.*}` on `.bashrc` or on a name without a dot | unexpected | check with `[[ $f == *.* ]]` |
| `printf '%d' 08` | invalid octal | `printf '%d' $((10#08))` |
| `printf '%s'` with several args and one `%s` | repeats the format | that's a feature: `printf '%s\n' a b c` prints 3 lines |
| `${s^^}` on Bash 3.2 (macOS) | "bad substitution" | install Bash 4+, or `tr '[:lower:]' '[:upper:]'` |
| uppercase of non-English letters | may not convert | depends on your locale |

---

## ✅ Summary

- `${#s}` length · `${s:i:n}` substring · `${s: -n}` last n
- `#`/`##` strip from the **front**; `%`/`%%` strip from the **end** (short / long)
- `${s/a/b}` first · `${s//a/b}` all · `${s//a}` delete
- `${s^^}` `${s,,}` `${s^}` change case
- `${path##*/}` basename · `${path%/*}` dirname · `${f##*.}` extension · `${f%.*}` no extension
- `[[ $s == *x* ]]` contains · `IFS=, read -ra` split · `printf` for formatting

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

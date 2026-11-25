# Lesson 25 — Expansions & Parameter Expansion Deep Dive

**Level 7 · Shell Internals · Time: ~75 minutes**

---

## 🎯 What you will learn

- The **order** in which Bash rewrites your command line (this explains 80% of "weird" bugs)
- Brace expansion and tilde expansion
- Every useful form of `${...}`: defaults, errors, indirection, case change, slicing, quoting
- Word splitting, `IFS`, and why quotes matter
- Globbing options: `nullglob`, `dotglob`, `extglob`, `globstar`
- `printf -v` and `${!name}` instead of dangerous `eval`

> Before Bash runs a command, it **rewrites the line** in a fixed order. If you know the order, you can predict any result.

---

## 1. The expansion order

Bash does these steps **in this order**, every time, before running the command:

| # | Step | Example |
|---|------|---------|
| 1 | **Brace** expansion | `{a,b}` → `a b` |
| 2 | **Tilde** expansion | `~` → `/home/you` |
| 3 | **Parameter** (variable) expansion | `$x`, `${x:-d}` |
| 4 | **Command substitution** | `$(date)` |
| 5 | **Arithmetic** expansion | `$((1+2))` |
| 6 | **Word splitting** (only on unquoted results) | `a b` → two words |
| 7 | **Pathname** expansion (globbing) | `*.txt` → file names |
| 8 | **Quote removal** | `"a"` → `a` |

(Steps 3, 4, 5 happen together, left to right.)

### The famous consequence

```bash
x=3
echo {1..$x}      # prints {1..3}   ← braces were expanded BEFORE $x existed
```

Brace expansion happens first, so it only sees the text `{1..$x}`, which is not a valid range. Fixes:

```bash
seq 1 "$x"                 # best
for ((i=1; i<=x; i++)); do echo "$i"; done
eval echo "{1..$x}"        # works, but avoid eval (see section 10)
```

> 🐍 **Python bridge:** Python evaluates an expression *once*, then calls the function. Bash **rewrites text first**, and only then runs the command. That is why quoting matters so much in Bash and almost never in Python.

---

## 2. Brace expansion: generate text

```bash
echo {a,b,c}            # a b c
echo {1..5}             # 1 2 3 4 5
echo {01..05}           # 01 02 03 04 05   (zero padded)
echo {1..10..3}         # 1 4 7 10          (step 3)
echo {e..a}             # e d c b a
echo {a,b}{1,2}         # a1 a2 b1 b2       (all combinations)
mkdir -p proj/{src,docs,tests/unit}
cp config.yml{,.bak}    # cp config.yml config.yml.bak
mv report.{txt,md}      # mv report.txt report.md
```

Braces are **text generators**. They do not look at files. `{,.bak}` means "nothing, or `.bak`".

---

## 3. Tilde expansion

| Text | Becomes |
|------|---------|
| `~` | your home folder |
| `~asha` | home of user `asha` |
| `~+` | current folder (`$PWD`) |
| `~-` | previous folder (`$OLDPWD`) |

Quoted tilde does **not** expand: `"~"` is a literal tilde. Use `"$HOME"` in scripts.

---

## 4. Parameter expansion: defaults and errors

| Form | Meaning |
|------|---------|
| `${v:-default}` | use `default` if `v` is **unset or empty** |
| `${v-default}` | use `default` only if `v` is **unset** |
| `${v:=default}` | same as `:-`, and **also assigns** it to `v` |
| `${v:?message}` | **stop with an error** if `v` is unset or empty |
| `${v:+alt}` | `alt` if `v` is set and non-empty, otherwise empty |

The colon (`:`) means "treat **empty** like unset". Without it, only *unset* counts.

```bash
name=${1:-guest}                 # optional argument with a default
: "${API_KEY:?API_KEY is required}"   # fail early with a clear message
echo "${DEBUG:+--verbose}"       # add a flag only when DEBUG is set
```

The `: "${x:=default}"` trick: `:` is a do-nothing command, so the line exists only for the assignment inside.

> 🐍 **Python bridge:** `${v:-d}` is `os.environ.get("v") or "d"`. `${v:?msg}` is `os.environ["v"]` with a custom error. `${v:+alt}` is `alt if v else ""`.

---

## 5. Indirection and names

```bash
colour=blue
ptr=colour
echo "${!ptr}"           # blue   (the value of the variable whose NAME is in ptr)

echo "${!app_*}"         # names of all variables starting with app_
arr=(x y z)
echo "${!arr[@]}"        # 0 1 2        (the indexes)
declare -A age=([asha]=20 [ravi]=22)
echo "${!age[@]}"        # the keys
echo "${#arr[@]}"        # 3            (count)
echo "${#colour}"        # 4            (length of text)
```

`${!name}` is the safe replacement for most `eval` uses: it reads a variable whose name you built yourself.

Build names and assign them safely with `printf -v`:

```bash
for i in 1 2 3; do printf -v "item_$i" '%s' "value-$i"; done
echo "$item_2"           # value-2
```

---

## 6. Changing case and transforming

```bash
w="hello World"
echo "${w^^}"    # HELLO WORLD     all upper
echo "${w,,}"    # hello world     all lower
echo "${w^}"     # Hello World     first letter upper
echo "${w~~}"    # HELLO wORLD     swap every letter
```

More transforms with `@` (Bash 5.1+ for most):

| Form | Result |
|------|--------|
| `${v@Q}` | quoted so Bash can re-read it safely |
| `${v@U}` `${v@L}` | UPPER / lower |
| `${v@a}` | the variable's attributes (`r` readonly, `x` exported...) |
| `${v@E}` | expand `\n`, `\t` escapes |

`${v@Q}` is excellent for logging a command safely: `echo "running: ${cmd[*]@Q}"`.

> 🐍 **Python bridge:** `${w^^}` = `w.upper()`, `${w,,}` = `w.lower()`, `${w^}` ≈ `w.capitalize()`, `${v@Q}` = `shlex.quote(v)`.

---

## 7. Slicing

```bash
s=0123456789
echo "${s:2}"        # 23456789        from index 2
echo "${s:2:3}"      # 234             3 characters from index 2
echo "${s: -3}"      # 789             last 3 (note the SPACE before -)
echo "${s:0:-2}"     # 01234567        drop the last 2
arr=(a b c d e)
echo "${arr[@]:1:2}" # b c             array slice
echo "${@:2}"        # all arguments from the 2nd
echo "${@: -1}"      # the last argument
```

Why the space in `${s: -3}`? Because `${s:-3}` is the **default value** form from section 4!

> 🐍 **Python bridge:** `s[2:5]` is `${s:2:3}` (Bash uses *start:length*, Python uses *start:stop*). `s[-3:]` is `${s: -3}`.

---

## 8. Pattern removal and replacement (review of Lesson 16)

```bash
p=/home/asha/report.final.tar.gz
echo "${p##*/}"      # report.final.tar.gz   (basename)
echo "${p%/*}"       # /home/asha            (dirname)
echo "${p#*.}"       # final.tar.gz          (shortest from the front)
echo "${p##*.}"      # gz                    (longest from the front → extension)
echo "${p/asha/ravi}"   # first match
echo "${p//a/A}"        # all matches
echo "${p/#$HOME/\~}"     # only at the start: replace $HOME with a literal ~
echo "${p/%.gz/.zip}"      # only at the end
```

Memory trick: `#` is on the left of `$` on a keyboard (front), `%` is on the right (end). Double = longest.

---

## 9. Word splitting and `IFS`

After expansion, **unquoted** results are split into words wherever `IFS` (default: space, tab, newline) appears.

```bash
list="a b  c"
printf '[%s]\n' $list       # [a] [b] [c]     3 words (and also globbed!)
printf '[%s]\n' "$list"     # [a b  c]        1 word
```

Rule: **quote every expansion** unless you *want* splitting.

Use `IFS` deliberately to split text:

```bash
IFS=, read -r -a parts <<< "red,green,blue"
echo "${parts[1]}"          # green
( IFS=:; set -- a b c; echo "$*" )   # a:b:c    "$*" joins with the first IFS character
```

| Form | Meaning |
|------|---------|
| `"$@"` | each argument as its **own** word (almost always what you want) |
| `"$*"` | all arguments joined into **one** word |
| `$@` `$*` (unquoted) | split again, broken for names with spaces |
| `"${arr[@]}"` | each element as its own word |

---

## 10. Globbing options and `eval`

Globs expand file names (step 7). Four `shopt` switches change the rules:

```bash
shopt -s nullglob   # a glob with no match becomes NOTHING (default: stays as text)
shopt -s dotglob    # * also matches hidden files
shopt -s globstar   # ** matches folders recursively:  ls **/*.py
shopt -s extglob    # advanced patterns:
```

| extglob | Matches |
|---------|---------|
| `?(a\|b)` | zero or one of the patterns |
| `*(a\|b)` | zero or more |
| `+(a\|b)` | one or more |
| `@(a\|b)` | exactly one |
| `!(a\|b)` | anything **except** |

```bash
shopt -s extglob
rm -- !(keep.txt)          # delete everything except keep.txt (careful!)
ls +(a|b).txt              # a.txt b.txt aa.txt ...
```

**About `eval`:** it runs text as code after expansion, so a bad value becomes a command. Replace it:

| Instead of | Use |
|------------|-----|
| `eval "v=\$$name"` | `v=${!name}` |
| `eval "$name=\$value"` | `printf -v "$name" '%s' "$value"` |
| `eval echo "{1..$n}"` | `seq 1 "$n"` or a `for ((;;))` loop |

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `{1..$n}` | brace runs before variables | `seq`, C-style `for` |
| `${s:-3}` meaning "last 3" | it is the default-value form | `${s: -3}` (space) |
| unquoted `$var` | splits and globs | `"$var"` |
| `"~"` or `"~/x"` | tilde not expanded in quotes | `"$HOME/x"` |
| `for f in $(ls)` | breaks on spaces | `for f in *` |
| `rm !(x)` without `extglob` | syntax error | `shopt -s extglob` first |
| `${v@Q}` on Bash 4 | bad substitution | needs Bash 5.1+ |
| `*.txt` with no match | stays literal `*.txt` | `shopt -s nullglob` |
| `${!arr[@]}` mixed up with `${!ptr}` | indexes vs indirection | `!name[@]` = keys; `!name` = indirection |

---

## ✅ Summary

- Bash expands in order: **brace → tilde → variable/command/arithmetic → split → glob → quote removal**
- `${v:-d}` default · `${v:=d}` assign · `${v:?msg}` fail · `${v:+alt}` alternative
- `${!name}` indirection · `${!arr[@]}` keys · `${#v}` length
- `${v^^}` `${v,,}` case · `${v:start:len}` slice · `${v@Q}` safe quoting
- Quote expansions to stop splitting; use `IFS` on purpose
- `nullglob`, `dotglob`, `globstar`, `extglob` tune globbing
- Prefer `${!name}` and `printf -v` to `eval`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

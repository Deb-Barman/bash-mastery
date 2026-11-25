# Lesson 25 — Resources

## 📋 Cheat Sheet

**Expansion order:** brace → tilde → variable / command / arithmetic → word split → glob → quote removal

| Form | Meaning |
|------|---------|
| `{a,b}` `{1..5}` `{01..05}` `{1..10..2}` | generate text (before variables!) |
| `~` `~user` `~+` `~-` | home / user's home / `$PWD` / `$OLDPWD` |
| `${v:-d}` | default if unset **or empty** |
| `${v-d}` | default if unset only |
| `${v:=d}` | default **and assign** |
| `${v:?msg}` | **error and exit** if unset or empty |
| `${v:+alt}` | `alt` if set and non-empty |
| `${!ptr}` | indirection: value of the variable named in `ptr` |
| `${!pre*}` | names of variables starting with `pre` |
| `${!arr[@]}` | indexes / keys |
| `${#v}` `${#arr[@]}` | length / item count |
| `${v^^}` `${v,,}` `${v^}` `${v~~}` | UPPER / lower / Capitalise / swap |
| `${v@Q}` | shell-quoted (Bash 5.1+) |
| `${v:2:3}` `${v: -3}` | slice (start:length), last 3 |
| `${arr[@]:1:2}` `${@:2}` | array / argument slices |
| `${v#p}` `${v##p}` `${v%p}` `${v%%p}` | cut from front (short / long), from end |
| `${v/a/b}` `${v//a/b}` `${v/#a/b}` `${v/%a/b}` | replace first / all / at start / at end |

**Globs:** `shopt -s nullglob dotglob globstar extglob`

**extglob:** `?(p)` `*(p)` `+(p)` `@(p)` `!(p)`

**Safe instead of `eval`:** `${!name}` (read) · `printf -v "$name" '%s' "$val"` (write)

---

## 🏋️ Exercises

Set up:

```bash
mkdir -p ~/bash-practice/ex25 && cd ~/bash-practice/ex25
touch notes.txt todo.txt data.csv "my report.pdf" .secret
```

**Level A: Easy**
1. Print the numbers `01` to `12` on one line with one command.
2. Create the folders `app/src`, `app/docs`, `app/tests` with **one** `mkdir`.
3. Copy `notes.txt` to `notes.txt.bak` using `{,.bak}`.
4. Set `user=${1:-guest}` in a tiny script and run it with and without an argument.

**Level B: Medium**
5. Print the last 4 characters of the variable `v="abcdefgh"`.
6. Convert `title="learn bash today"` to ALL UPPER CASE, then to `Learn bash today`.
7. Given `file="archive.tar.gz"`, print the name without the **last** extension, then without **all** extensions.
8. Write `need() { : "${!1:?variable $1 is required}"; }` and test it on a set and an unset variable.
9. List all variables whose names start with `BASH_` (names only).
10. Make `*.nomatch` expand to nothing instead of staying as text.

**Level C: Challenge**
11. Delete every file in the folder **except** `notes.txt`, safely (practice folder only, use `extglob` and `--`; run `echo` first).
12. Create variables `host_1 host_2 host_3` from the list `a b c` **without `eval`**, then print them with indirection.
13. Write `last_arg` that prints the last argument of any call, using slicing.
14. Print the integers 1 to `n` where `n` comes from a variable, in **three different ways** (none using `{1..$n}`).
15. Make a function `ext()` that returns the extension (or an empty string if none) of any file name.
16. (Think!) Why does `echo "${s:-3}"` not print the last 3 characters?
17. (Think!) Why does `echo {1..$n}` fail but `for i in $(seq 1 "$n")` works?
18. (Think!) What is the difference between `"$@"` and `$@`? Show it with a file named `my file.txt`.
19. 🐍 Translate to Python: `port=${PORT:-8080}` and `[[ -n ${DEBUG:+x} ]]`.

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
echo {01..12}

# 2
mkdir -p app/{src,docs,tests}

# 3
cp notes.txt{,.bak}

# 4
#!/usr/bin/env bash
user=${1:-guest}
echo "Hello, $user"

# 5
v=abcdefgh
echo "${v: -4}"           # efgh

# 6
title="learn bash today"
echo "${title^^}"         # LEARN BASH TODAY
echo "${title^}"          # Learn bash today

# 7
file=archive.tar.gz
echo "${file%.*}"         # archive.tar
echo "${file%%.*}"        # archive

# 8
need() { : "${!1:?variable $1 is required}"; }
HOME_OK=1
need HOME_OK && echo "set"
( need NOPE_NOT_SET )     # prints the error; subshell so your terminal survives

# 9
echo "${!BASH_*}"

# 10
shopt -s nullglob
echo *.nomatch            # prints an empty line

# 11
shopt -s extglob
echo rm -- !(notes.txt)   # look first
rm -- !(notes.txt)        # then really delete (dotfiles are not matched)

# 12
i=0
for h in a b c; do
    i=$((i+1))
    printf -v "host_$i" '%s' "$h"
done
for i in 1 2 3; do ref="host_$i"; echo "$ref=${!ref}"; done

# 13
last_arg() { echo "${@: -1}"; }
last_arg one two three     # three

# 14
n=5
seq 1 "$n"
for ((i=1; i<=n; i++)); do echo "$i"; done
eval echo "{1..$n}"        # works, but eval is the one to avoid

# 15
ext() {
    local f=${1##*/}
    [[ $f == *.* ]] && echo "${f##*.}" || echo ""
}
ext photo.jpeg             # jpeg
ext Makefile               # (empty)

# 16
# ${s:-3} is the DEFAULT-VALUE form ("3 if s is empty"). For "last 3" write ${s: -3}
# with a space (or ${s: -3} in parentheses: ${s:(-3)}).

# 17
# Brace expansion happens BEFORE variable expansion, so Bash sees the text {1..$n}
# which is not a valid range. $(seq 1 "$n") is command substitution, which runs
# later, after $n has been expanded.

# 18
f() { printf '[%s]\n' "$@"; }
g() { printf '[%s]\n' $@; }
f "my file.txt" b     # [my file.txt] [b]
g "my file.txt" b     # [my] [file.txt] [b]   ← broken apart

# 19
# import os
# port = os.environ.get("PORT") or "8080"
# debug_on = bool(os.environ.get("DEBUG"))
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `{1..$n}` prints literally | braces expand first | `seq`, `for ((...))` |
| `bad substitution` | `${v@Q}` on old Bash, or a typo in `${...}` | `bash --version`; check braces |
| `${s:-3}` gives the whole string | default-value form | `${s: -3}` |
| a name with a space is split in two | unquoted `$f` | `"$f"` |
| `*.txt` appears literally | no match | `nullglob`, or test before use |
| `rm !(x)` → `syntax error near unexpected token '('` | `extglob` is off | `shopt -s extglob` on an **earlier line** |
| `~` not expanded | inside quotes | `"$HOME"` |
| `unbound variable` | `set -u` plus missing variable | `${v:-}` for optional ones |
| `${!x}` gives empty | the variable named in `x` is unset | check with `declare -p "$x"` |

---

## 💡 Habits of pro coders

1. **Know the order** and let it explain every surprise.
2. **Quote every expansion** unless you want splitting.
3. **Use `${v:?msg}`** at the top of a script for required inputs.
4. **Use `${v:-default}`** for optional inputs: no `if` needed.
5. **Prefer `${!name}` and `printf -v`** over `eval`.
6. **Turn on `nullglob`** (and `extglob`) at the top of scripts that loop over files.
7. **Use `--`** before file names built from globs.

## 📚 Extra resources

- **`man bash`**, search `EXPANSION` (press `/`, type it, Enter)
- **mywiki.wooledge.org/BashGuide/Parameters** and **/BashFAQ/073** (parameter expansion)
- **mywiki.wooledge.org/WordSplitting**: why quoting matters
- **mywiki.wooledge.org/glob**: globbing and `extglob`
- **wiki.bash-hackers.org/syntax/pe**: every `${...}` form in one page

## 🧠 Self-check

1. List the expansion steps in order. Which one makes `{1..$n}` fail?
2. What is the difference between `${v:-d}` and `${v-d}`?
3. How do you stop a script immediately if a variable is missing?
4. Write the three ways to get the last 3 characters of a string, if you can think of more than one.
5. What do `"$@"` and `"$*"` produce for the arguments `a "b c"`?
6. Name two replacements for `eval`.

## ➡️ Next: Lesson 26 — Arithmetic & Math (`(( ))`, bases, bit operations, `bc`, `awk`)

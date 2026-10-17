# Lesson 6 — Resources

## 📋 Cheat Sheet

### Globs (match files that exist)

| Pattern | Matches |
|---------|---------|
| `*` | any characters (even none), not hidden files |
| `?` | exactly one character |
| `[abc]` | one of a, b, c |
| `[a-z]` | one lowercase letter |
| `[0-9]` | one digit |
| `[!abc]` or `[^abc]` | one character that is NOT a, b, c |
| `[[:digit:]]` `[[:alpha:]]` `[[:upper:]]` `[[:lower:]]` | character classes |
| `**/` | any depth of folders (needs `shopt -s globstar`) |

### Braces (invent text)

| Pattern | Result |
|---------|--------|
| `{a,b,c}` | `a b c` |
| `{1..5}` | `1 2 3 4 5` |
| `{01..10}` | `01 02 ... 10` |
| `{a..e}` | `a b c d e` |
| `{0..20..5}` | `0 5 10 15 20` |
| `file{1,2}.txt` | `file1.txt file2.txt` |
| `cp f{,.bak}` | `cp f f.bak` |
| `mv f.{txt,md}` | `mv f.txt f.md` |

### `shopt` switches

| Option | Effect |
|--------|--------|
| `dotglob` | `*` also matches hidden files |
| `nullglob` | no match → empty list |
| `failglob` | no match → error |
| `globstar` | enables `**` |
| `extglob` | enables `!(..)` `@(..)` `+(..)` `*(..)` `?(..)` |
| `nocaseglob` | ignore case when matching |

`shopt -s name` = on · `shopt -u name` = off · `shopt name` = check

### Golden rules

1. **Preview:** `echo pattern` or `ls pattern` before `rm pattern`.
2. **Quote variables:** `"$var"`. **Don't quote** patterns you want expanded.
3. Quote patterns you want to pass **literally** (`find -name "*.txt"`).
4. Prefix with `./` (`./*`) and use `--` to be safe with names starting with `-`.

---

## 🏋️ Exercises

Set up first:

```bash
mkdir -p ~/bash-practice/ex6 && cd ~/bash-practice/ex6
touch cat.txt dog.txt cow.txt bird.md fish.md
touch img{1..12}.png
touch log-2026-{01..03}.txt
touch .secret "my file.txt"
```

**Level A: Easy**
1. List all `.txt` files.
2. List all `.md` files.
3. List files whose name starts with `c`.
4. List files with exactly three letters before `.txt`. (Hint: `?`)

**Level B: Medium**
5. List `img1.png` to `img5.png` using a range with `[ ]`... then explain why `img[1-5].png` does **not** match `img10.png`.
6. List all `.png` files **except** one-digit ones (`img10.png`, `img11.png`, `img12.png`). (Hint: `??`)
7. Print (don't create) the names `report-1.txt` ... `report-4.txt` using braces.
8. List only files starting with `c` **or** `d`.
9. Make a backup copy of `cat.txt` as `cat.txt.bak` using a brace trick.
10. Show the hidden file `.secret` using a glob that is **not** `ls -A`.

**Level C: Challenge**
11. Create the folders `~/bash-practice/ex6/archive/2026/{01..12}` in one command.
12. Delete all `.png` files whose number has **two digits**, previewing first.
13. List everything that is **not** a `.txt` file (use `extglob`; remember the gotcha).
14. Delete the file called `my file.txt` safely (the name has a space). Show two ways.
15. (Think!) What does `rm *` do if you accidentally run it in your **home** folder? How would you have prevented that?
16. (Think!) Why is `find . -name *.txt` risky but `find . -name "*.txt"` safe?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
ls *.txt

# 2
ls *.md

# 3
ls c*

# 4
ls ???.txt          # cat.txt dog.txt cow.txt

# 5
ls img[1-5].png
# [1-5] means ONE character from 1..5. "img10.png" has TWO characters
# between "img" and ".png" ("10"), so it can't match a single [ ].

# 6
ls img??.png        # img10.png img11.png img12.png

# 7
echo report-{1..4}.txt

# 8
ls [cd]*

# 9
cp cat.txt{,.bak}

# 10
ls .s*              # or: ls .secret

# 11
mkdir -p archive/2026/{01..12}

# 12
echo img??.png      # preview
rm -v img??.png     # delete

# 13
bash -O extglob -c 'ls !(*.txt)'
# or in your terminal: shopt -s extglob   then   ls !(*.txt)

# 14
rm "my file.txt"
rm my\ file.txt
# (also: rm 'my file.txt')

# 15
# It deletes every non-hidden FILE in your home folder (not folders,
# since rm without -r skips them). There's no recycle bin.
# Prevention: run pwd first; run echo * or ls * to preview; use rm -i;
# practice in ~/bash-practice only.

# 16
# Unquoted, if the current folder contains e.g. a.txt and b.txt, Bash turns
# it into:  find . -name a.txt b.txt   → find errors ("paths must precede
# expression") or searches for the wrong thing. Quoted, find receives the
# literal pattern and matches names itself at every depth.
```

</details>

---

## 🐞 Common beginner errors

| Problem | Cause | Fix |
|---------|-------|-----|
| `ls: cannot access '*.xyz'` | no file matches | check name/extension; `echo *.xyz` shows the pattern stays literal |
| `*` misses hidden files | by design | `ls -A`, `.*`, or `shopt -s dotglob` |
| Name with space breaks | missing quotes on a **variable** | `"$var"` |
| `rm: cannot remove '*.log'` | pattern didn't match, or was quoted | check with `echo`; don't quote the `*` |
| `syntax error near unexpected token '('` | `extglob` pattern but extglob not on | `shopt -s extglob` on an **earlier** line |
| `{1..10}` printed literally | used `sh`, not Bash | run with `bash script.sh` |
| `{ 1..5 }` doesn't expand | spaces inside braces | no spaces: `{1..5}` |
| `img[1-12].png` doesn't work | `[ ]` matches **one** character | use `img{1..12}.png` (brace) or `img[1-9].png img1[0-2].png` |
| Glob result order differs | locale-dependent sorting | pipe to `sort` if order matters |

---

## 💡 Habits of pro coders

1. **`echo` is a free preview.** Use it before every destructive command.
2. **`./*` instead of `*`** in scripts: safe against names beginning with `-`.
3. **`shopt -s nullglob`** in scripts that loop over globs.
4. Know **who expands**: Bash (unquoted) or the command (quoted).
5. Prefer **braces to generate** names, **globs to find** them, **`find`** for deep or complex searches.
6. **Back up before bulk operations** you can't undo.

## 📚 Extra resources

- **`man bash`**, then search `/Pathname Expansion` and `/Brace Expansion`
- **Bash Hackers Wiki:** "Patterns" and "Brace expansion" pages
- **mywiki.wooledge.org/glob:** the best deep explanation of globbing
- **explainshell.com:** paste `rm img??.png` and see it labelled
- **shellcheck.net:** warns you about unquoted variables and risky globs

## 🧠 Self-check

1. Who expands `*.txt`: the command or Bash? How can you prove it?
2. What's the difference between `*` and `?`
3. Why does `[1-12]` not mean "1 to 12"?
4. How are braces different from globs?
5. How do you make `*` include hidden files?
6. When should you quote, and when not?

## ➡️ Next: Lesson 7 — Text Tools (`sort`, `uniq`, `cut`, `tr`, `sed`, `awk` basics)

# Lesson 6 — Wildcards & Globbing

**Level 2 · Power Tools · Time: ~55 minutes**

---

## 🎯 What you will learn

- Match **many files with one pattern** (`*`, `?`, `[ ]`)
- Generate **many names with one pattern** (`{a,b}`, `{1..10}`)
- Know the difference between **globbing** and **brace expansion**
- Know exactly **who** expands the pattern (Bash, not the command!)
- Handle hidden files, odd names, and "no match" safely
- Use the safety habit: **preview with `ls` or `echo` before `rm`**

> Renaming, copying, or deleting 5,000 files is one line when you know patterns.

---

## 1. The big idea: Bash expands, then runs

When you type:

```bash
ls *.txt
```

**Bash**, not `ls`, first replaces `*.txt` with the matching file names:

```bash
ls a.txt b.txt notes.txt
```

Only then does it start `ls`. This matching step is called **globbing**.

You can *see* the expansion with `echo`:

```bash
echo *.txt          # prints the list Bash built
```

> 💡 **Superpower:** whenever you wonder "what will this pattern match?", run `echo pattern`. It's a free preview and changes nothing.

---

## 2. `*`: any number of any characters (even zero)

```bash
ls *               # everything (not hidden files)
ls *.txt           # ends with .txt
ls report*         # starts with report
ls *2026*          # contains 2026
ls a*b             # starts with a, ends with b
```

`*` never matches a `/`, so `*` stays inside one folder level.

---

## 3. `?`: exactly one character

```bash
ls file?.txt       # file1.txt, fileA.txt  (NOT file10.txt)
ls ???.txt         # any name with exactly 3 letters, then .txt
```

---

## 4. `[ ]`: one character from a set or range

```bash
ls file[123].txt       # file1.txt file2.txt file3.txt
ls file[1-5].txt       # range 1 to 5
ls [a-c]*              # starts with a, b or c
ls *[0-9]              # ends with a digit
ls [!a-c]*             # starts with anything EXCEPT a, b, c  (also: [^a-c])
ls *.[ch]              # .c or .h files
```

Ready-made classes:

| Class | Meaning |
|-------|---------|
| `[[:digit:]]` | a digit |
| `[[:alpha:]]` | a letter |
| `[[:upper:]]` / `[[:lower:]]` | capital / small letter |
| `[[:space:]]` | space or tab |

Example: `ls [[:upper:]]*` → names starting with a capital letter.

---

## 5. Brace expansion `{ }`: *generate* names

**Totally different from globbing!** Globbing **searches existing files**. Braces **invent text**, even if no file exists.

```bash
echo {a,b,c}              # a b c
echo file{1,2,3}.txt      # file1.txt file2.txt file3.txt
echo {1..5}               # 1 2 3 4 5
echo {a..e}               # a b c d e
echo {01..10}             # 01 02 ... 10  (zero-padded!)
echo {10..1}              # counts down
echo {0..20..5}           # 0 5 10 15 20  (step of 5)
echo {2025..2027}-{01,02} # 2025-01 2025-02 2026-01 ... (combos!)
```

Real uses:

```bash
mkdir -p project/{src,docs,tests}
touch day{1..7}.txt
cp config.txt{,.bak}          # shortcut: cp config.txt config.txt.bak
mv report.{txt,md}            # mv report.txt report.md  (rename the extension)
```

**Rules:** no spaces inside braces, and brace expansion happens **before** globbing.

---

## 6. Hidden files (names starting with `.`)

`*` does **not** match names that start with a dot:

```bash
ls *            # skips .bashrc, .git
ls .*           # ⚠️ hidden files; on Bash older than 5.2 it ALSO matches . and ..
ls -A           # the safe way to see hidden files too
```

To match hidden files in a script, turn on:

```bash
shopt -s dotglob   # * now includes hidden files (but not . and ..)
```

---

## 7. When nothing matches

```bash
ls *.xyz
```

By default Bash passes the pattern **literally** when nothing matches: `ls: cannot access '*.xyz'`.

This is dangerous in loops (Lesson 13): a loop would run once with the text `*.xyz`. The fix:

```bash
shopt -s nullglob     # no match → the pattern becomes NOTHING (empty list)
shopt -s failglob     # no match → Bash prints an error and does not run the command
```

---

## 8. Quoting turns the magic **off**

```bash
echo *.txt         # expands to file names
echo "*.txt"       # prints: *.txt   (quotes protect it)
echo '*.txt'       # prints: *.txt
echo \*.txt        # prints: *.txt   (backslash protects one character)
```

This is why we write `find . -name "*.txt"`: we **want find**, not Bash, to interpret the `*`.

### The other side: quoting variables

```bash
name="my file.txt"
ls $name        # ❌ becomes: ls my file.txt   (two arguments)
ls "$name"      # ✅ one argument
```

**Rule of thumb:** quote variables `"$var"`; leave glob patterns **unquoted** when you *want* expansion.

```bash
rm "$folder"/*.tmp        # ✅ variable quoted, pattern outside quotes
```

---

## 9. Advanced patterns (shopt options)

### `**`: recursive (globstar)

```bash
shopt -s globstar
ls **/*.txt             # every .txt in every subfolder, any depth
```

### `extglob`: smarter patterns

```bash
shopt -s extglob
ls !(*.txt)             # everything EXCEPT .txt files
ls *.@(jpg|png)         # .jpg or .png files
ls +([0-9]).txt         # one-or-more digits then .txt   (1.txt, 205.txt)
rm !(keep.txt)          # delete everything except keep.txt (⚠️ preview first!)
```

| Pattern | Meaning |
|---------|---------|
| `?(a\|b)` | zero or one of the patterns |
| `*(a\|b)` | zero or more |
| `+(a\|b)` | one or more |
| `@(a\|b)` | exactly one |
| `!(a\|b)` | anything except |

---

## 10. Globs are NOT regular expressions

| | Glob (this lesson) | Regex (Lesson 19) |
|--|--------------------|-------------------|
| Used by | the shell for file names | `grep`, `sed`, `awk` for text |
| "any text" | `*` | `.*` |
| "one char" | `?` | `.` |
| "starts with" | n/a | `^` |

Same symbols, **different meanings**. Don't mix them up. For example `grep "*.txt"` is a regex, not a glob.

---

## 11. Weird file names

```bash
touch -- -report.txt       # "--" says "options end here"
rm -- -report.txt
ls ./*                     # "./" prefix: a file named "-rf" can't be mistaken for an option
```

Pro habit in scripts: `rm -- "$file"` and `./*` instead of bare `*`.

---

## ⚠️ Safety checklist before deleting with patterns

1. `pwd` (where am I?)
2. `echo pattern` or `ls pattern` (what exactly matches?)
3. Read the list. Does it contain only what you want?
4. Then `rm -i pattern` (or just `rm pattern` if you're sure)

**Never** run a pattern like `rm *` or `rm .*` without that check. `rm -rf .*` has caused real disasters.

---

## ✅ Summary

- Bash expands patterns **before** the command runs; preview with `echo`
- `*` any text · `?` one char · `[abc]` / `[a-z]` / `[!a-z]` one from a set
- `{a,b}` / `{1..10}` **generate** names (brace expansion ≠ globbing)
- `*` skips hidden files; `nullglob` handles "no match"
- Quotes switch the magic off; quote **variables**, not patterns
- `globstar` (`**`) and `extglob` (`!(...)`) give power-user patterns
- Globs ≠ regex

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

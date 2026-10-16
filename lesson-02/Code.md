# Lesson 2 — Code Explained (line by line)

This file explains `Code.sh`. Keep both open side by side.

**Run it:**

```bash
bash Code.sh
```

The script is **safe**: it only touches `~/bash-practice/lesson2-demo` and deletes it at the end. You can run it as many times as you like.

---

## The setup (new ideas!)

```bash
DEMO="$HOME/bash-practice/lesson2-demo"
```

This makes a **variable** called `DEMO`.

| Piece | Meaning |
|-------|---------|
| `DEMO=` | create a box named DEMO (no spaces around `=`!) |
| `"..."` | the value, in quotes |
| `$HOME` | a built-in variable: your home folder path |

Later, `"$DEMO"` means "put the value here." Variables get their full lesson in Lesson 10.

```bash
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
```

Plain English: **"If a folder named DEMO exists, delete it."**

- `[ -d "$DEMO" ]` is a test: *is this a directory?*
- This makes the script **re-runnable**: it always starts fresh.
- It deletes **one exact path**, never a pattern like `*`.

(`if` gets its own lesson in Lesson 12. Just read it as English for now.)

```bash
mkdir -p "$DEMO"
cd "$DEMO" || exit 1
```

- Create the demo folder, then go inside.
- `|| exit 1` means: **"if `cd` fails, stop the script immediately."**
- **This is a life-saving habit.** Imagine `cd` fails and the script keeps running `rm` commands in the wrong folder. Always guard `cd` in scripts.

---

## Part 1: mkdir

```bash
mkdir photos
mkdir docs music videos
mkdir -p projects/web/css
```

One folder, three folders, then a nested path. `-p` created `projects`, then `web` inside it, then `css` inside that.

---

## Part 2: touch

```bash
touch notes.txt
touch a.txt b.txt c.txt
```

Creates empty files. Because `ls` sorts alphabetically, files and folders appear mixed together.

---

## Part 3: `>`, `>>` and `cat`

```bash
echo "Hello file"  > hello.txt
echo "Second line" >> hello.txt
echo "Third line"  >> hello.txt
```

| Symbol | Meaning |
|--------|---------|
| `>` | send output into the file, **erasing** what was there |
| `>>` | send output to the **end** of the file |

So `hello.txt` now holds three lines. To feel the difference, change the **third** line's `>>` to `>` and run again: the file will contain only "Third line", because each `>` erased what came before.

```bash
cat hello.txt
cat -n hello.txt
```

`cat` prints the file. `-n` adds line numbers.

---

## Part 4: cp

```bash
cp hello.txt backup.txt
```

Copy `hello.txt` to a new file `backup.txt`. Format: `cp SOURCE DESTINATION`.

```bash
cp hello.txt photos/
```

The trailing `/` says "this is a folder." The copy keeps the name `hello.txt` inside `photos`.

```bash
cp -r photos photos-backup
```

`-r` (recursive) is required to copy a folder with its contents.

---

## Part 5: mv

```bash
mv backup.txt greeting.txt     # rename
mv greeting.txt docs/          # move
mv a.txt b.txt music/          # move two files
```

- If the destination is a **new name**, it renames.
- If the destination is an **existing folder**, it moves into it.
- With several sources, the **last argument must be a folder**.

```bash
echo "docs/  : $(ls docs)"
```

`$( )` runs `ls docs` and pastes the result into the sentence. When there are several files, they appear on separate lines. That's normal.

---

## Part 6: spaces in names

```bash
mkdir "my holiday photos"
touch "my holiday photos/beach day.txt"
ls "my holiday photos"
```

Quotes keep `my holiday photos` as **one** argument. Remove the quotes from one line and run it. You will see how Bash splits it into several wrong words. That's the classic beginner bug.

---

## Part 7: brace expansion

```bash
mkdir -p project/{src,docs,tests}
```

Bash rewrites this before running into:

```bash
mkdir -p project/src project/docs project/tests
```

**No spaces** inside the braces.

```bash
ls -R project
```

`-R` lists folders and everything inside them, level by level.

---

## Part 8: deleting

```bash
rm c.txt
rmdir videos
rm -r photos-backup
```

| Command | Works on | Safety |
|---------|----------|--------|
| `rm file` | files | permanent |
| `rmdir folder` | **empty** folders only | very safe |
| `rm -r folder` | folders with contents | permanent, be careful |

---

## Part 9: a safety net in action

```bash
rmdir docs 2>&1 || echo "(As expected ...)"
```

- `docs` is not empty, so `rmdir` refuses. Good, nothing was lost.
- `||` means **"if the previous command failed, do this next."**
- `2>&1` merges error messages into normal output. (You will master it in Lesson 5. Ignore it for now.)

---

## Cleanup

```bash
cd "$HOME" || exit 1
rm -r "$DEMO"
```

Leave the demo folder first (you cannot cleanly delete the folder you stand in), then remove it.

---

## 🧪 Experiments

1. Comment out the cleanup (`# rm -r "$DEMO"`), run again, and explore the folder yourself with `ls -R ~/bash-practice/lesson2-demo`.
2. Change `rm c.txt` to `rm -i c.txt`. It now asks first.
3. Remove the quotes around `"my holiday photos"` and read the error.
4. Run with `bash -x Code.sh 2>&1 | less` to watch every command as it runs. Press `q` to quit.
5. Add your own folder and file at the end of Part 7.

---

## ✅ New words in this file

`variable` · `$HOME` · `cd ... || exit 1` · `cp -r` · `mv` (rename) · `rm -r` · `rmdir` · `{a,b,c}` · `||` · `ls -R`

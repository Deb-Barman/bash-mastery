# Lesson 2 — Files & Folders

**Level 1 · Survival · Time: ~60 minutes**

---

## 🎯 What you will learn

- Create folders (`mkdir`) and empty files (`touch`)
- Show file contents (`cat`)
- Copy (`cp`), move and rename (`mv`)
- Delete safely (`rm`, `rmdir`)
- Handle names with spaces
- The golden safety habits that protect your data

> **Before you start:** open your terminal and go to the practice area:
> ```bash
> mkdir -p ~/bash-practice
> cd ~/bash-practice
> ```
> Do **all** of this lesson inside `~/bash-practice`.

---

## 1. `mkdir` — make a folder

```bash
mkdir photos                  # one folder
mkdir docs music videos       # three folders at once
mkdir -p projects/web/css     # nested folders in one go
```

`-p` means "create parent folders too, and don't complain if it already exists."

Check with `ls`.

---

## 2. `touch` — make an empty file

```bash
touch notes.txt
touch a.txt b.txt c.txt       # three files at once
```

If the file already exists, `touch` just updates its "last modified" time. It never erases content.

---

## 3. Writing something into a file (a small preview)

```bash
echo "Hello file" > hello.txt     # creates/overwrites hello.txt
echo "Second line" >> hello.txt   # APPENDS a line
```

- `>` = **overwrite** (danger: old content is lost)
- `>>` = **append** (adds to the end)

Redirection gets its own full lesson (Lesson 5). For now, it lets us make files with content.

---

## 4. `cat` — show a file

```bash
cat hello.txt
```

Prints the whole file. Great for short files. (For long ones, Lesson 3 teaches `less`.)

Useful options:

```bash
cat -n hello.txt      # show line numbers
```

---

## 5. `cp` — copy

```bash
cp hello.txt backup.txt           # copy a file under a new name
cp hello.txt photos/              # copy INTO a folder (keeps the name)
cp -r photos photos-backup        # copy a whole folder (-r = recursive)
```

Rule: **folders need `-r`**.

Safety option:

```bash
cp -i hello.txt backup.txt        # asks before overwriting
```

---

## 6. `mv` — move AND rename

Bash has no separate "rename" command. **Moving and renaming are the same thing.**

```bash
mv hello.txt greeting.txt         # RENAME
mv greeting.txt docs/             # MOVE into docs
mv docs/greeting.txt docs/hi.txt  # move/rename inside docs
mv a.txt b.txt c.txt music/       # move many files into a folder
```

Safety option: `mv -i old new` asks before overwriting.

---

## 7. `rm` — remove (⚠️ DANGEROUS)

```bash
rm c.txt                  # delete a file
rm -i b.txt               # ask first (recommended while learning)
rm -r photos-backup       # delete a folder and everything inside
rmdir music               # delete an EMPTY folder only (very safe)
```

### 🚨 There is NO Recycle Bin. Deleted means gone.

Memorize these rules:

1. **Run `ls` first** to see exactly what you will delete.
2. **Use `rm -i`** while learning.
3. **Never run `rm -rf /` or `rm -rf ~` or `rm -rf *` unless you are 100% sure where you are.** `-f` means "force, no questions."
4. **Check `pwd`** before any `rm -r`.
5. A space in the wrong place can be a disaster:
   - `rm -r my folder` → tries to delete `my` AND `folder` (two things!)
   - `rm -r "my folder"` → deletes the one folder you meant

---

## 8. Names with spaces

Spaces separate arguments, so Bash needs help:

```bash
mkdir "my holiday photos"         # quotes
mkdir my\ holiday\ photos2        # backslash escape
touch "My Notes.txt"
```

**Pro tip:** use `-` or `_` in names instead: `my-holiday-photos`. Names without spaces make scripting much easier. Quotes are mandatory in scripts when names might have spaces.

---

## 9. Check what you have: `ls` and `tree`

```bash
ls -l
ls -R              # list folders inside folders (recursive)
tree               # a nice tree view (install with: sudo apt install tree)
```

---

## 10. Combining ideas: a mini workflow

```bash
mkdir -p project/{src,docs,tests}     # {a,b,c} creates all three
touch project/src/main.sh
touch project/docs/README.md
ls -R project
```

`{src,docs,tests}` is **brace expansion**: Bash expands it into three words for you. Huge time-saver. (More in Lesson 6.)

---

## 11. Quick comparison

| Goal | Command |
|------|---------|
| New folder | `mkdir name` |
| New empty file | `touch name` |
| See a file | `cat name` |
| Copy file | `cp src dest` |
| Copy folder | `cp -r src dest` |
| Rename / move | `mv old new` |
| Delete file | `rm name` |
| Delete empty folder | `rmdir name` |
| Delete folder + contents | `rm -r name` |

---

## ✅ Summary

- `mkdir -p` makes folders, `touch` makes files
- `cat` shows a file; `>` overwrites, `>>` appends
- `cp` copies (folders need `-r`), `mv` moves **and** renames
- `rm` is permanent; use `-i`, check `ls` and `pwd` first
- Quote names with spaces, or better, avoid spaces

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

# Lesson 2 — Resources

## 📋 Cheat Sheet

| Command | What it does | Example |
|---------|-------------|---------|
| `mkdir` | make folder | `mkdir -p a/b/c` |
| `touch` | make empty file / update time | `touch notes.txt` |
| `cat` | show file | `cat -n file.txt` |
| `>` | write output to file (overwrite) | `echo hi > f.txt` |
| `>>` | append output to file | `echo hi >> f.txt` |
| `cp` | copy file | `cp a.txt b.txt` |
| `cp -r` | copy folder | `cp -r dir dir2` |
| `mv` | move or rename | `mv old new` |
| `rm` | delete file | `rm -i f.txt` |
| `rm -r` | delete folder + contents | `rm -r dir` |
| `rmdir` | delete empty folder | `rmdir dir` |
| `ls -R` | list recursively | `ls -R project` |

**Safety options:** `-i` ask before overwrite/delete · `-v` verbose (show what happened) · `-n` (cp/mv) never overwrite

**Brace expansion:** `mkdir {a,b,c}` → `a b c` · `touch file{1..5}.txt` → `file1.txt` ... `file5.txt`

**Before every delete:** `pwd` → `ls` → `rm -i`.

---

## 🏋️ Exercises

Work inside `~/bash-practice`.

**Level A: Easy**
1. Create a folder called `school`.
2. Inside `school`, create three empty files: `math.txt`, `science.txt`, `english.txt`.
3. Put the text `Algebra` into `math.txt`.
4. Show the contents of `math.txt`.

**Level B: Medium**
5. Copy `math.txt` to `math-backup.txt`.
6. Rename `science.txt` to `physics.txt`.
7. Create a folder `archive` and move `math-backup.txt` into it.
8. Create `files/{docs,images,videos}` in one command.
9. Create a folder called `My Trip` (with a space) and a file `day 1.txt` inside it.

**Level C: Challenge**
10. Create files `day1.txt` through `day7.txt` with **one** command.
11. Make a full copy of the folder `school` called `school-copy`, then delete `school-copy` safely, using the safest command that works.
12. Build this structure with a **single** `mkdir -p` command:
    ```
    website/
    ├── css/
    ├── js/
    └── images/
        ├── icons/
        └── photos/
    ```
13. (Think!) What is the difference between `rm -r folder` and `rmdir folder`? When would you pick each?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
mkdir school

# 2
touch school/math.txt school/science.txt school/english.txt
# or: cd school && touch math.txt science.txt english.txt

# 3
echo "Algebra" > school/math.txt

# 4
cat school/math.txt

# 5
cp school/math.txt school/math-backup.txt

# 6
mv school/science.txt school/physics.txt

# 7
mkdir school/archive
mv school/math-backup.txt school/archive/

# 8
mkdir -p files/{docs,images,videos}

# 9
mkdir "My Trip"
touch "My Trip/day 1.txt"

# 10
touch day{1..7}.txt

# 11
cp -r school school-copy
rm -ri school-copy      # -i asks for each item; or: rm -r school-copy after checking with ls

# 12
mkdir -p website/{css,js,images/{icons,photos}}

# 13
# rmdir only removes EMPTY folders, so it is a safe check:
# "delete this if there is nothing in it."
# rm -r removes everything inside too, so use it only when
# you are sure about the contents.
```

</details>

---

## 🐞 Common beginner errors

| Message | Cause | Fix |
|---------|-------|-----|
| `cp: -r not specified; omitting directory` | copying a folder without `-r` | `cp -r` |
| `rmdir: Directory not empty` | folder has content | check with `ls`, then `rm -r` if sure |
| `mv: target is not a directory` | several sources but last item isn't a folder | make sure the last argument is a folder |
| `No such file or directory` | wrong path / typo | `pwd`, `ls`, use Tab |
| File "disappeared" after `>` | `>` overwrote it | use `>>` to append |
| `mkdir: cannot create directory: File exists` | name already used | pick another name, or use `-p` |

---

## 💡 Habits of pro coders

1. **Tab-complete everything.** It also confirms the file really exists.
2. **Use `-v`** (`cp -v`, `mv -v`) so Bash tells you what it did.
3. **Never use spaces in names** you create. Use `kebab-case` or `snake_case`.
4. **Test a delete with `ls` first.** If `ls something*` shows the right files, then `rm something*` is safe.
5. **Keep backups** of anything you cannot recreate.

## 📚 Extra resources

- **explainshell.com:** paste `cp -r a b` and see each part explained
- **`man cp`, `man mv`, `man rm`:** built-in manuals (press `q` to leave). Lesson 4 teaches this properly
- **OverTheWire Bandit, levels 0 to 5:** practice moving through files for real

## 🧠 Self-check

1. What is the difference between `>` and `>>`?
2. Why does `mv` do both moving and renaming?
3. Why must you quote `"my folder"`?
4. What does `rmdir` refuse to do, and why is that useful?
5. What does `cd "$DIR" || exit 1` protect you from?

## ➡️ Next: Lesson 3 — Reading & Finding (`less`, `head`, `tail`, `find`, `grep`, `wc`)

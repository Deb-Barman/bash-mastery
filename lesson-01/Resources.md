# Lesson 1 — Resources

## 📋 Cheat Sheet

| Command | What it does | Example |
|---------|-------------|---------|
| `echo` | print text | `echo "Hi"` |
| `pwd` | show current location | `pwd` |
| `ls` | list files | `ls -la` |
| `cd` | change folder | `cd ~/bash-practice` |
| `clear` | clean screen | `clear` |
| `date` | date and time | `date` |
| `whoami` | your username | `whoami` |
| `hostname` | computer name | `hostname` |
| `mkdir -p` | make folder safely | `mkdir -p a/b/c` |

**`ls` options:** `-l` long · `-a` hidden · `-h` readable sizes · `-d` folder itself · `-t` newest first · `-r` reverse

**Path symbols:** `.` here · `..` up · `~` home · `/` root · `-` previous (with `cd`)

**Keys:** `Tab` complete · `↑↓` history · `Ctrl+C` stop · `Ctrl+L` clear · `Ctrl+A/E` line start/end · `Ctrl+R` search history

---

## 🏋️ Exercises

Do them **without looking at the answers**.

**Level A: Easy**
1. Print `I am learning Bash` on the screen.
2. Show which folder you are in.
3. List all files, **including hidden ones**.
4. Go to your home folder from anywhere, using the shortest command.

**Level B: Medium**
5. List files in long format with human-readable sizes.
6. Go to `/` (root), then list what is there, then come back to your previous folder.
7. Print today's date inside a sentence: `Today is <date>`.
8. Create the folder path `~/bash-practice/lesson1/day1` in **one** command.

**Level C: Challenge**
9. Create a script `hello.sh` that prints your name, your username, and the current folder. Run it.
10. Without opening any file manager, find out what hidden files live in your home folder.

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
echo "I am learning Bash"

# 2
pwd

# 3
ls -a

# 4
cd

# 5
ls -lh

# 6
cd /
ls
cd -

# 7
echo "Today is $(date)"

# 8
mkdir -p ~/bash-practice/lesson1/day1

# 9  (create the file with nano hello.sh, then paste:)
#!/usr/bin/env bash
echo "My name is Deb"
echo "My username is $(whoami)"
echo "I am in $(pwd)"
# Run it:  bash hello.sh

# 10
ls -a ~
```

</details>

---

## 🐞 Common beginner errors

| Error message | Cause | Fix |
|---------------|-------|-----|
| `command not found` | typo, or spaces missing | check spelling: `ls -l`, not `ls-l` |
| `No such file or directory` | wrong path or case | use `pwd` and `ls`; use Tab to complete |
| `unexpected EOF while looking for matching '"'` | missing closing quote | add the missing `"` |
| `Permission denied` | not allowed to access it | (Lesson 8) |
| Terminal looks frozen | a command is still running | press `Ctrl+C` |

---

## 📚 Extra resources (free)

- **Bash Reference Manual:** gnu.org/software/bash/manual (the official source)
- **explainshell.com:** paste any command and it explains every part
- **OverTheWire "Bandit":** a free game that teaches Linux commands
- **tldr.sh:** short, friendly summaries of commands
- **shellcheck.net:** paste a script, it finds your mistakes

## 🧠 Self-check (answer out loud)

1. What is the difference between a terminal and a shell?
2. What does `cd ..` do?
3. What is the difference between an absolute and a relative path?
4. Which keys stop a running command?
5. Why does `mkdir -p` make scripts safer?

## ➡️ Next: Lesson 2 — Files & Folders (`mkdir`, `touch`, `cp`, `mv`, `rm`, `cat`)

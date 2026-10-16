# Lesson 1 — Meet Bash: Your First Commands

**Level 1 · Survival · Time: ~45 minutes**

---

## 🎯 What you will learn

By the end of this lesson you can:

- Explain what Bash, the terminal, and a "command" are
- Know **where you are** in your computer (`pwd`)
- **Look around** (`ls`)
- **Move around** (`cd`)
- **Print text** (`echo`)
- Run your first real script

---

## 1. What is Bash? (The simple truth)

You normally control a computer with a **mouse**: click, drag, open.

Bash lets you control it with **words**. You type a command, press Enter, the computer obeys.

Why is this powerful?

> A mouse can do **one thing at a time**.
> A Bash command can do **10,000 things in one second**.

Example: renaming 5,000 photos by hand takes days. In Bash, it's **one line**.

### Three words people confuse

| Word | Meaning | Analogy |
|------|---------|---------|
| **Terminal** | The window where you type | The telephone |
| **Shell** | The program that understands your words | The person who answers |
| **Bash** | The most popular shell. Name = *Bourne Again SHell* | One specific person (very good at their job) |

---

## 2. Opening the terminal

- **Linux:** `Ctrl + Alt + T`
- **macOS:** Press `Cmd + Space`, type `Terminal`, press Enter
- **Windows:** open **WSL** or **Git Bash**

You will see something like:

```
deb@laptop:~$
```

Read it like this:

| Part | Meaning |
|------|---------|
| `deb` | your username |
| `@` | "at" |
| `laptop` | your computer's name |
| `~` | where you are now (`~` = your **home** folder) |
| `$` | "I'm ready, type something" |

**Important:** When we write `$ ls` in lessons, you type only `ls`. **Never type the `$`.**

---

## 3. The anatomy of a command

Every command follows the same pattern:

```
command   -options   arguments
   │          │          │
 what to    how to     what to
   do       do it      act on
```

Example:

```bash
ls -l Documents
```

- `ls` → list files
- `-l` → in long, detailed format
- `Documents` → the folder to look at

Spaces matter. `ls -l` works. `ls-l` fails.

---

## 4. Your first 5 commands

### `echo` — make the computer talk

```bash
echo "Hello, World!"
```

Output: `Hello, World!`

`echo` prints whatever you give it. You will use it **constantly**.

### `pwd` — Print Working Directory ("Where am I?")

```bash
pwd
```

Output: `/home/deb`

Your computer is a tree of folders. `pwd` shows your exact position in the tree.

### `ls` — List ("What is here?")

```bash
ls            # simple list
ls -l         # long list (size, date, permissions)
ls -a         # show hidden files (names starting with .)
ls -la        # both together
ls -lh        # human-readable sizes (KB, MB)
```

### `cd` — Change Directory ("Go there")

```bash
cd Documents      # go into Documents
cd ..             # go UP one level
cd ~              # go HOME (from anywhere)
cd                # also goes home
cd -              # go back to previous folder
cd /              # go to the very top (root)
```

### `clear` — Clean the screen

```bash
clear
```

Shortcut: `Ctrl + L`

---

## 5. Paths: the address of a file

A **path** is the address of a file or folder.

| Type | Starts with | Example | Meaning |
|------|------------|---------|---------|
| **Absolute** | `/` | `/home/deb/Documents` | Full address from the top. Works from anywhere. |
| **Relative** | anything else | `Documents/notes.txt` | Address starting from where you are now. |

Special shortcuts:

| Symbol | Meaning |
|--------|---------|
| `.` | here (current folder) |
| `..` | one folder up (parent) |
| `~` | your home folder |
| `/` | the root (top of everything) |

---

## 6. Comments: notes to yourself

Anything after `#` is ignored by Bash:

```bash
echo "Hi"   # this part is just a note
```

Good coders write comments. Future-you will thank present-you.

---

## 7. Keyboard superpowers (learn these today!)

| Keys | What it does |
|------|-------------|
| `Tab` | **Auto-complete** names. Type `cd Doc` + Tab → `cd Documents/` |
| `↑` / `↓` | Previous / next command you typed |
| `Ctrl + C` | **STOP** the running command (your emergency exit) |
| `Ctrl + L` | Clear screen |
| `Ctrl + A` | Jump to start of line |
| `Ctrl + E` | Jump to end of line |
| `Ctrl + R` | Search your command history |

> 💡 Pros press **Tab** after almost every few letters. It prevents typos and saves hours.

---

## 8. Your first script

A **script** is a text file full of commands. Bash runs them top to bottom, so **you type once and run forever**.

See `Code.sh` in this lesson. To run it:

```bash
bash Code.sh
```

You just automated something. Welcome to the club. 🎉

---

## ⚠️ Beginner safety rules

1. **Linux has no Recycle Bin in the terminal.** Deleted = gone. (We learn `rm` carefully in Lesson 2.)
2. **Never run commands you don't understand**, especially anything with `sudo` or `rm -rf`.
3. **Practice inside `~/bash-practice`**, not your real files.
4. Commands are **case-sensitive**: `LS` is not `ls`. `Documents` is not `documents`.

---

## ✅ Summary

- Terminal = window, Shell = translator, Bash = the shell we use
- Command pattern: `command -options arguments`
- `echo` prints, `pwd` shows location, `ls` lists, `cd` moves, `clear` cleans
- Absolute path starts with `/`; relative path starts from where you are
- `Tab` and `↑` make you fast; `Ctrl+C` stops anything

## ➡️ Next

Open **`Code.md`** to see every line of the script explained, then run **`Code.sh`**, then do the exercises in **`Resources.md`**.

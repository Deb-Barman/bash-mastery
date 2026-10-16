# Lesson 1 — Code Explained (line by line)

This file explains `Code.sh`. Read it with `Code.sh` open beside it.

**Run the script:**

```bash
bash Code.sh
```

---

## The header

```bash
#!/usr/bin/env bash
```

This is the **shebang**. It tells the computer: "run this file using Bash." It must be the **first line**. (Full explanation in Lesson 9.)

```bash
# Lesson 1 - Code.sh
```

Lines starting with `#` are **comments**. Bash ignores them. They are notes for humans.

---

## Part 1: echo

```bash
echo "Hello, World!"
```

| Piece | Meaning |
|-------|---------|
| `echo` | the command: print something |
| `"Hello, World!"` | the text to print, wrapped in quotes |

```bash
echo ""
```

Prints an **empty line**. Great for spacing your output.

```bash
echo "My name is Deb"        # change this to YOUR name!
```

Everything after `#` is a comment, even on the same line as code.

---

## Part 2: pwd

```bash
pwd
```

Prints the **full path** of the folder the script is running in.

---

## Part 3: ls

```bash
ls
```

Lists files in the current folder.

```bash
ls -l
```

`-l` = **long format**. You see:

```
-rw-r--r-- 1 deb deb 1855 Oct 10 15:10 Code.sh
│          │ │   │   │    │            └ file name
│          │ │   │   │    └ last modified
│          │ │   │   └ size in bytes
│          │ │   └ group
│          │ └ owner
│          └ number of links
└ permissions (Lesson 8)
```

---

## Part 4: cd

```bash
cd ..
```

Go **up one folder**. Then `pwd` proves it worked.

```bash
cd ~
```

Go to your **home** folder.

```bash
cd -
```

Jump back to the **previous** folder you were in. It also prints that path. Think of it like the "back" button in a browser, but it only remembers one step.

> **Why doesn't my terminal move when the script ends?**
> A script runs in its own little copy of Bash. When it finishes, that copy disappears. Your real terminal never moved. This is normal and good.

---

## Part 5: Information commands

```bash
echo "Today is   : $(date)"
```

New idea: **`$( )`** means "run this command and put its output here."

| Command | Gives you |
|---------|-----------|
| `date` | current date and time |
| `whoami` | your username |
| `hostname` | your computer name |

```bash
echo "Bash version: $BASH_VERSION"
```

`$BASH_VERSION` is a **variable**: a named box that holds a value. Bash fills it in for you. (Variables get their own full lesson in Lesson 10.)

---

## Part 6: Your first automation

```bash
mkdir -p ~/bash-practice
```

| Piece | Meaning |
|-------|---------|
| `mkdir` | make a directory (folder) |
| `-p` | no error if it already exists; create parents if needed |
| `~/bash-practice` | the folder, inside your home |

Run the script **10 times**. It never complains, because of `-p`. That safety trick is a core idea in automation: **scripts should be safe to run again.**

```bash
ls -d ~/bash-practice
```

`-d` shows the folder itself instead of what is inside it.

---

## 🧪 Experiments (do these now!)

1. Change `"Deb"` to your name. Run again.
2. Add `echo "I love Bash"` at the bottom. Run again.
3. Delete one closing quote `"` from any echo. Run it. **Read the error.**
4. Put a `#` at the start of one line. Run it. That line vanishes.
5. Run `bash -x Code.sh`. The `-x` shows every command as it executes. This is a pro debugging trick you will use for life.

---

## ✅ New words in this file

`shebang` · `comment` · `echo` · `pwd` · `ls` · `cd` · `mkdir -p` · `$( )` · `variable`

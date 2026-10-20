# Lesson 9 — Your First Real Script

**Level 3 · Real Scripting · Time: ~60 minutes**

---

## 🎯 What you will learn

- What a script really is (and why it beats typing commands)
- The **shebang** line: `#!/usr/bin/env bash`
- Three ways to run a script, and how they differ
- Make a script run by **name** from anywhere (`PATH`)
- **Exit codes**: how scripts say "worked" or "failed"
- Debug tools: `bash -n`, `bash -x`, ShellCheck
- The Windows line-ending trap (CRLF)
- A clean **script template** to start every project

> Up to now you ran commands. From today you **write programs** that run them for you, forever.

---

## 1. What is a script?

A script is a **plain text file** of commands. Bash reads it from top to bottom and runs each line, exactly as if you typed it.

```bash
#!/usr/bin/env bash
echo "Starting backup..."
mkdir -p ~/backup
cp ~/notes.txt ~/backup/
echo "Done!"
```

Typing 4 commands every day is boring. **Save them once, run with one word.** This is the heart of automation.

---

## 2. Writing your first script

### Step 1: create the file

```bash
cd ~/bash-practice
nano hello.sh
```

`nano` is a beginner-friendly editor inside the terminal:

| Keys | Action |
|------|--------|
| type normally | edit text |
| `Ctrl + O`, `Enter` | **save** (write Out) |
| `Ctrl + X` | **exit** |
| `Ctrl + K` / `Ctrl + U` | cut line / paste line |

(Prefer VS Code? Use `code hello.sh`. Any plain-text editor works. Never use Word.)

### Step 2: type this

```bash
#!/usr/bin/env bash
# hello.sh - my first script
echo "Hello, $(whoami)!"
echo "Today is $(date +%A)"
```

### Step 3: run it

```bash
bash hello.sh
```

### Step 4: make it runnable like a program

```bash
chmod +x hello.sh
./hello.sh
```

You wrote and ran a program.

---

## 3. The shebang: line 1

```bash
#!/usr/bin/env bash
```

| Part | Meaning |
|------|---------|
| `#!` | "shebang" (hash-bang): tells the system *which program should run this file* |
| `/usr/bin/env bash` | "find `bash` wherever it is installed and use it" |

Two common forms:

| Line | When |
|------|------|
| `#!/usr/bin/env bash` | **recommended**: works on Linux, macOS, WSL, even if Bash lives in an odd place |
| `#!/bin/bash` | fine on most Linux systems; fixed path |

Rules: it must be **line 1**, with **no spaces before `#`**. Without a shebang, `./script.sh` may run in the wrong shell.

(The same idea runs Python: `#!/usr/bin/env python3`.)

---

## 4. Three ways to run a script

| Way | Command | Needs `x` bit? | Runs in |
|-----|---------|----------------|---------|
| 1 | `bash script.sh` | no | a **new** Bash (child) |
| 2 | `./script.sh` | **yes** | a **new** process (child) |
| 3 | `source script.sh` or `. script.sh` | no | **your current shell** |

The key difference: **a child process can't change its parent.**

```bash
# setvar.sh
MYVAR="hello"
cd /tmp
```

```bash
bash setvar.sh
echo "$MYVAR"        # (empty)   the variable died with the child
pwd                  # unchanged

source setvar.sh
echo "$MYVAR"        # hello     it ran HERE, so changes stay
pwd                  # /tmp
```

Use `source` for files that **set up your environment** (like `~/.bashrc`, or an activate script). Use `./script.sh` for normal tools.

Why `./`? Because the current folder is **not** in `PATH` (Lesson 4). `./` means "this exact folder."

---

## 5. Running by name: put it in `PATH`

```bash
mkdir -p ~/bin
cp hello.sh ~/bin/hello
chmod +x ~/bin/hello
```

Make sure `~/bin` is searched. Add to the bottom of `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

Reload (`source ~/.bashrc`) and now, from **any** folder:

```bash
hello
```

You've created your own command. Professionals keep a `~/bin` full of personal tools.

(Many systems already use `~/.local/bin`, so check `echo "$PATH"` first.)

---

## 6. Exit codes: how scripts report success

Every command ends with a number, its **exit code**:

| Code | Meaning |
|------|---------|
| `0` | success |
| `1` to `255` | some kind of failure |

```bash
ls /tmp
echo $?            # 0
ls /nonexistent
echo $?            # 2
```

`$?` = exit code of the **last** command.

In **your** scripts, use `exit`:

```bash
#!/usr/bin/env bash
echo "Something went wrong" >&2    # >&2 sends the message to stderr
exit 1                              # tell the caller: failure
```

`exit 0` (or just reaching the end) means success.

Why it matters: other tools and scripts **check** your exit code.

```bash
./backup.sh && echo "Backup OK"        # runs echo only if backup.sh exited 0
./backup.sh || echo "Backup FAILED"    # runs echo only if it failed
```

Common conventions: `1` general error · `2` misuse (bad arguments) · `126` found but not executable · `127` command not found · `130` stopped with Ctrl+C.

---

## 7. `&&`, `||` and `;`

```bash
mkdir demo && cd demo          # cd only if mkdir succeeded
cd demo || exit 1              # leave the script if cd failed  (you used this!)
echo "one"; echo "two"         # ; = just run both, regardless
```

---

## 8. Debugging: when it doesn't work

| Tool | Command | What it does |
|------|---------|--------------|
| Syntax check | `bash -n script.sh` | checks for typos **without running** |
| Trace mode | `bash -x script.sh` | prints every command (prefixed with `+`) as it runs |
| ShellCheck | `shellcheck script.sh` | expert linter: finds bugs and bad habits (install: `sudo apt install shellcheck`, or use shellcheck.net) |
| Prints | `echo "DEBUG: x=$x" >&2` | the oldest trick, still great |

Make `bash -x` a reflex. It shows exactly what Bash ran.

---

## 9. The Windows trap: CRLF line endings

Windows editors end lines with **CR+LF** (`\r\n`). Linux expects just **LF** (`\n`). A script with CRLF fails with confusing errors:

```
env: 'bash\r': No such file or directory
bash: $'\r': command not found
```

The invisible `\r` is stuck to your commands. Fixes:

```bash
sed -i.bak 's/\r$//' script.sh        # remove the \r characters
tr -d '\r' < script.sh > fixed.sh     # portable alternative
dos2unix script.sh                    # if installed
```

Prevent it: in VS Code, click `CRLF` in the bottom bar and switch to `LF`. In Git: `git config --global core.autocrlf input`.

---

## 10. A good script template

```bash
#!/usr/bin/env bash
#
# name.sh - one line saying what this script does
# Usage: ./name.sh
#

# --- settings ---------------------------------------------------
# (variables go here)

# --- main -------------------------------------------------------
echo "Start"

# ... your commands ...

echo "Done"
exit 0
```

Habits to copy:

1. **Shebang** first.
2. **Header comment**: what it does, how to use it.
3. **Sections** with comments.
4. **Explicit `exit 0`** at the end (and `exit 1` on errors).
5. **Messages for humans** with `echo`.

Naming: lowercase, hyphens or underscores, no spaces: `backup-photos.sh`. The `.sh` is optional but helps editors and humans.

---

## ⚠️ Gotchas

1. `Permission denied` → missing `chmod +x`.
2. `bad interpreter` or `\r` errors → CRLF line endings.
3. `command not found` on your own script → you forgot `./` or it isn't in `PATH`.
4. `source script.sh` changes **your** shell, including `exit`, which can **close your terminal**. Don't `source` scripts that call `exit`.
5. A script named `test` can clash with the built-in `test`. Pick unique names.
6. Spaces matter: `VAR = 5` is an error; `VAR=5` is right (Lesson 10).

---

## ✅ Summary

- A script = text file of commands; first line `#!/usr/bin/env bash`
- Run: `bash f.sh` · `./f.sh` (needs `chmod +x`) · `source f.sh` (runs in current shell)
- Put scripts in `~/bin` + `PATH` to run them by name
- Exit code `0` = success; `exit 1` = failure; `$?` reads it; `&&` / `||` react to it
- Debug: `bash -n`, `bash -x`, ShellCheck
- Beware Windows CRLF

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

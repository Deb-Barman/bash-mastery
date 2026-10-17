# Lesson 4 — Help Yourself

**Level 1 · Survival · Time: ~50 minutes**

---

## 🎯 What you will learn

- Read the built-in manuals (`man`, `--help`, `help`)
- Know **what kind of thing** a command is (`type`, `which`, `command -v`)
- Understand `PATH`: how Bash finds commands
- Use **history** and **Tab completion** to type 10x less
- Make shortcuts with **aliases**
- Read an error message calmly

> **This is the lesson that makes you independent.** Nobody memorizes every option, not even a 34-year expert. Experts know **how to look things up in 10 seconds**.

---

## 1. Three ways to get help

### 1) `--help`: the quick answer

```bash
ls --help
cp --help
grep --help
```

Short, fast, great for "what was that option again?" For long output, pipe it:

```bash
grep --help | less
```

### 2) `man`: the full manual

```bash
man ls
```

Inside `man` (it uses `less`, so the same keys):

| Key | Action |
|-----|--------|
| `Space` / `b` | next / previous page |
| `/word` | search for `word`, then `n` for next match |
| `q` | **quit** |

Parts of a man page: **NAME** (what it is) · **SYNOPSIS** (how to type it) · **DESCRIPTION** · **OPTIONS** · **EXAMPLES** (sometimes).

Search all manuals by topic:

```bash
man -k "copy files"       # same as: apropos "copy files"
whatis ls                 # one-line description
```

### 3) `help`: for Bash's *built-in* commands

Some commands (`cd`, `echo`, `type`...) live inside Bash itself and have no man page:

```bash
help cd
help          # list all builtins
```

> 💡 If `man` says "No manual entry", try `help name` or `name --help`.

---

## 2. Reading a SYNOPSIS (the secret code)

```
ls [OPTION]... [FILE]...
```

| Symbol | Meaning |
|--------|---------|
| `[ ]` | optional |
| `...` | can repeat |
| `A \| B` | choose one |
| `UPPERCASE` | replace with your own value |

So `ls` alone works, `ls -l` works, `ls -l Documents Downloads` works. You just decoded it.

---

## 3. What is this command? `type`, `which`, `command -v`

```bash
type cd          # cd is a shell builtin
type ls          # ls is /usr/bin/ls
type -a echo     # show ALL matches (builtin AND program)
which bash       # /usr/bin/bash
command -v git   # path if it exists; prints nothing if not
```

Four kinds of commands:

| Kind | Example | Meaning |
|------|---------|---------|
| **builtin** | `cd`, `echo` | part of Bash itself |
| **program** | `ls`, `grep` | a file somewhere on disk |
| **alias** | `ll` | your own shortcut |
| **function** | (Lesson 14) | your own mini-program |

**Pro habit:** in scripts, check that a tool exists with `command -v tool`, not `which`. `which` differs between systems.

---

## 4. `PATH`: how Bash finds programs

```bash
echo "$PATH"
```

You'll see folders separated by `:` like `/usr/local/bin:/usr/bin:/bin`.

When you type `grep`, Bash looks in each of those folders, **in order**, for a file named `grep`. First match wins. If none: `command not found`.

```bash
echo "$PATH" | tr ':' '\n'      # one folder per line (readable!)
```

**Why this matters:** your own scripts live outside `PATH`, so you run them as `./myscript.sh` (the `./` says "this folder, exactly"). Later you'll add your own folder to `PATH`.

---

## 5. Tab completion: type less, make fewer mistakes

| You type | Press `Tab` | Result |
|----------|-------------|--------|
| `cd Doc` | once | `cd Documents/` |
| `ec` | twice | lists all commands starting with `ec` |
| `git ch` | once or twice | suggests `checkout`, `cherry-pick`... (if git completion is installed) |

If nothing happens, press `Tab` **twice** to see the options. If still nothing, there is no match, so check spelling.

---

## 6. History: never retype a long command

```bash
history              # numbered list of past commands
history | tail -n 5  # the last five
history | grep "find"
```

Fast ways to reuse:

| Shortcut | Does |
|----------|------|
| `↑` / `↓` | walk through old commands |
| `Ctrl + R` | **search** history: type a few letters, `Enter` to run, `→` to edit |
| `!!` | repeat the **last** command |
| `!42` | run command number 42 from `history` |
| `sudo !!` | last command again, with `sudo` (pros love it) |
| `!$` | the **last word** of the previous command |

Example:

```bash
mkdir ~/bash-practice/new-project
cd !$                 # cd ~/bash-practice/new-project
```

---

## 7. Aliases: your own shortcuts

```bash
alias ll='ls -lah'
alias ..='cd ..'
alias gs='git status'
```

Now `ll` runs `ls -lah`. To list or remove:

```bash
alias              # show all
unalias ll
```

Aliases set this way vanish when you close the terminal. To **keep them**, put the same `alias` lines at the bottom of `~/.bashrc`, then run:

```bash
source ~/.bashrc
```

(You'll understand startup files fully in later lessons. For now: `~/.bashrc` is Bash's personal settings file.)

---

## 8. Reading error messages (superpower)

Errors follow a pattern: **who** said it, **what** went wrong.

```
bash: lss: command not found
```
→ Bash couldn't find `lss`. Typo? (`ls`)

```
cat: notes.txt: No such file or directory
```
→ `cat` can't find the file. Check `pwd` and `ls`.

```
rm: cannot remove 'docs': Is a directory
```
→ it's a folder: use `rm -r` (carefully!) or `rmdir`.

```
bash: ./script.sh: Permission denied
```
→ not executable yet (Lesson 8/9).

**Method:** read the message → find the **file/command name** in it → check spelling, path, then spaces and quotes. 90% of errors are typos.

---

## 9. When you are really stuck

1. Run `command --help` or `man command`.
2. Paste the command into **explainshell.com**.
3. Search the exact error message in quotes.
4. Ask Claude: paste the command **and** the complete error.
5. Minimize: make the smallest example that still fails.

---

## ✅ Summary

- `--help` (quick), `man` (full), `help` (builtins)
- `type` / `command -v` tell you what a command is and where it lives
- `PATH` is the list of folders Bash searches for programs
- `Tab`, `↑`, `Ctrl+R`, `!!`, `!$` make you fast
- `alias` makes shortcuts; `~/.bashrc` keeps them forever
- Errors are clues, not insults

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

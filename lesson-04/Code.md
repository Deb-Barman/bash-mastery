# Lesson 4 — Code Explained (line by line)

This file explains `Code.sh`. Keep both open side by side.

**Run it:**

```bash
bash Code.sh
```

This script only **reads** information. It creates and deletes nothing, so it's 100% safe.

> Your output will differ from mine: your `PATH`, command count, and whether `git` or `man` exist depend on your computer. That is expected and a good thing to compare.

---

## Part 1: `--help`

```bash
ls --help | head -n 5
```

`ls --help` prints a long help text. `| head -n 5` keeps only the first 5 lines so the demo stays short. Remove the pipe to see everything.

---

## Part 2: `help` for builtins

```bash
help cd | head -n 4
```

`cd` is a **builtin** (part of Bash), so `man cd` often finds nothing useful, but `help cd` always works.

---

## Part 3: man, with a safety check

```bash
if command -v man > /dev/null 2>&1; then
```

Plain English: **"If the command `man` exists..."**

| Piece | Meaning |
|-------|---------|
| `command -v man` | prints the path of `man` if it exists; fails if not |
| `> /dev/null` | throw away normal output (we only need success/fail) |
| `2>&1` | send error messages the same way (also thrown away) |

```bash
MAN_TEXT=$(man ls 2> /dev/null | col -b 2> /dev/null | head -n 6)
```

- `man ls` prints the manual for `ls`
- `col -b` removes the bold/underline formatting characters so plain text remains
- `head -n 6` keeps six lines
- `$( ... )` captures the result **into the variable** `MAN_TEXT`

```bash
if [ -n "$MAN_TEXT" ]; then
```

`-n` means **"is not empty"**. So: *if we captured some text, print it; otherwise explain that manual pages aren't installed.* This is **defensive scripting**: the script handles the "tool missing" case gracefully instead of crashing or printing nothing.

> Real man pages begin with a NAME section like `ls - list directory contents`. In your live terminal, just type `man ls`.

---

## Part 4: `type` and `which`

```bash
type cd          # cd is a shell builtin
type ls          # ls is /usr/bin/ls
type -a echo     # echo exists TWICE: builtin and a program
which bash       # the path of bash
```

Why does `echo` exist twice? Bash has its own built-in version (fast), and the system has a separate program too. When you type `echo`, **the builtin wins**. `type -a` reveals all candidates. This is a great tool when "the wrong version" of something runs.

---

## Part 5: `command -v` in scripts

```bash
if command -v git > /dev/null 2>&1; then
    echo "git is installed at: $(command -v git)"
else
    echo "git is NOT installed"
fi
```

This is the **standard way to check for a tool** at the start of a real script ("I need `git` and `curl`, are they here?"). The second check uses a made-up tool name to show the `else` branch.

`if`/`then`/`else`/`fi` get their full lesson in Lesson 12. For now read it as English.

---

## Part 6: PATH

```bash
echo "$PATH"
```

All folders Bash searches, separated by `:`.

```bash
echo "$PATH" | tr ':' '\n'
```

`tr` **translates characters**. Here it swaps every `:` for a new line (`\n`), giving one folder per line. (More `tr` in Lesson 7.)

```bash
compgen -c | sort -u | wc -l
```

| Piece | Meaning |
|-------|---------|
| `compgen -c` | list every command Bash can run (programs, builtins, aliases) |
| `sort -u` | sort and remove duplicates |
| `wc -l` | count lines |

A three-command pipe that answers: *"How many commands do I have?"* (Usually 1,000+. You now know 20 of them. 😄)

---

## Part 7: alias

```bash
shopt -s expand_aliases
alias ll='ls -l'
type ll
```

- By default, aliases are **turned off inside scripts**, because they're designed for typing at the terminal. `shopt -s expand_aliases` switches them on for this demo.
- `type ll` reports: `ll is aliased to 'ls -l'`.
- **In real life** you add alias lines to `~/.bashrc`, not to scripts. In scripts, use **functions** instead (Lesson 14).

---

## Part 8: history

```bash
echo "Try these there:  history | tail -n 5   |   Ctrl+R   |   !!   |   !\$"
```

History is a feature of the **interactive** terminal. A script has no history. The `\$` stops Bash from treating `$` as the start of a variable and prints a real dollar sign. (Escaping gets full coverage in Lesson 10.)

---

## Part 9: errors are clues

```bash
bash -c 'lss' 2>&1
```

`bash -c 'text'` runs text as a command in a mini Bash. We run a typo (`lss`) on purpose.

Read the message: `bash: line 1: lss: command not found`

| Part | Meaning |
|------|---------|
| `bash:` | who is complaining |
| `line 1:` | where |
| `lss` | the thing it can't find |
| `command not found` | what's wrong |

```bash
cat no-such-file.txt 2>&1
```

→ `cat: no-such-file.txt: No such file or directory`: *cat* is complaining, about *that file*.

```bash
ls --banana 2>&1 | head -n 2
```

→ `ls: unrecognized option '--banana'` followed by a hint to try `ls --help`. Good programs tell you where to look next. **Always read the last line of an error.**

`2>&1` here makes sure error messages travel through the same channel as normal output so `head` can trim them. Lesson 5 explains channels fully.

---

## 🧪 Experiments

1. Run `man grep` in your terminal. Press `/recursive`, then `n` a few times, then `q`.
2. Run `type -a ls`. Is `ls` also an alias on your machine? (Many systems alias it to add colors.)
3. Change `git` in Part 5 to `python3`, `curl`, `jq`, `node`. Which ones are installed?
4. In your terminal, run `alias ll='ls -lah'`, then use `ll`. Close the terminal and try again. (It's gone!)
5. Press `Ctrl+R`, type `grep`, and watch Bash find your last grep command.
6. Run `echo "$PATH" | tr ':' '\n' | wc -l` to count your PATH folders.

---

## ✅ New words in this file

`--help` · `help` · `man` · `col -b` · `type -a` · `which` · `command -v` · `$PATH` · `tr` · `compgen -c` · `sort -u` · `alias` · `shopt -s expand_aliases` · `bash -c` · `[ -n "$var" ]` · `2>&1`

# Lesson 4 — Resources

## 📋 Cheat Sheet

| Goal | Command |
|------|---------|
| Quick help | `command --help` |
| Full manual | `man command` |
| Help for builtins (`cd`, `echo`...) | `help cd` |
| Search manuals by topic | `man -k "keyword"` or `apropos keyword` |
| One-line description | `whatis ls` |
| What kind of command is it? | `type cmd` · `type -a cmd` |
| Where is the program? | `which cmd` · `command -v cmd` |
| Show PATH nicely | `echo "$PATH" \| tr ':' '\n'` |
| List past commands | `history` |
| Search past commands | `Ctrl + R` |
| Repeat last command | `!!` |
| Last word of previous command | `!$` |
| Last command with sudo | `sudo !!` |
| Make a shortcut | `alias ll='ls -lah'` |
| Remove a shortcut | `unalias ll` |
| Reload settings file | `source ~/.bashrc` |

**`man` keys:** `Space` next · `b` back · `/word` search · `n` next match · `q` quit

**SYNOPSIS symbols:** `[ ]` optional · `...` repeatable · `A | B` choose one · `UPPERCASE` your value

**Error reading:** who complained → what it complained about → what's wrong. Check the **last line** first.

---

## 🏋️ Exercises

**Level A: Easy**
1. Show the quick help for `mkdir`.
2. Find out whether `cd` is a builtin or a program.
3. Print the full path of the `bash` program.
4. Show your `PATH`, one folder per line.

**Level B: Medium**
5. In `ls --help`, find which option sorts by **size**. (Use a pipe and `grep`.)
6. Check whether `curl` is installed. Print "yes" or "no". (Use `command -v`.)
7. Show how many commands you have used so far in this terminal session (`history` plus a count).
8. Create the alias `la` for `ls -A`. Prove it exists with `type la`.
9. List all of your aliases, then remove `la`.

**Level C: Challenge**
10. Using `man` or `--help`, find the option that makes `rm` print what it deletes. Then use it on a file you make in `~/bash-practice`.
11. Write a one-line check that prints `python3 found: <path>` if Python 3 is installed, otherwise `python3 missing`.
12. Count how many folders are in your `PATH`.
13. Use `Ctrl+R` to find the last `grep` command you ran. (Describe the keys you pressed.)
14. (Think!) A friend says `ls` "doesn't work the same" on their computer. Name two commands that would help you investigate.

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
mkdir --help

# 2
type cd                      # "cd is a shell builtin"

# 3
which bash                   # or: command -v bash

# 4
echo "$PATH" | tr ':' '\n'

# 5
ls --help | grep -i "size"   # shows -S (sort by file size) among others

# 6
if command -v curl > /dev/null 2>&1; then echo "yes"; else echo "no"; fi

# 7
history | wc -l

# 8
alias la='ls -A'
type la                      # la is aliased to `ls -A'

# 9
alias                        # list all
unalias la

# 10
rm --help | grep -i "verbose"    # -v, --verbose
touch ~/bash-practice/demo.txt
rm -v ~/bash-practice/demo.txt   # prints: removed '.../demo.txt'

# 11
if command -v python3 > /dev/null 2>&1; then echo "python3 found: $(command -v python3)"; else echo "python3 missing"; fi

# 12
echo "$PATH" | tr ':' '\n' | wc -l

# 13
# Press Ctrl+R, type: grep   -> the latest matching command appears.
# Enter runs it. Right-arrow (or Esc) lets you edit it first. Ctrl+R again
# jumps to the next older match. Ctrl+C cancels.

# 14
type -a ls          # is it an alias? where is it?
ls --version        # which version (GNU vs BSD/macOS)? or: man ls
```

</details>

---

## 🐞 Common beginner errors

| Problem | Cause | Fix |
|---------|-------|-----|
| `No manual entry for cd` | `cd` is a builtin | `help cd` |
| `man` shows nothing / not found | man pages not installed (minimal systems, Git Bash) | `sudo apt install man-db manpages`, or use `--help` / `tldr` |
| `alias` vanished after closing terminal | aliases live in memory only | add to `~/.bashrc`, then `source ~/.bashrc` |
| `!!` prints `event not found` style errors | history expansion only works in interactive terminals | use it in the live terminal, not scripts |
| Stuck inside `man` | it's a pager like `less` | press `q` |
| `which` says nothing | not installed, or it is a builtin/alias | use `type name` |
| `./script.sh: No such file` | forgot `./` or wrong folder | `pwd`, `ls`, then `./script.sh` |

---

## 💡 Habits of pro coders

1. **Look it up in 10 seconds** (`--help`, `man`, `/search`) instead of guessing.
2. **`command -v` check** at the top of every script that needs outside tools.
3. **Use `Ctrl+R`** all day. It's the biggest typing saver.
4. **Pipe long help into `less`** or `grep` for the option you need.
5. **Keep your aliases in `~/.bashrc`** and back that file up.

## 📚 Extra resources

- **explainshell.com:** paste any command, get every part explained
- **tldr.sh:** short, practical examples (`tldr tar`). Install with `npm i -g tldr` or `pip install tldr`
- **cheat.sh:** `curl cheat.sh/tar` shows quick examples right in the terminal
- **man7.org/linux/man-pages:** manuals in your browser
- **Bash Reference Manual:** gnu.org/software/bash/manual

## 🧠 Self-check

1. When do you use `man` and when `help`?
2. How does Bash find the command you typed?
3. Why can the same name (like `echo`) exist twice, and which wins?
4. Why do aliases vanish, and how do you keep them?
5. What are the first things to check when you see `command not found`?

## ➡️ Next: Lesson 5 — Pipes & Redirection (`|`, `>`, `>>`, `<`, `2>`, `2>&1`, `/dev/null`, `tee`)

> 🎉 **Level 1 complete!** You can move around, manage files, read and find things, and teach yourself. Level 2 starts the real power.

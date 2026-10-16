# 🐚 BASH: From Zero to Claude-Level

> Goal: Automate anything on a computer with a few lines of Bash — no manual work.

## How every lesson is delivered

| File | What it is |
|------|-----------|
| `Lesson-N.md` | The teaching: concepts, explained simply |
| `Code.md` | Every command explained line by line |
| `Code.sh` | The real script. Run it, break it, change it |
| `Resources.md` | Cheat sheet, exercises, answers, extra reading |

**Rule:** Never just read. Type every command yourself. Muscle memory is the real teacher.

---

## The Roadmap (6 Levels, 24 Lessons)

### 🟢 LEVEL 1 — Survival (You can move around)
1. **What is Bash? The terminal, your first commands** (`echo`, `pwd`, `ls`, `cd`, `clear`)
2. **Files & folders** (`mkdir`, `touch`, `cp`, `mv`, `rm`, `cat`)
3. **Reading & finding** (`less`, `head`, `tail`, `find`, `grep`, `wc`)
4. **Help yourself** (`man`, `--help`, `tldr`, `type`, `which`, tab completion, history)

### 🟡 LEVEL 2 — Power Tools (You can combine things)
5. **Pipes `|` and redirection `>` `>>` `<`**
6. **Wildcards & globbing** (`*`, `?`, `[a-z]`, `{a,b}`)
7. **Text tools** (`sort`, `uniq`, `cut`, `tr`, `sed`, `awk` basics)
8. **Permissions & users** (`chmod`, `chown`, `sudo`, `ls -l`)

### 🟠 LEVEL 3 — Real Scripting (You can write programs)
9. **Your first script** (shebang, `chmod +x`, running)
10. **Variables & quoting** (`"$var"`, `${var}`, `$(command)`)
11. **User input & arguments** (`read`, `$1`, `$@`, `$#`)
12. **Conditions** (`if`, `[[ ]]`, `case`, exit codes `$?`)
13. **Loops** (`for`, `while`, `until`, `break`, `continue`)
14. **Functions** (`local`, return values, reusable code)

### 🔴 LEVEL 4 — Professional (You write safe, clean code)
15. **Arrays & associative arrays**
16. **String manipulation** (`${var#}`, `${var%}`, `${var//}`)
17. **Error handling** (`set -euo pipefail`, `trap`, logging)
18. **Argument parsing** (`getopts`, `--flags`, usage messages)
19. **Regular expressions** (`grep -E`, `[[ =~ ]]`, `sed -E`)

### 🟣 LEVEL 5 — Automation (You stop doing manual work)
20. **Processes & jobs** (`&`, `jobs`, `kill`, `nohup`, `wait`, parallel work)
21. **Scheduling** (`cron`, `at`, `systemd timers`)
22. **Networking & APIs** (`curl`, `wget`, `jq`, `ssh`, `scp`, `rsync`)

### ⚫ LEVEL 6 — Claude Level (You build real tools)
23. **Real projects:** backup system, log analyzer, git auto-deployer, project scaffolder
24. **Mastery:** debugging (`set -x`, `shellcheck`), performance, style guide, testing with `bats`

---

## Your Learning Rules

1. **One lesson per day** is perfect. Two if you're excited.
2. **Do the exercises** in `Resources.md` before checking answers.
3. **Break things on purpose.** Delete a quote, remove a space, see the error. Errors are lessons.
4. **Keep a practice folder:** `~/bash-practice` — never practice in important folders.
5. **Stuck?** Read the error message *slowly*. Bash usually tells you exactly what's wrong.

## What you need

- **Linux / macOS:** open the Terminal app. Done.
- **Windows:** install **WSL** (`wsl --install` in PowerShell) or use **Git Bash**.
- **Phone:** Termux (Android) works for most lessons.
- A text editor: **VS Code**, or the terminal editor `nano` (easiest).

---

*Start with `lesson-01/Lesson-1.md` →*

---

## ✅ Status: all 24 lessons are included in this folder

See `README.md` for the index, how to study, and the requirements.

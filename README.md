# 🐚 Bash Course: From Zero to Claude Level

24 lessons. Every lesson has the same four files:

| File | What it is |
|------|-----------|
| `Lesson-N.md` | the teaching: concepts, examples, gotchas |
| `Code.md` | every part of the script explained, plus experiments |
| `Code.sh` | the real, runnable script (safe: works in its own demo folder and cleans up) |
| `Resources.md` | cheat sheet, exercises, answers, common errors, habits, extra reading |

Start with **`LESSON.md`** (the roadmap), then follow the lessons in order.

---

## How to study (the loop that works)

1. **Read** `Lesson-N.md` (30 to 40 minutes). Type the examples yourself in a terminal.
2. **Run** `bash Code.sh` and compare the output with `Code.md`.
3. **Break it:** do the experiments at the end of `Code.md`.
4. **Do** the exercises in `Resources.md` **before** opening the answers.
5. **Next day:** redo two exercises from memory.

Practice inside `~/bash-practice`. Never practice on your important folders.

---

## The lessons

### 🟢 Level 1: Survival
| # | Lesson |
|---|--------|
| 1 | Meet Bash: `echo`, `pwd`, `ls`, `cd` |
| 2 | Files & folders: `mkdir`, `touch`, `cp`, `mv`, `rm`, `cat` |
| 3 | Reading & finding: `less`, `head`, `tail`, `wc`, `find`, `grep` |
| 4 | Help yourself: `man`, `--help`, `type`, `PATH`, history, aliases |

### 🟡 Level 2: Power Tools
| # | Lesson |
|---|--------|
| 5 | Pipes & redirection |
| 6 | Wildcards & globbing, brace expansion |
| 7 | Text tools: `sort`, `uniq`, `cut`, `tr`, `sed`, `awk` |
| 8 | Permissions & users: `chmod`, `chown`, `sudo`, `umask` |

### 🟠 Level 3: Real Scripting
| # | Lesson |
|---|--------|
| 9 | Your first script: shebang, running, exit codes |
| 10 | Variables & quoting |
| 11 | User input & arguments |
| 12 | Conditions: `if`, `[[ ]]`, `case` |
| 13 | Loops: `for`, `while`, `until` |
| 14 | Functions |

### 🔴 Level 4: Professional
| # | Lesson |
|---|--------|
| 15 | Arrays & associative arrays |
| 16 | String manipulation |
| 17 | Error handling: `set -euo pipefail`, `trap` |
| 18 | Argument parsing: `getopts`, `--long` options, subcommands |
| 19 | Regular expressions |

### 🟣 Level 5: Automation
| # | Lesson |
|---|--------|
| 20 | Processes & jobs: background, `wait`, parallel work |
| 21 | Scheduling: cron, systemd timers, locking |
| 22 | Networking & APIs: `curl`, `jq`, `ssh`, `rsync` |

### ⚫ Level 6: Claude Level
| # | Lesson |
|---|--------|
| 23 | Real projects: backup, log analyzer, organizer, scaffolder, deployer |
| 24 | Mastery: debugging, speed, portability, testing, security, style |

---

## Requirements

- **Linux, WSL, or macOS** with Bash. Lessons 1 to 14 work with any Bash; Lessons 15 to 24 want **Bash 4+** (macOS ships 3.2: `brew install bash`).
- Some scripts use GNU tools (`stat -c`, `date -d`, `touch -d`). On macOS: `brew install coreutils gnu-sed grep`.
- Optional but recommended: `shellcheck`, `jq`, `bats`, `git`, `curl`, `python3`.

Check your version: `bash --version`.

## Running a lesson

```bash
cd lesson-10
bash Code.sh          # always run with bash, not sh
```

Every `Code.sh` writes only inside `~/bash-practice/lessonNN-demo` and removes it at the end (Lesson 22 also starts and stops a tiny local web server on 127.0.0.1; Lesson 21 never touches your real crontab).

To **keep** the files a demo creates (for example the tools from Lesson 23), comment out the `rm -r "$DEMO"` line near the bottom.

---

*Built to take you from "I don't know a single line of Bash" to writing, testing and shipping real tools. Keep one rule: automate something every week.* 🎓

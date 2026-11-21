# Lesson 23 — Real Projects

**Level 6 · Claude Level · Time: ~120 minutes (take your time, this is the capstone)**

---

## 🎯 What you will do

Build and run **five real tools** from scratch, using everything from Lessons 1 to 22:

| # | Tool | What it does | Skills used |
|---|------|--------------|-------------|
| 1 | `backup.sh` | archive a folder, **verify** it, keep only the newest N | `getopts`, `tar`, `mktemp`, `trap`, dry-run, rotation |
| 2 | `logsum.sh` | summarize a web server log | `awk`, `sort` + `uniq -c`, pipelines |
| 3 | `organize.sh` | sort a messy folder by file type | `case`, functions, string expansion, name-clash safety |
| 4 | `newproject.sh` | create a project skeleton + git repository | here-documents, validation, `git` |
| 5 | `deploy.sh` | clone/update a checkout, run a build hook | `git`, exit codes, subshells |

> You can't learn to build by reading. **Run `Code.sh`, then read the generated tools, then change them.**

The full code is in **`Code.sh`** (it writes each tool to a file, runs it on sample data, and shows the output). To keep the tools afterwards, comment out the three CLEANUP lines at the bottom.

---

## 1. How professionals build a tool (the 8-step method)

1. **Problem:** one sentence. "Keep my project folder safely backed up, but don't fill the disk."
2. **Interface first:** write the **usage message** before any code. What arguments? What options? What does `-h` print?
3. **Steps on paper:** a list of what must happen, in order.
4. **Skeleton:** shebang, `set -euo pipefail`, `usage`, `die`, `log`, argument parsing.
5. **Safe core:** build the logic with a **dry-run** switch from the beginning. Destructive steps go through a `run` wrapper.
6. **Test on a sandbox:** make fake data. Never test destructive code on real files first.
7. **Edge cases:** missing arguments, bad input, empty folders, names with spaces, running twice, name clashes.
8. **Document & polish:** header comment, `--help`, README, `shellcheck`.

This lesson follows the method for every tool.

---

## 2. Project 1: `backup.sh`

**Usage:** `backup.sh [-n] [-k KEEP] [-d DEST] SRC`

**Design decisions** (each one is a lesson you learned):

| Decision | Why |
|----------|-----|
| archive name = `NAME-YYYYmmdd-HHMMSS.tar.gz` | sorts alphabetically = by time, so rotation needs no date math |
| write to a **temp file** (`mktemp`) then `mv` | the archive appears **only when complete** (atomic); a crash can't leave a corrupt backup |
| `trap 'rm -f "$tmp"' EXIT` | cleans up the temp file on any failure |
| `tar -tzf` after creating | **verify** that the archive can be read |
| rotation with an array: `backups=( "$dest/$name"-*.tar.gz )` and `${backups[@]:0:excess}` | the oldest `excess` entries are deleted |
| `run` wrapper | `-n` prints instead of acting, so you can preview |
| validation: `-k` must be a whole number ≥ 1 | `-k 0` would delete **every** backup |

**Key idea, the rotation arithmetic:**

```bash
excess=$(( ${#backups[@]} - keep ))        # e.g. 4 files, keep 2 → delete the 2 oldest
for old in "${backups[@]:0:excess}"; do run rm -v -- "$old"; done
```

**Try:** `backup.sh -n ~/Documents` (dry run), then run it for real, then run it several times.

---

## 3. Project 2: `logsum.sh`

**Usage:** `logsum.sh LOGFILE`

A web log line (common format):

```
192.168.1.10 - - [10/Oct/2026:09:15:01 +0000] "GET /index.html HTTP/1.1" 200 1024
$1                $4                           $6    $7          $8        $9  $10
(ip)             (time)                       (method)(path)             (status)(bytes)
```

Every report is one pipeline you already know:

| Question | Pipeline |
|----------|----------|
| how many requests? | `wc -l < file` |
| bytes served? | `awk '{s += $10} END {print s}'` |
| status codes? | `awk '{print $9}' \| sort \| uniq -c \| sort -rn` |
| top visitors? | `awk '{print $1}' \| sort \| uniq -c \| sort -rn \| head -3` |
| requests per hour? | `awk '{h = substr($4, 14, 2); c[h]++} END {for (k in c) print k, c[k]}' \| sort` |
| 404 pages? | `awk '$9 == 404 {print $7}' \| sort \| uniq -c \| sort -rn` |

**The lesson:** most "analysis" tools are a sentence in `awk` plus `sort | uniq -c | sort -rn`. Replace the log format and you can analyze anything.

---

## 4. Project 3: `organize.sh`

**Usage:** `organize.sh [-n] DIR`

Design points:

- **`category()` function** with a `case` on `${1,,}` (lowercased extension), so `PNG` and `png` both work, and adding a type is one line
- **name clash safety:** if `Documents/notes.txt` exists, the newcomer becomes `notes-1.txt`, then `-2` ...
  ```bash
  while [[ -e $target/$newname ]]; do newname="$stem-$n$suffix"; n=$(( n + 1 )); done
  ```
- **files without extension** (`README`) go to `Other`; hidden files (`.bashrc`) are treated as having no extension
- **never touch folders** (`[[ -f $file ]] || continue`)
- **dry-run first:** `-n` prints every move without doing it
- `shopt -s nullglob` so an empty folder doesn't loop over a literal `*`

⚠️ **A famous trap you can see in the code:** with `set -e`, writing `(( moved++ ))` when `moved` is 0 returns status 1 and **kills the script**. The tool uses `moved=$(( moved + 1 ))` (Lesson 17).

---

## 5. Project 4: `newproject.sh`

**Usage:** `newproject.sh [-t bash|python] NAME`

- validates the name with a regex (Lesson 19): `^[A-Za-z0-9._-]+$`
- refuses to overwrite: `[[ ! -e $name ]]`
- builds the tree in one command: `mkdir -p "$name"/{src,tests,docs}`
- writes files with here-documents (quoted `'SH'` for scripts that must stay as-is, unquoted `MD` where `$name` should be filled in)
- the generated Bash project already has strict mode, a `main` function and a **test**
- `git init`, `git add .`, and a first commit, only if git exists
- **uses `git -c user.name=… -c user.email=…`** so it works even on a computer where git has no identity configured

**Idea for you:** add `-t node` or a `LICENSE` file, or read templates from `~/.config/newproject/`.

---

## 6. Project 5: `deploy.sh`

**Usage:** `deploy.sh REPO TARGET`

A pull-based deployment, in 20 lines:

1. `TARGET` has no checkout? → `git clone`
2. Otherwise → `git pull --ff-only` (fast-forward only: **refuses** to create merge commits or overwrite local edits on the server)
3. Compare the commit hash **before and after**; if different, show `git diff --stat`
4. If the repository has an executable `build.sh`, run it **in a subshell** `( cd "$target" && ./build.sh )` so your working directory doesn't change

The demo builds a complete local setup: a bare "origin" repository, a developer clone that pushes versions 1 and 2, and a "production" folder that deploys each. Run it with cron (Lesson 21) every 5 minutes and you have a poor man's continuous deployment.

---

## 7. What these tools have in common (the professional checklist)

| ✔ | Habit |
|---|-------|
| ✔ | `#!/usr/bin/env bash` + `set -euo pipefail` |
| ✔ | `usage()` and `-h`; errors to stderr; exit `2` for bad usage |
| ✔ | validate every input before acting |
| ✔ | **dry-run** for anything destructive |
| ✔ | never overwrite silently (clash handling, `[[ ! -e ]]`) |
| ✔ | temp files via `mktemp` + `trap` cleanup; atomic `mv` |
| ✔ | quoted variables, `--` before file names, `nullglob` |
| ✔ | run twice safely (idempotent) |
| ✔ | tested on sandbox data first |
| ✔ | readable: functions with one job, comments saying *why* |

---

## 8. Your capstone challenge

Build **one** tool of your own, from this list (or invent one), following the 8-step method:

1. **`cleanup-downloads.sh`**: delete files older than N days from a folder, with dry-run and a log
2. **`photo-renamer.sh`**: rename photos to `YYYY-MM-DD_HHMMSS.ext` using the file's modification date
3. **`disk-watch.sh`**: warn (email/ntfy/log) when any filesystem is above 85 %; schedule it with cron
4. **`site-check.sh`**: check a list of URLs in parallel, report status and response time
5. **`todo.sh`**: a command-line to-do list with `add`, `list`, `done`, stored in a file
6. **`dotfiles-install.sh`**: symlink your config files into `$HOME`, backing up what's already there
7. **`csv-report.sh`**: turn a CSV into a summary (totals per category) with `awk`
8. **`git-status-all.sh`**: scan `~/projects` and report repositories with uncommitted changes

Details and hints are in **`Resources.md`**.

---

## ✅ Summary

- A real tool = **interface first**, safe core with **dry-run**, **sandbox testing**, edge cases, documentation
- Backups: temp file → verify → atomic move → rotate
- Analysis: `awk` + `sort | uniq -c | sort -rn`
- Organizers: `case`, clash-safe names, dry-run
- Scaffolders: validation + here-documents + git
- Deployers: `git pull --ff-only`, compare hashes, build hook in a subshell

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, read the generated tools, then try the capstone in **`Resources.md`**.

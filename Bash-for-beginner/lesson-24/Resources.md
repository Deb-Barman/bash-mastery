# Lesson 24 — Resources

## 📋 Cheat Sheet

**Debugging**

| Tool | Command |
|------|---------|
| syntax | `bash -n f.sh` |
| trace | `bash -x f.sh` · `set -x` / `set +x` |
| rich trace | `PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '` (set inside the script) |
| inspect | `declare -p var` · `printf '[%s]\n' "$var"` |
| failing line | `trap 'echo "line $LINENO: $BASH_COMMAND" >&2' ERR` (+ `set -E`) |
| call stack | `FUNCNAME` · `BASH_LINENO` · `caller` |
| lint | `shellcheck f.sh` · `# shellcheck disable=SC2086` |

**Fast vs slow**

| Slow | Fast |
|------|------|
| `$(basename "$p")` | `${p##*/}` |
| `$(dirname "$p")` | `${p%/*}` |
| `$(expr …)` | `$(( … ))` |
| `$(date +%s)` in loops | `printf '%(%s)T' -1` |
| `\| tr a-z A-Z` | `${s^^}` |
| `cat f \| grep x` | `grep x f` |
| Bash loop over big files | `awk` / `sed` / `sort` |
| `sort` on text | `LC_ALL=C sort` |
| measuring | `time cmd` · `${EPOCHREALTIME/./}` (µs) · `$SECONDS` |

**Portability**

- `#!/bin/sh` = POSIX only; test with `dash script.sh`, lint with `shellcheck -s sh`
- bashisms: `[[ ]]` arrays `(( ))` `<<<` `<( )` `${x^^}` `{1..5}` `source` `&>`
- macOS: Bash 3.2 · `sed -i ''` (or `-i.bak`) · `date -v` · `stat -f` · no `grep -P` · `brew install coreutils gnu-sed grep bash`
- detect: `date --version` · `command -v tool` · `(( BASH_VERSINFO[0] >= 4 ))`

**Testing**

```bash
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi     # main guard
assert_eq() { [[ $2 == "$3" ]] && echo "PASS $1" || { echo "FAIL $1: [$2] vs [$3]"; return 1; }; }
```
`bats test/` · `@test "name" { run cmd; [ "$status" -eq 0 ]; [ "$output" = "x" ]; }`

**Security quick list:** quote everything · `--` and `./*` · no `eval` on input · `mktemp` · `umask 077` · secrets not in arguments · whitelist-validate input · fixed `PATH` in privileged scripts · verify downloads · least privilege

**Style quick list:** `#!/usr/bin/env bash` · `set -euo pipefail` · `[[ ]]` · `$( )` · `local` · `main "$@"` · `printf` · comments explain *why* · ~300 lines max, then rethink

**Install:** `install -D -m 755 bin/tool "$PREFIX/bin/tool"`

---

## 🏋️ Exercises

Work in `~/bash-practice/ex24`.

**Level A: Easy**
1. Write a 5-line script with a deliberate bug (use an undefined variable). Find it with `bash -x`, then with `set -u`.
2. Make `bash -x` print `file:line:function` for every command in one of your scripts.
3. Time `basename` vs `${p##*/}` for 300 iterations using `time`.
4. Run a Bash-only script (`[[ ]]`) with `sh` and explain the error.

**Level B: Medium**
5. Add the **main guard** to one of your scripts, then `source` it in the terminal and call one of its functions.
6. Write `assert_eq` and 4 tests for a function `is_even`.
7. Write an `ERR` trap that prints a stack trace for a 3-level function call that fails.
8. Fix this script's security problems: `rm -rf $dir/*` · `eval "$cmd"` · `tmp=/tmp/work.$$` · `cat $1`
9. Write a `lint` rule that flags the use of `eval` in a script and run it on a file.
10. Write a `Makefile` (or a `Makefile`-like shell script) with targets `test`, `lint`, `install`.

**Level C: Graduation projects (choose at least one)**
11. **Toolbox repo:** gather your 5 best scripts in a Git repository with a README, `bin/`, `lib/`, `test/`, an `install.sh`, ShellCheck-clean code and at least 10 tests.
12. **Port a script:** take one of the Lesson 23 tools and make it work on both Linux and macOS (detect GNU vs BSD, avoid bashisms where easy, document the rest).
13. **Optimise:** write a slow script (loop with `basename`, `date`, `expr` over 5,000 file names), measure it, make it 20× faster, and show the numbers.
14. **Review a script:** download a script from the internet (a public dotfiles repo), run ShellCheck, list 5 issues, fix them, and write what you learned.
15. (Think!) When would you choose Python over Bash for a task? Give three concrete signs.
16. (Think!) Why is the main guard compared as `${BASH_SOURCE[0]} == "$0"`?
17. (Think!) Why is `PS4` single-quoted?

---

## ✅ Answers (selected)

<details>
<summary>Click only after trying!</summary>

```bash
# 2
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
set -x          # at the top of your script (or export PS4 and run bash -x)

# 3
time (for i in {1..300}; do basename /a/b/c.txt > /dev/null; done)
p=/a/b/c.txt
time (for i in {1..300}; do echo "${p##*/}" > /dev/null; done)

# 4
sh -c '[[ a == a ]] && echo yes'      # dash: [[: not found   ([[ is a Bash keyword)

# 5
main() { echo "running"; }
is_even() { (( $1 % 2 == 0 )); }
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
# terminal:  source ./myscript.sh && is_even 4 && echo even

# 6
assert_eq() { if [[ $2 == "$3" ]]; then echo "PASS  $1"; else echo "FAIL  $1: expected [$2] got [$3]"; fi; }
is_even() { (( $1 % 2 == 0 )); }
for n in 2 3 10 0; do
    is_even "$n" && got=even || got=odd
    expected=odd; (( n % 2 == 0 )) && expected=even
    assert_eq "is_even $n" "$expected" "$got"
done

# 7
set -eEuo pipefail
trap 'echo "FAIL at line $LINENO: $BASH_COMMAND" >&2
      for ((i=0; i<${#FUNCNAME[@]}-1; i++)); do echo "  ${FUNCNAME[i]}() called from line ${BASH_LINENO[i]}" >&2; done' ERR
a() { b; }
b() { c; }
c() { false; }
a
# output:  FAIL at line 6: false / c() called from line 5 / b() called from line 4 / a() called from line 7

# 8
: "${dir:?dir must be set}"
[[ -d $dir && $dir == /tmp/myapp/* ]] || die "refusing to delete $dir"
rm -rf -- "${dir:?}"/*                       # quoted, guarded, with --
# eval "$cmd"  →  build an array:  cmd=(ls -l -- "$path"); "${cmd[@]}"
tmp=$(mktemp -d)                             # instead of /tmp/work.$$
cat -- "$1"                                  # quoted, with --

# 9
grep -n -E '(^|[^a-z_])eval ' script.sh && echo "eval found: avoid it"

# 10 (Makefile)
PREFIX ?= /usr/local
test:
	bats test/
lint:
	shellcheck bin/* lib/*.sh
install:
	install -D -m 755 bin/mytool $(DESTDIR)$(PREFIX)/bin/mytool

# 15
# Python is the better tool when: the data is nested (JSON/YAML trees); you need
# real data structures, decimals/maths, or libraries; the script has grown past
# a few hundred lines and needs unit tests; you parse complex formats; it must
# run on Windows without WSL; performance matters for millions of iterations.

# 16
# BASH_SOURCE[0] is the file Bash is currently reading; $0 is the program that
# was started. They match only when the file is executed directly. When the file
# is sourced, $0 is the calling shell/script, so they differ and main is skipped.

# 17
# Single quotes delay expansion. PS4 must be expanded again for EVERY traced
# command (new line number, new function). In double quotes ${LINENO} would be
# fixed to the line where PS4 was assigned.
```

</details>

---

## 🎓 Graduation checklist

Tick every line you can do **without looking**:

**Foundations (Lessons 1 to 6)**
- [ ] Move around, create/copy/move/delete files and folders safely
- [ ] Find files (`find`) and text (`grep`), read with `less`/`head`/`tail`
- [ ] Use pipes and redirection (`|`, `>`, `>>`, `2>&1`, `/dev/null`, `tee`)
- [ ] Use globs and brace expansion

**Power tools (Lessons 7, 8)**
- [ ] Process text with `sort`, `uniq`, `cut`, `tr`, `sed`, `awk`
- [ ] Read and set permissions (`chmod 755`, `600`), know what `sudo` does

**Scripting (Lessons 9 to 14)**
- [ ] Write, run and debug a script (shebang, `chmod +x`, `bash -x`)
- [ ] Quote variables correctly; use `$( )`, `$(( ))`, `${var:-default}`
- [ ] Take arguments and input (`$1`, `"$@"`, `read -r`)
- [ ] Decide with `if`, `[[ ]]`, `(( ))`, `case`
- [ ] Loop with `for`, `while`, `read` over files safely
- [ ] Write functions with `local`, return values and statuses

**Professional (Lessons 15 to 19)**
- [ ] Use arrays and associative arrays; `mapfile`
- [ ] Manipulate strings with `${…}` and `printf`
- [ ] Use `set -euo pipefail`, `trap`, `mktemp`, logging
- [ ] Parse options (`getopts`, manual `--long`), write `usage`
- [ ] Use regular expressions with `grep -E`, `sed -E`, `[[ =~ ]]`

**Automation (Lessons 20 to 22)**
- [ ] Run jobs in parallel (`&`, `wait`, `xargs -P`), stop them with signals
- [ ] Schedule with cron/systemd timers; handle locking and logging
- [ ] Call APIs with `curl` + `jq`; use `ssh`, `scp`, `rsync -n`

**Mastery (Lessons 23, 24)**
- [ ] Build a complete tool (usage, validation, dry-run, tests, docs)
- [ ] Debug with `PS4`, stack traces, ShellCheck
- [ ] Write tests (`assert_eq` or `bats`) and use the main guard
- [ ] Spot security problems (eval, unquoted variables, option-like names, temp files)
- [ ] Know when Bash is the wrong tool

If you ticked at least 80%, **you are a Bash programmer.** Keep one rule: *automate something every week.*

---

## 🐞 Common mistakes at this level

| Symptom | Cause | Fix |
|---------|-------|-----|
| test suite runs the whole script | no main guard | `if [[ ${BASH_SOURCE[0]} == "$0" ]]` |
| ShellCheck warnings ignored | "it works" | fix them; each one is a bug waiting |
| optimised the wrong part | no measurement | `time`, profile, then change |
| works on Linux, fails on macOS | GNU-only flags | detect or document; install GNU tools |
| tests pass but script is wrong | tests too weak | add edge cases: empty input, spaces, `-` names, huge input |
| a script grew into a monster | no refactoring | split into functions/files, or move logic to Python |
| secrets leaked in logs | `set -x` | `set +x` around them |
| deployment script broke production | no dry-run, no rollback | dry-run, backups, `--ff-only`, small steps |

---

## 💡 Habits of professional shell programmers

1. **ShellCheck every script. Always.**
2. **Strict mode, quoting, and `main`** in every file.
3. **Test the edges:** spaces, empty values, names starting with `-`, missing files.
4. **Dry-run, then run.** Back up, then change.
5. **Measure before optimising.**
6. **Keep scripts small and focused;** compose them.
7. **Document the *why*.**
8. **Keep learning:** read other people's scripts every week.

## 📚 Extra resources

- **mywiki.wooledge.org**: BashGuide, BashFAQ, BashPitfalls (read all three)
- **google.github.io/styleguide/shellguide.html**: Google Shell Style Guide
- **shellcheck.net** and **github.com/koalaman/shellcheck/wiki**: every warning explained
- **github.com/bats-core/bats-core**: testing framework and docs
- **github.com/dylanaraps/pure-bash-bible**: built-in tricks
- **exercism.org/tracks/bash**, **overthewire.org/wargames/bandit**, **adventofcode.com**: practice
- **man bash**: the complete reference (search with `/`)

## 🧠 Final self-check

1. Name three tools that find bugs in a script, and how you'd use each.
2. Why are `${p##*/}` and `$(( ))` faster than `basename` and `expr`?
3. What is the main guard, and why do tests need it?
4. Name five security mistakes in shell scripts and their fixes.
5. How do you make a script work on both Linux and macOS?
6. When should you stop writing Bash and use Python?

---

# 🎓 Congratulations!

You went from "I don't know one line of Bash" to writing, testing, securing and shipping real tools. Everything else is practice. Open a terminal and **automate something today.**

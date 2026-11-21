# Lesson 24 — Mastery

**Level 6 · Claude Level · Time: ~90 minutes**

---

## 🎯 What you will learn

The skills that separate "I can write scripts" from "I write scripts people trust":

1. **Debugging** like an expert (`PS4`, stack traces, ShellCheck)
2. **Performance**: when a script is slow and why
3. **Portability**: `sh` vs Bash, Linux vs macOS
4. **Testing** your scripts (a mini framework, the **main guard**, `bats`)
5. **Security**: injection, option-like file names, temp files, secrets
6. **Style**: code others can read, review and maintain
7. **Packaging**: documentation, `install`, versions
8. **Knowing when not to use Bash**, and where to go next

> You started this course not knowing one line of Bash. This lesson is the last step: **thinking like a professional**.

---

## 1. Debugging

### The toolbox

| Tool | Command | Use it when |
|------|---------|-------------|
| syntax check | `bash -n script.sh` | "does it even parse?" |
| trace | `bash -x script.sh` | "what did Bash actually run?" |
| partial trace | `set -x … set +x` | trace one section only |
| smart trace | `PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '` | "which file/line/function?" |
| verbose | `bash -v script.sh` | print lines as they are **read** |
| inspect | `declare -p var` / `printf '[%s]\n' "$var"` | "what is really inside?" |
| lint | `shellcheck script.sh` | find bugs **before** running |

Set `PS4` **inside** the script (or in your shell) before `set -x`:

```bash
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
set -x
```

### A stack trace on failure

```bash
set -eEuo pipefail
on_error() {
    local status=$?
    echo "ERROR: '$BASH_COMMAND' failed with status $status" >&2
    local i
    for (( i = 0; i < ${#FUNCNAME[@]} - 1; i++ )); do
        echo "   at ${FUNCNAME[i+1]}() called from line ${BASH_LINENO[i]}" >&2
    done
}
trap on_error ERR
```

`FUNCNAME` (array of function names, innermost first) and `BASH_LINENO` (line numbers of the callers) tell you **the path** that led to the failure.

### ShellCheck

```bash
sudo apt install shellcheck        # or: brew install shellcheck
shellcheck myscript.sh
shellcheck -x -s bash myscript.sh  # follow `source`, assume Bash
# shellcheck disable=SC2086        # silence ONE warning on the next line, with a reason
```

Famous codes: **SC2086** unquoted variable · **SC2046** unquoted `$( )` · **SC2164** `cd` without `|| exit` · **SC2155** `local x=$(…)` · **SC2012** parsing `ls` · **SC2181** checking `$?` indirectly.

### A debugging method that always works

1. **Reproduce** it with the smallest possible input.
2. **Read the error message**, top to bottom, once, slowly.
3. **Trace** (`bash -x`) and find the first line where reality differs from what you expected.
4. **Print the values** (`printf '[%s]\n'`) at that point.
5. **Change one thing** at a time. Re-run.
6. **Write a test** so it can never come back.

---

## 2. Performance

Bash is slow at one thing: **starting programs**. Every `$(basename …)`, `expr`, `date`, `cat file | …` creates a new **process**. Inside a loop that runs 10,000 times, that's 10,000 processes.

| Slow (forks) | Fast (built in) |
|--------------|-----------------|
| `$(basename "$p")` | `${p##*/}` |
| `$(dirname "$p")` | `${p%/*}` |
| `$(expr $a + $b)` | `$(( a + b ))` |
| `$(date +%s)` in a loop | `printf '%(%s)T' -1` |
| `echo "$s" \| tr a-z A-Z` | `${s^^}` |
| `echo "$s" \| sed 's/a/b/'` | `${s/a/b}` |
| `$(cat file)` | `$(< file)` |
| `cat file \| grep x` | `grep x file` |
| `grep x f \| wc -l` | `grep -c x f` |

Measured in the demo (500 runs each): `basename` ~480 ms vs `${p##*/}` ~5 ms: **about 100× faster**.

### Big data? Use the right tool

A Bash `while read` loop over 20,000 lines took ~80 ms, `awk` took ~3 ms. For **bulk text**, hand the work to `awk`, `sed`, `sort`, `grep`; Bash orchestrates, they crunch.

### Measuring

```bash
time ./script.sh                 # real / user / sys
start=$SECONDS; … ; echo $((SECONDS - start))s
t0=${EPOCHREALTIME/./}           # microseconds (Bash 5+)
```

More speed-ups: `LC_ALL=C sort` / `LC_ALL=C grep` (byte-wise, much faster than Unicode-aware), `xargs -P` / background jobs for parallel work (Lesson 20), process each file **once**, avoid `ls | while`, avoid repeated `cd`.

**First make it correct, then measure, then optimise only the slow part.**

---

## 3. Portability

### Which shell is running your script?

| Shebang | Meaning |
|---------|---------|
| `#!/usr/bin/env bash` | needs Bash (arrays, `[[ ]]`, `(( ))`, `${x^^}`…) |
| `#!/bin/sh` | **POSIX** shell only. On Debian/Ubuntu `sh` is **dash** (fast, minimal); on macOS it's a restricted Bash |

Bash-only features ("bashisms") that fail in `sh`/dash: `[[ ]]` · arrays · `(( ))` · `<<<` · `<( )` · `${x^^}` `${x,,}` · `${x/a/b}` · `{1..5}` · `source` (use `.`) · `function name` · `==` in `[ ]` · `local -n` · `&>`.

```bash
dash script.sh                # test with a strict POSIX shell
shellcheck -s sh script.sh    # lint as POSIX
```

**Rule:** if the script says `bash`, use Bash freely. If it says `sh`, be strict. Never mix.

### Linux (GNU) vs macOS (BSD)

| Task | GNU (Linux) | BSD (macOS) |
|------|-------------|-------------|
| in-place edit | `sed -i 's/a/b/' f` | `sed -i '' 's/a/b/' f` · portable: `sed -i.bak …` |
| date from text | `date -d "yesterday"` | `date -v-1d` |
| file size | `stat -c %s f` | `stat -f %z f` |
| absolute path | `readlink -f p` | `realpath p` (newer) / `greadlink -f` |
| PCRE grep | `grep -P` | not available (`brew install grep`) |
| default Bash | 4 / 5 | **3.2** (no associative arrays, no `${x^^}`, no `mapfile`) |

Install GNU tools on macOS: `brew install coreutils gnu-sed grep bash` (they come with a `g` prefix, e.g. `gsed`).

Detect before you use:

```bash
if date --version > /dev/null 2>&1; then echo "GNU date"; else echo "BSD date"; fi
command -v flock > /dev/null || echo "flock missing"
(( BASH_VERSINFO[0] >= 4 )) || { echo "Bash 4+ required" >&2; exit 1; }
```

---

## 4. Testing

### Why test shell scripts?

Because scripts delete files and run servers. A test is the cheapest insurance.

### Step 1: make the code testable: the **main guard**

```bash
slugify() { … }          # functions at the top

main() { … }

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then     # true when RUN, false when SOURCED
    main "$@"
fi
```

Now a test file can `source ./script.sh` to get the functions **without** running `main`.

### Step 2: a tiny test framework (no install needed)

```bash
PASS=0; FAIL=0
assert_eq() {                                   # assert_eq "description" EXPECTED ACTUAL
    if [[ $2 == "$3" ]]; then PASS=$((PASS+1)); echo "PASS  $1"
    else FAIL=$((FAIL+1)); printf 'FAIL  %s\n   expected: [%s]\n   actual  : [%s]\n' "$1" "$2" "$3"; fi
}

source ./textlib.sh
assert_eq "slugify simple" "hello-world" "$(slugify "Hello World")"
echo "$PASS passed, $FAIL failed"
(( FAIL == 0 ))                                 # exit status for CI
```

Test exit codes too (`assert_status`), output of the script, files it creates (in a `mktemp -d` sandbox).

### Step 3: `bats-core` (the standard framework)

```bash
sudo apt install bats           # or: brew install bats-core
```

```bash
# test/textlib.bats
setup() { source "$BATS_TEST_DIRNAME/../textlib.sh"; }

@test "slugify turns spaces into dashes" {
    run slugify "Hello World"
    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "is_number rejects text" {
    run is_number "4x"
    [ "$status" -ne 0 ]
}
```

`bats test/` runs everything and prints a clear report.

### Step 4: automate with CI (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: test
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y shellcheck bats
      - run: shellcheck *.sh
      - run: bats test/
```

Every push now lints and tests your scripts automatically.

---

## 5. Security

Shell scripts run with **your** powers. Treat every input (arguments, file names, environment, network data) as hostile until validated.

| Danger | Example | Defence |
|--------|---------|---------|
| **Code injection** | `eval "echo $input"` with `input='x; rm -rf ~'` | never `eval` input; `printf '%s\n' "$input"`; use arrays for commands |
| **Word splitting / globbing** | `rm $file` with `file='a b'` or `*` | quote: `"$file"` |
| **Option-like file names** | file named `-rf` or `-l` | `--` and `./`: `rm -- "$f"`, `ls ./*` |
| **Predictable temp files** | `/tmp/myapp.tmp` can be pre-created or symlinked by an attacker | `mktemp` / `mktemp -d` |
| **Secrets in arguments** | `./login.sh --password hunter2` visible in `ps` | environment, files with `chmod 600`, `read -s` |
| **Secrets in logs / Git** | `set -x` prints tokens; token committed to the repo | `set +x` around secrets; `.gitignore`; rotate leaked secrets |
| **PATH hijack** | `./` or a writable folder first in `PATH` | `export PATH=/usr/local/bin:/usr/bin:/bin` at the top of root/cron scripts |
| **Running as root unnecessarily** | `sudo ./script.sh` for everything | least privilege; `sudo` only for the one command |
| **Race conditions (TOCTOU)** | check `[[ -e f ]]` then use it | operate atomically (`mv`, `mkdir`, `ln -s`, `set -o noclobber`) |
| **Blind downloads** | `curl … \| sudo bash` | download → read → verify checksum → run |
| **Loose permissions** | world-readable key files | `umask 077`; `chmod 600` |

Safe patterns:

```bash
cmd=(rsync -a -- "$src" "$dest")        # build commands as ARRAYS …
"${cmd[@]}"                              # … never as strings
printf '%q\n' "$untrusted"               # quote anything shown/reused
[[ $input =~ ^[A-Za-z0-9._-]+$ ]] || die "bad input"      # whitelist, don't blacklist
ssh host "$(printf '%q ' "${args[@]}")"  # quote arguments sent through ssh
```

---

## 6. Style: write for the next reader (that's usually future you)

A condensed version of the Google Shell Style Guide:

| Topic | Rule |
|-------|------|
| shebang | `#!/usr/bin/env bash` |
| header | comment: what it does, usage, requirements |
| safety | `set -euo pipefail`, quote everything |
| tests | `[[ ]]`, arithmetic `(( ))` |
| substitution | `$( )`, never backticks |
| functions | `name() { … }`, `local` variables, one job each, `main "$@"` at the bottom |
| names | `lower_snake_case` for variables and functions; `UPPER_CASE` for constants / environment; `readonly` for constants |
| indent | 2 or 4 spaces (be consistent), no tabs mixed in |
| line length | ~80 to 100 characters; break long pipelines at the `\|` |
| output | `printf` over `echo`; messages for humans on stderr |
| don't | parse `ls`; use `eval`; use aliases in scripts; use `function` keyword; ignore errors |
| comments | explain **why**, not what |
| size | if a script passes ~300 lines or needs complex data structures, split it or rewrite in Python |

---

## 7. Packaging & documentation

A tool others (or future you) can use:

```text
mytool/
├── README.md          what it is, install, examples
├── bin/mytool         the script (chmod +x)
├── lib/helpers.sh     sourced functions
├── test/*.bats        tests
├── Makefile           test / lint / install
└── LICENSE
```

Minimal `Makefile`:

```make
PREFIX ?= /usr/local
test:    ; bats test/
lint:    ; shellcheck bin/mytool lib/*.sh
install: ; install -D -m 755 bin/mytool $(DESTDIR)$(PREFIX)/bin/mytool
```

`install -D -m 755 src dest` creates missing folders, copies, and sets permissions **in one step**.

Also provide: `--help`, `--version`, meaningful exit codes, a **CHANGELOG**, and Git tags for releases (`git tag v1.0.0`).

---

## 8. When NOT to use Bash

Bash is **glue**: running programs, wiring pipes, files, cron, small automation. Switch to **Python** (or Go, etc.) when:

- the script grows past a few hundred lines
- you need **nested data** (JSON trees, objects), real data structures, or math with decimals
- you need serious error handling, unit tests, libraries, or Windows-native support
- you're parsing complex formats (HTML, YAML, CSV with quotes)
- performance matters and loops run millions of times

Great pattern: **Bash for orchestration, Python for logic**, e.g. a Bash wrapper that calls `python3 tool.py`. Knowing the boundary is part of mastery.

---

## 9. Where to go next

| Goal | Resource |
|------|----------|
| read excellent Bash | the scripts in `/etc/`, `/usr/bin/` (`file /usr/bin/*` and look for "script"), Git hooks, open-source dotfiles repos |
| deeper reference | **Greg's Wiki** (mywiki.wooledge.org), **Bash Reference Manual**, **Advanced Bash-Scripting Guide**, **pure-bash-bible** |
| practice | **Exercism** Bash track, **OverTheWire: Bandit**, **Advent of Code**, **Rosetta Code**, **Codewars** |
| text mastery | learn `awk` and `sed` deeply (the *AWK Programming Language*, grymoire.com) |
| build automation | `make`, GitHub Actions, Docker (`ENTRYPOINT` scripts), systemd |
| other shells | `zsh` (nicer interactive use), `fish`, PowerShell (Windows) |
| contribute | fix a shell script in an open-source project, add tests, submit a ShellCheck cleanup |

**The best next step:** automate something you do every week. Real problems teach more than any course.

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| no main guard | tests run the whole script on `source` | `if [[ ${BASH_SOURCE[0]} == "$0" ]]` |
| `set -x` with secrets | tokens in logs | `set +x` around them |
| optimising too early | complexity with no gain | measure with `time` first |
| `#!/bin/sh` with bashisms | works on your machine only | `#!/usr/bin/env bash`, or write POSIX |
| assuming GNU tools on macOS | `sed -i` / `date -d` fail | detect, or install GNU tools, or use portable flags |
| testing on real data | deleted files | sandbox in `mktemp -d` |
| disabling ShellCheck warnings blindly | hidden bugs | fix them, or disable one with a reason comment |
| fixing the test to make it pass | bug stays | decide whether code or test is wrong |

---

## ✅ Summary

- **Debug** with `bash -x` + a rich `PS4`, `ERR` traps with stack traces, `declare -p`, ShellCheck
- **Speed:** avoid forks in loops (use `${…}` and `$(( ))`), give bulk text to `awk`/`sed`/`sort`, measure first
- **Portability:** know `sh` vs Bash, GNU vs BSD; detect features; require Bash 4+ if you need it
- **Test:** main guard + `assert_eq` or `bats`; automate in CI
- **Secure:** quote, `--`, `mktemp`, no `eval`, no secrets in arguments, whitelist input
- **Style & packaging:** readable, documented, installable
- **Judgement:** Bash is glue; know when to reach for Python

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then complete the **graduation checklist** in **`Resources.md`**.

> 🎓 **Course complete.** 24 lessons, from `echo` to a professional toolbox. You now think in Bash.

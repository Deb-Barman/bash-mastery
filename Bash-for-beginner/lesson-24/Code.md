# Lesson 24 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson24-demo`, deleted at the end. The "dangerous" demos only use harmless `echo` commands. Needs Bash 4+. It finishes in about 2 seconds. Timings, temp-file names and your `sh` type will differ on your machine.

---

## Part 1: a useful trace

```bash
bash -x traced.sh
```

Plain `-x` prefixes every executed line with `+` (and `++` for commands inside `$( )`). It shows **what ran**, not **where**. The second run puts this line at the top of the traced file:

```bash
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
```

`PS4` is the prefix Bash prints before every traced command (the default is `+ `). Now each line shows **file:line:function**, for example `traced-ps4.sh:4:add: local a=2 b=3`.

> **Why not `PS4=… bash -x script`?** Bash does not reliably accept `PS4` from the environment for non-interactive scripts, so set it inside the file (or `export PS4=…` in your own shell before running).

The single quotes matter: they delay expansion, so `${LINENO}` is evaluated for **each traced line**, not once when `PS4` is assigned.

---

## Part 2: a stack trace

`stacktrace.sh` calls `level_one → level_two → level_three → ls /definitely/not/here`.

```bash
set -eEuo pipefail
trap on_error ERR
```

`-E` makes the ERR trap work **inside functions**. When `ls` fails, `on_error` prints:

```
ERROR: command 'ls /definitely/not/here' failed with status 2
Stack trace (innermost first):
   at level_three() called from line 14
   at level_two() called from line 15
   at level_one() called from line 16
   at main() called from line 18
```

- `BASH_COMMAND` = the command that failed
- `FUNCNAME[i+1]` = the function name at each level
- `BASH_LINENO[i]` = the **line the call came from**

Read it from the bottom: `main` (line 18) called `level_one`, which (line 16) called `level_two`, and so on down to the failing `ls`. Because `local status=$?` is the **first** line of the handler, it still holds the failing command's status.

---

## Part 3: performance

```bash
bench "label" 500 some_function
```

`bench` runs a function many times and reports the total in milliseconds, using `EPOCHREALTIME` (microsecond clock, Bash 5+; the script falls back to whole seconds on older Bash).

Typical results (yours will differ):

| Job | Forking a program | Built into Bash | Speed-up |
|-----|-------------------|-----------------|----------|
| file name from path | `basename` ~480 ms | `${path##*/}` ~5 ms | about 100× |
| arithmetic | `expr` ~460 ms | `$(( ))` ~3 ms | about 150× |
| current time | `date +%s` ~440 ms | `printf '%(%s)T'` ~10 ms | about 40× |

Each program start costs roughly **1 ms**. That's nothing once, and a disaster inside a loop with 100,000 iterations.

The second test sums 20,000 numbers: a Bash `while read` loop took ~80 ms, `awk` ~3 ms. For bulk data the lesson is: **let specialised tools do bulk work, and use Bash to wire them together.**

---

## Part 4: portability

- `readlink -f "$(command -v sh)"` shows what `sh` really is. On Debian/Ubuntu it's **dash**
- `bashism.sh` uses `[[ ]]` and an array. With `bash`, both work. With `sh` (dash) you get `[[: not found` and `Syntax error: "(" unexpected`
- `posix.sh` achieves the same ideas with `case` and `set --` (positional parameters as a poor man's array) and runs everywhere
- the last lines detect **GNU vs BSD** tools by asking `date --version` and `sed --version`. BSD versions don't understand `--version`, which makes it a cheap test

---

## Part 5: testing

### The main guard

`textlib.sh` holds three functions and a `main`. Its last lines:

```bash
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
```

`BASH_SOURCE[0]` is the **file being read**, `$0` is the **program being run**. They're equal only when the file is executed directly.

- executed: `./textlib.sh "Bash Rocks!"` → `main` runs → `bash-rocks`
- sourced: `source ./textlib.sh` → nothing runs, but `type -t slugify` says `function`

That's exactly what a test file needs.

### The tests

`assert_eq` compares expected and actual and counts passes and failures; `assert_status` runs a command and checks its exit status. Nine tests pass (slug, number checks, max). Then **one test fails on purpose**:

```
FAIL  max with negatives (wrong expectation)
      expected: [-1]
      actual  : [-3]
```

That's the format of a good failure report: **what** was tested, **what you expected**, **what you got**. In this case the **test** is wrong (`max -5 -3 -9` really is `-3`), a reminder that when a test fails you must decide whether the code or the test is at fault.

---

## Part 6: security demos

1. **`eval` injection:** input `report; echo INJECTED-COMMAND-RAN`. With `eval "echo $user_input"` the text after `;` **runs as a command**. Here it's a harmless `echo`, but it could be anything. `printf '%s\n' "$user_input"` prints it as plain data.
2. **Unquoted variable:** `[a][b.txt]` (two arguments) vs `[a b.txt]` (one).
3. **Option-like names:** files named `-l` and `-n`. `ls *` expands to `ls -l -n "a b.txt" c.txt`, so `-l` and `-n` become **options** (you see a long numeric listing instead of file names). `ls ./*` or `ls -- *` treats them as names. The same trap with `rm *` and a file named `-rf` has bitten many people.
4. **Temp files:** `/tmp/myapp.tmp` is predictable; `mktemp` creates a unique file with mode **600** (only you can read it).
5. **`umask 077`** makes new files private (600), inside a subshell so it doesn't change your session.
6. **`printf '%q'`** prints text escaped so it is safe to paste back into a shell command.

---

## Part 7: a tiny style linter

`lint FILE` checks for common problems with `grep -E`: missing shebang, missing strict mode, backticks, the `function` keyword, old `$[ ]` arithmetic, single `[ ]`, and parsing `ls`. It reports **six** findings on `bad.sh` and none on `good.sh`. It's deliberately simple, and real projects should use **ShellCheck**, which the script runs automatically if it's installed.

Notice how `good.sh` fixes each issue: shebang + `set -euo pipefail`, `backup() { … }`, `local f`, `for f in ./*.txt` (glob, not `ls`), `[[ ]]`, `rm -- "$f"`, `$(( 1 + 2 ))`.

---

## Part 8: the `install` command

```bash
install -D -m 755 textlib.sh "$PREFIX/bin/textlib"
install -D -m 644 good.sh   "$PREFIX/share/examples/good.sh"
```

`install` copies, **creates missing directories** (`-D`) and sets the mode (`-m`) in one go: `-rwxr-xr-x` for a program, `-rw-r--r--` for data. `PREFIX` is the conventional variable that lets users choose where to install (`make install PREFIX=$HOME/.local`). Here it points to a fake folder inside the demo.

---

## 🧪 Experiments

1. Set `PS4` in your own terminal (`export PS4='+ ${LINENO}: '`), then run `bash -x` on any script of yours.
2. Add a fourth level to the stack trace demo and see the new line.
3. Benchmark `cat file | wc -l` vs `wc -l < file`, and `echo "$s" | tr a-z A-Z` vs `${s^^}`.
4. Write 5 tests for one of your own functions, using `assert_eq`.
5. Add rules to `lint` (for example, `eval`, or `rm -rf $`).
6. Install **ShellCheck** and run it on every script you wrote in this course. Fix what it finds.
7. Install **bats** and rewrite the Part 5 tests as a `.bats` file.

---

## ✅ New words in this file

`PS4` · `FUNCNAME` · `BASH_LINENO` · `BASH_COMMAND` · `BASH_SOURCE` · `EPOCHREALTIME` · `bash -x / -n / -v` · `trap … ERR` + `set -E` · main guard · `source` · `type -t` · `assert_eq` · `bats` · `shellcheck` · `eval` (and why not) · `--` / `./*` · `mktemp` · `umask 077` · `printf '%q'` · `install -D -m` · `PREFIX`

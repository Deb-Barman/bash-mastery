# Lesson 17 — Resources

## 📋 Cheat Sheet

**Strict mode**

```bash
set -euo pipefail        # after the shebang
```

| Option | Effect |
|--------|--------|
| `-e` | exit when a command fails |
| `-u` | unset variable = error |
| `-o pipefail` | pipeline fails if **any** stage fails |
| `-E` | ERR trap also fires in functions/subshells |
| `-x` | trace commands (debug) |

**`set -e` blind spots:** conditions (`if`, `while`), left of `&&`/`||`, `!`, `local x=$(…)`, functions called from a condition. **Gotchas:** `(( i++ ))` from 0, `grep` with no match.

**Explicit handling**

```bash
cmd || die "message"
cd "$dir" || exit 1
if ! cmd; then ...; fi
cmd || true                       # failure is acceptable
```

**Traps**

```bash
trap 'rm -rf "$tmp"' EXIT                     # always cleanup
trap 'echo "line $LINENO: $BASH_COMMAND" >&2' ERR
trap 'echo interrupted; exit 130' INT TERM
trap - EXIT                                   # remove
trap -p                                       # list
```

**Temporary files:** `f=$(mktemp)` · `d=$(mktemp -d)` · `mktemp "${dest}.XXXXXX"`

**Safety idioms**

| Goal | Idiom |
|------|-------|
| refuse empty variable | `"${VAR:?VAR must be set}"` |
| guarded delete | `rm -rf -- "${DIR:?}/"*` |
| idempotent | `mkdir -p` · `rm -f` · `ln -sfn` |
| dry run | `run() { (( DRY_RUN )) && echo "[dry] $*" \|\| "$@"; }` |
| atomic write | write to `mktemp`, then `mv` |
| single instance | `mkdir lockdir` + `trap 'rmdir lockdir' EXIT` |
| timeout | `timeout 10 cmd` (124 = timed out) |

**Exit codes:** `0` ok · `1` error · `2` misuse · `124` timeout · `126` not executable · `127` not found · `130` Ctrl+C · `143` TERM

**Debug:** `bash -n` · `bash -x` · `set -x` / `set +x` · `PS4='+ ${LINENO}: '` · `shellcheck`

---

## 🏋️ Exercises

Work in `~/bash-practice/ex17`.

**Level A: Easy**
1. Write a script that prints `before`, runs `false`, prints `after`. Run it normally, then add `set -e` and compare.
2. Write a script that uses an undefined variable. Add `set -u` and read the error.
3. Show with `false | true; echo $?` and again with `set -o pipefail` why pipefail matters.
4. Write `safe-cd.sh` that does `cd /no/such/dir`, prints an error to stderr and exits `1` if `cd` fails.

**Level B: Medium**
5. Write a script that creates a temp folder with `mktemp -d`, writes a file in it, and **always** removes the folder when the script ends (test with a failing command in the middle).
6. Add an `ERR` trap that prints `Error at line N: COMMAND`. Trigger it with `ls /nonexistent`.
7. Make a script that exits with `130` and prints `Interrupted` when you press Ctrl+C during `sleep 30`.
8. Write `needs.sh` with `require_cmd curl jq git` that prints which commands are missing (all of them, not just the first) and exits `1` if any are.
9. Make `grep "x" file` safe under `set -e` in three different ways.
10. Write `fixcount.sh` that counts to 3 with `set -e` using `(( n++ ))` **correctly** (no early exit).

**Level C: Challenge**
11. Write `retry.sh N DELAY CMD...` and test it with a command that fails twice, then succeeds (use a counter file).
12. Write `once.sh`: a script that refuses to run if another copy is already running (lock directory + trap), and test it by running two copies at once (use `sleep 5` inside).
13. Add `DRY_RUN` support to a script that deletes `*.tmp` files; `DRY_RUN=1` only prints.
14. Write `safe-save.sh` that writes the output of `date` to `out.txt` **atomically**.
15. Build a complete **script skeleton** with: strict mode, `log`/`die`, temp dir + cleanup trap, ERR trap, argument check, and `main "$@"`. Run it with and without arguments.
16. (Think!) Why does `set -e` not stop on `false || echo ok`? Why not inside `if false; then`?
17. (Think!) Why must the trap use **single quotes**: `trap 'rm -rf "$tmp"' EXIT`?
18. (Think!) What's wrong with `local x=$(failing_command)` under `set -e`?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
cat > t1.sh << 'EOF'
echo before
false
echo after
EOF
bash t1.sh                      # before / after
sed -i '1i set -e' t1.sh; bash t1.sh      # before only

# 2
bash -c 'set -u; echo "$nope"'  # nope: unbound variable

# 3
false | true; echo $?           # 0
set -o pipefail; false | true; echo $?    # 1

# 4  safe-cd.sh
#!/usr/bin/env bash
cd /no/such/dir || { echo "cannot cd to /no/such/dir" >&2; exit 1; }

# 5
#!/usr/bin/env bash
set -e
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo hello > "$tmp/a.txt"
ls "$tmp"
false                           # fails; the folder still disappears
echo "not reached"

# 6
set -eE
trap 'echo "Error at line $LINENO: $BASH_COMMAND" >&2' ERR
ls /nonexistent

# 7
trap 'echo Interrupted; exit 130' INT
sleep 30

# 8  needs.sh
#!/usr/bin/env bash
missing=()
for c in "$@"; do
    command -v "$c" > /dev/null 2>&1 || missing+=("$c")
done
if (( ${#missing[@]} > 0 )); then
    echo "Missing: ${missing[*]}" >&2
    exit 1
fi
echo "All commands found"
# ./needs.sh curl jq git

# 9
set -e
grep "x" file || true
if grep -q "x" file; then echo found; fi
grep "x" file > /dev/null || status=$?        # capture instead of dying

# 10  fixcount.sh
#!/usr/bin/env bash
set -e
n=0
while (( n < 3 )); do
    n=$(( n + 1 ))              # or: (( n += 1 ))
    echo "n=$n"
done

# 11  retry.sh
#!/usr/bin/env bash
tries=$1 delay=$2; shift 2
n=1
until "$@"; do
    (( n >= tries )) && { echo "failed after $n attempts" >&2; exit 1; }
    echo "attempt $n failed; retrying in ${delay}s" >&2
    sleep "$delay"
    (( n++ ))
done
echo "succeeded on attempt $n"

# 12  once.sh
#!/usr/bin/env bash
lock=/tmp/once.lock
if ! mkdir "$lock" 2>/dev/null; then
    echo "Already running." >&2
    exit 1
fi
trap 'rmdir "$lock"' EXIT
echo "running..."; sleep 5; echo "done"
# terminal 1: ./once.sh      terminal 2 (within 5s): ./once.sh  → "Already running."

# 13
DRY_RUN=${DRY_RUN:-0}
run() { if (( DRY_RUN )); then echo "[dry-run] $*"; else "$@"; fi; }
shopt -s nullglob
for f in *.tmp; do run rm -v -- "$f"; done

# 14  safe-save.sh
#!/usr/bin/env bash
set -e
tmp=$(mktemp out.txt.XXXXXX)
date > "$tmp"
mv -- "$tmp" out.txt

# 15  skeleton.sh
#!/usr/bin/env bash
set -euo pipefail
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
tmp=$(mktemp -d)
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT
trap 'log "Failed at line $LINENO: $BASH_COMMAND"' ERR
main() {
    [[ $# -ge 1 ]] || die "Usage: $0 FILE"
    [[ -r $1 ]] || die "Cannot read: $1"
    log "Processing $1"
    wc -l < "$1" > "$tmp/count"
    log "Lines: $(cat "$tmp/count")"
}
main "$@"
# (add set -E if you want the ERR trap inside functions too)

# 16
# POSIX/Bash rule: set -e is suppressed when the failing command is part of a
# test (if/while condition, left side of && or ||, or negated by !). In those
# places the failure is the point: it's "handled" by the construct.

# 17
# Double quotes would expand $tmp immediately, when the trap line RUNS. If $tmp
# is empty or changes later, the trap uses the old value. Single quotes delay
# expansion until the trap fires, so it sees the current value.

# 18
# `local` always succeeds, so its status (0) replaces the failing command's
# status, and set -e never notices. Write:   local x; x=$(failing_command)
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| script exits mysteriously | `set -e` + `grep` no match / `(( i++ ))` | `\|\| true`, `if grep -q`, `(( i += 1 ))` |
| `unbound variable` on optional args | `set -u` | `${1:-}` / `${VAR:-default}` |
| trap uses an empty variable | defined later, or double quotes | single quotes; define variable first |
| temp files left behind | no `trap … EXIT` | add cleanup trap |
| ERR trap silent in functions | missing `-E` | `set -E` (or `set -eE`) |
| pipeline error ignored | no `pipefail` | `set -o pipefail` |
| `command not found` for `timeout`/`flock` | not installed (macOS) | `brew install coreutils flock`, or other approach |
| `trap` runs twice | both `EXIT` and `INT` call the same cleanup that calls `exit` | keep traps small; `trap - EXIT` inside the handler |
| lock never released | script killed with `-9` (no traps run) | check lock age; store the PID in the lock |
| `rm -rf "$dir/"*` removed too much | empty `$dir` | `"${dir:?}"` and checks |

---

## 💡 Habits of pro coders

1. **`set -euo pipefail`** and **explicit checks** for important steps.
2. **Every temp file via `mktemp`, every cleanup via `trap … EXIT`.**
3. **Error messages: stderr, specific, actionable, non-zero exit.**
4. **Guard every destructive variable** with `${VAR:?}` and a sanity check.
5. **Idempotent by default.** Running twice must be safe.
6. **Dry-run first, real run second.**
7. **Log with timestamps**, including failures with line numbers.
8. **Run `shellcheck`** on every script before you trust it.

## 📚 Extra resources

- **`help set`**, **`help trap`**: built-in documentation
- **mywiki.wooledge.org/BashFAQ/105**: "Why doesn't `set -e` do what I expected?" (essential reading)
- **redsymbol.net/articles/unofficial-bash-strict-mode**: the "strict mode" article
- **Google Shell Style Guide**: error handling and `main`
- **shellcheck.net:** SC2155 (`local x=$(…)`), SC2086 (quote variables), SC2164 (`cd` without `||`)

## 🧠 Self-check

1. What does Bash do by default after a failed command?
2. What do `-e`, `-u` and `pipefail` each protect against?
3. Name three places where `set -e` does **not** stop the script.
4. What does `trap … EXIT` guarantee? Why use `mktemp`?
5. How can a script report which line failed?
6. What makes a script **idempotent**? Give two examples.

## ➡️ Next: Lesson 18 — Argument Parsing (`getopts`, `--long` options, usage, subcommands)

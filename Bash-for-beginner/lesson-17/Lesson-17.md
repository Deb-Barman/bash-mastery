# Lesson 17 — Error Handling

**Level 4 · Professional · Time: ~80 minutes**

---

## 🎯 What you will learn

- Why Bash scripts fail **silently** by default (and how to stop that)
- The "strict mode" trio: `set -e`, `set -u`, `set -o pipefail`
- What `set -e` does **not** catch, and the traps that bite
- `trap`: run cleanup code when a script ends, fails, or is interrupted
- Temporary files done right (`mktemp`)
- Logging, retries, timeouts, lock files
- Safe habits: dry-run mode, atomic writes, idempotent scripts

> Beginner scripts work when everything goes right. **Professional scripts behave well when things go wrong.** That's what this lesson teaches.

---

## 1. The problem: Bash keeps going after errors

```bash
#!/usr/bin/env bash
cd /backup/folder        # fails: the folder doesn't exist
rm -rf *                 # ...runs anyway, in whatever folder you were in!
```

Without protection, Bash prints an error and **continues to the next line**. That is how scripts delete the wrong files.

Two ways to stay safe:

1. **Explicit checks:** `cd /backup/folder || exit 1`
2. **Strict mode:** make Bash stop on errors by itself (plus explicit checks where it matters)

---

## 2. Strict mode, one switch at a time

### `set -e` (errexit): exit when a command fails

```bash
set -e
echo "start"
false                    # exit status 1 → the script stops HERE
echo "never printed"
```

### `set -u` (nounset): unset variables are errors

```bash
set -u
echo "$undefined_variable"      # error: unbound variable → script stops
```

Catches typos such as `$BACKUP_DRI`. (Lesson 10.)

### `set -o pipefail`: a pipeline fails if **any** part fails

```bash
false | true
echo $?                  # 0  (only the LAST command counts by default)

set -o pipefail
false | true
echo $?                  # 1  (now the failure is noticed)
```

### The common combination

```bash
set -euo pipefail
```

Put it right after the shebang in every script you care about. Some add `IFS=$'\n\t'` so word-splitting only happens on newlines and tabs, not on spaces.

---

## 3. 🔑 `set -e` is not magic: where it does NOT stop

`set -e` is **ignored** in these places (by design):

| Situation | Example |
|-----------|---------|
| Part of a condition | `if grep -q x file; then` / `while cmd; do` |
| Left of `&&` or `||` | `cmd1 && cmd2` (only the **last** command of the chain can trigger exit) |
| After `!` | `! cmd` |
| Inside `$( )` assigned via `local` | `local x=$(failing)` (status of `local` wins) |
| Inside functions called in a condition | `if myfunc; then` |

### Common traps with `set -e`

```bash
set -e
count=0
(( count++ ))        # ❌ the expression's value is 0 → exit status 1 → script exits!
(( count += 1 ))     # ✅ safe (assignments return success when the result is non-zero)
count=$(( count + 1 ))   # ✅ also safe

grep "pattern" file  # ❌ no match = exit 1 → script exits
grep "pattern" file || true      # ✅ "it's fine if there's no match"
if grep -q "pattern" file; then ...   # ✅ the clean way

[[ -f $file ]] && echo "found"   # as the LAST line of a function/script, a false test returns 1
```

Because of these surprises, many experts say: **use `set -e` as a safety net, not as your error handling.** Write explicit checks for the important steps.

---

## 4. Explicit error handling

```bash
# 1) "or stop"
cd "$dir" || exit 1
mkdir -p "$out" || { echo "cannot create $out" >&2; exit 1; }

# 2) with if
if ! cp "$src" "$dest"; then
    echo "copy failed" >&2
    exit 1
fi

# 3) with a helper
die() { echo "ERROR: $*" >&2; exit 1; }
cd "$dir" || die "cannot enter $dir"

# 4) capture a status, decide later
if some_command; then
    echo "ok"
else
    status=$?
    echo "failed with status $status" >&2
fi
```

Error messages: go to **stderr**, say **what failed** and **with what input**, and exit **non-zero**.

---

## 5. `trap`: run code when something happens

```bash
trap 'COMMANDS' SIGNAL_OR_EVENT
```

| Event | When it fires |
|-------|---------------|
| `EXIT` | whenever the script ends: success, failure, `exit`, even `set -e` stops |
| `ERR` | when a command fails (like `set -e` would notice) |
| `INT` | you press **Ctrl+C** |
| `TERM` | someone runs `kill PID` |
| `HUP` | terminal closed |

### The most useful trap: cleanup on EXIT

```bash
tmpdir=$(mktemp -d)                 # a fresh, private temporary folder
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT                   # runs no matter how the script ends

echo "working in $tmpdir"
# ... do work; even if something fails, the folder is removed
```

`mktemp` creates a **unique, safe** name (no clashes, no guessable names). Use `mktemp` for files, `mktemp -d` for folders. Never write to `/tmp/myfile` directly.

### Report where an error happened

```bash
set -eE                              # -E makes the ERR trap work inside functions too
trap 'echo "ERROR on line $LINENO: $BASH_COMMAND (status $?)" >&2' ERR
```

### Handle Ctrl+C and kill

```bash
trap 'echo "Interrupted, cleaning up..."; exit 130' INT TERM
```

(Exit code `130` = 128 + signal 2 (INT); `143` = 128 + 15 (TERM). That's the convention.)

Remove a trap: `trap - EXIT`. List traps: `trap -p`.

---

## 6. Logging

A tiny logging toolkit:

```bash
LOG_FILE="${LOG_FILE:-/tmp/myscript.log}"

log()   { printf '%s [INFO ] %s\n'  "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE"; }
warn()  { printf '%s [WARN ] %s\n'  "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE" >&2; }
error() { printf '%s [ERROR] %s\n'  "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE" >&2; }
die()   { error "$*"; exit 1; }
```

Send **everything** the script prints (normal + errors) to a file and the screen:

```bash
exec > >(tee -a "$LOG_FILE") 2>&1
```

(`exec` with redirections changes where **the rest of the script** writes. Advanced but powerful.)

---

## 7. Retries and timeouts

```bash
retry() {
    local tries=$1 delay=$2 n=1
    shift 2
    until "$@"; do
        if (( n >= tries )); then
            echo "failed after $n attempts: $*" >&2
            return 1
        fi
        echo "attempt $n failed, retrying in ${delay}s..." >&2
        sleep "$delay"
        (( n++ ))
    done
}
retry 3 2 curl -fsS https://example.com/api
```

Timeouts (`timeout` is part of GNU coreutils):

```bash
timeout 10 ./slow-command || echo "timed out or failed (status $?)"     # 124 = timed out
```

---

## 8. Lock files: only one copy at a time

```bash
LOCK=/tmp/myscript.lock
if ! mkdir "$LOCK" 2>/dev/null; then       # mkdir is atomic: only one process can succeed
    echo "Another copy is running." >&2
    exit 1
fi
trap 'rmdir "$LOCK"' EXIT
```

Or with `flock` (Linux): `exec 9>/tmp/my.lock; flock -n 9 || { echo "busy" >&2; exit 1; }`

---

## 9. Safe-by-design habits

### Check before you act (idempotent scripts)

Running a script twice should give the same result and never fail on the second run:

```bash
mkdir -p "$dir"                 # not "mkdir" (fails if it exists)
rm -f "$file"                   # not "rm" (fails if it's missing)
ln -sfn "$target" "$link"       # replace a symlink safely
```

### Dry-run mode

```bash
DRY_RUN="${DRY_RUN:-0}"
run() {
    if (( DRY_RUN )); then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}
run rm -v -- "$file"           # DRY_RUN=1 ./script.sh  → only prints
```

### Atomic writes: never leave half a file

```bash
tmp=$(mktemp "${dest}.XXXXXX")
generate_data > "$tmp"
mv -- "$tmp" "$dest"            # mv within the same filesystem is atomic
```

### Defensive checks at the top

```bash
[[ $# -ge 1 ]] || die "Usage: $0 FILE"
[[ -r $1 ]]    || die "Cannot read $1"
require_cmd jq
(( EUID == 0 )) || die "Run as root (sudo)"
```

### Guard destructive variables

```bash
: "${TARGET_DIR:?TARGET_DIR must be set}"
[[ $TARGET_DIR == /tmp/* ]] || die "Refusing to touch $TARGET_DIR"
rm -rf -- "${TARGET_DIR:?}/"*
```

---

## 10. Debugging toolbox

| Tool | Use |
|------|-----|
| `bash -n script.sh` | syntax check, no run |
| `bash -x script.sh` | trace every command |
| `set -x` / `set +x` | trace only a section |
| `PS4='+ ${BASH_SOURCE}:${LINENO}: '` | richer trace lines (file:line) |
| `echo "DEBUG ..." >&2` | print values |
| `shellcheck script.sh` | linter: finds most mistakes before you run |
| `declare -p var` | show a variable's exact value |

---

## 11. Exit code conventions

| Code | Meaning |
|------|---------|
| `0` | success |
| `1` | general error |
| `2` | misuse / bad arguments |
| `124` | `timeout` expired |
| `126` | found but not executable |
| `127` | command not found |
| `128 + n` | killed by signal n (130 = Ctrl+C, 143 = TERM) |

---

## 12. A professional script skeleton

```bash
#!/usr/bin/env bash
#
# name.sh - what it does
# Usage: name.sh [-h] ARGS
#
set -euo pipefail

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT
trap 'die "Interrupted"' INT TERM
trap 'log "Failed at line $LINENO: $BASH_COMMAND"' ERR

main() {
    [[ $# -ge 1 ]] || die "Usage: $0 FILE"
    local file="$1"
    [[ -r $file ]] || die "Cannot read: $file"
    log "Processing $file"
    # ... work in "$tmpdir" ...
    log "Done"
}

main "$@"
```

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `set -e` + `(( i++ ))` from 0 | script exits | `(( i += 1 ))` / `i=$((i+1))` |
| `set -e` + `grep` with no match | script exits | `\|\| true` or use `if grep -q` |
| `local v=$(cmd)` | error hidden | `local v; v=$(cmd)` |
| `trap ... EXIT` but variable defined **after** | cleanup uses empty variable | define variables first; use `${tmpdir:-}` guards |
| `trap` with double quotes | variable expanded **now**, not at trap time | use single quotes: `trap 'rm -rf "$tmp"' EXIT` |
| `set -u` + `$1` missing | "unbound variable" | `${1:-}` or check `$#` |
| `cmd \| tee log` hides a failing `cmd` | status of `tee` | `set -o pipefail` |
| `exit` inside `trap EXIT` loops | confusing | keep cleanup short and simple |
| `/tmp/file` hard-coded | clashes, security risk | `mktemp` |
| relying on `set -e` alone | silent gaps | explicit checks for key steps |

---

## ✅ Summary

- Bash continues after errors, so protect yourself: `set -euo pipefail` + explicit `|| die`
- `set -e` has blind spots (conditions, `&&`/`||`, `local x=$(…)`, `((i++))`)
- `trap cleanup EXIT` + `mktemp -d` = tidy scripts; `trap … ERR` shows where it broke
- Log to stderr/files; retry with back-off; `timeout`; lock with `mkdir`/`flock`
- Idempotent operations (`mkdir -p`, `rm -f`), dry-run mode, atomic writes (`mktemp` + `mv`)
- Debug with `bash -x`, `PS4`, `shellcheck`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

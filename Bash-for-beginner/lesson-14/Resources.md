# Lesson 14 — Resources

## 📋 Cheat Sheet

```bash
name() {                   # define (before use!)
    local a="$1" b="$2"    # private variables
    echo "result"          # "return a value" (stdout)
    return 0               # "return a status" (0-255)
}

name x y                   # call (no parentheses, no commas)
v=$(name x y)              # capture the output
if name x y; then ...      # use the status
```

| Idea | Syntax |
|------|--------|
| Arguments | `$1 $2 ... "$@" $#` (the function's own) |
| Private variable | `local x` / `local x=5` |
| Status | `return 0` (ok) · `return 1` (fail) |
| Value | `echo "$result"` + `$(f)` |
| Debug output | `echo "..." >&2` |
| List functions | `declare -F` |
| Show code | `declare -f name` |
| Remove | `unset -f name` |
| Library | `source ./lib.sh` |
| Name reference | `local -n ref=$1` |

**Helper starter kit**

```bash
log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" > /dev/null 2>&1 || die "Missing command: $1"; }
confirm() { local r; read -r -p "$1 [y/N] " r; [[ $r == [yY]* ]]; }
```

**Script skeleton**

```bash
#!/usr/bin/env bash
# helpers → functions → main
main() { ...; }
main "$@"
```

---

## 🏋️ Exercises

Work in `~/bash-practice/ex14`.

**Level A: Easy**
1. Write `hello()` that prints `Hello, World!` and call it twice.
2. Write `greet NAME` that prints `Hello, NAME!`.
3. Write `double N` that **echoes** N × 2 and use it like `x=$(double 21)`.
4. Write `is_positive N` that succeeds for positive numbers; use it in an `if`.

**Level B: Medium**
5. Write `max A B` that echoes the larger number.
6. Write `repeat TEXT COUNT` that prints TEXT COUNT times, one per line.
7. Write `file_size FILE` that echoes the size in bytes (`wc -c < file`) and fails (status 1, message to stderr) if the file is missing.
8. Write `sum` that adds **any number** of arguments: `sum 1 2 3 4` → `10`.
9. Write `is_number STR` (status 0 for whole numbers) and use it to validate a script argument.
10. Prove with a small test that a variable **without** `local` leaks out of a function, and one **with** `local` doesn't.

**Level C: Challenge**
11. Write `fib N` (recursive) printing the Nth Fibonacci number (`fib 10` → `55`).
12. Write `lib.sh` with `upper TEXT` and `lower TEXT` (using `tr`), source it from another script and use both.
13. Build `mini.sh` with the `main` pattern: `./mini.sh add 2 3` → `5`, `./mini.sh mul 4 5` → `20`, anything else → usage + exit 2.
14. Write `retry N CMD...` that runs a command up to N times until it succeeds. Print the attempt number each time.
15. (Think!) Why does `result=$(my_func)` lose variable changes made inside `my_func`?
16. (Think!) What's wrong with `local out=$(some_command)` when you care about errors?
17. (Think!) What's the difference between `exit` and `return` inside a function?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
hello() { echo "Hello, World!"; }
hello; hello

# 2
greet() { echo "Hello, $1!"; }

# 3
double() { echo $(( $1 * 2 )); }
x=$(double 21); echo "$x"

# 4
is_positive() { (( $1 > 0 )); }
if is_positive 5; then echo "positive"; fi

# 5
max() { if (( $1 >= $2 )); then echo "$1"; else echo "$2"; fi; }
echo "$(max 3 9)"

# 6
repeat() {
    local text="$1" count="$2" i
    for (( i = 0; i < count; i++ )); do echo "$text"; done
}

# 7
file_size() {
    if [[ ! -f $1 ]]; then
        echo "file_size: no such file: $1" >&2
        return 1
    fi
    wc -c < "$1"
}

# 8
sum() {
    local total=0 n
    for n in "$@"; do (( total += n )); done
    echo "$total"
}
sum 1 2 3 4        # 10

# 9
is_number() { [[ $1 =~ ^[0-9]+$ ]]; }
if ! is_number "$1"; then echo "not a number" >&2; exit 2; fi

# 10
leaky()  { leaked="visible outside"; }
tidy()   { local private="hidden"; }
leaky; tidy
echo "leaked=[$leaked] private=[$private]"
# leaked=[visible outside] private=[]

# 11
fib() {
    local n=$1
    if (( n < 2 )); then
        echo "$n"
    else
        local a b
        a=$(fib $(( n - 1 )))
        b=$(fib $(( n - 2 )))
        echo $(( a + b ))
    fi
}
fib 10             # 55  (slow for big n: each call forks a subshell)

# 12  lib.sh
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
# use.sh
source ./lib.sh
upper "hello"; lower "WORLD"

# 13  mini.sh
#!/usr/bin/env bash
usage() { echo "Usage: $0 add|mul A B" >&2; exit 2; }
main() {
    [[ $# -eq 3 ]] || usage
    case "$1" in
        add) echo $(( $2 + $3 )) ;;
        mul) echo $(( $2 * $3 )) ;;
        *)   usage ;;
    esac
}
main "$@"

# 14
retry() {
    local max="$1" attempt=1
    shift
    until "$@"; do
        if (( attempt >= max )); then
            echo "failed after $attempt attempts" >&2
            return 1
        fi
        echo "attempt $attempt failed, retrying..." >&2
        (( attempt++ ))
        sleep 1
    done
    echo "succeeded on attempt $attempt"
}
retry 3 false          # fails 3 times
retry 3 true           # succeeds immediately

# 15
# $( ) runs the function in a SUBSHELL (a copy of your shell). Changes to
# variables happen in the copy and vanish. Only its output comes back.

# 16
# The status of `local` (always 0) replaces the command's status, so a failure
# in some_command is hidden. Write:
#   local out
#   out=$(some_command) || return 1

# 17
# return leaves just the function (with a status). exit ends the entire
# script (or subshell).
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `foo: command not found` | called before defined, or typo | define above; check the name |
| `syntax error near unexpected token '('` | `greet("x")` | `greet "x"` |
| `return: numeric argument required` | `return "text"` | `echo "text"` |
| variable "changes by itself" | missing `local` | `local` every variable |
| captured value has extra lines | debug `echo` on stdout | `>&2` |
| changes inside `$(func)` lost | subshell | return via stdout, or call without `$( )` |
| whole script stops unexpectedly | `exit` in a helper | `return` and let the caller decide |
| `local: can only be used in a function` | `local` at top level | remove `local` or move into a function |
| function ignores script's `$1` | function has its own `$1` | pass it: `f "$1"` |

---

## 💡 Habits of pro coders

1. **`local` for everything** inside functions.
2. **One job per function**, with a verb name: `backup_folder`, `parse_args`.
3. **Prefix library names** (`lib_`, `app_`) to avoid clashes.
4. **stdout is for results, stderr is for messages.**
5. **`main "$@"`** at the bottom of every non-trivial script.
6. **Use `return` for flow, `exit` only in `main`/`die`.**
7. **Document each function:** one comment line on what it takes and returns.
8. **Test functions** by sourcing the file and calling them from the terminal.

## 📚 Extra resources

- **`help function`**, **`help local`**, **`help return`**
- **mywiki.wooledge.org/BashGuide/Practices** (functions, scoping)
- **Google Shell Style Guide** (function naming, `main`)
- **shellcheck.net:** SC2155 warns about `local x=$(cmd)`

## 🧠 Self-check

1. How do you pass arguments to a function and read them inside?
2. What does `local` prevent?
3. How can a function "return" a value? A status? Which is used with `if`?
4. Why shouldn't value-returning functions print debug text to stdout?
5. What does `main "$@"` do?
6. `exit` vs `return` in a function?

## ➡️ Next: Lesson 15 — Arrays (indexed + associative), `mapfile`, safe loops over lists

> 🏁 **Level 3 complete!** You can write real scripts. Level 4 teaches you to write them like a professional.

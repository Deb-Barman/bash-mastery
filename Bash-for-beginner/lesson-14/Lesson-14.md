# Lesson 14 — Functions: Reusable Code

**Level 3 · Real Scripting · Time: ~75 minutes**

---

## 🎯 What you will learn

- Define and call functions
- Pass arguments to functions (`$1`, `$@`, `$#` work inside them)
- **`local`** variables: keep functions from leaking
- Two kinds of "return": **exit status** (`return`) and **output** (`echo` + `$( )`)
- Useful helper functions every script needs (`log`, `die`, `usage`, `confirm`)
- The `main` pattern for tidy scripts
- Put functions in a **library file** and `source` it
- Recursion

> **DRY: Don't Repeat Yourself.** If you copy-paste the same lines twice, make a function.

---

## 1. Your first function

```bash
greet() {
    echo "Hello, $1!"
}

greet "Asha"          # Hello, Asha!
greet "Ravi"          # Hello, Ravi!
```

Two equivalent ways to define one:

```bash
greet() { ...; }             # most common, POSIX style
function greet { ...; }      # Bash style
```

Rules:

- **Define before you call.** Bash reads top to bottom.
- Calling has **no parentheses and no commas**: `greet "Asha" 25`
- The body is `{ ... }`: with spaces after `{` and a `;` or newline before `}`

---

## 2. Arguments inside functions

A function gets its **own** `$1`, `$2`, `$#`, `"$@"` (separate from the script's):

```bash
add() {
    echo $(( $1 + $2 ))
}

add 3 4               # 7

show_all() {
    echo "Got $# arguments:"
    for arg in "$@"; do
        echo "  - $arg"
    done
}
show_all one "two words" three
```

`$0` is still the **script's** name. Use `${FUNCNAME[0]}` for the function's name.

---

## 3. 🔑 `local`: private variables

Variables are **global by default**, even when created inside a function:

```bash
set_name() {
    name="inside"          # ❌ changes the global 'name'!
}
name="outside"
set_name
echo "$name"               # inside   (surprise!)
```

Fix with `local`:

```bash
set_name() {
    local name="inside"    # ✅ exists only in this function
}
name="outside"
set_name
echo "$name"               # outside
```

**Rule: declare every function variable with `local`.** Otherwise functions silently overwrite each other's variables (a nasty bug to find).

```bash
process() {
    local file="$1"
    local count=0
    ...
}
```

Careful: `local x=$(cmd)` hides the command's exit status. Do it in two lines:

```bash
local x
x=$(cmd) || return 1
```

---

## 4. 🔑 Returning things: status vs output

Bash functions can't return strings or numbers like other languages. There are **two channels**:

### A) Exit status: `return N` (0 to 255)

For **success/failure**, used with `if`:

```bash
is_even() {
    (( $1 % 2 == 0 ))          # the last command's status becomes the function's status
}

if is_even 10; then echo "even"; fi

file_exists() {
    [[ -f $1 ]] && return 0
    return 1
}
```

`return` with no number returns the status of the last command.

### B) Output: `echo` / `printf`, captured with `$( )`

For **values**:

```bash
square() {
    echo $(( $1 * $1 ))
}

result=$(square 7)
echo "7 squared is $result"      # 49
```

Everything the function prints becomes the result. So **don't print debug messages to stdout inside such functions**. Send them to stderr: `echo "debug" >&2`.

### Common mistake

```bash
get_value() { echo 42; return 5; }
x=$(get_value)       # x=42, and $? is 5 (status)
```

`return 42` is a **status**, not a value, and it wraps around after 255.

---

## 5. Useful helper functions (copy these!)

```bash
log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }          # timestamped message
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }               # print error and stop

usage() {
    cat << EOF
Usage: $0 [-h] FILE
  FILE   the file to process
EOF
}

require_cmd() {
    command -v "$1" > /dev/null 2>&1 || die "Required command not found: $1"
}

confirm() {                    # confirm "Delete everything?"  →  returns 0 for yes
    local reply
    read -r -p "$1 [y/N] " reply
    [[ $reply == [yY]* ]]
}
```

Use them:

```bash
require_cmd curl
log "Starting backup"
[[ -f $1 ]] || die "No such file: $1"
confirm "Really delete $1?" && rm -- "$1"
```

> `exit` inside a function exits the **whole script**. `return` leaves only the function.

---

## 6. The `main` pattern

For anything longer than ~30 lines, structure the script like this:

```bash
#!/usr/bin/env bash

# --- helpers ---------------------------------------------
log() { printf '[%s] %s\n' "$(date +%T)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- functions -------------------------------------------
backup_folder() {
    local src="$1" dest="$2"
    [[ -d $src ]] || die "Not a folder: $src"
    mkdir -p "$dest"
    cp -r "$src" "$dest/"
    log "Backed up $src to $dest"
}

# --- main ------------------------------------------------
main() {
    [[ $# -eq 2 ]] || die "Usage: $0 SRC DEST"
    backup_folder "$1" "$2"
}

main "$@"
```

Benefits: readable top-down, all variables are in functions, easy to test, easy to add features. `main "$@"` at the very bottom passes the script's arguments in.

---

## 7. Function libraries: `source`

Put reusable functions in their own file and load them anywhere:

```bash
# lib.sh
log() { echo "[lib] $*"; }
```

```bash
# any script
source "$(dirname "$0")/lib.sh"        # load the functions
log "hello"
```

(`source` runs the file in the **current** shell, so its functions become available, as you learned in Lesson 9.) Keep a personal `~/lib/helpers.sh`, or set up `~/.bashrc` to load your favourites in every terminal.

---

## 8. Recursion

A function can call itself:

```bash
factorial() {
    local n=$1
    if (( n <= 1 )); then
        echo 1
    else
        local prev
        prev=$(factorial $(( n - 1 )))
        echo $(( n * prev ))
    fi
}
factorial 5          # 120
```

Always have a **stopping condition** (`n <= 1`) or it recurses forever. Great for walking folder trees, but Bash recursion is slow. Prefer loops when you can.

---

## 9. Inspecting functions

```bash
declare -F             # list all function names
declare -f greet       # print greet's code
unset -f greet         # delete a function
type greet             # "greet is a function" + its code
```

Functions beat aliases for anything with arguments or logic. In scripts, **use functions, never aliases**.

---

## 10. Passing "variables by name" and arrays (preview)

```bash
set_result() {
    local -n out=$1         # nameref: 'out' becomes another name for the caller's variable (Bash 4.3+)
    out="computed"
}
set_result answer
echo "$answer"              # computed
```

Arrays: pass with `"${arr[@]}"` and receive with `"$@"` (more in Lesson 15).

---

## ⚠️ Common mistakes

| Mistake | Effect | Fix |
|---------|--------|-----|
| calling a function **before** defining it | `command not found` | define first (or put in `main`) |
| forgetting `local` | functions overwrite globals | `local var` |
| `return "text"` | `numeric argument required` | `echo` the text and capture with `$( )` |
| `greet("Asha")` | syntax error | `greet "Asha"` |
| debug `echo` inside a value-returning function | pollutes the result | `>&2` |
| `local x=$(cmd)` | hides `cmd`'s failure | declare, then assign |
| `exit` in a helper meant to just fail | kills the whole script | `return 1` (and let the caller decide) |
| function name equals a command (`test`, `cd`) | confusing behaviour | choose unique names (`app_log`) |
| missing `;` before `}` on one line | syntax error | `f() { cmd; }` |

---

## ✅ Summary

- `name() { ...; }` defines; `name arg1 arg2` calls
- Inside: `$1`, `$@`, `$#`; use **`local`** for variables
- Status: `return 0/1` for `if`; Value: `echo` and capture `$( )`
- Helpers: `log`, `die`, `usage`, `require_cmd`, `confirm`
- `main "$@"` at the bottom for tidy scripts; share code with `source lib.sh`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

> 🎉 **Level 3 complete after this lesson.** You can now write real programs: variables, input, decisions, loops, and functions.

# Lesson 14 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson14-demo` and deletes it at the end. The timestamp in Part 6 will show your own time.

---

## Parts 1 and 2: define, call, pass arguments

```bash
greet() {
    echo "Hello, $1!"
}
greet "Asha"
```

The function must be defined **above** the line that calls it. Inside, `$1` is the function's first argument.

```bash
add() { echo $(( $1 + $2 )); }
echo "add 3 4 -> $(add 3 4)"
```

The function **prints** its answer; `$( )` captures it. `show_all` loops over `"$@"` to prove that `"two words"` stays a single argument.

---

## Part 3: `local` (the most important function habit)

| Call | Result | Why |
|------|--------|-----|
| `tidy` | prints its own `name`, but outside `name` is **still** `outside` | `local name=...` creates a private copy that disappears at the end |
| `leaky` | outside `name` becomes `changed by leaky()` | no `local` → it overwrote the **global** variable |

In long scripts, leaky functions cause bugs that appear far away from their cause. Make `local` automatic for every variable you create inside a function.

---

## Part 4: return status

```bash
is_even() {
    (( $1 % 2 == 0 ))
}
if is_even "$n"; then ...
```

The `(( ))` test is the last command, so its exit status (0 true / 1 false) **becomes the function's status**. That is why `if is_even 4` works with no `return`.

```bash
file_exists() {
    [[ -f $1 ]] && return 0
    return 1
}
```

Explicit `return 0` / `return 1`. Then `file_exists real.txt && echo ...` and `file_exists ghost.txt || echo ...` use the status in the `&&` / `||` shortcuts.

---

## Part 5: returning values with output

```bash
square() { echo $(( $1 * $1 )); }
result=$(square 7)
```

Anything the function writes to **stdout** is what `$( )` captures.

```bash
noisy() {
    echo "debug: working..." >&2
    echo 42
}
value=$(noisy 2> /dev/null)
```

The debug line goes to **stderr** (`>&2`), so it isn't captured. Without `>&2`, `value` would contain **both lines**.

```bash
status_and_value() { echo 42; return 5; }
x=$(status_and_value)      # x=[42], $? = 5
```

Two separate channels: **output** is the value; **return** is the success/failure code.

---

## Part 6: helper functions

| Helper | What it does |
|--------|--------------|
| `log` | prints `[HH:MM:SS] message` |
| `warn` | message to stderr, script continues |
| `die` | message to stderr, then `exit 1` (**ends the whole script**) |
| `require_cmd` | stops with an error if a needed program is missing |
| `confirm` | asks yes/no; its **status** is the answer, so `confirm "..." && do_it` works |

Because `die` calls `exit`, the demo runs it inside a subshell: `( require_cmd definitely-not-installed )`. Only the subshell exits (status 1), and our demo goes on.

```bash
echo y | { confirm "Proceed?" && echo "  -> user said yes"; }
```

We pipe in the answer. The `{ ...; }` group puts both commands on the **receiving** side of the pipe, so `confirm` and the `echo` that follows share the same stdin.

---

## Part 7: the `main` pattern

`backup.sh` is written to disk, then run three ways:

1. `./backup.sh data safe-copy` → works; lists `file.txt`
2. `./backup.sh` → `Usage: ./backup.sh SRC DEST`, exit 1
3. `./backup.sh nope safe-copy` → `Not a folder: nope`, exit 1

Structure to copy: helpers at the top → feature functions → `main()` → `main "$@"` as the **last line**. All variables live in functions, and `main "$@"` passes the script's arguments through. Notice `local src="$1" dest="$2"`: one `local` can declare several variables.

---

## Part 8: a function library

```bash
source ./lib.sh
```

Before `source`, `type -t lib_hello` finds nothing. After it prints `function`. The library file has **no shebang** and doesn't need `chmod +x`, since it is meant to be loaded, not run. A common idiom inside real scripts:

```bash
source "$(dirname "$0")/lib.sh"      # the lib sits next to the script
```

Use a **prefix** (`lib_`) so your function names never collide with real commands.

---

## Part 9: recursion

```bash
factorial() {
    local n=$1
    if (( n <= 1 )); then echo 1
    else
        local prev
        prev=$(factorial $(( n - 1 )))
        echo $(( n * prev ))
    fi
}
```

`factorial 5` calls `factorial 4`, which calls `factorial 3`, ... down to `factorial 1` (the stopping case) which returns 1, and the results multiply on the way back up: 5×4×3×2×1 = 120. `local prev` is declared on its own line first, then assigned, so the status of the inner call isn't hidden.

`countdown` prints `5 4 3 2 1 0` by calling itself with `n - 1`; `(( n < 0 )) && return` is the stopping condition.

---

## Part 10: inspecting functions

- `type -t greet` → `function`
- `declare -F` lists function names (we filter with `grep` to show only ours)
- `declare -f greet` prints its **source code**, reformatted by Bash
- `unset -f greet` deletes it; afterwards `type -t` finds nothing

---

## Part 11: nameref

```bash
set_result() {
    local -n out=$1
    out="computed inside the function"
}
set_result answer
```

`local -n out=$1` makes `out` an **alias** for the variable whose *name* was passed (`answer`). Assigning to `out` assigns to `answer`. It's an advanced way to return several values without `$( )` (needs Bash 4.3+; macOS's default Bash 3.2 lacks it).

---

## 🧪 Experiments

1. Remove `local` from `tidy` and watch Part 3 change.
2. Write `max a b` that echoes the larger number; test it with `$(max 3 9)`.
3. Add a `usage` function to `backup.sh` that prints help for `-h`.
4. Make `countdown` print `Liftoff!` at the end.
5. Make `factorial` fail cleanly for negative input (print to stderr, `return 1`).
6. Move `log`, `warn` and `die` into `lib.sh` and `source` them in `backup.sh`.

---

## ✅ New words in this file

`name() { }` · `local` · `return N` · `$(func)` · `>&2` · `${FUNCNAME}` · `declare -f` / `-F` · `unset -f` · `type -t` · `main "$@"` · `source ./lib.sh` · `local -n` · recursion

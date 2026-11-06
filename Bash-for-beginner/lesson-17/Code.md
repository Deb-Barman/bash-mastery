# Lesson 17 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson17-demo`, deleted at the end. Some demos create temporary folders with `mktemp` (names like `/tmp/tmp.6jjm3a0KvH` will differ on your machine) and remove them again.

---

## How the demo works

`set -e` would stop **Code.sh itself** at the first failure, which would end the lesson early. So each experiment is a **small helper script** (`p1.sh`, `p2.sh`...) written with a here-document, then run in its own Bash by this function:

```bash
run_demo() {
    bash "$1" 2>&1 | sed 's/^/    | /'
    echo "    => exit status: ${PIPESTATUS[0]}"
}
```

- `2>&1` merges errors into the output, `sed 's/^/    | /'` indents each line with `| ` so the helper's output is easy to tell apart
- `${PIPESTATUS[0]}` is the exit status of the **first** command in the last pipeline (the helper script). Plain `$?` would show `sed`'s status instead. (`PIPESTATUS` is an array holding the status of every command in the pipe.)

---

## Part 1: the default

`false` fails, but step 2 still prints and the final status is `0`. The script "succeeded" despite an error in the middle. That silent behaviour is the root of many disasters.

---

## Part 2: `set -e`

After `false`, the script stops. Exit status 1, and `step 2` never prints.

---

## Part 3: `set -u`

The typo `$backup_dri` (instead of `backup_dir`) would have produced `Deleting /old` and carried on. With `set -u`: **`backup_dri: unbound variable`** and the script stops. In a script that runs `rm -rf "$backup_dri/old"`, that difference is the difference between "error message" and "wiped the wrong folder".

---

## Part 4: `pipefail`

`false | true` normally reports `0`, because only the last command (`true`) counts. With `set -o pipefail` the pipeline reports the failure: `1`. This matters for real pipelines like `cat missing.txt | sort | head`, where the first command fails but the last succeeds.

---

## Part 5: the traps of `set -e`

| Helper | What happens | Why |
|--------|--------------|-----|
| `p5a` | script exits at `(( count++ ))` | the expression's value is **0** (value before incrementing), and `(( 0 ))` has exit status 1 |
| `p5b` | works | `(( count += 1 ))` and `count=$(( count + 1 ))` don't return failure |
| `p5c` | exits at `grep` | no match = status 1 = "failure" |
| `p5d` | works | `|| true` makes the failure acceptable, and `if grep -q` handles both outcomes explicitly |
| `p5e` | keeps going | `set -e` is **ignored** on the left of `||`, in `if` conditions, and before `&&` |

Moral: `set -e` is a safety net with holes. Handle important failures **explicitly**.

---

## Part 6: explicit handling

```bash
cd "$dir" || die "cannot enter $dir"
```

First line is Bash's own message (`cd: ...: No such file or directory`), second is our clearer one, and the exit code is 1. This works with or without `set -e`.

---

## Part 7: `trap cleanup EXIT` + `mktemp`

```bash
tmpdir=$(mktemp -d)
trap cleanup EXIT
...
false          # set -e stops the script here
```

Look at the order of the output: *"now something FAILS..."* → *"cleanup: removing /tmp/tmp..."*. The `EXIT` trap ran **even though the script died from an error**. That's the whole point: cleanup happens whatever the ending.

---

## Part 8: `trap ... ERR`

```bash
set -eE
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND (status $?)" >&2' ERR
```

- `BASH_COMMAND` = the command that was running
- `LINENO` = its line number
- `$?` = its status
- `-E` makes the ERR trap also fire inside functions and subshells

Output: `ERROR at line 4: ls /definitely/not/here (status 2)`. You now know **exactly** where it broke. The single quotes are important: they delay expansion until the trap runs. With double quotes `$LINENO` would be fixed at the line where `trap` was *defined*.

---

## Part 9: `trap ... TERM`

`kill -TERM $$` sends the TERM signal to **this very script** (`$$` = own process id). The handler prints a message and exits with `143` (128 + 15). In real life, `kill PID` from another terminal or a system shutdown triggers the same handler. Use `INT` to catch **Ctrl+C**.

---

## Part 10: `retry`

`flaky` reads a counter from a temp file and succeeds only on the third call. `retry 5 0 flaky` retries up to 5 times with 0 seconds delay (so the demo is fast): attempts 1 and 2 fail, attempt 3 succeeds. In real life use a delay: `retry 3 5 curl ...`. `"$@"` after `shift 2` is the command to run, quoted and safe.

---

## Part 11: `timeout`

`timeout 1 sleep 3` stops the `sleep` after one second. Status **124** is `timeout`'s special code for "I killed it". If your system lacks `timeout` (some minimal systems or macOS), the script says so.

---

## Part 12: lock directory

`mkdir` is **atomic**: of two processes trying at the same instant, exactly one succeeds. The first run gets the lock (and removes it again via `trap ... EXIT`). In the second run we pre-create `my.lock` to imitate "another copy is running", so `mkdir` fails and the script refuses to continue.

---

## Part 13: dry-run

`DRY_RUN=1 run_demo p13.sh` sets the variable only for that one call. In dry-run mode, `run rm -v victim.txt` just prints what **would** happen, so the file survives. The real run deletes it. Putting every destructive command behind a `run` wrapper gives your script a free "preview" mode.

---

## Part 14: atomic write

```bash
tmp=$(mktemp "${dest}.XXXXXX")
{ echo "line 1"; echo "line 2"; } > "$tmp"
mv -- "$tmp" "$dest"
```

The data is written to a **temporary file** first and moved into place at the end. `mv` within one filesystem is a single atomic step, so other programs see either the **old** complete file or the **new** complete file, never a half-written one. (`XXXXXX` is replaced by random characters.)

---

## Part 15: guarding `rm -rf`

```bash
rm -rf -- "${TARGET_DIR:?TARGET_DIR must be set}/"*
```

If `TARGET_DIR` is empty or unset, the `:?` refuses to continue. Without the guard the command would become `rm -rf /*`. This one idiom has saved countless systems.

---

## 🧪 Experiments

1. Add `set -o pipefail` to a helper that runs `cat nofile | sort`, and compare.
2. Add `trap 'echo bye' EXIT` to `p2.sh` and see it print on failure.
3. Change the retry count in Part 10 to 2: now it gives up. Check the exit status.
4. Press **Ctrl+C** during a `sleep 30` in a helper with `trap 'echo caught INT; exit 130' INT`.
5. Add `PS4='+ ${LINENO}: '` and `set -x` to a helper, and read the trace.
6. Wrap one of your own `rm` commands in the dry-run `run` function.

---

## ✅ New words in this file

`set -e` · `set -u` · `set -o pipefail` · `set -E` · `trap … EXIT/ERR/TERM/INT` · `$BASH_COMMAND` · `$LINENO` · `PIPESTATUS` · `mktemp` / `mktemp -d` · `timeout` · `kill -TERM $$` · `mkdir` as a lock · `${var:?msg}` · `|| true` · `exec` (mentioned) · `flock` (mentioned)

# Lesson 20 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Needs Bash 4.3+ (for `wait -n`; the script checks). It starts only short `sleep` jobs and stops them again. Output files go to `~/bash-practice/lesson20-demo` (deleted at the end). It takes about 10 seconds to run, because it really waits for the jobs. PIDs and timings will differ on your machine.

---

## Part 1: PID and parent

`$$` is the script's own PID, `$PPID` its parent (your terminal's Bash, or whatever launched it). `ps -o pid=,ppid=,comm= -p $$` asks `ps` for the same facts (the trailing `=` removes the column headers).

---

## Part 2: a background job

```bash
sleep 1 &
pid=$!
kill -0 "$pid"      # alive?
wait "$pid"         # block until it finishes
```

- `&` starts the job and returns at once
- `$!` is its PID. **Save it immediately**; the next background job overwrites it
- `kill -0` sends **no signal** and just reports whether the process exists (exit 0 = yes)
- after `wait`, `kill -0` fails: the process is gone

---

## Part 3: exit statuses

```bash
( sleep 0.2; exit 3 ) & bad_pid=$!
wait "$bad_pid"; echo "job B exited with $?"      # 3
```

The parentheses make a subshell that sleeps and then exits with a chosen code. `wait PID` returns **that job's status**, so you can tell which jobs failed. A plain `wait` (no PID) would return 0 and hide failures.

---

## Part 4: the payoff

```bash
for i in 1 2 3; do sleep 1; done          # 3 seconds
for i in 1 2 3; do sleep 1 & done; wait   # about 1 second
```

`SECONDS` is a built-in counter (seconds since it was last reset); we reset it with `SECONDS=0` before each test. Same work, one third of the time.

---

## Part 5: one output file per job

```bash
work() { sleep "0.$(( 4 - $1 ))"; echo "task $1 finished" > "result-$1.txt"; }
for n in 1 2 3; do work "$n" & pids+=($!); done
for p in "${pids[@]}"; do wait "$p" || (( failed++ )); done
```

- different jobs take different times (0.3, 0.2, 0.1 s), so they finish **out of order**
- each job writes its own file, so nothing gets mixed up; we read them all afterwards with `cat result-*.txt`
- `${BASHPID}` is the PID of the *current* subshell (`$$` would show the parent's)
- results are collected from **files**, because variables set inside a background job are lost

---

## Part 6: signals

| Step | Result |
|------|--------|
| `kill "$victim"` | TERM → the process stops → `wait` status **143** (128 + 15) |
| `kill -9 "$victim"` | KILL → status **137** (128 + 9) |
| `pgrep -f 'sleep 30'` | finds PIDs by command line |
| `kill -l` | lists signals |

(If `pgrep` shows an extra PID when you test it from another script, that's because `-f` matches **command lines**, and the command line of the shell running `pgrep` can contain the same text. Use specific patterns.)

---

## Part 7: limiting concurrency

```bash
for task in 1 2 3 4 5 6; do
    ( sleep 0.5; echo "  task $task done" ) &
    while (( $(jobs -rp | wc -l) >= max )); do
        wait -n
    done
done
wait
```

After starting each task, if `max` jobs are already running (`jobs -rp` lists running PIDs), block with `wait -n` until **any one** finishes. Six half-second tasks, two at a time → about 1.5 s (we print whole seconds, so you'll see 1 or 2). Without the limit all six would start at once, which is exactly what you must avoid when each task uses lots of CPU, memory, or network connections.

---

## Part 8: `xargs -P`

```bash
printf '%s\n' 1 2 3 4 | xargs -P 4 -I{} sh -c 'sleep 1; echo "  item {} done"' | sort
```

`xargs` reads items and runs the command for each one, up to `-P 4` at a time. `-I{}` substitutes each item for `{}`. Four 1-second tasks take about one second. `| sort` only makes the demo output tidy.

---

## Part 9: `jobs`, `nohup`, `disown`

`jobs` lists background jobs of the **current shell** (`Running`, with `+`/`-` marking the current and previous job). `nohup cmd > file 2>&1 &` ignores HUP and writes to a file; `disown $!` detaches it from Bash's job table. Interactive-only tools: Ctrl+Z, `fg`, `bg`.

---

## Part 10: cleaning up children

`workers.sh` starts two 30-second sleeps and **exits immediately**. Its `trap cleanup EXIT` kills the leftovers (`jobs -rp` lists them). Afterwards no `sleep 30` remains. Without the trap, those two processes would keep running as orphans for 30 seconds. In real scripts, add `INT TERM` to the trap so Ctrl+C is covered too.

(`kill $pids` is intentionally **unquoted** so each PID becomes a separate argument: one of the few correct uses of word splitting.)

---

## Part 11: `( )` vs `{ }`

Parentheses run in a **child subshell**: the `cd` is forgotten afterwards. Braces run in the **current shell**: the `cd` sticks (we `cd` back to keep the demo tidy).

---

## Part 12: `time` and `timeout`

`time` is a Bash **keyword** that prints how long a command took; `TIMEFORMAT` customises the output (`%R` = real seconds). `timeout 0.5 sleep 3` stops the sleep after half a second and returns **124**.

---

## 🧪 Experiments

1. Change `max=2` to `1`, then `6`, and compare the timings in Part 7.
2. Add a job that fails (`exit 1`) to Part 5 and watch `failed` change.
3. In a real terminal: run `sleep 100`, press **Ctrl+Z**, then `jobs`, `bg`, `fg`, and finally Ctrl+C.
4. Start `sleep 300 &` in one terminal and find/kill it from another with `pgrep -a sleep` and `pkill sleep`.
5. Use `xargs -P 2` to create 6 empty files named `f1` to `f6`, 2 at a time.
6. Add `trap 'echo caught; kill $(jobs -p)' INT` to a script and press Ctrl+C during `wait`.

---

## ✅ New words in this file

`$$` · `$PPID` · `$!` · `$BASHPID` · `&` · `wait [pid]` · `wait -n` · `jobs -rp` · `kill -0 / -9 / -TERM` · `pgrep` · `pkill` · `nohup` · `disown` · `xargs -P` · `trap … EXIT` · `time` / `TIMEFORMAT` · `timeout` · `SECONDS`

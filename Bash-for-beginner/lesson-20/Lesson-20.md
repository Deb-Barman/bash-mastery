# Lesson 20 — Processes & Jobs

**Level 5 · Automation · Time: ~70 minutes**

---

## 🎯 What you will learn

- What a **process** is, and its **PID** and **parent**
- Look at processes (`ps`, `pgrep`, `top`)
- Stop them properly with **signals** (`kill`, `pkill`)
- Run things **in the background** (`&`, `$!`, `wait`, `jobs`)
- Keep jobs alive after you log out (`nohup`, `disown`)
- Do **parallel work** and collect the results
- Limit concurrency; add timeouts

> Until now your scripts did one thing at a time. Now they can do **ten at once**, the real "no manual work" power.

---

## 1. Processes in one minute

Every running program is a **process** with:

| Property | Meaning | In Bash |
|----------|---------|---------|
| **PID** | unique number | `$$` (my own PID) |
| **PPID** | parent's PID | `$PPID` |
| **exit status** | 0 = ok | `$?` |

When you run `ls`, your Bash is the **parent**; `ls` is the **child**. This is why a child can't change the parent's variables (Lesson 9).

```bash
echo "I am $$, my parent is $PPID"
ps -o pid,ppid,comm -p $$          # PID, parent PID, command name
```

---

## 2. Looking at processes

```bash
ps                      # processes in this terminal
ps aux                  # every process, with owner, CPU, memory   (BSD style)
ps -ef                  # every process, with parent PID            (POSIX style)
ps aux | grep '[n]ginx' # trick: [n] stops grep from matching itself
pgrep -a ssh            # PIDs (and command lines with -a) matching "ssh"
pgrep -f "backup.sh"    # match the whole command line, not just the name
top                     # live view (q to quit); htop is nicer if installed
```

---

## 3. Signals: telling a process what to do

`kill` doesn't only kill. It **sends a signal**:

| Signal | # | Meaning | Typical use |
|--------|---|---------|-------------|
| `TERM` | 15 | "please stop" (can clean up) | the **default** of `kill` |
| `INT` | 2 | interrupt | what **Ctrl+C** sends |
| `HUP` | 1 | hang up / reload config | terminal closed; many daemons reload |
| `KILL` | 9 | stop **now** (can't be caught) | last resort |
| `STOP` / `CONT` | 19 / 18 | pause / resume | Ctrl+Z pauses |
| `USR1` | 10 | user-defined | e.g. rotate logs |

```bash
kill 1234               # TERM
kill -TERM 1234         # same, by name
kill -9 1234            # KILL: no cleanup, use only if TERM is ignored
kill -0 1234            # sends nothing; exit status 0 if the process EXISTS (a handy "is it alive?" test)
pkill -f backup.sh      # kill by command-line pattern
pkill -P $$             # kill all my child processes
kill -l                 # list all signals
```

Exit status of a process killed by signal N is **128 + N** (TERM → 143, KILL → 137, INT → 130).

**Order of politeness:** `TERM` → wait a moment → `KILL`.

---

## 4. Background jobs: `&`

```bash
sleep 30 &              # runs in the background; the prompt returns immediately
echo "started PID $!"   # $! = PID of the most recent background job
```

In an **interactive** terminal:

| Action | Keys / command |
|--------|----------------|
| run in background | `command &` |
| pause the foreground job | **Ctrl+Z** |
| list jobs | `jobs` |
| resume in the background | `bg %1` |
| bring to the foreground | `fg %1` |
| kill a job | `kill %1` |

---

## 5. `wait`: collect your background jobs

Without `wait`, a script may end while its children still run.

```bash
sleep 2 &
pid=$!
echo "doing other work meanwhile..."
wait "$pid"             # block until that job ends
echo "job exited with status $?"        # wait returns the job's exit status!
```

```bash
job_a & job_b & job_c &
wait                    # wait for ALL background jobs
```

---

## 6. Parallel work, with results

```bash
pids=()
for host in alpha beta gamma; do
    ( ping -c1 -W1 "$host" > /dev/null 2>&1 ) &    # each check runs at the same time
    pids+=($!)
done

failed=0
for pid in "${pids[@]}"; do
    wait "$pid" || (( failed++ ))                   # collect every status
done
echo "$failed host(s) failed"
```

**Three jobs taking 1 s each finish in ~1 s, not 3 s.** That's the whole point.

### Limit how many run at once

```bash
max=3
for task in {1..10}; do
    work "$task" &
    while (( $(jobs -rp | wc -l) >= max )); do     # jobs -rp = PIDs of running jobs
        wait -n                                      # wait for ANY one job to finish (Bash 4.3+)
    done
done
wait
```

### `xargs -P`: parallel without writing the loop

```bash
printf '%s\n' *.jpg | xargs -P 4 -I{} convert {} -resize 50% small_{}    # 4 at a time
printf '%s\n' 1 2 3 4 5 6 | xargs -P 3 -I{} sh -c 'sleep 1; echo done {}'
```

(`GNU parallel` is even richer, but `xargs -P` is already installed everywhere.)

---

## 7. Keep running after logout: `nohup`, `disown`, `setsid`

When you close a terminal, Bash sends `HUP` to its jobs and they die. Prevent that:

```bash
nohup ./long-task.sh > task.log 2>&1 &     # ignores HUP, output goes to task.log
long_command & disown                       # remove the job from Bash's list (no HUP)
setsid ./daemon.sh > /dev/null 2>&1 &       # start in its own session
```

For long-lived interactive work use **`tmux`** or **`screen`**: sessions you can detach and re-attach later (even over SSH).

---

## 8. Cleaning up children when the script ends

```bash
cleanup() {
    local pids
    pids=$(jobs -rp)
    [[ -n $pids ]] && kill $pids 2> /dev/null      # unquoted on purpose: several PIDs
}
trap cleanup EXIT INT TERM

./worker.sh &
./worker.sh &
wait
```

Without this, pressing **Ctrl+C** on your script can leave workers running.

---

## 9. Timing and priorities

```bash
time ./slow.sh                  # Bash keyword: prints real / user / sys time
timeout 10 ./slow.sh            # stop it after 10 s (exit status 124)
nice -n 10 ./heavy.sh           # lower its priority (be polite to other programs)
sleep 0.5                       # GNU sleep accepts fractions
echo $SECONDS                   # seconds since the shell/script started
```

---

## 10. Subshell `( )` vs group `{ }`

```bash
( cd /tmp; pwd )     # runs in a CHILD: the cd is forgotten afterwards
{ cd /tmp; pwd; }    # runs in the CURRENT shell: you really moved
( cmd1; cmd2 ) &     # run a sequence in the background as one unit
```

---

## 11. Finding what's using a port or file

```bash
ss -ltnp                          # listening TCP ports and their processes (Linux)
lsof -i :8080                     # who uses port 8080
kill "$(lsof -t -i :8080)"        # stop it (careful!)
lsof +D /some/dir                 # who has files open there
fuser -v file                     # similar
```

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| script ends before background jobs | jobs killed or orphaned | `wait` |
| `$!` read after another command | wrong PID | save it right away: `pid=$!` |
| `wait` returns 0 although a job failed | plain `wait` ignores statuses | `wait "$pid"` for each |
| background output interleaves | all write to one stdout | each job writes to its own file, then `cat` |
| shared files written by several jobs | race conditions, corruption | unique file per job, or locking (Lesson 21) |
| `kill -9` first | no cleanup, leftover temp files | `TERM`, then `KILL` |
| `grep name` shows itself in `ps aux` | grep matches its own line | `pgrep` or `[n]ame` |
| variables set in a background job | lost (it's a subshell) | write results to files/pipes |
| `jobs`, `fg`, `bg` in scripts | job control is interactive | use PIDs and `wait` |
| closed terminal kills jobs | HUP | `nohup`, `disown`, `tmux` |
| `kill $(pgrep -f x)` kills itself/others | pattern too broad | specific pattern; check with `pgrep -a` first |

---

## ✅ Summary

- Every program is a process with a PID and a parent; `$$` is yours, `$!` the last background job
- `ps`, `pgrep -a`, `top` to look; `kill` / `pkill` send **signals** (TERM first, KILL last)
- `cmd &` runs in the background; **`wait [pid]`** collects it and its exit status
- Parallelism: background loop + `wait`, limit with `wait -n`, or `xargs -P`
- `nohup` / `disown` / `tmux` survive logout; `trap` cleans up children
- `time`, `timeout`, `nice` control timing and priority

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

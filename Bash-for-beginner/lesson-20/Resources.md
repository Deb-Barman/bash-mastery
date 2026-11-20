# Lesson 20 — Resources

## 📋 Cheat Sheet

| Goal | Command |
|------|---------|
| My PID / parent | `$$` / `$PPID` |
| Last background PID | `$!` |
| List processes | `ps aux` · `ps -ef` · `pgrep -a name` |
| Live view | `top` · `htop` |
| Stop politely | `kill PID` (TERM) |
| Stop now | `kill -9 PID` |
| Alive? | `kill -0 PID` |
| By name / pattern | `pkill name` · `pkill -f pattern` |
| Kill my children | `pkill -P $$` |
| Run in background | `cmd &` |
| Wait | `wait` · `wait $pid` · `wait -n` |
| Running job PIDs | `jobs -rp` |
| Survive logout | `nohup cmd > log 2>&1 &` · `disown` · `tmux` |
| Parallel | `xargs -P N -I{} cmd {}` |
| Timing | `time cmd` · `timeout 10 cmd` · `$SECONDS` |
| Priority | `nice -n 10 cmd` |
| Who uses a port | `ss -ltnp` · `lsof -i :PORT` |

**Signals:** `HUP 1` · `INT 2` (Ctrl+C) · `TERM 15` (default) · `KILL 9` · `STOP 19` · `CONT 18` · exit status = 128 + signal

**Patterns**

```bash
# parallel with collected statuses
pids=(); for x in a b c; do work "$x" & pids+=($!); done
fail=0; for p in "${pids[@]}"; do wait "$p" || (( fail++ )); done

# limit concurrency
while (( $(jobs -rp | wc -l) >= max )); do wait -n; done

# cleanup children
trap 'kill $(jobs -rp) 2>/dev/null' EXIT INT TERM
```

---

## 🏋️ Exercises

Work in `~/bash-practice/ex20`.

**Level A: Easy**
1. Print your shell's PID and its parent's PID.
2. Start `sleep 60` in the background and print its PID.
3. Check that it is alive (`kill -0`), then stop it, then check again.
4. Run `sleep 2 &` and wait for it. Print its exit status.

**Level B: Medium**
5. Start 3 background jobs `sleep 1` and measure that waiting for all takes about 1 second.
6. Start two jobs, one succeeding and one that does `exit 5`; print each exit status.
7. Use `pgrep -a` to list `sleep` processes you started, then `pkill sleep`.
8. Run a command with `timeout 1` that sleeps 5 seconds and check status 124.
9. Run `time` on `sleep 0.5` with a custom format showing only seconds.
10. Show that a `cd` inside `( )` does not change your directory, but inside `{ }` it does.

**Level C: Challenge**
11. Write `pingall.sh HOST...` that checks every host (use `ping -c1 -W1` or, offline, `sleep`) **in parallel**, then prints a summary `N ok, M failed` using each job's exit status.
12. Write `limited.sh` that processes 10 numbers with a function that sleeps 0.3 s, running **at most 3 at a time** (`wait -n`).
13. Use `xargs -P 4` to "download" (just `echo` + `sleep 1`) 8 URLs from a file, 4 at a time.
14. Write `guard.sh` that starts a background `sleep 100` and guarantees it is killed when the script ends (even with Ctrl+C), using `trap`.
15. Write `watchdog.sh PID` that prints `alive` every second while the PID exists and `gone` when it disappears.
16. (Think!) Why is `$!` unreliable if you read it later? What do you do instead?
17. (Think!) Why do variables set inside a background job not appear in the parent script? How can you get results back?
18. (Think!) Why try `TERM` before `KILL`?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
echo "PID $$, parent $PPID"

# 2
sleep 60 &
pid=$!; echo "$pid"

# 3
kill -0 "$pid" && echo alive
kill "$pid"; wait "$pid" 2>/dev/null
kill -0 "$pid" 2>/dev/null && echo alive || echo gone

# 4
sleep 2 &
wait $!; echo "status $?"

# 5
SECONDS=0
for i in 1 2 3; do sleep 1 & done
wait; echo "${SECONDS}s"

# 6
( exit 0 ) & a=$!
( exit 5 ) & b=$!
wait "$a"; echo "A: $?"
wait "$b"; echo "B: $?"

# 7
sleep 100 & sleep 100 &
pgrep -a sleep
pkill sleep

# 8
timeout 1 sleep 5; echo "status $?"      # 124

# 9
TIMEFORMAT='%R seconds'
time sleep 0.5

# 10
here=$PWD
( cd /tmp ); echo "after ( ): $PWD"
{ cd /tmp; }; echo "after { }: $PWD"
cd "$here"

# 11  pingall.sh
#!/usr/bin/env bash
pids=()
for h in "$@"; do
    ping -c1 -W1 "$h" > /dev/null 2>&1 &
    pids+=($!)
done
ok=0 bad=0
for p in "${pids[@]}"; do
    if wait "$p"; then (( ok++ )); else (( bad++ )); fi
done
echo "$ok ok, $bad failed"

# 12  limited.sh
#!/usr/bin/env bash
work() { sleep 0.3; echo "done $1"; }
max=3
for n in {1..10}; do
    work "$n" &
    while (( $(jobs -rp | wc -l) >= max )); do wait -n; done
done
wait

# 13
# urls.txt has 8 lines
xargs -P 4 -I{} sh -c 'echo "fetching {}"; sleep 1; echo "done {}"' < urls.txt

# 14  guard.sh
#!/usr/bin/env bash
sleep 100 &
child=$!
trap 'kill "$child" 2>/dev/null' EXIT INT TERM
echo "child is $child; working..."
sleep 3
echo "finished"

# 15  watchdog.sh
#!/usr/bin/env bash
pid=$1
while kill -0 "$pid" 2>/dev/null; do
    echo "alive"
    sleep 1
done
echo "gone"

# 16
# $! is overwritten by the next background job. Save it at once: pid=$!
# (or collect into an array: pids+=($!)).

# 17
# A background job is a separate process (a copy of the shell). Its changes
# to variables die with it. Return results through files, pipes, or an exit
# status (wait "$pid"; echo $?).

# 18
# TERM can be caught: the program gets a chance to flush data, close files,
# remove temporary files, and stop children. KILL cannot be caught, so none
# of that happens. Use KILL only after TERM has failed.
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| script exits, jobs vanish / orphaned | no `wait` | `wait` before exiting |
| `wait: pid N is not a child of this shell` | job started in a subshell/another script | wait in the same shell that started it |
| wrong PID killed | read `$!` late | `pid=$!` immediately |
| garbled output | parallel jobs share stdout | separate files, or `sort` afterwards |
| machine overloaded | unlimited parallel jobs | `wait -n` limit or `xargs -P N` |
| `kill: (123) - No such process` | already finished | `kill -0` first, or `2>/dev/null` |
| `pkill -f x` kills the wrong thing | pattern too broad | check with `pgrep -a -f x` first |
| job dies when terminal closes | HUP | `nohup`, `disown`, `tmux` |
| `wait -n` "invalid option" | Bash < 4.3 | upgrade Bash |
| `jobs` shows nothing | jobs run in a subshell / another shell | use PIDs |

---

## 💡 Habits of pro coders

1. **Save every PID** (`pids+=($!)`) and **wait for each one**.
2. **Always limit parallelism**; start with 2 to 4 workers.
3. **One output file (or directory) per worker**; merge afterwards.
4. **Trap `EXIT INT TERM`** and stop your children.
5. **`TERM` first, wait, then `KILL`.**
6. **Check before killing:** `pgrep -a pattern`.
7. **Use `tmux`** for anything that must outlive your SSH session.
8. **Log PIDs and exit statuses**, so failures are traceable.

## 📚 Extra resources

- **`help wait`**, **`help jobs`**, **`help disown`**, **`man kill`**, **`man 7 signal`**
- **mywiki.wooledge.org/ProcessManagement**: the best guide on this topic
- **GNU Parallel** (gnu.org/software/parallel): a powerful `xargs -P` alternative
- **tmux cheat sheet**: tmuxcheatsheet.com
- **`man xargs`**: `-P`, `-n`, `-0`, `-I`

## 🧠 Self-check

1. What are PID and PPID? What are `$$` and `$!`?
2. Why does `kill` default to `TERM`, and when would you use `KILL`?
3. How do you start a background job and get its exit status?
4. How do you run 100 tasks, 4 at a time?
5. What does `nohup` do? What about `disown`?
6. Why can't a background job set variables in the parent?

## ➡️ Next: Lesson 21 — Scheduling (`cron`, `at`, systemd timers, locking, logging)

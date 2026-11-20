#!/usr/bin/env bash
# ==========================================================
# Lesson 20 - Code.sh
# Topic : PID/PPID, ps/pgrep, signals, background jobs,
#         wait, parallel work, limiting concurrency, xargs -P,
#         nohup, cleanup traps, time/timeout
# Run   : bash Code.sh
# Safe  : only starts short `sleep` jobs and stops them again.
#         File output goes to ~/bash-practice/lesson20-demo
#         (cleaned up after).
# Needs : Bash 4.3+ for `wait -n`.
# ==========================================================

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
    echo "This lesson needs Bash 4.3 or newer (you have $BASH_VERSION)."
    exit 1
fi

DEMO="$HOME/bash-practice/lesson20-demo"
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- PART 1: PID and parent --------------------------------
echo "== Part 1: who am I? =="
echo "My PID (\$\$)       : $$"
echo "My parent (\$PPID)  : $PPID"
if command -v ps > /dev/null 2>&1; then
    echo "ps says           : $(ps -o pid=,ppid=,comm= -p $$)   (PID PPID COMMAND)"
fi
echo ""

# --- PART 2: a background job, $!, kill -0, wait -----------
echo "== Part 2: a background job =="
sleep 1 &
pid=$!
echo "Started 'sleep 1' in the background, PID = $pid"
if kill -0 "$pid" 2> /dev/null; then echo "kill -0 says: it is alive"; fi
echo "Doing other work while it runs..."
wait "$pid"
echo "wait returned status $?  (0 = it finished normally)"
if kill -0 "$pid" 2> /dev/null; then echo "still alive"; else echo "kill -0 says: it is gone now"; fi
echo ""

# --- PART 3: exit statuses of background jobs --------------
echo "== Part 3: collect each job's exit status =="
( sleep 0.2; exit 0 ) & ok_pid=$!
( sleep 0.2; exit 3 ) & bad_pid=$!
wait "$ok_pid";  echo "job A exited with $?"
wait "$bad_pid"; echo "job B exited with $?"
echo ""

# --- PART 4: parallel is faster ----------------------------
echo "== Part 4: 3 jobs of 1 second, one after the other vs together =="
SECONDS=0
for i in 1 2 3; do sleep 1; done
echo "Sequential: ${SECONDS}s"

SECONDS=0
for i in 1 2 3; do sleep 1 & done
wait
echo "Parallel  : ${SECONDS}s"
echo ""

# --- PART 5: parallel jobs, each with its own output file --
echo "== Part 5: parallel jobs with separate output files =="
work() {                         # work N: pretend to process something
    sleep "0.$(( 4 - $1 ))"      # different durations: 0.3 / 0.2 / 0.1 s
    echo "task $1 finished (PID $BASHPID)" > "result-$1.txt"
}
pids=()
for n in 1 2 3; do
    work "$n" &
    pids+=($!)
done
failed=0
for p in "${pids[@]}"; do
    wait "$p" || (( failed++ ))
done
echo "failed jobs: $failed"
cat result-*.txt
echo "(each job wrote to its OWN file, so the output never interleaves)"
echo ""

# --- PART 6: killing a process -----------------------------
echo "== Part 6: signals =="
sleep 30 &
victim=$!
echo "Started 'sleep 30' as PID $victim"
if command -v pgrep > /dev/null 2>&1; then
    echo "pgrep finds it   : $(pgrep -f 'sleep 30' | tr '\n' ' ')"
fi
kill "$victim"                               # sends TERM (15)
wait "$victim" 2> /dev/null
echo "after kill (TERM) its status was $?  (143 = 128 + 15)"

sleep 30 &
victim=$!
kill -9 "$victim"
wait "$victim" 2> /dev/null
echo "after kill -9    its status was $?  (137 = 128 + 9)"
echo "A few signal names: $(kill -l | tr '\n' ' ' | cut -c1-70)..."
echo ""

# --- PART 7: limit how many run at once --------------------
echo "== Part 7: at most 2 jobs at a time (wait -n) =="
max=2
SECONDS=0
for task in 1 2 3 4 5 6; do
    ( sleep 0.5; echo "  task $task done" ) &
    while (( $(jobs -rp | wc -l) >= max )); do
        wait -n
    done
done
wait
echo "6 tasks of 0.5s each, 2 at a time, took ${SECONDS}s (one after the other it would take 3s)"
echo ""

# --- PART 8: xargs -P --------------------------------------
echo "== Part 8: xargs -P (parallel without a loop) =="
SECONDS=0
printf '%s\n' 1 2 3 4 | xargs -P 4 -I{} sh -c 'sleep 1; echo "  item {} done"' | sort
echo "4 items of 1s with 4 workers took about ${SECONDS}s"
echo ""

# --- PART 9: jobs, nohup, disown ---------------------------
echo "== Part 9: jobs / nohup / disown =="
sleep 2 &
sleep 2 &
echo "jobs (running in this script):"
jobs
nohup sleep 1 > nohup.out 2>&1 &
disown $!
echo "nohup + disown: that last job is no longer tied to this shell."
echo "(job control keys Ctrl+Z, fg, bg only work in an interactive terminal)"
wait
echo ""

# --- PART 10: cleaning up children with trap ---------------
echo "== Part 10: a script that cleans up its children =="
cat > workers.sh << 'EOF'
#!/usr/bin/env bash
cleanup() {
    local pids
    pids=$(jobs -rp)
    if [[ -n $pids ]]; then
        echo "cleanup: stopping workers: $(echo $pids)"
        kill $pids 2> /dev/null
    fi
}
trap cleanup EXIT
sleep 30 &
sleep 30 &
echo "two workers started; now the script ends early..."
exit 0
EOF
bash workers.sh | sed 's/^/    | /'
echo "Any 'sleep 30' left behind? $(pgrep -f 'sleep 30' | wc -l)   (0 = clean)"
echo ""

# --- PART 11: subshell vs group ----------------------------
echo "== Part 11: ( ) vs { } =="
here=$PWD
( cd /tmp; echo "inside ( ):  $PWD" )
echo "after  ( ):  $PWD   (unchanged)"
{ cd /tmp; echo "inside { }:  $PWD"; }
echo "after  { }:  $PWD   (really moved!)"
cd "$here" || exit 1
echo ""

# --- PART 12: time and timeout -----------------------------
echo "== Part 12: time and timeout =="
TIMEFORMAT='   time says: %R seconds'
time sleep 0.3
if command -v timeout > /dev/null 2>&1; then
    timeout 0.5 sleep 3
    echo "   timeout stopped it; status $?  (124 = timed out)"
fi
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

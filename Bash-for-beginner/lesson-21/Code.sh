#!/usr/bin/env bash
# ==========================================================
# Lesson 21 - Code.sh
# Topic : scheduling: a cron-expression checker written in
#         Bash, cron-friendly scripts, minimal-environment
#         testing, locking, systemd unit files, heartbeats
# Run   : bash Code.sh
# Safe  : NEVER touches your real crontab. Everything lives in
#         ~/bash-practice/lesson21-demo (cleaned up after).
# Needs : Bash 4+, GNU date (Linux / WSL / Git Bash).
# ==========================================================

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This lesson needs Bash 4 or newer (you have $BASH_VERSION)."
    exit 1
fi

DEMO="$HOME/bash-practice/lesson21-demo"
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# ==========================================================
# A cron-expression engine, in pure Bash (uses Lessons 14, 15, 19)
# ==========================================================

# field_matches FIELD VALUE MIN MAX
#   FIELD like  *   */15   5   1-5   0,30   10-50/10
field_matches() {
    local field=$1 value=$((10#$2)) min=$3 max=$4
    local -a parts
    local part range step lo hi
    IFS=, read -r -a parts <<< "$field"       # split on commas (no glob expansion!)
    for part in "${parts[@]}"; do
        step=1
        range=$part
        if [[ $part == */* ]]; then
            range=${part%%/*}
            step=${part#*/}
        fi
        if [[ $range == '*' ]]; then
            lo=$min; hi=$max
        elif [[ $range == *-* ]]; then
            lo=${range%-*}; hi=${range#*-}
        else
            lo=$range; hi=$range
            [[ $part == */* ]] && hi=$max       # "5/10" means 5,15,25...
        fi
        if (( value >= lo && value <= hi && (value - lo) % step == 0 )); then
            return 0
        fi
    done
    return 1
}

# cron_matches "m h dom mon dow" EPOCH  -> status 0 if the job would run that minute
cron_matches() {
    local m h dom mon dow parts tm th td tmo tw
    read -r m h dom mon dow <<< "$1"
    printf -v parts '%(%M %H %d %m %w)T' "$2"
    read -r tm th td tmo tw <<< "$parts"

    field_matches "$m"   "$tm"  0 59 || return 1
    field_matches "$h"   "$th"  0 23 || return 1
    field_matches "$mon" "$tmo" 1 12 || return 1

    local dom_ok=0 dow_ok=0
    field_matches "$dom" "$td" 1 31 && dom_ok=1
    field_matches "$dow" "$tw" 0 7  && dow_ok=1
    if (( tw == 0 )) && field_matches "$dow" 7 0 7; then dow_ok=1; fi    # 7 = Sunday too

    # cron's famous rule: if BOTH day fields are restricted, either one may match (OR)
    if [[ $dom != '*' && $dow != '*' ]]; then
        (( dom_ok || dow_ok ))
    else
        (( dom_ok && dow_ok ))
    fi
}

# next_runs "expr" COUNT START_EPOCH  -> prints the next COUNT run times (within 7 days)
next_runs() {
    local expr=$1 count=$2 t=$3 found=0 limit
    limit=$(( t + 7 * 24 * 60 * 60 ))
    t=$(( t - t % 60 + 60 ))
    while (( found < count && t < limit )); do
        if cron_matches "$expr" "$t"; then
            printf '      %(%a %Y-%m-%d %H:%M)T\n' "$t"
            (( found++ ))
        fi
        (( t += 60 ))
    done
    (( found > 0 )) || echo "      (no run within the next 7 days)"
}

# valid_cron "expr" -> 0 if it has 5 well-formed fields (shape check with regex)
valid_cron() {
    local item='(\*|[0-9]+(-[0-9]+)?)(/[0-9]+)?'
    local field="^${item}(,${item})*$"
    local -a f
    read -r -a f <<< "$1"
    (( ${#f[@]} == 5 )) || return 1
    local x
    for x in "${f[@]}"; do
        [[ $x =~ $field ]] || return 1
    done
}

# --- PART 1: the format ------------------------------------
echo "== Part 1: the five fields =="
cat << 'EOF'
   ┌───────── minute       (0-59)
   │ ┌─────── hour         (0-23)
   │ │ ┌───── day of month (1-31)
   │ │ │ ┌─── month        (1-12)
   │ │ │ │ ┌─ day of week  (0-7, Sunday = 0 or 7)
   * * * * *  command
EOF
echo ""

# --- PART 2: validate expressions --------------------------
echo "== Part 2: is this a valid cron expression? (regex from Lesson 19) =="
for expr in "*/5 * * * *" "30 2 * * *" "0 9 * * 1-5" "0 0 1 * *" "* * * *" "abc * * * *" "60 25 * * *" "0,30 8-18 * * 1-5"; do
    if valid_cron "$expr"; then
        printf '   valid     : %s\n' "$expr"
    else
        printf '   NOT valid : %s\n' "$expr"
    fi
done
echo "   (this checks the SHAPE only; 60 is out of range for minutes but passes the shape test)"
echo ""

# --- PART 3: when would it run? ----------------------------
echo "== Part 3: the next runs (starting Mon 2026-10-12 08:00 UTC) =="
export TZ=UTC
START=$(date -u -d "2026-10-12 08:00:00" +%s 2> /dev/null)
if [[ -z $START ]]; then
    echo "   (GNU date is needed for this part; skipping)"
else
    echo "   */20 9 * * *   (every 20 minutes during the 09:00 hour)"
    next_runs "*/20 9 * * *" 4 "$START"
    echo "   30 2 * * *     (every day at 02:30)"
    next_runs "30 2 * * *" 3 "$START"
    echo "   0 9 * * 1-5    (09:00, Monday to Friday)"
    next_runs "0 9 * * 1-5" 5 "$START"
    echo "   0 3 * * 0      (03:00 every Sunday)"
    next_runs "0 3 * * 0" 2 "$START"
    echo "   0 0 1 * *      (midnight on the 1st: none within a week)"
    next_runs "0 0 1 * *" 2 "$START"
    echo "   0 0 13 * 5     (the day-of-month / day-of-week OR rule: 13th OR Friday)"
    next_runs "0 0 13 * 5" 3 "$START"
fi
unset TZ
echo ""

# --- PART 4: a sample crontab file (NOT installed) ---------
echo "== Part 4: a sample crontab (written to a file, NOT installed) =="
cat > sample.crontab << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=""

# m   h  dom mon dow  command
30    2   *   *   *   /home/asha/bin/nightly-backup.sh >> /home/asha/logs/backup.log 2>&1
*/10  *   *   *   *   flock -n /tmp/check.lock /home/asha/bin/check-site.sh >> /home/asha/logs/check.log 2>&1
0     9   *   *   1-5 /home/asha/bin/weekday-report.sh
@reboot               /home/asha/bin/start-tunnel.sh
EOF
cat sample.crontab
echo "   To install it you would run:  crontab sample.crontab   (this REPLACES your jobs!)"
echo "   Safer: back up first:         crontab -l > my-crontab.backup"
echo "   Is crontab available here?   $(command -v crontab > /dev/null 2>&1 && echo yes || echo 'no (this machine has no cron installed)')"
echo "   Is 'at' available here?      $(command -v at > /dev/null 2>&1 && echo yes || echo no)"
echo ""

# --- PART 5: a cron-friendly script ------------------------
echo "== Part 5: a cron-friendly backup script =="
mkdir -p data backups logs
echo "important data" > data/notes.txt

cat > nightly-backup.sh << EOF
#!/usr/bin/env bash
# nightly-backup.sh - designed to run from cron
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin

BASE="$DEMO"
LOG="\$BASE/logs/backup.log"
LOCKDIR="\$BASE/backup.lock"

log() { printf '%s %s\n' "\$(date '+%F %T')" "\$*" >> "\$LOG"; }

# 1) never overlap
if ! mkdir "\$LOCKDIR" 2> /dev/null; then
    log "previous run still active, skipping"
    exit 0
fi
trap 'rmdir "\$LOCKDIR"' EXIT

# 2) work + log
log "start"
archive="\$BASE/backups/data-\$(date +%H%M%S).tar.gz"
tar -czf "\$archive" -C "\$BASE" data
log "created \$(basename "\$archive") (\$(du -h "\$archive" | cut -f1))"
log "done"
EOF
chmod +x nightly-backup.sh

echo "-- run it the way cron would: with an EMPTY environment (env -i) --"
env -i HOME="$HOME" PATH=/usr/bin:/bin ./nightly-backup.sh
echo "exit status: $?"
echo "-- pretend a previous run is still active (lock exists) --"
mkdir backup.lock
env -i HOME="$HOME" PATH=/usr/bin:/bin ./nightly-backup.sh
echo "exit status: $? (0: skipping on purpose is not an error)"
rmdir backup.lock
echo "-- the log file --"
sed 's/^/   /' logs/backup.log
echo ""

# --- PART 6: why env -i matters ----------------------------
echo "== Part 6: what a minimal environment breaks =="
cat > needs-path.sh << 'EOF'
#!/usr/bin/env bash
# Works in your terminal only if 'mytool' is somewhere in PATH.
mytool --version
EOF
chmod +x needs-path.sh
mkdir -p mybin
printf '#!/usr/bin/env bash\necho "mytool 1.0"\n' > mybin/mytool
chmod +x mybin/mytool
echo "-- with a PATH that includes mybin (like your terminal) --"
PATH="$DEMO/mybin:$PATH" ./needs-path.sh
echo "-- with cron's minimal PATH --"
env -i PATH=/usr/bin:/bin ./needs-path.sh 2>&1 | sed 's/^/   /'
echo "   -> fix: call it by absolute path ($DEMO/mybin/mytool) or set PATH inside the script."
echo ""

# --- PART 7: flock -----------------------------------------
echo "== Part 7: flock (locking in one line) =="
if command -v flock > /dev/null 2>&1; then
    flock -n job.lock sleep 1 &
    sleep 0.2
    if flock -n job.lock echo "got the lock"; then
        :
    else
        echo "   second copy refused: the first one still holds the lock"
    fi
    wait
    flock -n job.lock echo "   after the first finished, the lock is free again"
else
    echo "   (flock is not installed here; on Linux it comes with util-linux)"
fi
echo ""

# --- PART 8: a simulated scheduler -------------------------
echo "== Part 8: the idea behind a scheduler: a loop with sleep =="
for tick in 1 2 3; do
    printf '   tick %s at %s\n' "$tick" "$(date +%T)"
    sleep 1
done
echo ""

# --- PART 9: systemd timer files ---------------------------
echo "== Part 9: systemd service + timer (written to files, not installed) =="
cat > backup.service << 'EOF'
[Unit]
Description=Nightly backup

[Service]
Type=oneshot
ExecStart=/home/asha/bin/nightly-backup.sh
EOF
cat > backup.timer << 'EOF'
[Unit]
Description=Run backup nightly

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF
echo "--- backup.timer ---"
cat backup.timer
echo "To install (as a normal user):"
echo "   mkdir -p ~/.config/systemd/user && cp backup.service backup.timer ~/.config/systemd/user/"
echo "   systemctl --user daemon-reload && systemctl --user enable --now backup.timer"
echo "   systemctl --user list-timers"
if command -v systemd-analyze > /dev/null 2>&1; then
    echo "systemd-analyze says:"
    systemd-analyze calendar "*-*-* 02:30:00" 2> /dev/null | sed 's/^/   /' | head -n 4
fi
echo ""

# --- PART 10: dead man's switch ----------------------------
echo "== Part 10: a heartbeat file (dead man's switch) =="
check_heartbeat() {            # check_heartbeat FILE MAX_AGE_SECONDS
    local file=$1 max=$2 age
    [[ -e $file ]] || { echo "   MISSING: $file"; return 1; }
    age=$(( $(date +%s) - $(stat -c %Y "$file") ))
    if (( age > max )); then
        echo "   STALE: $file is ${age}s old (limit ${max}s). The job has stopped running!"
        return 1
    fi
    echo "   OK: $file is ${age}s old"
}
touch heartbeat
check_heartbeat heartbeat 300
touch -d "10 minutes ago" heartbeat
check_heartbeat heartbeat 300
check_heartbeat no-such-file 300
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Your real crontab was never touched."

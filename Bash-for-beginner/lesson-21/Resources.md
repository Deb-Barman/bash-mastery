# Lesson 21 — Resources

## 📋 Cheat Sheet

```
m h dom mon dow  command
│ │  │   │   └─ 0-7 (0 and 7 = Sunday)
│ │  │   └───── 1-12
│ │  └───────── 1-31
│ └──────────── 0-23
└────────────── 0-59
```

| Symbol | Meaning | Example |
|--------|---------|---------|
| `*` | every | `* * * * *` |
| `,` | list | `0,30 * * * *` |
| `-` | range | `0 9-17 * * *` |
| `/` | step | `*/15 * * * *` |

| Schedule | Meaning |
|----------|---------|
| `*/5 * * * *` | every 5 minutes |
| `0 * * * *` | hourly |
| `30 2 * * *` | daily 02:30 |
| `0 9 * * 1-5` | weekdays 09:00 |
| `0 0 1 * *` | monthly |
| `@reboot` `@daily` `@weekly` `@hourly` | shortcuts |

| Command | Purpose |
|---------|---------|
| `crontab -l` / `-e` | list / edit |
| `crontab -l > backup.txt` | **back up first** |
| `crontab file` | replace all jobs from a file |
| `crontab -ri` | remove all (asks) |
| `env -i PATH=/usr/bin:/bin ./script` | test with cron's bare environment |
| `flock -n lockfile cmd` | skip if already running |
| `echo cmd \| at 17:30` · `atq` · `atrm N` | one-off jobs |
| `systemctl --user enable --now x.timer` | systemd timer |
| `systemctl --user list-timers` | next runs |
| `journalctl --user -u x.service` | logs |
| `systemd-analyze calendar "Mon *-*-* 09:00"` | check an `OnCalendar` expression |

**Crontab top lines:** `SHELL=/bin/bash` · `PATH=/usr/local/bin:/usr/bin:/bin` · `MAILTO=""`

**Cron script checklist:** absolute paths · set `PATH` · no prompts · log with timestamps · lock · exit codes · idempotent · alert on failure

---

## 🏋️ Exercises

Work in `~/bash-practice/ex21`. **Never run `crontab file` unless you first saved `crontab -l`.**

**Level A: Easy**
1. Write the cron expression for: every day at 06:45.
2. ... every 10 minutes.
3. ... at 18:00 on weekdays.
4. ... at midnight on the first day of each month.
5. What does `0 */2 * * *` mean? What about `*/2 0 * * *`?

**Level B: Medium**
6. Write `hello-cron.sh` that appends the date and the text `hello` to `~/bash-practice/ex21/hello.log` using **absolute paths**, then write the crontab line that runs it every minute (don't install it, or install and remove it afterwards).
7. Run `hello-cron.sh` with `env -i` and a minimal PATH. Does it still work? Fix it if not.
8. Add a lock (`mkdir` or `flock`) so two copies can never overlap; test by running two copies at once with `sleep 3` inside.
9. Make the script log failures: if a `required` file is missing, write `ERROR` to the log and exit 1.
10. Write a `heartbeat` check: the job touches `~/bash-practice/ex21/alive`; `check.sh` prints `STALE` if the file is older than 2 minutes.

**Level C: Challenge**
11. Write the systemd `.service` and `.timer` for "every day at 03:15, run `/home/me/bin/cleanup.sh`, catch up if the machine was off".
12. Write `weekly-report.sh` that creates `report-YYYY-MM-DD.txt` containing disk usage (`df -h`) and logs how long it took, plus its crontab line for Mondays at 08:00.
13. Make a script that **removes its own cron line** from a saved crontab file (use `grep -v`), writing the result to a new file (don't touch your real crontab).
14. Write `ping-url.sh URL` that calls `curl -fsS -m 10 URL` and **only** reports on failure (`curl` exit status), suitable as a cron job.
15. (Think!) Why does `0 0 13 * 5` run on more days than "Friday the 13th"? How would you actually do "only Friday the 13th"?
16. (Think!) A script works in your terminal but not in cron. List 4 things to check first.
17. (Think!) Why is `date +%F` inside a crontab line a problem, and what's the fix?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
45 6 * * *
# 2
*/10 * * * *
# 3
0 18 * * 1-5
# 4
0 0 1 * *
# 5
# 0 */2 * * *  → at minute 0 of every 2nd hour (00:00, 02:00, ... 22:00)
# */2 0 * * *  → every 2nd minute during the 00:00 hour only

# 6  hello-cron.sh
#!/usr/bin/env bash
echo "$(date '+%F %T') hello" >> /home/YOU/bash-practice/ex21/hello.log
# crontab line:
* * * * * /home/YOU/bash-practice/ex21/hello-cron.sh

# 7
env -i PATH=/usr/bin:/bin /home/YOU/bash-practice/ex21/hello-cron.sh
# works because date/echo are in /usr/bin:/bin; if it used a tool in another
# folder, add export PATH=... at the top or use the absolute path

# 8
#!/usr/bin/env bash
lock=/tmp/hello.lock
mkdir "$lock" 2>/dev/null || { echo "already running" >&2; exit 0; }
trap 'rmdir "$lock"' EXIT
sleep 3
echo "$(date '+%F %T') hello" >> /home/YOU/bash-practice/ex21/hello.log
# or in the crontab:  * * * * * flock -n /tmp/hello.lock /path/hello-cron.sh

# 9
log=/home/YOU/bash-practice/ex21/hello.log
if [[ ! -f /home/YOU/bash-practice/ex21/required ]]; then
    echo "$(date '+%F %T') ERROR: required file missing" >> "$log"
    exit 1
fi

# 10
# job:     touch ~/bash-practice/ex21/alive
# check.sh
#!/usr/bin/env bash
f="$HOME/bash-practice/ex21/alive"
age=$(( $(date +%s) - $(stat -c %Y "$f") ))
(( age > 120 )) && { echo "STALE (${age}s)"; exit 1; } || echo "OK (${age}s)"

# 11  cleanup.service
[Unit]
Description=Cleanup
[Service]
Type=oneshot
ExecStart=/home/me/bin/cleanup.sh
# cleanup.timer
[Unit]
Description=Daily cleanup
[Timer]
OnCalendar=*-*-* 03:15:00
Persistent=true
[Install]
WantedBy=timers.target

# 12  weekly-report.sh
#!/usr/bin/env bash
start=$SECONDS
out="/home/YOU/reports/report-$(date +%F).txt"
mkdir -p "$(dirname "$out")"
df -h > "$out"
echo "$(date '+%F %T') report written in $((SECONDS - start))s" >> /home/YOU/reports/report.log
# crontab:  0 8 * * 1 /home/YOU/bin/weekly-report.sh

# 13
crontab -l > current.txt          # (a saved copy)
grep -v 'weekly-report.sh' current.txt > new.txt
# review new.txt, then:  crontab new.txt

# 14  ping-url.sh
#!/usr/bin/env bash
if ! curl -fsS -m 10 "$1" > /dev/null; then
    echo "$(date '+%F %T') DOWN: $1" >&2
    exit 1
fi

# 15
# When both day-of-month and day-of-week are restricted, cron ORs them: it
# runs on the 13th AND on every Friday. For "only Friday the 13th", schedule
# 0 0 13 * * and test inside the script:
#   [[ $(date +%u) -eq 5 ]] || exit 0

# 16
# 1) PATH (use absolute paths)   2) working directory (cd or absolute paths)
# 3) environment variables / .bashrc not loaded   4) no TTY / interactive input
# 5) permissions (chmod +x)  6) output not logged (add >> log 2>&1)
# 7) % characters in the crontab line

# 17
# In a crontab, an unescaped % means "newline", so the command is cut in two.
# Escape it:  date +\%F      or put the command in a script file.
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| job never runs | cron service not running (WSL!) / syntax error / no trailing newline | `sudo service cron start`; check `crontab -l`; end file with newline |
| `command not found` in the log | minimal PATH | absolute paths / `export PATH` |
| `Permission denied` | no `chmod +x` | `chmod +x script.sh` |
| works manually, not in cron | environment, cwd, TTY | test with `env -i`, redirect output to a log |
| runs every minute by accident | `* * * * *` | recheck the five fields |
| `date +%F` output wrong / job cut | unescaped `%` | `\%` or wrapper script |
| all jobs vanished | `crontab file` or `crontab -r` | restore from `crontab -l > backup` |
| overlapping runs pile up | job slower than interval | `flock -n` / lock dir |
| runs at the "wrong" hour | server time zone / DST | check `date`, use UTC |
| systemd timer doesn't fire | not enabled / `daemon-reload` missing | `systemctl --user enable --now x.timer` |

---

## 💡 Habits of pro coders

1. **Back up the crontab before editing.** (`crontab -l > cron.backup`.)
2. **Write the script first, test it by hand, then test with `env -i`, then schedule it.**
3. **Always log** (`>> file 2>&1`) and **rotate** the logs.
4. **Lock** anything that can overlap.
5. **Alert on failure *and* on silence** (dead man's switch).
6. **Prefer UTC** on servers; avoid DST-sensitive hours.
7. **Put the schedule in version control** (a `crontab` file in your repo).
8. **Idempotent jobs**: running twice must be harmless.

## 📚 Extra resources

- **crontab.guru:** type a cron expression, get plain English
- **`man 5 crontab`**, **`man at`**, **`man systemd.timer`**, **`man flock`**
- **healthchecks.io** and **Uptime Kuma**: dead man's switch monitoring
- **cron.help** and **cronitor.io/guides**: gotchas and examples
- **Arch Wiki "systemd/Timers"** and **"Cron"** pages: excellent references

## 🧠 Self-check

1. Name the five cron fields in order.
2. Why does a script that works in your terminal fail in cron? Give three reasons.
3. How can you test a script in cron-like conditions?
4. How do you prevent two runs overlapping?
5. What advantages do systemd timers have over cron?
6. How do you find out when a scheduled job silently stops running?

## ➡️ Next: Lesson 22 — Networking & APIs (`curl`, `wget`, `jq`, `ssh`, `scp`, `rsync`)

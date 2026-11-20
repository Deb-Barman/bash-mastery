# Lesson 21 — Scheduling: Run It Without You

**Level 5 · Automation · Time: ~70 minutes**

---

## 🎯 What you will learn

- Schedule scripts with **cron** (the classic) and know its `m h dom mon dow` format by heart
- Why scripts that work in your terminal **fail in cron**, and how to fix that
- One-off jobs with `at`
- Modern scheduling with **systemd timers**
- Stop two copies from running at once (locking)
- Log, monitor, and get alerted when a scheduled job fails

> This is the final step to "no manual work": your scripts run **by themselves**, at 3 a.m., every day.

---

## 1. cron in 5 minutes

`cron` is a background service that runs commands on a schedule. Each user has a **crontab** (a table of jobs).

```bash
crontab -l        # list my jobs
crontab -e        # edit my jobs (opens an editor)
crontab file.txt  # install jobs from a file (replaces ALL existing jobs!)
crontab -r        # ⚠️ delete ALL my jobs, no confirmation. Avoid. (-i asks first)
```

### The format: five time fields, then the command

```
┌───────── minute       (0-59)
│ ┌─────── hour         (0-23)
│ │ ┌───── day of month (1-31)
│ │ │ ┌─── month        (1-12)
│ │ │ │ ┌─ day of week  (0-7; 0 and 7 = Sunday)
│ │ │ │ │
* * * * *  /full/path/to/command arguments
```

| Symbol | Meaning | Example |
|--------|---------|---------|
| `*` | every | `* * * * *` = every minute |
| `,` | list | `0,30 * * * *` = at :00 and :30 |
| `-` | range | `0 9-17 * * *` = hourly, 9:00 to 17:00 |
| `/` | step | `*/15 * * * *` = every 15 minutes |

### Examples

| Schedule | Meaning |
|----------|---------|
| `*/5 * * * *` | every 5 minutes |
| `0 * * * *` | every hour, on the hour |
| `30 2 * * *` | every day at 02:30 |
| `0 9 * * 1-5` | 09:00 Monday to Friday |
| `0 0 1 * *` | midnight on the 1st of every month |
| `0 3 * * 0` | 03:00 every Sunday |
| `15 14 1 1 *` | 14:15 on 1 January |

Shortcuts: `@reboot` (at startup) · `@hourly` · `@daily` · `@weekly` · `@monthly` · `@yearly`

⚠️ **Day-of-month and day-of-week are OR-ed** when both are restricted: `0 0 13 * 5` runs on the 13th **and** on every Friday (not "Friday the 13th").

---

## 2. 🔑 Why "it works in my terminal but not in cron"

Cron runs jobs in a **bare, minimal environment**:

| Difference | Effect | Fix |
|------------|--------|-----|
| tiny `PATH` (`/usr/bin:/bin`) | `command not found` | use **absolute paths**, or set `PATH=` at the top of the script/crontab |
| not your login shell | `.bashrc` isn't loaded; `sh` may be used | `SHELL=/bin/bash` in the crontab; shebang `#!/usr/bin/env bash` |
| working directory is `$HOME` | relative paths break | `cd "$(dirname "$0")"` or absolute paths |
| no terminal (no TTY) | `read`, colours, prompts fail | no interactive input |
| output is **emailed** (or lost) | silent failures | redirect: `>> /path/log 2>&1` |
| `%` is special in crontab lines | `date +%F` breaks | escape `\%` or move it into a script |
| different environment variables | `$USER`, `$DISPLAY`, ssh agent missing | set what you need explicitly |
| different time zone / DST jumps | job runs "late" or twice | prefer UTC servers; avoid 02:00-03:00 for DST-sensitive jobs |

Typical crontab:

```bash
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=""                                   # no mail (or put your address)

30 2 * * *  /home/asha/bin/backup.sh >> /home/asha/logs/backup.log 2>&1
*/10 * * * * /home/asha/bin/check-site.sh >> /home/asha/logs/check.log 2>&1
@reboot      /home/asha/bin/start-tunnel.sh
```

### Test like cron does

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin SHELL=/bin/sh /home/asha/bin/backup.sh
```

`env -i` starts with an **empty** environment, so you see the failures **before** cron does.

---

## 3. Writing cron-friendly scripts

```bash
#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin

LOG=/home/asha/logs/backup.log
LOCKDIR=/tmp/backup.lock

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

# 1) never overlap
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    log "previous run still active, skipping"
    exit 0
fi
trap 'rmdir "$LOCKDIR"' EXIT

# 2) do the work, log the result
log "start"
tar -czf "/backups/home-$(date +%F).tar.gz" -C /home asha
log "done"
```

Rules: absolute paths · log with timestamps · lock · `exit 0` when skipping on purpose, non-zero for real failures · idempotent (safe to run twice).

With `flock` (Linux), the whole lock logic fits in the crontab line:

```
*/5 * * * * flock -n /tmp/job.lock /home/asha/bin/job.sh
```

---

## 4. `at`: run something once

```bash
echo "/home/asha/bin/report.sh" | at 17:30          # today at 17:30
echo "backup.sh" | at now + 2 hours
echo "backup.sh" | at 02:00 tomorrow
atq              # list pending jobs
atrm 3           # remove job 3
```

(`at` needs the `atd` service. `batch` runs a job when the machine is idle.)

---

## 5. systemd timers (modern Linux)

Two small files: a **service** (what to run) and a **timer** (when).

`~/.config/systemd/user/backup.service`

```ini
[Unit]
Description=Nightly backup

[Service]
Type=oneshot
ExecStart=/home/asha/bin/backup.sh
```

`~/.config/systemd/user/backup.timer`

```ini
[Unit]
Description=Run backup nightly

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now backup.timer
systemctl --user list-timers                 # when does it run next?
journalctl --user -u backup.service          # logs of past runs
systemd-analyze calendar "Mon..Fri 09:00"    # check a schedule expression
```

**Why timers beat cron:** logs in the journal, `Persistent=true` runs a missed job after the machine was off, dependencies, resource limits, easy "run now" (`systemctl --user start backup.service`).

---

## 6. Other ways

| Need | Tool |
|------|------|
| laptop that isn't always on | `anacron`, or systemd `Persistent=true` |
| repeat every few seconds | a `while true; do …; sleep N; done` loop (run it with `systemd`/`tmux`) |
| watch a command's output | `watch -n 2 'df -h'` |
| Windows | Task Scheduler; in WSL start the cron service first |
| macOS | `launchd` (plists in `~/Library/LaunchAgents`) |
| cloud/CI | GitHub Actions `schedule:` cron syntax, same five fields |

---

## 7. Monitoring: how do you know it ran?

Scheduled jobs fail **silently**. Add one of these:

1. **Log + look:** `tail -n 20 backup.log`
2. **Exit-code alert:** `./job.sh || curl -fsS -d "job failed" ntfy.sh/mytopic`
3. **Dead man's switch:** the job pings a URL when it **succeeds**; a monitoring service (healthchecks.io, Uptime Kuma) alerts you if the ping **doesn't** arrive:
   ```bash
   ./backup.sh && curl -fsS -m 10 --retry 3 https://hc-ping.com/YOUR-UUID > /dev/null
   ```
4. **Heartbeat file:** the job `touch`es a file; another check complains if it's older than N minutes.
5. **Mail:** cron emails any output of a job when `MAILTO` is set and a mail system exists.

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| relative paths / `~` / aliases | work in terminal only | absolute paths; no aliases |
| `* * * * *` typed by mistake | runs every minute | read the line twice; test with `crontab -l` |
| `crontab file` | **replaces** all existing jobs | `crontab -l > backup.txt` first |
| `crontab -r` | deletes everything | use `crontab -ri`, keep backups |
| `%` inside the command | cut off / error | `\%` or put it in a script |
| job takes longer than the interval | overlapping runs, pile-up | lock (`flock -n`, `mkdir`) |
| no newline at the end of the crontab | last line ignored | end with a newline |
| script not executable | `Permission denied` in the log | `chmod +x` |
| 02:30 on DST change day | skipped or double run | use UTC / avoid those hours |
| editing a script while cron runs it | half-old half-new execution | write to a temp file, then `mv` |

---

## ✅ Summary

- cron: `m h dom mon dow command`; `crontab -e/-l`; shortcuts like `@daily`, `@reboot`
- cron's environment is bare: **absolute paths, set PATH, log everything, no prompts**
- Test with `env -i`; prevent overlaps with `flock -n` or `mkdir` locks
- `at` for one-off jobs; **systemd timers** for modern, logged, persistent schedules
- Monitor with logs, failure alerts, or a dead man's switch

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

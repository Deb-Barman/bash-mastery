# Lesson 21 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: it **never touches your real crontab**. Everything is written to `~/bash-practice/lesson21-demo` (deleted at the end). It needs Bash 4+ and GNU `date` (Linux, WSL, Git Bash), and takes around 8 seconds. Times and sizes in the output will differ on your machine.

---

## The star of the show: a cron engine in Bash

To understand cron you can **build one**. The script defines four functions (using skills from Lessons 14, 15 and 19).

### `field_matches FIELD VALUE MIN MAX`

Does one cron field (like `*/15`, `1-5`, or `0,30`) match one number?

1. `IFS=, read -r -a parts <<< "$field"` splits the field on **commas** into an array. (We use `read` instead of an unquoted `for part in $field`, so a `*` can never be expanded into file names.)
2. For each part: split off a `/step` if present, then work out the range:
   - `*` → whole range (`min`..`max`)
   - `a-b` → that range
   - a single number → just that number (or `a/step` → from `a` to `max`)
3. The value matches if `lo <= value <= hi` **and** `(value - lo) % step == 0`.

So `*/20` for minutes means 0, 20, 40, and `10-50/10` means 10, 20, 30, 40, 50.

### `cron_matches "m h dom mon dow" EPOCH`

```bash
printf -v parts '%(%M %H %d %m %w)T' "$2"
```

`printf '%(...)T'` formats a timestamp **without starting `date`**, which keeps thousands of checks fast. We get minute, hour, day-of-month, month and weekday (`%w`: 0 = Sunday), then test each field.

The famous rule is implemented explicitly:

```bash
if [[ $dom != '*' && $dow != '*' ]]; then (( dom_ok || dow_ok ))   # OR
else                                      (( dom_ok && dow_ok ))   # AND
```

If **both** day fields are restricted, either match is enough. Sunday may be written `0` or `7`, so the code accepts both.

### `next_runs "expr" COUNT START`

Walks forward **minute by minute** (up to 7 days = 10,080 steps) and prints each minute where `cron_matches` succeeds. It is slow in theory, fast in practice because everything is built-in.

### `valid_cron "expr"`

A shape check with the regex skills from Lesson 19:

```bash
item='(\*|[0-9]+(-[0-9]+)?)(/[0-9]+)?'
field="^${item}(,${item})*$"
```

"A star or a number or a range, optionally followed by `/step`, repeated with commas." We also require exactly **5** fields. It accepts `60 25 * * *` (shape OK) even though the numbers are out of range: shape vs meaning, as always.

---

## Part 3: reading the output

Starting Monday 2026-10-12 08:00 UTC:

| Expression | Next runs | Lesson |
|------------|-----------|--------|
| `*/20 9 * * *` | 09:00, 09:20, 09:40, then tomorrow 09:00 | steps inside one hour |
| `30 2 * * *` | 02:30 on each following day | daily |
| `0 9 * * 1-5` | Mon, Tue, Wed, Thu, Fri at 09:00 | weekdays |
| `0 3 * * 0` | Sunday 03:00 | weekly |
| `0 0 1 * *` | nothing this week | monthly |
| `0 0 13 * 5` | **Tue the 13th** and **Fridays** | the OR rule |

`export TZ=UTC` makes the demo identical on every computer; remove it to see your own time zone.

---

## Part 4: a sample crontab

Written to `sample.crontab`, **not installed**. Note the three header lines (`SHELL`, `PATH`, `MAILTO`), absolute paths, `>> log 2>&1`, `flock -n` on the 10-minute job to prevent overlap, and `@reboot`. The script also reports whether `crontab` and `at` exist on your machine.

---

## Part 5: a cron-friendly script (and testing it like cron)

`nightly-backup.sh` follows every rule from the lesson: `PATH` set, absolute `BASE`, a `log()` function with timestamps, a **lock directory**, `trap` to remove the lock, and exit `0` when skipping on purpose.

(It is written with an unquoted `<< EOF`, so the script's own `$DEMO` is filled in **now**, while `\$BASE` and `\$(date …)` are escaped so they are evaluated **later**, when the backup runs.)

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin ./nightly-backup.sh
```

`env -i` starts with an **empty environment**, then we pass only what cron would: `HOME` and a minimal `PATH`. It worked, and the log shows `start / created ... / done`.

Next we create `backup.lock` ourselves to pretend a previous run is active. The script logs `previous run still active, skipping` and exits 0.

---

## Part 6: what a minimal environment breaks

`needs-path.sh` calls `mytool`, which lives in a folder that is on **your** PATH but not on cron's. With the terminal-like PATH it works; with `env -i PATH=/usr/bin:/bin` you see `mytool: command not found`, exactly the error you find in a cron log at 3 a.m. Fix: absolute path, or `export PATH=...` inside the script.

---

## Part 7: `flock`

```bash
flock -n job.lock sleep 1 &        # takes the lock for 1 second
flock -n job.lock echo "..."       # -n = don't wait: fails at once if locked
```

The second command fails while the first holds the lock; after `wait` the lock is free. One word replaces the whole `mkdir` + `trap` dance (Linux; part of `util-linux`).

---

## Part 8: what a scheduler is

A loop with `sleep`: check, act, wait. Real cron checks once a minute. For "every few seconds" jobs this pattern (run under `systemd`/`tmux`) is the usual answer.

---

## Part 9: systemd files

`backup.service` (what to run, `Type=oneshot`) and `backup.timer` (`OnCalendar=*-*-* 02:30:00`, `Persistent=true` to catch up after downtime, a random delay to avoid everyone hitting a server at the same second). If `systemd-analyze` exists, it checks the schedule expression and shows the next run.

---

## Part 10: dead man's switch

```bash
age=$(( $(date +%s) - $(stat -c %Y "$file") ))
```

`stat -c %Y` is the file's modification time in epoch seconds. A healthy job touches the file each run; a **checker** (itself scheduled) complains when the file is too old. We simulate a stopped job with `touch -d "10 minutes ago"`, giving `STALE`. This catches the scariest failure of all: **the job silently stopped running**.

---

## 🧪 Experiments

1. Add your own expressions to `next_runs` (for example `*/7 * * * *`, or `0 12 * * 6,0`).
2. Make `valid_cron` also check that minutes are 0-59 and hours 0-23.
3. Remove `export TZ=UTC` and run again.
4. Comment out the `trap` in `nightly-backup.sh` and run it twice to see the lock stick.
5. Write the systemd timer for "every Monday at 09:00" (`OnCalendar=Mon *-*-* 09:00:00`).
6. Add a `--dry-run` flag to the backup script (Lesson 17).

---

## ✅ New words in this file

`crontab -e/-l` · `m h dom mon dow` · `@reboot` · `env -i` · `flock -n` · `printf '%(…)T'` · `stat -c %Y` · `touch -d` · `OnCalendar` · `Persistent=true` · `systemd-analyze calendar` · `IFS=, read -a` · unquoted heredoc (`<< EOF`) expansion · dead man's switch

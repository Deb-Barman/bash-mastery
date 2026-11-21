# Lesson 23 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson23-demo` and is deleted at the end. It needs Bash 4+, `tar`, `awk`, and `git` for tools 4 and 5 (skipped politely if git is missing). It takes about 5 seconds, because the backup demo waits one second between runs. Times, hashes and sizes will differ on your machine.

> **Keep the tools:** the last lines of `Code.sh` delete the demo folder. Comment out `rm -rf "$DEMO"` and you can copy `tools/*.sh` anywhere (for example into `~/bin`).

---

## How `Code.sh` is organised

1. For each tool: a `cat > tools/NAME.sh << 'EOF' … EOF` block **writes the tool to disk**. The quotes around `'EOF'` keep every `$` and backtick exactly as typed.
2. `chmod +x tools/*.sh` makes them runnable.
3. Then five demos run each tool on sample data, including **error cases**.

Read each generated tool on its own: they're realistic scripts, 40 to 90 lines each.

---

## Tool 1: `backup.sh` (what the demo shows)

| Step in the demo | What to notice |
|------------------|----------------|
| `backup.sh -n -d backups mydata` | **dry run**: every action is printed with `[dry-run]`, and afterwards `backups/` still doesn't exist |
| four real runs with `-k 2` | the folder holds at most 2 archives; runs 3 and 4 print `removed '…'` for the oldest |
| `sleep 1` between runs | names contain **seconds**, so two runs in the same second would collide |
| `tar -tzf` on the newest | the archive lists `mydata/`, `book.txt`, `book2.txt` |
| `nosuchfolder` / `-k 0` | clear error message, exit status **1** |

How the script protects you:

- `tmp=$(mktemp "$dest/.partial.XXXXXX")` and `trap 'rm -f "$tmp"' EXIT`: if `tar` fails halfway, no half-written file is left; after `mv`, `trap - EXIT` cancels the cleanup
- verification: `tar -tzf "$tmp" > /dev/null || die "archive failed verification"`
- rotation: `backups=( "$dest/$name"-*.tar.gz )` is sorted alphabetically (= oldest first) because the timestamp is inside the name; `${backups[@]:0:excess}` slices the oldest ones

---

## Tool 2: `logsum.sh`

The sample log has 12 lines. Reading the result:

- 12 requests, 9216 bytes, **2** server errors (the two `500`s on `/api/data`)
- status codes: 6 × `200`, 3 × `404`, 2 × `500`, 1 × `302`
- top visitor `192.168.1.10` with 5 requests
- 4 requests in each of three hours
- the 404 list shows which missing pages are being asked for (`/missing.html` twice)

Notes on the code:

- `awk '{s += $10} END {print s + 0}'`: the `+ 0` forces `0` instead of an empty line when the file is empty
- `substr($4, 14, 2)` takes characters 14 and 15 of `[10/Oct/2026:09:15:01`, which is the hour
- `for (k in c)` has no guaranteed order, so we pipe to `sort`

---

## Tool 3: `organize.sh`

The demo folder holds 13 entries: files of every kind, a folder, an extension-less `README`, an unknown `.xyz`, and `Notes.TXT` / `notes.txt` (upper vs lower case).

1. **dry run** lists 12 planned moves (the folder `keep-this-folder` is skipped)
2. **real run** moves them into `Archives`, `Audio`, `Code`, `Documents`, `Images`, `Other`, `Video`
3. a **new** `notes.txt` is created while `Documents/notes.txt` already exists → the script renames the newcomer `notes-1.txt` and **overwrites nothing**

Code details:

- `category "${1,,}"` lowercases the extension, so `PNG` = `png`
- `[[ $base == *.* && $base != .* ]]`: has a dot **and** doesn't start with one (so `.bashrc` isn't "extension `bashrc`")
- `moved=$(( moved + 1 ))` instead of `(( moved++ ))`: under `set -e`, `(( moved++ ))` from 0 returns status 1 and would end the script (the Lesson 17 trap, in the wild)
- the final message `$( (( dry )) && echo 'would be moved' || echo moved )` picks the right wording

---

## Tool 4: `newproject.sh`

```
hello-tool/
├── .gitignore
├── README.md
├── docs/
├── src/main.sh
└── tests/test_main.sh
```

The generated test runs `src/main.sh` and compares its output: **`PASS`**. A git repository with one commit is created (`git log --oneline` shows it). The error cases: creating the same project twice → `Already exists` (exit 1); `'bad name!'` → `Invalid project name` (exit 2, a usage error).

Two here-document styles are mixed on purpose:

- `<< MD` (unquoted): `$name`, `$type` and `$(date +%F)` are **filled in** while writing the README
- `<< 'SH'` (quoted): the generated script is written **exactly as typed**

---

## Tool 5: `deploy.sh`

The demo builds its own mini infrastructure:

```
origin.git   (a bare repository: the "server")
dev/         (the developer's clone: edits and pushes)
prod/        (the production checkout, managed by deploy.sh)
```

Sequence you will see:

1. **first deploy** → `cloned into prod at 5d35d2c`, then `build step: version 1`
2. **deploy again** → `already up to date`, hash unchanged (the build hook still runs; real tools often skip it)
3. the developer pushes **version 2**
4. **deploy** → `updated 5d35d2c -> 953327e`, `git diff --stat` lists `VERSION` and `build.sh`, the build prints `version 2`

`git pull --ff-only` is the safety net: if the production checkout has diverged (someone edited files there), the pull **fails** instead of creating a merge.

---

## 🧪 Experiments

1. Run `backup.sh -n` on your real Documents folder (dry run is safe!).
2. Add `.mp3` handling for `organize.sh`'s `Audio` category, or a new category `Fonts`.
3. Teach `logsum.sh` to print the **slowest** requests (if you add a response-time column) or the top 3 **user agents**.
4. Add a `-q` (quiet) flag to `backup.sh`.
5. Make `newproject.sh` copy a `LICENSE` file from `~/templates` if it exists.
6. Make `deploy.sh` skip the build hook when nothing changed.
7. Put `tools/` on your `PATH` (Lesson 9) and run the tools by name from any folder.

---

## ✅ New words in this file

`mktemp` + `mv` (atomic write) · `tar -czf / -tzf` · rotation with array slices · `awk` summaries · `case "${1,,}"` · clash-safe naming · `git init / add / commit / clone / pull --ff-only / diff --stat / rev-parse` · `git -c user.name=…` · bare repository · `( cd dir && cmd )` · here-doc quoting (`<< 'EOF'` vs `<< EOF`)

# Lesson 9 — Code Explained (line by line)

**Run it:**

```bash
bash Code.sh
```

Today's script is special: **it writes other scripts, runs them, and explains the results.** It works only in `~/bash-practice/lesson9-demo` and deletes it at the end.

---

## The setup

```bash
DEMO="$HOME/bash-practice/lesson9-demo"
if [ -d "$DEMO" ]; then rm -r "$DEMO"; fi
mkdir -p "$DEMO/bin"
cd "$DEMO" || exit 1
```

The usual safe start. This time we also create a `bin` folder to practise `PATH`.

---

## Part 1: writing a script from a script

```bash
cat > hello.sh << 'EOF'
#!/usr/bin/env bash
# hello.sh - my first script
echo "Hello, $(whoami)!"
echo "Today is $(date +%A)"
EOF
```

A here-document (Lesson 5) writes everything up to `EOF` into `hello.sh`.

**Why `'EOF'` in quotes?** The quotes stop the **outer** script from expanding `$(whoami)` while writing. We want those characters saved into `hello.sh` untouched, so they run when *hello.sh* runs. Try removing the quotes: the file would then contain "Hello, root!" already filled in (the outer script did the work).

`date +%A` prints the weekday name (Sunday). `+%A` is a format string; see `man date`.

---

## Part 2: three ways to run

```bash
bash hello.sh          # way 1
./hello.sh             # way 2, fails first: no x bit
chmod +x hello.sh
./hello.sh             # way 2, works now
source ./hello.sh      # way 3
```

You see the same greeting each time, but the **mechanism** differs:

| Way | What happens |
|-----|--------------|
| `bash hello.sh` | starts a new Bash, which reads the file |
| `./hello.sh` | the system reads the shebang, starts that interpreter on the file |
| `source ./hello.sh` | **the current shell** reads and runs the lines itself |

---

## Part 3: the big difference (child vs source)

`setvar.sh` does two things: sets `MYVAR` and does `cd subfolder`.

```bash
MYVAR="(not set yet)"
bash setvar.sh
echo "...MYVAR='$MYVAR' folder=$(basename "$PWD")"
```

- `basename "$PWD"` prints only the **last part** of the current folder path.
- After `bash setvar.sh`: **nothing changed**. The variable and the `cd` happened inside a child process that has already finished.
- After `source ./setvar.sh`: **both changed**, because the commands ran in *this* shell.

```bash
cd "$DEMO" || exit 1
```

We walk back to the demo folder, since `source` moved us.

> **Rule of thumb:** a program can change **its own** world, never its parent's. That is why you must `source ~/.bashrc` (not run it) for changes to affect your terminal.

---

## Part 4: exit codes

```bash
./ok.sh
echo "exit code of ok.sh   : $?"      # 0
./fail.sh 2>&1
echo "exit code of fail.sh : $?"      # 3
```

- `exit 0` / `exit 3` in the script sets the code
- `$?` reads the **last** command's code. Read it **immediately**, because the next command (even `echo`) replaces it
- In `fail.sh`, `echo "..." >&2` sends the message to **stderr**: errors belong there, so they don't pollute normal output (Lesson 5)

```bash
./ok.sh   && echo "..."          # && = "and then", only if success
./fail.sh 2> /dev/null && ...    # not shown: fail.sh failed
./fail.sh 2> /dev/null || echo "..."    # || = "or else", only if failure
```

The last pattern:

```bash
./fail.sh 2> /dev/null || { echo "handling the failure..."; }
```

`{ ...; }` groups commands. After `||`, the whole group runs **only** on failure. (Spaces after `{` and the `;` before `}` are required.)

---

## Part 5: PATH

```bash
cat > bin/greet << 'EOF'
...
EOF
chmod +x bin/greet
```

First we check: `command -v greet` finds nothing; Bash doesn't know about our `bin` folder yet.

```bash
export PATH="$DEMO/bin:$PATH"
```

Read this as: *"New PATH = our bin folder, then a colon, then the old PATH."* Folders on the left are searched first. `export` makes the variable visible to programs we start (Lesson 10).

Now `greet` works by name. In real life you add the `export` line to `~/.bashrc` once.

---

## Part 6: a small useful script

```bash
echo "Disk    : $(df -h . | tail -n 1 | awk '{print $4 " free of " $2}')"
```

Mini-pipeline inside `$( )`:

1. `df -h .` shows disk usage for the current folder in readable sizes (header + one row)
2. `tail -n 1` keeps the data row
3. `awk '{print $4 " free of " $2}'` prints column 4 (available) and column 2 (size)

You see: `Disk : 10G free of 252G` (your numbers will differ). The script also follows our **template**: shebang, header comment, `exit 0`.

---

## Part 7: debugging

```bash
bash -x hello.sh 2>&1 | head -n 6
```

`-x` ("xtrace") prints every command **after** Bash expands it, prefixed by `+`. You see `+ echo 'Hello, root!'`, with the `$(whoami)` already replaced. A `++` prefix marks commands run inside `$( )`. Trace output goes to stderr, hence `2>&1`.

```bash
bash -n broken.sh
```

`broken.sh` starts an `if` but never writes `fi`. `-n` reads the script **without running** it and reports: `syntax error: unexpected end of file`. Exit code `2`. Use it to catch typos before running something dangerous.

---

## Part 8: the CRLF trap

```bash
printf '#!/usr/bin/env bash\r\necho "hi ..."\r\n' > crlf.sh
```

`printf` lets us write the invisible `\r` (carriage return) characters, exactly as Windows editors do.

```bash
./crlf.sh 2>&1
# /usr/bin/env: 'bash\r': No such file or directory
```

The system tried to find a program literally named `bash` + carriage return. The error text shows `\r`, which is your clue.

```bash
grep -c $'\r' crlf.sh        # counts lines containing a carriage return
tr -d '\r' < crlf.sh > fixed.sh
```

- `$'\r'` is Bash syntax for "the real carriage-return character"
- `tr -d '\r'` deletes them, and `fixed.sh` runs fine

---

## Cleanup

```bash
cd "$HOME" || exit 1
rm -r "$DEMO"
```

---

## 🧪 Experiments

1. Comment out the cleanup, then try the scripts yourself: `cd ~/bash-practice/lesson9-demo`.
2. Edit `hello.sh` to print your own message, and run it three ways.
3. Remove the `'` quotes around `EOF` in Part 1 and compare `cat hello.sh`.
4. Add `exit 5` to the end of `report.sh` and check `$?`.
5. Make `broken.sh` correct (`fi`) and run `bash -n` again: silence means OK.
6. Write your own script `mycommand`, put it in `~/bin`, and run it from another folder.

---

## ✅ New words in this file

`#!/usr/bin/env bash` · `chmod +x` · `./script` · `source` · `exit N` · `$?` · `&&` · `||` · `{ ...; }` · `>&2` · `export PATH` · `basename` · `df -h` · `bash -n` · `bash -x` · `$'\r'` · `tr -d '\r'`

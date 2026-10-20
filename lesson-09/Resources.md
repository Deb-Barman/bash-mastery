# Lesson 9 — Resources

## 📋 Cheat Sheet

| Goal | Command |
|------|---------|
| Create/edit a script | `nano script.sh` (`Ctrl+O` save, `Ctrl+X` exit) |
| First line | `#!/usr/bin/env bash` |
| Make runnable | `chmod +x script.sh` |
| Run (child shell) | `./script.sh` or `bash script.sh` |
| Run in current shell | `source script.sh` or `. script.sh` |
| Last exit code | `echo $?` |
| Exit with success / failure | `exit 0` / `exit 1` |
| Print to stderr | `echo "error" >&2` |
| Syntax check (no run) | `bash -n script.sh` |
| Trace every command | `bash -x script.sh` |
| Lint | `shellcheck script.sh` |
| Add to PATH (permanent) | add `export PATH="$HOME/bin:$PATH"` to `~/.bashrc` |
| Fix CRLF | `tr -d '\r' < in.sh > out.sh` or `dos2unix script.sh` |

**Run ways compared**

| | `bash f` | `./f` | `source f` |
|--|---------|-------|-----------|
| needs `x` bit | no | yes | no |
| uses shebang | no | yes | no |
| separate process | yes | yes | **no** |
| can change my shell (cd, variables) | no | no | **yes** |

**Exit codes:** `0` OK · `1` general error · `2` misuse · `126` not executable · `127` not found · `130` Ctrl+C

**Chaining:** `A && B` (B if A ok) · `A || B` (B if A failed) · `A; B` (always)

**Script template**

```bash
#!/usr/bin/env bash
#
# name.sh - what it does
# Usage: ./name.sh
#

echo "Start"
# ... commands ...
echo "Done"
exit 0
```

---

## 🏋️ Exercises

Work in `~/bash-practice/ex9`.

**Level A: Easy**
1. Create `hi.sh` that prints `Hi from my script` and run it with `bash`.
2. Make it executable and run it with `./hi.sh`.
3. Make `hi.sh` also print today's date and your username.
4. Check the exit code of `hi.sh`.

**Level B: Medium**
5. Write `fail.sh` that prints an error to **stderr** and exits with code `4`. Show that the code is `4`.
6. Write one command line that runs `fail.sh` and prints `FAILED` only if it fails.
7. Write one command line that runs `hi.sh` and then prints `OK` only if it succeeded.
8. Write `where.sh` that does `cd /tmp`. Show that running it with `bash` does **not** move you, but `source` does.
9. Use `bash -x` on `hi.sh` and explain what the `+` lines mean.
10. Create `bin` inside `ex9`, put a script called `hello` in it, and run `hello` **by name** (temporary PATH change is enough).

**Level C: Challenge**
11. Write `backup.sh` that: creates folder `backup-$(date +%F)` if missing, copies all `*.txt` files into it, prints how many were copied, and exits `0`. (Practice with a few `.txt` files.)
12. Make `backup.sh` exit `1` with an error message to stderr if there are **no** `.txt` files. (Hint: `ls *.txt` or a count.)
13. Write a script with a deliberate typo (missing `fi`), find it with `bash -n`, fix it.
14. Create a file with CRLF endings using `printf`, see it fail, then fix it with `tr`.
15. (Think!) Why can `source script.sh` be dangerous if the script contains `exit`?
16. (Think!) Why does a script that does `cd /tmp` not leave you in `/tmp` when you run it with `./script.sh`?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
mkdir -p ~/bash-practice/ex9 && cd ~/bash-practice/ex9

# 1
cat > hi.sh << 'EOF'
#!/usr/bin/env bash
echo "Hi from my script"
EOF
bash hi.sh

# 2
chmod +x hi.sh
./hi.sh

# 3
cat > hi.sh << 'EOF'
#!/usr/bin/env bash
echo "Hi from my script"
echo "Date: $(date +%F)"
echo "User: $(whoami)"
EOF

# 4
./hi.sh; echo $?                    # 0

# 5
cat > fail.sh << 'EOF'
#!/usr/bin/env bash
echo "error: something broke" >&2
exit 4
EOF
chmod +x fail.sh
./fail.sh; echo $?                  # 4

# 6
./fail.sh 2>/dev/null || echo "FAILED"

# 7
./hi.sh && echo "OK"

# 8
printf '#!/usr/bin/env bash\ncd /tmp\n' > where.sh
bash where.sh; pwd                  # unchanged
source where.sh; pwd                # /tmp
cd ~/bash-practice/ex9

# 9
bash -x hi.sh
# "+" = a command Bash is about to run (after expanding variables).
# "++" = a command inside $( ), e.g. ++ whoami

# 10
mkdir -p bin
printf '#!/usr/bin/env bash\necho "hello by name"\n' > bin/hello
chmod +x bin/hello
PATH="$PWD/bin:$PATH" hello
# or: export PATH="$PWD/bin:$PATH"; hello

# 11
cat > backup.sh << 'EOF'
#!/usr/bin/env bash
dest="backup-$(date +%F)"
mkdir -p "$dest"
cp ./*.txt "$dest"/
echo "Copied $(ls "$dest" | wc -l) file(s) into $dest"
exit 0
EOF
chmod +x backup.sh
touch a.txt b.txt; ./backup.sh

# 12
cat > backup.sh << 'EOF'
#!/usr/bin/env bash
if ! ls ./*.txt > /dev/null 2>&1; then
    echo "error: no .txt files to back up" >&2
    exit 1
fi
dest="backup-$(date +%F)"
mkdir -p "$dest"
cp ./*.txt "$dest"/
echo "Copied $(ls "$dest" | wc -l) file(s) into $dest"
EOF
# (if / ! / fi are fully explained in Lesson 12; read it as English for now)

# 13
printf '#!/usr/bin/env bash\nif true; then\n  echo hi\n' > typo.sh
bash -n typo.sh                     # syntax error: unexpected end of file
printf 'fi\n' >> typo.sh            # fix
bash -n typo.sh && echo "syntax OK"

# 14
printf '#!/usr/bin/env bash\r\necho crlf\r\n' > crlf.sh
chmod +x crlf.sh
./crlf.sh                           # fails: 'bash\r'
tr -d '\r' < crlf.sh > fixed.sh && chmod +x fixed.sh && ./fixed.sh

# 15
# source runs the lines in YOUR shell. An 'exit' then exits YOUR shell,
# which can close your terminal window.

# 16
# The script ran in a child process. The child's working folder changed,
# the parent's (your terminal's) didn't. A child cannot change its parent.
```

</details>

---

## 🐞 Common beginner errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Permission denied` | no execute bit | `chmod +x script.sh` |
| `command not found` (for `script.sh`) | not in PATH, missing `./` | `./script.sh` |
| `bad interpreter` / `'bash\r'` | CRLF line endings | `tr -d '\r'` / `dos2unix` |
| `syntax error: unexpected end of file` | missing `fi` / `done` / `}` / closing quote | `bash -n`, check pairs |
| `: No such file or directory` on the shebang | wrong path in `#!` | use `#!/usr/bin/env bash` |
| variables disappear after running | ran in a child shell | use `source` when you need them |
| terminal closes unexpectedly | `source` of a script with `exit` | run it normally instead |
| `unexpected token near '('` in `sh` | ran Bash script with `sh` | `bash script.sh` |

---

## 💡 Habits of pro coders

1. **Always** shebang, header comment, and `exit 0`.
2. **Test with `bash -n` and `bash -x`**, and run **ShellCheck** on everything.
3. **Errors go to stderr** (`>&2`) and use a **non-zero exit code**.
4. **Make scripts safe to re-run** (use `mkdir -p`, check before overwrite).
5. Keep your tools in `~/bin` and **version them with Git**.
6. **Name scripts clearly:** `backup-photos.sh`, not `script2.sh`.

## 📚 Extra resources

- **shellcheck.net:** paste a script, get expert feedback
- **explainshell.com:** decode any line
- **Bash Guide for Beginners (Machtelt Garrels)**: free classic book
- **Google Shell Style Guide** (google.github.io/styleguide/shellguide.html): professional conventions
- **`man bash`**: section "SHELL GRAMMAR" and "EXIT STATUS"

## 🧠 Self-check

1. What does the shebang do, and why `env bash`?
2. How do `bash f`, `./f`, and `source f` differ?
3. What does exit code `0` mean? How do you read the last one?
4. Why must a script's errors go to stderr?
5. What does `bash -x` show you?
6. What is the CRLF problem, and how do you fix it?

## ➡️ Next: Lesson 10 — Variables & Quoting (`"$var"`, `${var}`, `$(command)`, `$(( ))`, `export`)

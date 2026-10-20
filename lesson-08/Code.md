# Lesson 8 — Code Explained (line by line)

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson8-demo`, never uses `sudo`, and restores permissions before deleting its demo folder.

> **Run it as a normal user** (your everyday login). If you run it as `root`, Parts 6 and 7 are skipped, because root ignores permissions. I tested it both ways.
> Needs GNU `stat -c` (Linux, WSL, Git Bash). On macOS replace `stat -c '%A (%a)'` with `stat -f '%Sp (%Lp)'`.

---

## The setup

```bash
if [ -d "$DEMO" ]; then
    chmod -R u+rwx "$DEMO"
    rm -r "$DEMO"
fi
```

If an earlier run left locked files (like `chmod 000`), `rm` could fail. So we **unlock first**, then delete. `-R` means recursive.

```bash
IS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=1
fi
```

`id -u` prints your numeric user id. Root is always `0`. `-eq` is "equals" for **numbers**. We store the answer in a variable so later parts can adapt. (Real scripts do this constantly.)

---

## Part 1: who am I?

```bash
whoami     # deb
id         # uid=1000(deb) gid=1000(deb) groups=...
groups     # deb sudo ...
```

These tell you who Linux believes is running your commands.

---

## Part 2: reading `ls -l`

```bash
ls -l
ls -l notes.txt | cut -c1-10
```

`cut -c1-10` keeps the first 10 characters, which is exactly the permission column:

```
-rw-r--r--
│└┬┘└┬┘└┬┘
│ │  │  └ other: r--
│ │  └ group: r--
│ └ user: rw-
└ type: - (file)
```

Folders start with `d`, as in `drwxr-xr-x`.

---

## Part 3: letters

Each line changes one thing, and `stat -c '%A (%a)'` shows letters **and** number:

| Command | Result | Number |
|---------|--------|--------|
| `chmod u=rw,g=r,o=` | `-rw-r-----` | 640 |
| `chmod u+x` | `-rwxr-----` | 740 |
| `chmod g+w` | `-rwxrw----` | 760 |
| `chmod o+r` | `-rwxrw-r--` | 764 |
| `chmod go-rwx` | `-rwx------` | 700 |
| `chmod a+r` | `-rwxr--r--` | 744 |

Watch the number change as the letters change. That's how you learn to convert in your head.

`=` **sets exactly**, `+` **adds**, `-` **removes**. `go-rwx` means "from group and other, remove r, w and x."

---

## Part 4: numbers

```bash
chmod 754 numbers.txt
```

`7` = 4+2+1 = `rwx` · `5` = 4+0+1 = `r-x` · `4` = 4+0+0 = `r--` → `-rwxr-xr--`.

Look at the four common values in the output (644, 755, 600, 700) until you can picture them.

---

## Part 5: the execute bit

```bash
cat > hello.sh << 'EOF'
#!/usr/bin/env bash
echo "Hello from hello.sh!"
EOF
```

A new file has **no** execute bit (umask removes it; see Part 9).

```bash
./hello.sh 2>&1
```

`./hello.sh` asks the system to *run the file as a program*. It needs `x`. Result: `Permission denied`. (`2>&1` just makes sure the error appears in our output in order.)

```bash
bash hello.sh
```

Here **you** run `bash`, and `bash` only needs to **read** the file, so it works.

```bash
chmod +x hello.sh
./hello.sh
```

Now it runs directly. This is the most common `chmod` in daily life.

---

## Part 6: a real "Permission denied"

```bash
echo "top secret" > secret.txt
chmod 000 secret.txt
cat secret.txt
```

With `000`, nobody (including the owner) has any access. A normal user sees:

```
cat: secret.txt: Permission denied
```

Root can still read it, so for root the script skips this step and says why.

```bash
chmod 600 secret.txt
```

The owner can read and write again.

---

## Part 7: directories

```bash
mkdir vault
touch vault/item.txt
chmod u-x vault
```

Now the owner has `rw-` on the folder: **no `x`**.

As a normal user you will see:

- `cd vault` → `Permission denied` (no `x` = cannot enter)
- `ls vault` → **still lists `item.txt`**, because `r` lets you read the *names*

That is the "`r` without `x`" case from the lesson: you can see names but can't open anything properly. (`ls -l vault` would show errors, because reading details needs `x`.)

```bash
chmod u+x vault
```

Restores access.

---

## Part 8: chown

```bash
MYUSER="$(id -un)"
MYGROUP="$(id -gn)"
chown "$MYUSER:$MYGROUP" notes.txt
```

`id -un` and `id -gn` print your user name and group name. Setting a file's owner to **yourself** needs no special rights, so this is safe to demo. Giving it to **another** user needs root (`sudo chown alice file`), which we deliberately don't run.

---

## Part 9: umask

```bash
( umask 022; touch default.txt; mkdir default-dir )
( umask 077; touch private.txt;  mkdir private-dir )
```

Parentheses `( ... )` run the commands in a **subshell**: a temporary copy of Bash. A `umask` change inside it disappears when it ends, so your real settings are untouched (the last line proves it).

| umask | New file | New folder |
|-------|----------|------------|
| `022` | 666 − 022 = **644** | 777 − 022 = **755** |
| `077` | 666 − 077 = **600** | 777 − 077 = **700** |

(The subtraction is a simplification; technically it clears bits, but for these common values it works the same.)

---

## Part 10: the sticky bit

```bash
ls -ld /tmp | cut -c1-10      # drwxrwxrwt
```

`-d` shows the folder itself (not its contents). The final `t` is the **sticky bit**: everyone can create files in `/tmp`, but each person can only delete their own.

---

## Part 11: a summary table

```bash
printf '%-5s %-10s %s\n' "NUM" "LETTERS" "USE"
```

`printf` with `%-5s` and `%-10s` pads columns to fixed widths, so the table lines up. (Format codes: `%s` text, `-` left-align, the number is the width.)

---

## Cleanup

```bash
cd "$HOME" || exit 1
chmod -R u+rwx "$DEMO"
rm -r "$DEMO"
```

Leave the folder, unlock everything (we had a `chmod 000` file earlier), then delete.

---

## 🧪 Experiments

1. Comment out the cleanup, then explore: `ls -l ~/bash-practice/lesson8-demo`.
2. Make `notes.txt` unwritable (`chmod 444`) and try `echo more >> notes.txt`. Read the error.
3. `chmod 640 notes.txt`, then use `stat -c '%A' notes.txt` to confirm the letters.
4. Predict `chmod 640` in letters **before** you run it.
5. Create a folder with `chmod 555` (no write) and try `touch newfile` inside it. What happens?
6. Run `umask 077` in a terminal, create a file, check its permissions, then close the terminal. (Back to normal.)

---

## ✅ New words in this file

`whoami` · `id -u/-un/-gn` · `groups` · `chmod` (letters/numbers/-R) · `chown` · `stat -c` · `umask` · `( subshell )` · `-eq` · `ls -ld` · `printf '%-5s'`

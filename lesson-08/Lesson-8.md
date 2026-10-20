# Lesson 8 — Permissions & Users

**Level 2 · Power Tools · Time: ~60 minutes**

---

## 🎯 What you will learn

- Read the mysterious `-rwxr-xr--` in `ls -l`
- Know who can do what to a file or folder
- Change permissions (`chmod`) in two ways: letters and numbers
- Change owners (`chown`, `chgrp`)
- Understand `sudo` and the `root` user
- Understand `umask` (default permissions)
- Fix the most common error in all of Linux: **`Permission denied`**

> **Why it matters:** permissions are the reason your script says `Permission denied`, the reason attackers can't read your private keys, and the reason you must never run random commands with `sudo`.

---

## 1. Users and groups

Linux is multi-user. Every file belongs to **one user** and **one group**.

```bash
whoami           # your username
id               # your user id, group id, and all your groups
groups           # just the group names
```

Typical `id` output:

```
uid=1000(deb) gid=1000(deb) groups=1000(deb),27(sudo)
```

Special user: **root** (uid 0), the administrator. Root ignores almost all permission checks. That power is why we are careful with it.

---

## 2. Reading `ls -l`

```bash
ls -l
```

```
-rwxr-xr--  1  deb  staff  1520  Oct 10 15:10  backup.sh
│└┬┘└┬┘└┬┘     │    │
│ │  │  │      │    └ group that owns it
│ │  │  │      └ user that owns it
│ │  │  └ OTHER (everybody else)
│ │  └ GROUP
│ └ USER (the owner)
└ type: - file · d directory · l symbolic link
```

Three **sets** of three letters:

| Set | Who | Example above |
|-----|-----|---------------|
| user (u) | the owner | `rwx` read, write, execute |
| group (g) | members of the file's group | `r-x` read, execute |
| other (o) | everyone else | `r--` read only |

A `-` means "not allowed".

---

## 3. What `r`, `w`, `x` mean

| Letter | On a **file** | On a **directory** |
|--------|---------------|--------------------|
| `r` read | see the contents | **list** the names inside (`ls`) |
| `w` write | change the contents | **create, rename, delete** files inside |
| `x` execute | run it as a program | **enter** it (`cd`) and reach things inside |

Important directory facts:

- To `cd` into a folder you need `x` on it.
- To delete a file you need `w` **on the folder**, not on the file.
- A folder with `r` but no `x`: you can see names but not open anything.

---

## 4. Numbers: the octal system

Each letter has a value:

```
r = 4     w = 2     x = 1     - = 0
```

Add them up **per set**:

| Letters | Math | Number |
|---------|------|--------|
| `rwx` | 4+2+1 | **7** |
| `rw-` | 4+2+0 | **6** |
| `r-x` | 4+0+1 | **5** |
| `r--` | 4+0+0 | **4** |
| `---` | 0 | **0** |

So `rwxr-xr--` = **7 5 4** = `754`.

The ones you'll use 95% of the time:

| Number | Letters | Used for |
|--------|---------|----------|
| `644` | `rw-r--r--` | normal files |
| `755` | `rwxr-xr-x` | scripts, programs, public folders |
| `600` | `rw-------` | private files (SSH keys, secrets) |
| `700` | `rwx------` | private folders, private scripts |
| `664` / `775` | group-writable | shared project files / folders |

⚠️ **`777` means everyone can do everything.** It's almost never the right answer. If a tutorial says `chmod 777`, find a better fix.

---

## 5. `chmod`: change mode

### Number style

```bash
chmod 755 script.sh
chmod 644 notes.txt
chmod 600 secret.txt
```

### Letter style (adds/removes only what you name)

```
chmod  WHO  OPERATOR  PERMISSIONS  file
        u g o a   + - =   r w x
```

```bash
chmod u+x script.sh       # give the owner execute   (the classic!)
chmod +x script.sh        # execute for everyone (a is the default)
chmod g-w file            # remove write from the group
chmod o-rwx file          # remove all access from others
chmod a+r file            # everybody can read
chmod u=rw,g=r,o= file    # set exactly: rw-r-----
chmod -R u+rwX project/   # recursive. Capital X = x only on folders and already-executable files
```

**When to use which:** letters for small tweaks (`+x`), numbers for setting everything exactly.

---

## 6. Making a script executable

```bash
./hello.sh               # bash: ./hello.sh: Permission denied
chmod +x hello.sh
./hello.sh               # works!
```

Without the execute bit you can still run it by naming the interpreter, because then `bash` only needs to **read** the file:

```bash
bash hello.sh
```

---

## 7. Changing owner: `chown` and `chgrp`

Only root can give files away. (Regular users can't hand their files to others.)

```bash
sudo chown alice file.txt           # new owner
sudo chown alice:devs file.txt      # new owner and group
sudo chown :devs file.txt           # group only
sudo chgrp devs file.txt            # group only (alternative)
sudo chown -R deb:deb ~/project     # recursive
```

---

## 8. `sudo`: borrow root powers for ONE command

```bash
sudo apt update              # run as root
sudo !!                      # repeat the last command with sudo
sudo -i                      # open a root shell (dangerous, be careful)
```

Rules to live by:

1. **Understand a command before you put `sudo` in front of it.**
2. Never paste `sudo` commands from the internet blindly.
3. If something says `Permission denied`, the first fix is **not** `sudo`. First check *who owns it* and *what permissions it has*. Often `chmod` or `chown` on your own files is the correct answer.
4. Never `sudo` things in your home folder if you can avoid it. Root-owned files in `~` cause pain later.

---

## 9. `umask`: the default permissions

New files start from a maximum and the **umask** takes bits away:

- Files start at `666` (no execute by default, for safety)
- Folders start at `777`

```bash
umask          # 0022 on most systems
```

With `022`:

```
files:   666 - 022 = 644   (rw-r--r--)
folders: 777 - 022 = 755   (rwxr-xr-x)
```

With `077` (private):

```
files:   600   folders:   700
```

Change it for one subshell:

```bash
( umask 077; touch private.txt )     # parentheses = run in a mini-shell, umask change disappears after
```

---

## 10. Quick look at the special bits

```bash
ls -ld /tmp          # drwxrwxrwt  <- the "t" is the sticky bit
```

| Bit | Seen as | Meaning |
|-----|---------|---------|
| **sticky** on a folder | `t` | everyone may add files, but you can delete only your own (that's `/tmp`) |
| **setgid** on a folder | `s` in group | new files inherit the folder's group (great for shared team folders) |
| **setuid** on a program | `s` in user | runs with the **owner's** rights (e.g. `passwd`). Powerful and risky |

You do not need to set these yet, only recognize them.

---

## 11. Seeing exact permissions

```bash
ls -l file               # letters
stat -c '%a %A %U:%G %n' file    # numbers + letters + owner  (Linux/GNU)
stat -f '%Lp %Sp %Su:%Sg %N' file   # macOS version
```

---

## 12. Fixing "Permission denied": a decision path

```
Permission denied
      │
      ├─ running a script?      →  ls -l script.sh   → no x?  chmod +x script.sh
      ├─ can't read/edit a file? → ls -l file        → who owns it? → chmod / chown
      ├─ can't enter a folder?   → ls -ld folder     → missing x? → chmod +x folder
      ├─ can't create a file in a folder? → need w on the FOLDER
      └─ system file / package?  → this really may need sudo (read what you're running first!)
```

Also remember `Operation not permitted` often means **only the owner (or root) may do that** (e.g. `chmod` on a file you don't own).

---

## ⚠️ Gotchas

1. `chmod -R 777 .` "to make it work" is a security hole and hides the real problem.
2. Execute bit on **directories** means "enter", not "run".
3. Editing a file needs `w` on the **file**; deleting it needs `w` on the **folder**.
4. `sudo echo hi > /root/file` fails because the **redirect** runs as you (Lesson 5). Use `| sudo tee`.
5. Windows drives mounted in WSL often show everything as `777`. That's the mount, not a bug in your script.

---

## ✅ Summary

- Every file: an owner, a group, and `rwx` for user / group / other
- `r=4 w=2 x=1`: `755` scripts, `644` files, `600` secrets
- `chmod +x script.sh` makes scripts runnable
- `chown` changes owner (root only); `sudo` = one-off root power, use with care
- `umask` decides defaults; `022` → files `644`, folders `755`
- Directories: `x` = enter, `w` = add/remove entries, `r` = list names

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

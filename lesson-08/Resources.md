# Lesson 8 — Resources

## 📋 Cheat Sheet

**Reading permissions**

```
-rwxr-xr--   type | user | group | other
 d = folder    - = file    l = link
```

| Letter | Value | File | Folder |
|--------|-------|------|--------|
| `r` | 4 | read contents | list names |
| `w` | 2 | modify contents | add / rename / delete entries |
| `x` | 1 | run it | enter it (`cd`) |

**Octal quick table**

| Number | Letters | Number | Letters |
|--------|---------|--------|---------|
| 7 | `rwx` | 3 | `-wx` |
| 6 | `rw-` | 2 | `-w-` |
| 5 | `r-x` | 1 | `--x` |
| 4 | `r--` | 0 | `---` |

**Common modes:** `644` files · `755` scripts/public folders · `600` secrets · `700` private folders · `664`/`775` shared with a group

**Commands**

| Goal | Command |
|------|---------|
| Make script runnable | `chmod +x script.sh` |
| Exact permissions | `chmod 640 file` |
| Add / remove | `chmod g+w file` · `chmod o-rwx file` |
| Set exactly (letters) | `chmod u=rwx,g=rx,o= file` |
| Recursive | `chmod -R u+rwX dir` |
| Change owner | `sudo chown user:group file` |
| Change group | `sudo chgrp group file` |
| Who am I? | `whoami` · `id` · `groups` |
| Show exact modes | `stat -c '%a %A %U:%G %n' file` |
| Default permissions | `umask` |
| Folder itself, not contents | `ls -ld dir` |

**`who` letters:** `u` user · `g` group · `o` other · `a` all
**Operators:** `+` add · `-` remove · `=` set exactly

---

## 🏋️ Exercises

Set up:

```bash
mkdir -p ~/bash-practice/ex8 && cd ~/bash-practice/ex8
touch report.txt script.sh key.pem
mkdir shared
```

**Level A: Easy**
1. Show the permissions of all files in long format.
2. Make `script.sh` executable for its owner only.
3. Convert `rwxr-xr--` to a number.
4. Convert `640` to letters.

**Level B: Medium**
5. Set `report.txt` so the owner can read/write, the group can read, others get nothing. Use **letters**, then verify.
6. Do the same with **numbers**.
7. Make `key.pem` private: only the owner can read and write.
8. Remove write permission from the group on `report.txt` (without touching other bits).
9. Show only the permission string (first 10 characters) of `shared`.
10. What will `chmod 755 shared` do, in letters?

**Level C: Challenge**
11. Make `shared` a folder anyone can enter and list, but only the owner can change.
12. Create a file with default permissions **600** without using `chmod` afterwards. (Hint: `umask` in a subshell.)
13. Print the numeric permission of `report.txt` (just the number).
14. Give the group the same permissions the owner has on `report.txt`, in one command. (Hint: `g=u`.)
15. (Think!) You can't delete a file in a folder, but the file is yours and `rw-`. Why? What do you fix?
16. (Think!) A tutorial says `chmod -R 777 /var/www`. Name two reasons that's a bad fix and one better approach.
17. (Think!) Why does `sudo echo hi > /root/file.txt` fail, and what works?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1
ls -l

# 2
chmod u+x script.sh

# 3
# rwx=7  r-x=5  r--=4  → 754

# 4
# 6=rw-  4=r--  0=---  → rw-r-----

# 5
chmod u=rw,g=r,o= report.txt
ls -l report.txt                # -rw-r-----

# 6
chmod 640 report.txt

# 7
chmod 600 key.pem

# 8
chmod g-w report.txt

# 9
ls -ld shared | cut -c1-10

# 10
# 7=rwx  5=r-x  5=r-x  → rwxr-xr-x  (owner full; everyone else can enter and list)

# 11
chmod 755 shared

# 12
( umask 077; touch private.txt )
stat -c '%a' private.txt          # 600

# 13
stat -c '%a' report.txt
# macOS: stat -f '%Lp' report.txt

# 14
chmod g=u report.txt              # group := same as user

# 15
# Deleting a file needs 'w' (and 'x') on the FOLDER that contains it, not on
# the file. Fix the folder: chmod u+wx folder   (or ask its owner to).

# 16
# 1) Everyone can now modify or replace your website's files: a serious
#    security hole.  2) It hides the real problem (wrong owner or group).
# Better: give the web server's user/group the right ownership and use
#    chown -R user:group /var/www ; find /var/www -type d -exec chmod 755 {} +
#    find /var/www -type f -exec chmod 644 {} +

# 17
# The ">" redirect is performed by YOUR shell (not root) before sudo runs.
# Use:   echo hi | sudo tee /root/file.txt > /dev/null
```

</details>

---

## 🐞 Common beginner errors

| Message | Cause | Fix |
|---------|-------|-----|
| `bash: ./script.sh: Permission denied` | no `x` bit | `chmod +x script.sh` |
| `cat: file: Permission denied` | no `r` | check `ls -l`; `chmod u+r` if it's yours |
| `cd: dir: Permission denied` | no `x` on the folder | `chmod u+x dir` |
| `cannot create regular file: Permission denied` | no `w` on the **folder** | `chmod u+w folder` |
| `rm: cannot remove 'f': Permission denied` | no `w` on the **folder** | same |
| `chmod: changing permissions of 'f': Operation not permitted` | you don't own it | use `sudo` only if appropriate, or ask the owner |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` (ssh) | key is too open | `chmod 600 key.pem` |
| `sudo: command not found` / `not in sudoers file` | your user isn't an admin | ask the admin; don't work around it |

---

## 💡 Habits of pro coders

1. **Principle of least privilege:** give only the access that's needed.
2. **Never `chmod 777`.** Find the real owner/group problem instead.
3. **`ls -l` first, then fix**: look before you `sudo`.
4. **Private things get `600` / `700`**: SSH keys, `.env`, tokens.
5. **Scripts get `755`** (or `700` if only you use them).
6. **Use `chmod -R` carefully:** files and folders need different modes (`X`, or `find ... -type f/d`).

## 📚 Extra resources

- **`man chmod`**, **`man chown`**, **`man umask`**, **`man 7 credentials`**
- **chmod-calculator.com:** click boxes, get the number
- **explainshell.com:** paste `chmod u=rwx,g=rx,o= file`
- **OverTheWire Bandit:** several levels use permissions and `sudo`-less tricks
- **Linux Journey (linuxjourney.com):** friendly "Users and Permissions" lessons

## 🧠 Self-check

1. What do the three sets of `rwx` stand for?
2. What number is `rw-r--r--`?
3. What does `x` mean on a **folder**?
4. Why is `chmod 777` usually wrong?
5. Why can `bash script.sh` run when `./script.sh` says "Permission denied"?
6. What does `umask 022` give you for new files and folders?

## ➡️ Next: Lesson 9 — Your First Real Script (shebang, `chmod +x`, running, exit codes, `PATH`)

> 🎉 **Level 2 complete after Lesson 8!** You can combine commands, match files, process text, and control access. Level 3 teaches you to *write programs*.

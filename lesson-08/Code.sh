#!/usr/bin/env bash
# ==========================================================
# Lesson 8 - Code.sh
# Topic : ls -l, chmod (letters + numbers), executable bit,
#         id/whoami/groups, chown, umask, sticky bit
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson8-demo
#         and cleans up after itself. Never uses sudo.
# Note  : uses GNU `stat -c` (Linux / WSL / Git Bash).
#         On macOS use:  stat -f '%Lp %Sp %N' file
# ==========================================================

DEMO="$HOME/bash-practice/lesson8-demo"

if [ -d "$DEMO" ]; then
    chmod -R u+rwx "$DEMO"          # make sure we are allowed to delete it
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

IS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=1
fi

echo "Working in: $(pwd)"
echo ""

# --- PART 1: who am I? -------------------------------------
echo "== Part 1: users and groups =="
echo "whoami : $(whoami)"
echo "id     : $(id)"
echo "groups : $(groups)"
if [ "$IS_ROOT" -eq 1 ]; then
    echo "NOTE   : you are ROOT. Root ignores most permission checks, so"
    echo "         some 'Permission denied' demos below will be skipped."
fi
echo ""

# --- PART 2: read ls -l ------------------------------------
echo "== Part 2: reading ls -l =="
echo "hello" > notes.txt
mkdir projects
ls -l
echo ""
echo "Anatomy of the first column of notes.txt:"
echo "  $(ls -l notes.txt | cut -c1-10)  -> type + user + group + other"
echo ""

# --- PART 3: chmod with letters ----------------------------
echo "== Part 3: chmod with letters =="
touch letters.txt
chmod u=rw,g=r,o= letters.txt
echo "u=rw,g=r,o=      -> $(stat -c '%A (%a)' letters.txt)"
chmod u+x letters.txt
echo "u+x              -> $(stat -c '%A (%a)' letters.txt)"
chmod g+w letters.txt
echo "g+w              -> $(stat -c '%A (%a)' letters.txt)"
chmod o+r letters.txt
echo "o+r              -> $(stat -c '%A (%a)' letters.txt)"
chmod go-rwx letters.txt
echo "go-rwx           -> $(stat -c '%A (%a)' letters.txt)"
chmod a+r letters.txt
echo "a+r              -> $(stat -c '%A (%a)' letters.txt)"
echo ""

# --- PART 4: chmod with numbers ----------------------------
echo "== Part 4: chmod with numbers =="
touch numbers.txt
chmod 644 numbers.txt; echo "644 -> $(stat -c '%A' numbers.txt)  normal file"
chmod 755 numbers.txt; echo "755 -> $(stat -c '%A' numbers.txt)  scripts, public folders"
chmod 600 numbers.txt; echo "600 -> $(stat -c '%A' numbers.txt)  private file"
chmod 700 numbers.txt; echo "700 -> $(stat -c '%A' numbers.txt)  private script/folder"
chmod 754 numbers.txt; echo "754 -> $(stat -c '%A' numbers.txt)  rwx r-x r--  (7=4+2+1, 5=4+1, 4)"
echo ""

# --- PART 5: making a script executable --------------------
echo "== Part 5: the execute bit =="
cat > hello.sh << 'EOF'
#!/usr/bin/env bash
echo "Hello from hello.sh!"
EOF
echo "Permissions now: $(stat -c '%A' hello.sh)  (no x anywhere)"
echo "Try ./hello.sh:"
./hello.sh 2>&1
echo "Run it with 'bash hello.sh' instead (needs only read permission):"
bash hello.sh
chmod +x hello.sh
echo "After chmod +x: $(stat -c '%A' hello.sh)"
echo "Try ./hello.sh again:"
./hello.sh
echo ""

# --- PART 6: what 'Permission denied' looks like -----------
echo "== Part 6: reading a file without permission =="
echo "top secret" > secret.txt
chmod 000 secret.txt
echo "secret.txt is now: $(stat -c '%A (%a)' secret.txt)"
if [ "$IS_ROOT" -eq 1 ]; then
    echo "(Skipped: root can read anything. Run this script as a normal user to see the error.)"
else
    cat secret.txt 2>&1
fi
chmod 600 secret.txt
echo "After chmod 600 the owner can read it again: $(cat secret.txt)"
echo ""

# --- PART 7: directories -----------------------------------
echo "== Part 7: directory permissions =="
mkdir vault
touch vault/item.txt
chmod u-x vault
echo "vault is now: $(stat -c '%A' vault)  (owner lost x = cannot enter)"
if [ "$IS_ROOT" -eq 1 ]; then
    echo "(Skipped: root ignores directory permissions.)"
else
    cd vault 2>&1
    ls vault 2>&1
fi
chmod u+x vault
echo "After chmod u+x: contents -> $(ls vault)"
echo ""

# --- PART 8: chown (to yourself, no sudo needed) -----------
echo "== Part 8: chown =="
MYUSER="$(id -un)"
MYGROUP="$(id -gn)"
chown "$MYUSER:$MYGROUP" notes.txt
echo "Owner:group of notes.txt -> $(stat -c '%U:%G' notes.txt)"
echo "To give a file to someone else you need root:  sudo chown alice:devs file"
echo ""

# --- PART 9: umask -----------------------------------------
echo "== Part 9: umask (default permissions) =="
echo "Current umask: $(umask)"
( umask 022; touch default.txt; mkdir default-dir )
echo "umask 022 -> file $(stat -c '%a' default.txt), folder $(stat -c '%a' default-dir)"
( umask 077; touch private.txt; mkdir private-dir )
echo "umask 077 -> file $(stat -c '%a' private.txt), folder $(stat -c '%a' private-dir)"
echo "(The ( ... ) runs in a mini-shell, so your real umask is unchanged: $(umask))"
echo ""

# --- PART 10: sticky bit on /tmp ---------------------------
echo "== Part 10: the sticky bit =="
echo "ls -ld /tmp -> $(ls -ld /tmp | cut -c1-10)   (the final 't' = sticky)"
echo ""

# --- PART 11: quick octal calculator -----------------------
echo "== Part 11: summary table of the numbers you really use =="
printf '%-5s %-10s %s\n' "NUM" "LETTERS" "USE"
printf '%-5s %-10s %s\n' "644" "rw-r--r--" "normal files"
printf '%-5s %-10s %s\n' "755" "rwxr-xr-x" "scripts, public folders"
printf '%-5s %-10s %s\n' "600" "rw-------" "secrets, SSH keys"
printf '%-5s %-10s %s\n' "700" "rwx------" "private folders"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
chmod -R u+rwx "$DEMO"
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

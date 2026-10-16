#!/usr/bin/env bash
# ==========================================================
# Lesson 2 - Code.sh
# Topic : mkdir, touch, cat, cp, mv, rm, rmdir, spaces
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson2-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson2-demo"

# Start fresh: remove an old demo folder if it exists.
# (We delete only this one exact path, never anything else.)
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi

mkdir -p "$DEMO"
cd "$DEMO" || exit 1        # if cd fails, stop the script (safety!)

echo "Working in: $(pwd)"
echo ""

# --- PART 1: mkdir -----------------------------------------
echo "== Part 1: mkdir =="
mkdir photos
mkdir docs music videos
mkdir -p projects/web/css
ls
echo ""

# --- PART 2: touch -----------------------------------------
echo "== Part 2: touch =="
touch notes.txt
touch a.txt b.txt c.txt
ls
echo ""

# --- PART 3: write into a file, then cat -------------------
echo "== Part 3: > and >> then cat =="
echo "Hello file"  > hello.txt     # > overwrites
echo "Second line" >> hello.txt    # >> appends
echo "Third line"  >> hello.txt
cat hello.txt
echo "-- with line numbers --"
cat -n hello.txt
echo ""

# --- PART 4: cp --------------------------------------------
echo "== Part 4: cp =="
cp hello.txt backup.txt             # copy a file
cp hello.txt photos/                # copy into a folder
cp -r photos photos-backup          # copy a folder (-r)
ls
echo "Inside photos/:"
ls photos
echo ""

# --- PART 5: mv (move and rename) --------------------------
echo "== Part 5: mv =="
mv backup.txt greeting.txt          # RENAME
mv greeting.txt docs/               # MOVE into docs
mv a.txt b.txt music/               # move two files at once
echo "docs/  : $(ls docs)"
echo "music/ : $(ls music)"
echo ""

# --- PART 6: names with spaces -----------------------------
echo "== Part 6: spaces in names =="
mkdir "my holiday photos"
touch "my holiday photos/beach day.txt"
ls "my holiday photos"
echo ""

# --- PART 7: brace expansion -------------------------------
echo "== Part 7: brace expansion {a,b,c} =="
mkdir -p project/{src,docs,tests}
touch project/src/main.sh project/docs/README.md
ls -R project
echo ""

# --- PART 8: rm and rmdir ----------------------------------
echo "== Part 8: deleting (careful!) =="
rm c.txt                            # delete one file
echo "Deleted c.txt"
rmdir videos                        # videos is empty, so this works
echo "Deleted empty folder: videos"
rm -r photos-backup                 # delete folder + contents
echo "Deleted folder: photos-backup"
echo ""

echo "What is left:"
ls
echo ""

# --- PART 9: what rmdir refuses to do (a safety feature) ---
echo "== Part 9: rmdir refuses non-empty folders =="
rmdir docs 2>&1 || echo "(As expected: docs is not empty, so it was protected.)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

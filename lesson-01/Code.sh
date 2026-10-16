#!/usr/bin/env bash
# ==========================================================
# Lesson 1 - Code.sh
# Topic : echo, pwd, ls, cd, comments, first script
# Run   : bash Code.sh
# ==========================================================

# --- PART 1: echo ------------------------------------------
echo "=============================="
echo "  Welcome to Bash, Lesson 1!"
echo "=============================="
echo ""                      # empty line

echo "Part 1: echo prints text"
echo "Hello, World!"
echo "My name is Deb"        # change this to YOUR name!
echo ""

# --- PART 2: pwd (where am I?) -----------------------------
echo "Part 2: pwd shows where I am"
pwd
echo ""

# --- PART 3: ls (what is here?) ----------------------------
echo "Part 3: ls shows what is in this folder"
ls
echo ""
echo "Same, but long format (ls -l):"
ls -l
echo ""

# --- PART 4: cd (move around) ------------------------------
# Important: a script moves only while it runs.
# When it ends, YOUR terminal stays where it was.
echo "Part 4: cd moves between folders"
echo "I start in:"
pwd

cd ..                        # go up one level
echo "After 'cd ..' I am in:"
pwd

cd ~                         # go to home folder
echo "After 'cd ~' I am in:"
pwd

cd -                         # jump back to the PREVIOUS folder (it prints that path too)
echo "After 'cd -' I jumped back to the folder I was in before ~ :"
pwd
echo ""

# --- PART 5: Little extras ---------------------------------
echo "Part 5: ready-made information commands"
echo "Today is   : $(date)"
echo "I am user  : $(whoami)"
echo "Computer   : $(hostname)"
echo "Bash version: $BASH_VERSION"
echo ""

# --- PART 6: Your first real automation --------------------
echo "Part 6: automation - make a practice folder"
mkdir -p ~/bash-practice
echo "Created: ~/bash-practice"
ls -d ~/bash-practice
echo ""

echo "All done! You just ran your first Bash script."

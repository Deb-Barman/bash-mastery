#!/usr/bin/env bash
# ==========================================================
# Lesson 4 - Code.sh
# Topic : --help, help, man, type, which, command -v, PATH,
#         aliases, reading error messages
# Run   : bash Code.sh
# Safe  : only READS information. It changes nothing.
# ==========================================================

echo "=============================="
echo "  Lesson 4: Help Yourself"
echo "=============================="
echo ""

# --- PART 1: --help ----------------------------------------
echo "== Part 1: --help (first 5 lines for ls) =="
ls --help | head -n 5
echo ""

# --- PART 2: help (Bash builtins) --------------------------
echo "== Part 2: help for a builtin (cd) =="
help cd | head -n 4
echo ""

# --- PART 3: man (only if it is installed) -----------------
echo "== Part 3: man pages =="
if command -v man > /dev/null 2>&1; then
    # Capture the first lines of the manual into a variable
    MAN_TEXT=$(man ls 2> /dev/null | col -b 2> /dev/null | head -n 6)
    if [ -n "$MAN_TEXT" ]; then      # -n means "is not empty"
        echo "First lines of 'man ls':"
        echo "$MAN_TEXT"
    else
        echo "man exists, but this system has no manual pages installed."
        echo "On Debian/Ubuntu: sudo apt install man-db manpages"
    fi
else
    echo "man is not installed on this system."
    echo "Install it with: sudo apt install man-db   (Debian/Ubuntu)"
fi
echo ""

# --- PART 4: what kind of command is it? -------------------
echo "== Part 4: type and which =="
type cd
type ls
type -a echo
which bash
echo ""

# --- PART 5: command -v (the script-safe way) --------------
echo "== Part 5: is a tool installed? (command -v) =="
if command -v git > /dev/null 2>&1; then
    echo "git is installed at: $(command -v git)"
else
    echo "git is NOT installed"
fi

if command -v definitely-not-a-tool > /dev/null 2>&1; then
    echo "definitely-not-a-tool is installed (surprising!)"
else
    echo "definitely-not-a-tool is NOT installed (as expected)"
fi
echo ""

# --- PART 6: PATH ------------------------------------------
echo "== Part 6: PATH (where Bash looks for programs) =="
echo "Raw PATH:"
echo "$PATH"
echo ""
echo "One folder per line:"
echo "$PATH" | tr ':' '\n'
echo ""
echo "Number of commands Bash can find: $(compgen -c | sort -u | wc -l)"
echo ""

# --- PART 7: aliases ---------------------------------------
# Aliases are meant for the interactive terminal. Inside a script
# they are OFF by default, so we turn them on just for this demo.
echo "== Part 7: alias =="
shopt -s expand_aliases
alias ll='ls -l'
echo "I made an alias:  ll = ls -l"
type ll
echo "To keep aliases forever, add them to ~/.bashrc"
echo ""

# --- PART 8: history (note) --------------------------------
echo "== Part 8: history =="
echo "history works in your live terminal, not inside a script."
echo "Try these there:  history | tail -n 5   |   Ctrl+R   |   !!   |   !\$"
echo ""

# --- PART 9: reading error messages ------------------------
echo "== Part 9: errors are clues =="
echo "-- 1) a command that does not exist --"
bash -c 'lss' 2>&1
echo ""
echo "-- 2) a file that does not exist --"
cat no-such-file.txt 2>&1
echo ""
echo "-- 3) a wrong option --"
ls --banana 2>&1 | head -n 2
echo ""

echo "Done! You now know how to teach yourself any command."

#!/usr/bin/env bash
# ==========================================================
# Lesson 14 - Code.sh
# Topic : functions, arguments, local, return vs output,
#         helper functions, main pattern, libraries, recursion
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson14-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson14-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- PART 1: define and call -------------------------------
echo "== Part 1: define, then call =="
greet() {
    echo "Hello, $1!"
}
greet "Asha"
greet "Ravi"
echo ""

# --- PART 2: arguments -------------------------------------
echo "== Part 2: arguments inside a function =="
add() {
    echo $(( $1 + $2 ))
}
echo "add 3 4 -> $(add 3 4)"

show_all() {
    echo "show_all received $# arguments:"
    for arg in "$@"; do
        echo "  - [$arg]"
    done
}
show_all one "two words" three
echo ""

# --- PART 3: local vs global -------------------------------
echo "== Part 3: local variables =="
name="outside"

leaky() {
    name="changed by leaky()"
}
tidy() {
    local name="only inside tidy()"
    echo "  inside tidy: name = $name"
}

echo "before          : name = $name"
tidy
echo "after tidy()    : name = $name   <- untouched, local protected it"
leaky
echo "after leaky()   : name = $name   <- overwritten! (no 'local')"
echo ""

# --- PART 4: return status (for if) ------------------------
echo "== Part 4: return status =="
is_even() {
    (( $1 % 2 == 0 ))          # the last command's status is the function's status
}
for n in 4 7; do
    if is_even "$n"; then
        echo "$n is even"
    else
        echo "$n is odd"
    fi
done

file_exists() {
    [[ -f $1 ]] && return 0
    return 1
}
touch real.txt
file_exists real.txt && echo "real.txt exists (status 0)"
file_exists ghost.txt || echo "ghost.txt does not exist (status 1)"
echo ""

# --- PART 5: returning values via output -------------------
echo "== Part 5: returning a value with echo + \$( ) =="
square() {
    echo $(( $1 * $1 ))
}
result=$(square 7)
echo "7 squared is $result"

noisy() {
    echo "debug: working..." >&2       # stderr: does NOT pollute the captured value
    echo 42
}
value=$(noisy 2> /dev/null)
echo "captured value: [$value]  (the debug line went to stderr)"

status_and_value() {
    echo 42
    return 5
}
x=$(status_and_value)
echo "x=[$x] and the status was $?   (two separate channels)"
echo ""

# --- PART 6: helper functions ------------------------------
echo "== Part 6: helper functions =="
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
    command -v "$1" > /dev/null 2>&1 || die "Required command not found: $1"
}

confirm() {
    local reply
    read -r -p "$1 [y/N] " reply
    [[ $reply == [yY]* ]]
}

log "this is a log line with a timestamp"
warn "this warning goes to stderr" 2>&1
require_cmd ls && echo "require_cmd ls -> found"
echo "-- die() ends the script, so we test it in a subshell ( ) --"
( require_cmd definitely-not-installed ) 2>&1
echo "subshell exit status: $?"
echo "-- confirm with piped answers --"
echo y | { confirm "Proceed?" && echo "  -> user said yes"; }
echo n | { confirm "Proceed?" || echo "  -> user said no"; }
echo ""

# --- PART 7: the main pattern ------------------------------
echo "== Part 7: the main pattern (written to a file, then run) =="
cat > backup.sh << 'EOF'
#!/usr/bin/env bash
# backup.sh - copy a folder into a destination
# Usage: backup.sh SRC DEST

log() { printf '[backup] %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

backup_folder() {
    local src="$1" dest="$2"
    [[ -d $src ]] || die "Not a folder: $src"
    mkdir -p "$dest"
    cp -r "$src" "$dest/"
    log "Copied $src into $dest"
}

main() {
    [[ $# -eq 2 ]] || die "Usage: $0 SRC DEST"
    backup_folder "$1" "$2"
}

main "$@"
EOF
chmod +x backup.sh
mkdir -p data
echo "important" > data/file.txt
./backup.sh data safe-copy
ls safe-copy/data
./backup.sh
echo "exit status: $?"
./backup.sh nope safe-copy
echo "exit status: $?"
echo ""

# --- PART 8: a library file --------------------------------
echo "== Part 8: a function library loaded with source =="
cat > lib.sh << 'EOF'
# lib.sh - reusable helpers (no shebang needed: it is sourced)
lib_hello() { echo "hello from lib.sh, $1"; }
lib_double() { echo $(( $1 * 2 )); }
EOF
echo "before source: $(type -t lib_hello || echo 'lib_hello is unknown')"
source ./lib.sh
echo "after source : $(type -t lib_hello)"
lib_hello "Asha"
echo "lib_double 21 -> $(lib_double 21)"
echo ""

# --- PART 9: recursion -------------------------------------
echo "== Part 9: recursion =="
factorial() {
    local n=$1
    if (( n <= 1 )); then
        echo 1
    else
        local prev
        prev=$(factorial $(( n - 1 )))
        echo $(( n * prev ))
    fi
}
echo "factorial 5 = $(factorial 5)"
echo "factorial 10 = $(factorial 10)"

countdown() {
    local n=$1
    (( n < 0 )) && return        # stopping condition
    printf '%s ' "$n"
    countdown $(( n - 1 ))
}
printf 'countdown 5: '
countdown 5
echo ""
echo ""

# --- PART 10: inspecting functions -------------------------
echo "== Part 10: inspecting functions =="
echo "type greet   : $(type -t greet)"
echo "Some of my functions: $(declare -F | awk '{print $3}' | grep -E '^(greet|add|square|factorial)$' | sort | tr '\n' ' ')"
echo "-- the code of greet --"
declare -f greet
unset -f greet
echo "after unset -f greet: $(type -t greet || echo 'greet no longer exists')"
echo ""

# --- PART 11: a nameref (return by variable name) ----------
echo "== Part 11: nameref (Bash 4.3+) =="
set_result() {
    local -n out=$1
    out="computed inside the function"
}
set_result answer
echo "answer = $answer"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

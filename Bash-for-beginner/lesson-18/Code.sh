#!/usr/bin/env bash
# ==========================================================
# Lesson 18 - Code.sh
# Topic : argument parsing: manual while/case/shift loop,
#         getopts, GNU getopt, subcommands, validation,
#         precedence (default < env < flag)
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson18-demo
#         and cleans up after itself.
# The script writes small command-line tools, then runs them with
# many different arguments so you can see how parsing behaves.
# ==========================================================

DEMO="$HOME/bash-practice/lesson18-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# t TOOL ARGS...  -> shows the command, runs it, shows the exit status
t() {
    printf '  $ %s\n' "$*"
    bash "$@" 2>&1 | sed 's/^/      /'
    echo "      (exit status ${PIPESTATUS[0]})"
}

# ==========================================================
# TOOL 1: manual parsing loop
# ==========================================================
cat > manual.sh << 'EOF'
#!/usr/bin/env bash
verbose=0
output=""
positional=()

usage() {
    cat << USAGE
Usage: ${0##*/} [-v] [-o FILE] [--] ARGS...
  -v, --verbose        print extra information
  -o, --output FILE    write results to FILE
  -h, --help           show this help
USAGE
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage; exit 0 ;;
        -v|--verbose)
            verbose=1; shift ;;
        -o|--output)
            [[ $# -ge 2 ]] || { echo "Option $1 needs a value" >&2; exit 2; }
            output="$2"; shift 2 ;;
        --output=*)
            output="${1#*=}"; shift ;;
        --)
            shift; positional+=("$@"); break ;;
        -*)
            echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)
            positional+=("$1"); shift ;;
    esac
done

echo "verbose=$verbose output=[$output] positional=(${positional[*]})"
echo "number of positionals: ${#positional[@]}"
EOF

echo "== Part 1: the manual while/case/shift loop =="
t manual.sh -v -o out.txt file1 file2
t manual.sh --verbose --output=out.txt file1
t manual.sh file1 -v file2
t manual.sh -o
t manual.sh --bogus
t manual.sh -- -weird-file -v
t manual.sh --help
echo ""

# ==========================================================
# TOOL 2: getopts
# ==========================================================
cat > opts.sh << 'EOF'
#!/usr/bin/env bash
verbose=0
output=""
count=1

usage() { echo "Usage: ${0##*/} [-v] [-o FILE] [-n NUM] [ARGS...]"; }

while getopts ":vho:n:" opt; do
    case "$opt" in
        v)  verbose=1 ;;
        h)  usage; exit 0 ;;
        o)  output="$OPTARG" ;;
        n)  count="$OPTARG" ;;
        :)  echo "Option -$OPTARG requires a value" >&2; exit 2 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; usage >&2; exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

if ! [[ $count =~ ^[0-9]+$ ]]; then
    echo "Error: -n needs a whole number, got '$count'" >&2
    exit 2
fi

echo "verbose=$verbose output=[$output] count=$count rest=[$*]"
EOF

echo "== Part 2: getopts =="
t opts.sh -v -o out.txt -n 3 a b
echo "-- combined flags and attached value: -vn5 --"
t opts.sh -vn5 a
t opts.sh -n
t opts.sh -x
t opts.sh -n abc
echo "-- getopts stops at the first positional argument: --"
t opts.sh file.txt -v
echo ""

# ==========================================================
# TOOL 3: subcommands
# ==========================================================
cat > todo.sh << 'EOF'
#!/usr/bin/env bash
FILE="${TODO_FILE:-todo.txt}"

usage() {
    cat << USAGE
Usage: ${0##*/} COMMAND [args]
Commands:
  add TEXT...   add an item
  list          show all items
  done N        remove item number N
  help          show this help
USAGE
}

cmd_add() {
    [[ $# -ge 1 ]] || { echo "add: needs some text" >&2; return 2; }
    echo "$*" >> "$FILE"
    echo "Added: $*"
}

cmd_list() {
    [[ -s $FILE ]] || { echo "(nothing to do)"; return 0; }
    nl -w2 -s'. ' "$FILE"
}

cmd_done() {
    [[ ${1:-} =~ ^[0-9]+$ ]] || { echo "done: needs an item number" >&2; return 2; }
    [[ -s $FILE ]] && (( $1 >= 1 && $1 <= $(wc -l < "$FILE") )) \
        || { echo "done: no item $1" >&2; return 1; }
    sed -i.bak "${1}d" "$FILE" && rm -f "$FILE.bak"
    echo "Removed item $1"
}

[[ $# -ge 1 ]] || { usage >&2; exit 2; }

cmd="$1"
shift

case "$cmd" in
    add)             cmd_add "$@" ;;
    list|ls)         cmd_list ;;
    done)            cmd_done "$@" ;;
    help|-h|--help)  usage ;;
    *)               echo "Unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac
EOF

echo "== Part 3: subcommands (like git add / git commit) =="
t todo.sh
t todo.sh list
t todo.sh add buy milk
t todo.sh add "call the bank"
t todo.sh add write Bash lesson notes
t todo.sh list
t todo.sh done 2
t todo.sh list
t todo.sh done 99
t todo.sh fly
echo ""

# ==========================================================
# TOOL 4: precedence default < environment < flag
# ==========================================================
cat > greet.sh << 'EOF'
#!/usr/bin/env bash
greeting="${GREETING:-Hello}"            # env var, or the built-in default
name="world"

while (( $# > 0 )); do
    case "$1" in
        -g|--greeting) greeting="$2"; shift 2 ;;
        -*) echo "Unknown option: $1" >&2; exit 2 ;;
        *)  name="$1"; shift ;;
    esac
done

echo "$greeting, $name!"
EOF

echo "== Part 4: where values come from (default < environment < flag) =="
echo "-- 1) built-in default --"
t greet.sh
echo "-- 2) environment variable beats the default --"
GREETING="Namaste" t greet.sh Asha
echo "-- 3) flag beats the environment variable --"
GREETING="Namaste" t greet.sh -g Hola Asha
echo ""

# ==========================================================
# TOOL 5: GNU getopt (only if the enhanced version exists)
# ==========================================================
echo "== Part 5: GNU getopt (long options, Linux) =="
# The enhanced (GNU) getopt announces itself: "getopt --test" exits with 4.
have_gnu_getopt=0
if command -v getopt > /dev/null 2>&1; then
    getopt --test > /dev/null 2>&1
    (( $? == 4 )) && have_gnu_getopt=1
fi

if (( have_gnu_getopt )); then
    cat > gnu.sh << 'EOF'
#!/usr/bin/env bash
verbose=0
output=""
OPTS=$(getopt -o hvo: --long help,verbose,output: -n "${0##*/}" -- "$@") || exit 2
eval set -- "$OPTS"
while true; do
    case "$1" in
        -h|--help)    echo "usage: ${0##*/} [-v] [-o FILE] ARGS"; exit 0 ;;
        -v|--verbose) verbose=1; shift ;;
        -o|--output)  output="$2"; shift 2 ;;
        --)           shift; break ;;
        *)            echo "internal error" >&2; exit 3 ;;
    esac
done
echo "verbose=$verbose output=[$output] rest=[$*]"
EOF
    t gnu.sh -v --output result.txt a b
    t gnu.sh a -vo r.txt b
    t gnu.sh --verbos x
    t gnu.sh --bogus
else
    echo "  (the enhanced GNU getopt is not available here: typical on macOS/BSD."
    echo "   That's why the manual loop is the portable choice.)"
fi
echo ""

# ==========================================================
# Part 6: validation helpers
# ==========================================================
echo "== Part 6: validate after parsing =="
cat > validate.sh << 'EOF'
#!/usr/bin/env bash
output=""
count=""
quiet=0
verbose=0
files=()

die() { echo "${0##*/}: $*" >&2; exit 2; }

while (( $# > 0 )); do
    case "$1" in
        -o) output="$2"; shift 2 ;;
        -n) count="$2"; shift 2 ;;
        -q) quiet=1; shift ;;
        -v) verbose=1; shift ;;
        *)  files+=("$1"); shift ;;
    esac
done

[[ -n $output ]]             || die "missing required option -o FILE"
[[ $count =~ ^[0-9]+$ ]]     || die "-n needs a whole number"
(( ! (quiet && verbose) ))   || die "-q and -v cannot be used together"
(( ${#files[@]} >= 1 ))      || die "at least one input file is required"
for f in "${files[@]}"; do
    [[ -r $f ]] || die "cannot read input: $f"
done

echo "OK: output=$output count=$count files=${files[*]}"
EOF
touch input.txt
t validate.sh input.txt
t validate.sh -o out -n x input.txt
t validate.sh -o out -n 3 -q -v input.txt
t validate.sh -o out -n 3
t validate.sh -o out -n 3 missing.txt
t validate.sh -o out -n 3 input.txt
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"

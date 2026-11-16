# Lesson 18 — Resources

## 📋 Cheat Sheet

**Manual loop (portable, flexible)**

```bash
while (( $# > 0 )); do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--verbose) verbose=1; shift ;;
        -o|--output)  [[ $# -ge 2 ]] || die "$1 needs a value"; out="$2"; shift 2 ;;
        --output=*)   out="${1#*=}"; shift ;;
        --)           shift; positional+=("$@"); break ;;
        -*)           die "unknown option: $1" ;;
        *)            positional+=("$1"); shift ;;
    esac
done
```

**`getopts` (short options)**

```bash
while getopts ":vho:n:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) out="$OPTARG" ;;
        :) die "-$OPTARG needs a value" ;;
        \?) die "unknown option -$OPTARG" ;;
    esac
done
shift $(( OPTIND - 1 ))
```

| Piece | Meaning |
|-------|---------|
| leading `:` | silent mode (you print errors) |
| `o:` | option takes a value |
| `OPTARG` | the value (or bad letter) |
| `OPTIND` | next argument index |
| `local OPTIND=1` | reset in functions |

**Subcommands:** `cmd="$1"; shift; case "$cmd" in add) ...;; list) ...;; *) usage;; esac`

**GNU getopt:** `OPTS=$(getopt -o ho: --long help,output: -n "$0" -- "$@") || exit 2; eval set -- "$OPTS"`

**Conventions:** `-h` → usage, exit 0 · bad usage → stderr, exit 2 · `--` ends options · `-vn5` = `-v -n 5`

**Precedence:** default < config < environment < flag

**Usage template**

```bash
usage() {
    cat << EOF
Usage: ${0##*/} [options] FILE...
  -o, --output FILE   ...
  -h, --help          ...
EOF
}
```

---

## 🏋️ Exercises

Work in `~/bash-practice/ex18`.

**Level A: Easy**
1. Write `hello.sh` with a `-n NAME` option (using `getopts`) printing `Hello, NAME!` (default `world`).
2. Add a `-h` option that prints a usage line and exits 0.
3. Add `-u` to make the greeting upper case.
4. Make unknown options print `Unknown option: -x` to stderr and exit 2.

**Level B: Medium**
5. Rewrite exercise 1 with the **manual loop**, supporting `-n NAME`, `--name NAME` and `--name=NAME`.
6. Write `count.sh [-l] [-w] FILE...`: `-l` prints lines, `-w` prints words (like a tiny `wc`); with no flags print both.
7. Write `copy.sh [-v] SRC DEST`: positional arguments are required (exactly two); `-v` prints what it copies; usage + exit 2 if wrong.
8. Add `-n NUM` to a script and validate it is a whole number between 1 and 100.
9. Make a script where `--color=red` overrides the `MYAPP_COLOR` environment variable, which overrides the default `blue`.
10. Make `--` work: `./script.sh -- -file-starting-with-dash` must treat it as a positional argument.

**Level C: Challenge**
11. Build `notes.sh` with subcommands `add TEXT`, `list`, `search WORD`, `clear`, storing notes in `${NOTES_FILE:-notes.txt}`; `clear` asks for confirmation.
12. Add `--verbose` counting: `-v`, `-vv`, `-vvv` → levels 1, 2, 3.
13. Build `backup.sh [-v|--verbose] [-o|--output DIR] [--exclude=PATTERN]... SRC...`: repeated `--exclude` options go into an **array**. Print the parsed result.
14. Write a script that accepts options **anywhere** (before and after positional arguments) and prints positionals separately.
15. (Think!) Why does `getopts` not see `-v` in `./opts.sh file.txt -v`? How would you work around it?
16. (Think!) What happens in your manual loop if a branch forgets `shift`? Why is it dangerous?
17. (Think!) Why is the leading `:` in `getopts ":vho:"` useful?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1-4  hello.sh
#!/usr/bin/env bash
name="world"; upper=0
usage() { echo "Usage: ${0##*/} [-n NAME] [-u] [-h]"; }
while getopts ":n:uh" opt; do
    case "$opt" in
        n)  name="$OPTARG" ;;
        u)  upper=1 ;;
        h)  usage; exit 0 ;;
        :)  echo "Option -$OPTARG needs a value" >&2; exit 2 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
    esac
done
msg="Hello, $name!"
(( upper )) && msg="${msg^^}"
echo "$msg"

# 5  hello2.sh
#!/usr/bin/env bash
name="world"
while (( $# > 0 )); do
    case "$1" in
        -n|--name)  [[ $# -ge 2 ]] || { echo "$1 needs a value" >&2; exit 2; }
                    name="$2"; shift 2 ;;
        --name=*)   name="${1#*=}"; shift ;;
        -*)         echo "Unknown option: $1" >&2; exit 2 ;;
        *)          shift ;;
    esac
done
echo "Hello, $name!"

# 6  count.sh
#!/usr/bin/env bash
l=0 w=0
while getopts ":lw" o; do
    case "$o" in l) l=1 ;; w) w=1 ;; \?) echo "bad option -$OPTARG" >&2; exit 2 ;; esac
done
shift $((OPTIND - 1))
(( l == 0 && w == 0 )) && l=1 w=1
for f in "$@"; do
    out="$f:"
    (( l )) && out+=" lines=$(wc -l < "$f")"
    (( w )) && out+=" words=$(wc -w < "$f")"
    echo "$out"
done

# 7  copy.sh
#!/usr/bin/env bash
verbose=0
while getopts ":v" o; do
    case "$o" in v) verbose=1 ;; \?) echo "Unknown option -$OPTARG" >&2; exit 2 ;; esac
done
shift $((OPTIND - 1))
(( $# == 2 )) || { echo "Usage: ${0##*/} [-v] SRC DEST" >&2; exit 2; }
(( verbose )) && echo "Copying $1 to $2"
cp -- "$1" "$2"

# 8
[[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= 100 )) \
    || { echo "-n must be a whole number from 1 to 100" >&2; exit 2; }

# 9
color="${MYAPP_COLOR:-blue}"
while (( $# > 0 )); do
    case "$1" in --color=*) color="${1#*=}"; shift ;; *) shift ;; esac
done
echo "$color"
# MYAPP_COLOR=green ./s.sh → green ; MYAPP_COLOR=green ./s.sh --color=red → red

# 10
# manual loop with:   --) shift; positional+=("$@"); break ;;
# then:  ./script.sh -- -file-starting-with-dash

# 11  notes.sh
#!/usr/bin/env bash
FILE="${NOTES_FILE:-notes.txt}"
usage() { echo "Usage: ${0##*/} add TEXT | list | search WORD | clear" >&2; }
[[ $# -ge 1 ]] || { usage; exit 2; }
cmd=$1; shift
case "$cmd" in
    add)    [[ $# -ge 1 ]] || { usage; exit 2; }; echo "$*" >> "$FILE" ;;
    list)   [[ -f $FILE ]] && cat -n "$FILE" || echo "(no notes)" ;;
    search) [[ $# -eq 1 ]] || { usage; exit 2; }; grep -n -- "$1" "$FILE" || echo "(no match)" ;;
    clear)  read -r -p "Delete ALL notes? [y/N] " a
            [[ $a == [yY]* ]] && : > "$FILE" && echo "cleared" ;;
    *)      usage; exit 2 ;;
esac

# 12
verbosity=0
while getopts ":v" o; do case "$o" in v) (( verbosity++ )) ;; esac; done
echo "verbosity=$verbosity"          # ./s.sh -vvv → 3  (also -v -v -v)
# (without set -e this is fine; under set -e use verbosity=$((verbosity+1)))

# 13  backup.sh (parsing part)
#!/usr/bin/env bash
verbose=0; outdir="."; excludes=(); srcs=()
while (( $# > 0 )); do
    case "$1" in
        -v|--verbose)   verbose=1; shift ;;
        -o|--output)    outdir="$2"; shift 2 ;;
        --exclude=*)    excludes+=("${1#*=}"); shift ;;
        --)             shift; srcs+=("$@"); break ;;
        -*)             echo "Unknown option: $1" >&2; exit 2 ;;
        *)              srcs+=("$1"); shift ;;
    esac
done
echo "verbose=$verbose outdir=$outdir"
echo "excludes: ${excludes[*]:-(none)}"
echo "sources : ${srcs[*]:-(none)}"

# 14
# The manual loop (as in exercise 13) already accepts options anywhere.

# 15
# getopts stops at the first non-option argument (file.txt), so -v is left
# in "$@". Workarounds: use the manual while/case loop; or pre-sort the
# arguments; or document "options before arguments"; or use GNU getopt.

# 16
# The same argument is examined forever → infinite loop (and the script hangs
# or floods the output). Every branch must consume its arguments.

# 17
# Silent mode: getopts prints NO error text itself; instead it sets opt to
# "?" (unknown option) or ":" (missing value) and fills OPTARG. You write
# clear, consistent messages and choose the exit status.
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| script hangs / infinite loop | missing `shift` | every branch shifts |
| `shift: shift count out of range` | `shift 2` with 1 arg left | check `$# -ge 2` first |
| `getopts` ignores later options | stops at first positional | manual loop |
| `OPTARG` empty | missing `:` after the letter | `"o:"` |
| `-x` treated as a positional | no `-*)` branch, or it comes after `*)` | order: specific → `-*)` → `*)` |
| second `getopts` loop does nothing | `OPTIND` not reset | `OPTIND=1` / `local OPTIND` |
| `--output=file` not recognized | only `--output)` handled | add `--output=*)` |
| value like `-5` parsed as an option | begins with `-` | document `--n=-5`, or accept `--` |
| BSD `getopt` errors on `--long` | macOS version | manual loop |
| usage goes to stdout on errors | `echo` without `>&2` | `usage >&2` |

---

## 💡 Habits of pro coders

1. **Always provide `-h/--help`**, and exit `0` for it.
2. **Errors: stderr + usage hint + exit 2.**
3. **Validate** required options, types, ranges, files, conflicts.
4. **Keep the parser at the top, logic in functions**, then `main`.
5. **Support `--` and `--opt=value`** if the tool will be used by others.
6. **Defaults < config < env < flags**: document it.
7. **Prefer long names in scripts** (`--output`) and short ones for typing (`-o`).
8. **Never `eval` user input** (the `getopt` idiom is the one safe exception).

## 📚 Extra resources

- **`help getopts`**, **`man getopt`**
- **mywiki.wooledge.org/BashFAQ/035**: "How can I handle command-line arguments (options)?"
- **Google Shell Style Guide**: flags and usage
- **docopt.org**: describing CLIs by their help text (inspiration)
- **shellcheck.net:** SC2220/SC2214 for `getopts` mistakes

## 🧠 Self-check

1. What's the difference between a flag, an option with a value, and a positional argument?
2. What does the `:` after a letter mean in a `getopts` string? And at the very start?
3. What do `OPTARG` and `OPTIND` hold? What does `shift $((OPTIND-1))` do?
4. When would you choose a manual loop over `getopts`?
5. What does `--` mean on a command line?
6. In what order do default, environment variable, and flag apply?

## ➡️ Next: Lesson 19 — Regular Expressions (`grep -E`, `sed -E`, `[[ =~ ]]`, `BASH_REMATCH`)

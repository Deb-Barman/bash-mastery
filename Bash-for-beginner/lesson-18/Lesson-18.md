# Lesson 18 — Argument Parsing

**Level 4 · Professional · Time: ~75 minutes**

---

## 🎯 What you will learn

- Give scripts real **options**: `-v`, `-o file`, `--help`, `--output=file`
- Parse them with the classic **`while` + `case` + `shift`** loop
- Use the built-in **`getopts`** for short options
- Know when to use GNU **`getopt`**
- Build **subcommands** like `git add`, `git commit`
- Validate input and print a proper **usage** message
- Combine defaults, environment variables and flags in the right order

> Every professional command-line tool you use (`ls -la`, `git commit -m`, `curl --silent URL`) does exactly this. Today your scripts join them.

---

## 1. Anatomy of a command line

```
./backup.sh  -v  -o /tmp/out  --exclude=*.tmp  src_folder  dest_folder
             └─────── options ───────────────┘  └─── positional arguments ──┘
```

| Kind | Examples |
|------|----------|
| **Flag** (on/off) | `-v`, `--verbose` |
| **Option with a value** | `-o FILE`, `--output FILE`, `--output=FILE` |
| **Positional argument** | `src_folder`, `dest_folder` |
| **End of options** | `--` (everything after is positional) |

Conventions people expect:

- `-h` / `--help` prints usage and exits `0`
- unknown option → error message + usage + exit `2`
- `-abc` may mean `-a -b -c` (combined short flags)
- `--` ends option parsing (so you can pass a file named `-weird`)

---

## 2. Method 1: the manual loop (most flexible)

```bash
#!/usr/bin/env bash

verbose=0
output=""
positional=()

usage() {
    cat << EOF
Usage: ${0##*/} [-v] [-o FILE] [--] ARGS...
  -v, --verbose        print extra information
  -o, --output FILE    write results to FILE
  -h, --help           show this help
EOF
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
```

How it works:

1. `while (( $# > 0 ))`: keep going while arguments remain
2. `case "$1"` looks at the **first** remaining argument
3. Each branch handles it and **`shift`s** it away (`shift 2` when a value was used too)
4. `--output=*` splits the `key=value` form with `${1#*=}` (Lesson 16)
5. `--` stops parsing: everything after is positional
6. `-*)` catches unknown options, **before** `*)` (order matters!)
7. `*)` collects the positional arguments

`${0##*/}` is the script's base name (so usage says `backup.sh`, not `./some/path/backup.sh`).

---

## 3. Method 2: `getopts` (built in, short options)

```bash
while getopts ":vho:n:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        h) usage; exit 0 ;;
        o) output="$OPTARG" ;;
        n) count="$OPTARG" ;;
        :) echo "Option -$OPTARG requires a value" >&2; exit 2 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ))          # remove the parsed options; "$@" is now just positionals
```

Reading the **option string** `":vho:n:"`:

| Part | Meaning |
|------|---------|
| leading `:` | **silent mode**: *you* print the errors (recommended) |
| `v` | flag `-v` (no value) |
| `h` | flag `-h` |
| `o:` | `-o` **takes a value** (colon after the letter) |
| `n:` | `-n` takes a value |

Special variables:

| Variable | Meaning |
|----------|---------|
| `opt` (any name) | the option letter found |
| `OPTARG` | the option's value (or the bad letter in error cases) |
| `OPTIND` | index of the **next** argument to process |

In silent mode, `getopts` sets `opt` to `?` for unknown options and `:` for a missing value, so those two `case` branches handle them.

It handles combined flags automatically: `-vn5`, `-v -n 5`, `-vn 5` all work.

**Limits of `getopts`:**

- no `--long` options
- options must come **before** positional arguments (`script.sh file -v` stops at `file`)
- inside a function, add `local OPTIND` so repeated calls start fresh

---

## 4. Method 3: GNU `getopt` (long options, Linux)

```bash
OPTS=$(getopt -o hvo: --long help,verbose,output: -n "${0##*/}" -- "$@") || exit 2
eval set -- "$OPTS"

while true; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--verbose) verbose=1; shift ;;
        -o|--output)  output="$2"; shift 2 ;;
        --)           shift; break ;;
        *)            echo "internal error" >&2; exit 3 ;;
    esac
done
```

It reorders arguments and understands long options and `--output=file` for you. But it's an **external program with a different version on every OS**: macOS/BSD `getopt` is not compatible. For portable scripts, prefer the **manual loop** (Method 1).

**Which method?**

| Need | Use |
|------|-----|
| a few short flags, simple | `getopts` |
| `--long` options, portable | manual `while`/`case` |
| subcommands | manual `case` on `$1` |
| GNU-only, lots of options | GNU `getopt` |

---

## 5. Subcommands (like `git add`)

```bash
#!/usr/bin/env bash
cmd_add()  { echo "adding: $*"; }
cmd_list() { echo "listing"; }
usage()    { echo "Usage: ${0##*/} {add|list|help} [args]"; }

[[ $# -ge 1 ]] || { usage >&2; exit 2; }

cmd="$1"; shift                  # take the command word, leave the rest

case "$cmd" in
    add)       cmd_add "$@" ;;
    list)      cmd_list "$@" ;;
    help|-h|--help) usage ;;
    *)         echo "Unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac
```

Each subcommand can parse **its own** options in its function (with its own `getopts` or loop, using `local OPTIND`).

---

## 6. Validate after parsing

```bash
# required option
[[ -n $output ]] || { echo "Error: -o FILE is required" >&2; usage >&2; exit 2; }

# number check
[[ $count =~ ^[0-9]+$ ]] || { echo "Error: -n needs a whole number" >&2; exit 2; }

# file checks
[[ -r ${positional[0]:-} ]] || { echo "Error: cannot read input" >&2; exit 1; }

# not both options
if (( quiet && verbose )); then echo "Error: -q and -v conflict" >&2; exit 2; fi

# at least N positionals
(( ${#positional[@]} >= 1 )) || { usage >&2; exit 2; }
```

---

## 7. Where do values come from? (precedence)

Typical order, **lowest to highest priority**:

1. **built-in default** in the script
2. **config file** (`~/.myscriptrc`)
3. **environment variable** (`MYSCRIPT_COLOR=red`)
4. **command-line flag** (`--color blue`): always wins

```bash
color="${MYSCRIPT_COLOR:-green}"      # env var, or default
# ... then the argument loop may override: --color) color="$2"; shift 2 ;;
```

---

## 8. A few extras

### Counting verbosity: `-v`, `-vv`, `-vvv`

```bash
verbosity=0
while getopts ":v" opt; do
    case "$opt" in v) (( verbosity++ )) ;; esac
done
(( verbosity >= 2 )) && echo "debug info"
```

### `--version`

```bash
VERSION="1.2.0"
... --version) echo "${0##*/} $VERSION"; exit 0 ;;
```

### Options that may come anywhere (before **and** after positionals)

The manual loop handles this naturally, because it checks every argument.

### Reading `-` as "standard input"

```bash
input="${positional[0]:--}"
if [[ $input == - ]]; then cat; else cat -- "$input"; fi
```

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| forgetting `shift` in the loop | infinite loop | every branch must consume its arguments |
| `shift 2` when only one argument remains | error / wrong state | check `$# -ge 2` first |
| `-*)` placed **after** `*)` | never matches | order: specific → `-*)` → `*)` |
| `getopts` string without `:` after a value option | `OPTARG` empty | `"o:"` |
| using `$OPTARG` for flags | meaningless | only value-options set it |
| `getopts` in a function called twice | second call starts mid-way | `local OPTIND=1` |
| options after positionals with `getopts` | ignored | manual loop, or reorder |
| unquoted `$@` in the loop | words split | `"$@"` |
| value starting with `-` (e.g. `-n -5`) | taken as an option | document it, or accept `--n=-5` |
| BSD/macOS `getopt` | incompatible with GNU | manual loop |

---

## 9. A professional CLI template

```bash
#!/usr/bin/env bash
#
# tool.sh - describe what it does
#
set -euo pipefail

VERSION="1.0.0"
verbose=0
output=""
positional=()

usage() {
    cat << EOF
Usage: ${0##*/} [options] INPUT...

Options:
  -o, --output FILE   write results to FILE (required)
  -v, --verbose       more output
  -h, --help          show this help
      --version       show version
EOF
}
die() { echo "${0##*/}: $*" >&2; exit 2; }

while (( $# > 0 )); do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        --version)    echo "${0##*/} $VERSION"; exit 0 ;;
        -v|--verbose) verbose=1; shift ;;
        -o|--output)  [[ $# -ge 2 ]] || die "option $1 needs a value"
                      output="$2"; shift 2 ;;
        --output=*)   output="${1#*=}"; shift ;;
        --)           shift; positional+=("$@"); break ;;
        -*)           die "unknown option: $1 (try --help)" ;;
        *)            positional+=("$1"); shift ;;
    esac
done

[[ -n $output ]]              || die "missing required option -o/--output"
(( ${#positional[@]} >= 1 )) || die "missing INPUT (try --help)"

main() {
    (( verbose )) && echo "Writing to $output" >&2
    cat -- "${positional[@]}" > "$output"
}
main
```

---

## ✅ Summary

- Options (`-v`, `-o FILE`, `--long`) + positional arguments + `--`
- Manual loop: `while (( $# ))` + `case "$1"` + `shift`; handles long options and `--key=value`
- `getopts ":vho:" opt`: built-in, short options only; `OPTARG`, `OPTIND`, `shift $((OPTIND-1))`
- Subcommands: `cmd="$1"; shift; case "$cmd" in …`
- Validate required options, numbers, files; usage to stderr + exit 2; `-h` exits 0
- Precedence: default < config < environment < flag

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

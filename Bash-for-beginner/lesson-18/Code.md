# Lesson 18 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: works only in `~/bash-practice/lesson18-demo`, deleted at the end. The script writes five small command-line tools, then runs each one with many different argument lists.

---

## How the demo is set up

```bash
t() {
    printf '  $ %s\n' "$*"
    bash "$@" 2>&1 | sed 's/^/      /'
    echo "      (exit status ${PIPESTATUS[0]})"
}
```

`t manual.sh -v file1` shows the command line, runs it, indents the output, then prints the exit status (like Lesson 17).

> **Display quirk:** the `$ ...` line prints the arguments without their quotes (for example `todo.sh add "call the bank"` shows as `todo.sh add call the bank`). The tool still receives `"call the bank"` as **one** argument, so only the display is affected.

---

## Part 1: `manual.sh` (the manual loop)

| Command | What it shows |
|---------|---------------|
| `-v -o out.txt file1 file2` | flag + option with value + two positionals |
| `--verbose --output=out.txt file1` | long names and the `--option=value` form |
| `file1 -v file2` | options **after** positionals work too, because every argument is examined |
| `-o` | the option needs a value → the `[[ $# -ge 2 ]]` check prints an error and exits 2 |
| `--bogus` | unknown option → message + usage to **stderr**, exit 2 |
| `-- -weird-file -v` | after `--`, even `-v` is just a positional argument |
| `--help` | usage on stdout, exit **0** |

The heart of it:

```bash
while (( $# > 0 )); do
    case "$1" in
        -v|--verbose)  verbose=1; shift ;;
        -o|--output)   output="$2"; shift 2 ;;
        --output=*)    output="${1#*=}"; shift ;;
        --)            shift; positional+=("$@"); break ;;
        -*)            ...unknown... ;;
        *)             positional+=("$1"); shift ;;
    esac
done
```

Each branch **consumes** what it used (`shift` or `shift 2`), so the loop always makes progress. Forget the `shift` and you loop forever.

---

## Part 2: `opts.sh` (`getopts`)

Option string `":vho:n:"`:

- leading `:` → silent mode, so our `:)` and `\?)` branches print the messages
- `v` and `h` are flags
- `o:` and `n:` **take values** (the colon after the letter)

What the runs show:

| Command | Result |
|---------|--------|
| `-v -o out.txt -n 3 a b` | everything parsed; `rest=[a b]` |
| `-vn5 a` | **combined**: `-v`, then `-n` with value `5` |
| `-n` | missing value → branch `:` fires |
| `-x` | unknown option → branch `\?` fires |
| `-n abc` | parsed fine, but **our own validation** rejects `abc` (getopts doesn't check types) |
| `file.txt -v` | `getopts` **stops at the first non-option**, so `-v` is left as a normal argument: `rest=[file.txt -v]` |

After the loop: `shift $(( OPTIND - 1 ))` removes the parsed options. `OPTIND` is the index of the next unread argument, so `"$@"` now holds only the positionals.

---

## Part 3: `todo.sh` (subcommands)

```bash
cmd="$1"
shift
case "$cmd" in
    add)  cmd_add "$@" ;;
    ...
esac
```

Take the **command word** off the front, dispatch to a function, and pass the rest along. A walkthrough:

1. no arguments → usage, exit 2
2. `list` on a missing file → "(nothing to do)"
3. three `add` calls append lines to `todo.txt` (`"$*"` joins the words)
4. `list` numbers them with `nl -w2 -s'. '`
5. `done 2` deletes line 2 with `sed -i.bak '2d'` (then removes the backup)
6. `done 99` → "no item 99", exit 1; `fly` → unknown command, exit 2

Details worth reading in the script:

- `FILE="${TODO_FILE:-todo.txt}"`: the data file can be changed by an **environment variable**
- each `cmd_*` function **returns** a status; the script's exit status is that of the last command
- `cmd_done` validates that the argument is a number **and** within range before touching the file

---

## Part 4: precedence

```bash
greeting="${GREETING:-Hello}"        # 1) default, or the environment variable
...
-g|--greeting) greeting="$2"; shift 2 ;;     # 2) the flag overrides it
```

Three runs: no input → `Hello`; `GREETING=Namaste` → `Namaste`; `GREETING=Namaste ... -g Hola` → `Hola`. The flag wins because it is applied last.

---

## Part 5: GNU `getopt`

Only runs if `getopt --test` exits **4** (the sign of the enhanced GNU version; macOS/BSD returns something else, and the script says so).

```bash
OPTS=$(getopt -o hvo: --long help,verbose,output: -n "${0##*/}" -- "$@") || exit 2
eval set -- "$OPTS"
```

`getopt` rewrites the arguments into a normalized form (options first, `--`, then positionals); `eval set -- ...` installs that as the new `$@`. Results to notice:

- `a -vo r.txt b`: options can be mixed with positionals, and `-vo r.txt` combined works
- `--verbos` was **accepted as `--verbose`**: GNU `getopt` allows unambiguous **abbreviations** of long options. Convenient for users, but a surprise if you didn't expect it
- `--bogus` produces `getopt`'s own error message and we exit 2

---

## Part 6: validation (`validate.sh`)

```bash
[[ -n $output ]]           || die "missing required option -o FILE"
[[ $count =~ ^[0-9]+$ ]]   || die "-n needs a whole number"
(( ! (quiet && verbose) )) || die "-q and -v cannot be used together"
```

Each line reads: "this must be true, **or else** die with a clear message". After the parse loop, the script checks required options, number formats, **conflicting** flags, at least one input file, and that each file is readable. Six runs show five different errors (each exit 2) and one success.

Notice the first test runs `validate.sh input.txt` with no `-o`: the earliest failing check reports first. Put the **most important** checks first.

---

## 🧪 Experiments

1. Add a `-q`/`--quiet` flag to `manual.sh` and a `--version` flag.
2. Make `opts.sh` accept `-vvv` and print the count of `v`s (verbosity levels).
3. Add a `edit N TEXT` subcommand to `todo.sh`.
4. Make `greet.sh` also read a config file `~/.greetrc` (default < config < env < flag).
5. Try `./manual.sh -o -v`: the value of `-o` becomes `-v`. How would you reject that?
6. Replace the `case` in `manual.sh` with `getopts` for the short options only. What do you lose?

---

## ✅ New words in this file

`while (( $# > 0 ))` · `case "$1"` · `shift N` · `${1#*=}` · `--` · `getopts ":vho:"` · `OPTARG` · `OPTIND` · `shift $((OPTIND-1))` · `getopt --long` · `eval set --` · subcommands · `${0##*/}` · `TODO_FILE` (env override) · `nl` · `PIPESTATUS`

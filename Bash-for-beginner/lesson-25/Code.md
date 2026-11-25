# Lesson 25 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Safe: everything happens in `~/bash-practice/lesson25-demo`, deleted at the end. Needs Bash 4.4+ (the `@Q`, `@U`, `@L` lines are guarded and only run on Bash 5.1+).

The script uses a tiny helper so every demo prints in the same shape:

```bash
show() { printf '   %-34s -> %s\n' "$1" "$2"; }
```

`$1` is the **expression as text**, `$2` is the **real result**. `%-34s` pads the left column to 34 characters so the arrows line up.

The second line of the script, `# shellcheck disable=...`, silences warnings that are **intentional** here: the lesson shows pitfalls on purpose.

---

## Part 1: the order matters

| Command | Result | Lesson |
|---------|--------|--------|
| `echo {1..3}` | `1 2 3` | a normal range |
| `echo {1..$x}` (x=3) | `{1..3}` | brace expansion ran **before** `$x` was replaced, so the range is invalid and stays as text |
| `eval echo "{1..$x}"` | `1 2 3` | `eval` expands twice. It works, but avoid it |
| `echo {a,b}{1,2}` | `a1 a2 b1 b2` | all combinations |
| `echo {01..05}` | `01 02 03 04 05` | leading zero means padded |
| `echo {1..10..3}` | `1 4 7 10` | `..3` is the step |
| `echo {e..a}` | `e d c b a` | letters work, and backwards too |

---

## Part 2: braces build file trees

```bash
mkdir -p proj/{src,docs,tests/unit}
touch proj/src/{main,util}.py proj/docs/{intro,usage}.md
cp proj/src/main.py{,.bak}
```

Three commands create four folders and five files. `main.py{,.bak}` expands to `main.py main.py.bak`, so `cp` receives a source and a destination. `find proj -type f | sort` lists the result.

---

## Part 3: tilde

`~` is your home. `~+` is `$PWD` and `~-` is `$OLDPWD` (the folder you were in before the last `cd`). The script pipes them through `sed` only to replace your real home path with `~`, so the output looks the same for everyone.

---

## Part 4: default values

| Line | Result | Why |
|------|--------|-----|
| `${name:-guest}` (unset) | `guest` | unset → default |
| `${empty:-guest}` (empty) | `guest` | `:-` treats empty like unset |
| `${empty-guest}` (empty) | `[]` | without the colon only **unset** counts, so empty stays empty |
| `${set_val:+is set}` | `is set` | `:+` returns the alternative when the variable has a value |
| `: "${name:=saved-default}"` | `name` becomes `saved-default` | `:=` also assigns |

The last test runs in a **subshell** `( ... )` with `${must:?must be provided}`. The shell prints the error and stops *that subshell*, so the demo keeps going. In a real script the same line would stop the whole script.

---

## Part 5: indirection

- `ptr=colour` then `${!ptr}` → `blue`: Bash reads the name from `ptr`, then the value of that name.
- `${!app_*}` lists variable **names** that start with `app_`: `app_debug app_name app_port`.
- `${!scores[@]}` lists the **keys** of an associative array. Their order is not guaranteed, so the demo sorts them.
- `${!fruits[@]}` lists indexes `0 1 2 3`; `${#fruits[@]}` counts items; `${#colour}` is the text length.

---

## Part 6: case and transforms

`${word^^}` UPPER, `${word,,}` lower, `${word^}` first letter, `${word~~}` swaps case of every letter. On Bash 5.1+: `${q@Q}` prints `'it'\''s a "test"'`, which is the string quoted so it can be pasted back into Bash. `${ro@a}` prints `r` for a read-only variable.

---

## Part 7: slicing

`${s:2:3}` is *start 2, length 3*. `${s: -3}` needs the **space**, otherwise it is the default-value form. `${*:2}` and `${*: -1}` slice the positional arguments after `set -- one two three four`.

---

## Part 8: pattern edits

A quick review of Lesson 16 on a long file name: `##*/` basename, `%/*` dirname, `#*.` everything after the **first** dot, `##*.` the **last** extension, `/x/y` replace first, `//x/y` replace all.

---

## Part 9: word splitting

```bash
count() { echo "$#"; }
count $list      # 3
count "$list"    # 1
```

`count` just prints how many arguments it got. The unquoted `$list` was split into three words; the quoted one stayed as one. `IFS=, read -r -a parts` splits a CSV line into an array. In `"$*"` the words are joined with the first character of `IFS`, which gives `a:b:c`.

---

## Part 10: globbing

| Setting | Effect in the demo |
|---------|--------------------|
| default | `*.nomatch` stays as the text `*.nomatch` |
| `nullglob` | it becomes empty |
| `dotglob` | `*` now includes `.hidden` |
| `extglob` | `!(*.txt)` lists everything except `.txt` files; `+(a\|b).txt`; `@(a\|c).*` |
| `globstar` | `proj/**/*.py` finds `.py` files at any depth |

Each option is switched on with `shopt -s` and off again with `shopt -u` so it does not leak into the next demo. The file called `my file.txt` is deliberately there: in the `dotglob` line, `tr ' ' ','` makes the space inside the name visible as `my,file.txt`.

---

## Part 11: `printf -v` instead of `eval`

```bash
printf -v "item_$i" '%s' "value-$i"
ref="item_$i"; echo "${!ref}"
```

`printf -v NAME` writes the result **into the variable called NAME**. Combined with `${!ref}` you can create and read `item_1`, `item_2`, ... without `eval`.

---

## 🧪 Experiments

1. Run `x=3; echo {1..$x}` in your terminal, then fix it with `seq`.
2. Change `${empty:-guest}` to `${empty-guest}` and compare.
3. Remove the **space** in `${s: -3}` and see the different result.
4. Make `show` print an error if called with fewer than two arguments, using `${2:?missing result}`.
5. Use `${path%.*}` and `${path##*/}` to build a function `newext FILE EXT`.
6. Run `shopt -s extglob; ls !(*.md)` in a test folder.
7. Try `printf '[%s]\n' $list` with `set -f` (no globbing) and without it, after creating a file named `a`.
8. 🐍 Write the same default-value logic in Python with `os.environ.get`, and compare line by line.

---

## ✅ New words in this file

`{a,b}` `{1..9..2}` · `~+` `~-` · `${v:-d}` `${v-d}` `${v:=d}` `${v:?m}` `${v:+a}` · `${!name}` `${!prefix*}` `${!arr[@]}` · `${v^^}` `${v,,}` `${v~~}` `${v@Q}` · `${v:s:l}` · `IFS` · `"$@"` `"$*"` · `nullglob` `dotglob` `globstar` `extglob` · `printf -v` · `shopt -s/-u`

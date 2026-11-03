# Lesson 15 — Code Explained

**Run it:**

```bash
bash Code.sh
```

The script first checks `BASH_VERSINFO[0]` (your Bash major version). Below 4, it prints how to install a newer Bash and stops, because associative arrays need Bash 4+. File demos live in `~/bash-practice/lesson15-demo` (deleted at the end).

---

## Part 1: why arrays

A plain string `"my report.txt notes.txt"` looped **unquoted** gives three pieces: `[my]`, `[report.txt]`, `[notes.txt]`. The real array `("my report.txt" "notes.txt")` looped with `"${array[@]}"` gives the two intended items.

---

## Part 2: reading

| Expression | Result |
|------------|--------|
| `${fruits[0]}` | `apple` |
| `${fruits[-1]}` | `date` (negative = counted from the end, Bash 4.3+) |
| `${fruits[@]}` | all elements |
| `${#fruits[@]}` | `4`, the **count** |
| `${!fruits[@]}` | `0 1 2 3`, the **indices** |
| `${#fruits[1]}` | `6`, the **length of one element** (`banana`) |
| `${fruits[@]:1:2}` | `banana cherry`, a **slice** (start 1, take 2) |
| `$fruits` | `apple`, **only element 0** (a classic surprise) |

---

## Part 3: the golden rule, live

```bash
items=("a b" "c")
printf '[%s]' "${items[@]}"     # [a b][c]   2 items ✅
printf '[%s]' "${items[*]}"     # [a b c]    1 string
printf '[%s]' ${items[@]}       # [a][b][c]  3 items ❌
```

`printf '[%s]'` wraps each **argument** in brackets, so you can count how many arguments Bash really passed. Use this trick whenever you wonder what an expansion produces.

---

## Part 4: changing

```bash
nums+=(40)               # append one
nums+=(50 60)            # append several
nums[1]=99               # replace
unset 'nums[0]'          # delete element 0 → indices now 1 2 3 4 5 (a gap!)
nums=("${nums[@]}")      # re-pack: indices 0 1 2 3 4
```

`"${nums[@]}"` expands to the remaining values, and the parentheses build a fresh array from them, numbered from 0 again. Quote `'nums[0]'` in `unset` so the shell never tries to treat `[0]` as a glob.

---

## Part 5: looping

By value `for fruit in "${fruits[@]}"` when you only need the items; by index `for i in "${!fruits[@]}"` when you also need the position. Looping over `"${!arr[@]}"` also works with **gaps** in the indices.

---

## Part 6: filling arrays

| Line | Source | Result |
|------|--------|--------|
| `globbed=(*.txt)` | glob | 3 names, including `c d.txt` as **one** item |
| `read -r -a words <<< "one two three"` | string split on spaces | 3 items |
| `IFS=, read -r -a parts <<< "red,green,blue"` | split on commas | 3 items |
| `mapfile -t lines < lines.txt` | file | one element per **line** |
| `mapfile -t listing < <(ls)` | command output | one element per output line |
| `set -- "arg one" ...; args=("$@")` | positional arguments | copies the script's arguments |

`set -- ...` replaces `$1 $2 ...` for the rest of the script (here only to demonstrate). `-t` in `mapfile` strips the trailing newline from each line.

---

## Part 7: recipes

- **Join:** `( IFS=,; echo "${arr[*]}" )`: `"${arr[*]}"` glues elements using the first character of `IFS`. The parentheses run it in a subshell so `IFS` isn't changed for the rest of the script.
- **Sort / unique:** pipe the elements through `sort` (`printf '%s\n' "${arr[@]}"` prints one per line), then load back with `mapfile -t`. This keeps items with spaces intact.
- **contains:** a function that loops and returns status `0` on a match. `contains "fig" "${arr[@]}" && ...` reads like English.
- **Max, filter, sum:** plain loops with `(( ))`. `big+=("$n")` appends to a result array.

---

## Part 8: arrays and functions

`print_all "${files_array[@]}"` passes **each element as a separate argument**; inside, `"$@"` is the list again. It received 2 items, and `my report.txt` stayed whole.

---

## Part 9: associative arrays

```bash
declare -A color=([apple]=red [banana]=yellow [grape]=purple)
color[lime]=green
```

- `declare -A` is **required**. Without it Bash treats keys as arithmetic (all become `0`)
- `${!color[@]}` = **keys**; `${color[@]}` = **values**; `${#color[@]}` = number of pairs
- **Order is not guaranteed**, so the demo sorts the keys: `$(printf '%s\n' "${!color[@]}" | sort)`. (Unquoted `$( )` is acceptable here only because these keys contain no spaces.)
- `[[ -v color[apple] ]]` tests whether a **key exists**
- `unset 'color[banana]'` deletes a key

### Counting words

```bash
for word in red blue red green blue red; do
    (( count[$word]++ ))
done
```

First time we see `red`, `count[red]` doesn't exist and counts as 0, so `++` makes it 1. Result: red 3, blue 2, green 1. This is the in-memory version of `sort | uniq -c`.

---

## Part 10: `declare -p`

Prints an array's definition: `declare -a fruits=([0]="apple" ...)`. For associative arrays the order of pairs is arbitrary. (We tidy that line with `sed` and `cut` only to keep the demo output short.) Use `declare -p arr` whenever an array "looks wrong".

---

## Part 11: the classic bug

```bash
wrong=$(printf 'one\ntwo\nthree\n')     # one string with newlines inside
mapfile -t right < <(printf 'one\ntwo\nthree\n')   # a real 3-element array
```

`${#wrong[@]}` is `1` because `wrong` is a plain string; `${#right[@]}` is `3`.

---

## 🧪 Experiments

1. Print `${fruits[@]^^}` (uppercase every element, a Lesson 16 preview).
2. Remove the quotes in Part 3 and see how many items appear.
3. Use `declare -p` after every change in Part 4.
4. Build an associative array of 3 people and their ages, then print the oldest.
5. Use `mapfile -t` to load `/etc/passwd` and print how many lines it has.
6. Reverse an array using a C-style loop that walks from the last index down.

---

## ✅ New words in this file

`arr=( )` · `"${arr[@]}"` · `${#arr[@]}` · `${!arr[@]}` · `${arr[@]:s:n}` · `arr+=( )` · `unset 'arr[i]'` · `mapfile -t` · `read -a` · `declare -A` · `[[ -v arr[key] ]]` · `declare -p` · `BASH_VERSINFO`

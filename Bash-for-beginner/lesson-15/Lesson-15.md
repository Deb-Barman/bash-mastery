# Lesson 15 — Arrays

**Level 4 · Professional · Time: ~75 minutes**

---

## 🎯 What you will learn

- **Indexed arrays**: ordered lists that safely hold items with spaces
- Create, read, change, append, and delete elements
- The golden rule: **`"${arr[@]}"`**
- Loop over arrays; get the count, indices, slices
- Fill arrays from files, globs, and commands (`mapfile`)
- Sort, join, search, and filter arrays
- **Associative arrays** (dictionaries / key → value)
- Pass arrays to functions

> Strings can't safely hold a *list* of filenames (spaces break them). Arrays can. Professional Bash uses arrays everywhere a list appears.

> ⚠️ Associative arrays need **Bash 4+**. Linux and WSL are fine. macOS ships Bash 3.2, so install a newer one (`brew install bash`). Check with `echo "$BASH_VERSION"`.

---

## 1. Why arrays?

```bash
files="my report.txt notes.txt"       # ❌ one string; word-splitting breaks it
for f in $files; do echo "[$f]"; done # [my] [report.txt] [notes.txt]

files=("my report.txt" "notes.txt")   # ✅ a real list of two items
for f in "${files[@]}"; do echo "[$f]"; done    # [my report.txt] [notes.txt]
```

---

## 2. Creating arrays

```bash
fruits=(apple banana cherry)            # three elements
mixed=("red apple" 42 "two words")      # quote items with spaces
empty=()                                # empty array
fruits[3]="date"                        # set one element (index 3)
declare -a names                        # declare an (empty) indexed array
```

Indexes start at **0**: `fruits[0]` is `apple`.

### From other sources

```bash
files=(*.txt)                           # a glob → array of matching names
read -r -a words <<< "one two three"    # split a string on spaces
IFS=, read -r -a parts <<< "a,b,c"      # split on commas → (a b c)
mapfile -t lines < file.txt             # each LINE of a file → one element (-t removes newlines)
mapfile -t found < <(find . -name "*.log")      # each line of a command's output
args=("$@")                             # copy the script's arguments
```

`mapfile` (also called `readarray`) is the right way to load lines. **Never** write `arr=($(cmd))`: it splits on spaces and expands globs.

---

## 3. Reading elements

```bash
fruits=(apple banana cherry date)

echo "${fruits[0]}"          # apple          (always use braces)
echo "${fruits[2]}"          # cherry
echo "${fruits[-1]}"         # date           (last element; Bash 4.3+)
echo "${fruits[@]}"          # apple banana cherry date   (all)
echo "${#fruits[@]}"         # 4              (how many elements)
echo "${!fruits[@]}"         # 0 1 2 3        (the indices)
echo "${#fruits[1]}"         # 6              (length of "banana")
echo "${fruits[@]:1:2}"      # banana cherry  (slice: start 1, length 2)
echo "${fruits[@]:2}"        # cherry date    (from index 2 to the end)
```

Common mistake: `echo $fruits` prints only the **first** element (same as `${fruits[0]}`).

---

## 3b. 🔑 The golden rule

> **Always write `"${arr[@]}"`, in double quotes, with `@`.**

| Form | Result for `("a b" "c")` |
|------|--------------------------|
| `"${arr[@]}"` | `a b` and `c`: **2 items** ✅ |
| `"${arr[*]}"` | `a b c`: one string |
| `${arr[@]}` (unquoted) | `a`, `b`, `c`: **3 items** ❌ broken apart |

Same idea as `"$@"` in Lesson 11 (arguments are really just an array).

---

## 4. Changing arrays

```bash
fruits+=(elderberry)             # append one
fruits+=(fig grape)              # append several
fruits[1]="blueberry"            # replace an element
unset 'fruits[0]'                # delete an element (leaves a gap in the indices!)
fruits=("${fruits[@]}")          # "compact": re-number indices from 0
unset fruits                     # delete the whole array
```

After `unset 'fruits[0]'`, indexes are `1 2 3 ...` (no 0). Re-number with `fruits=("${fruits[@]}")` when you need contiguous indices.

Prepend: `arr=(new "${arr[@]}")` · Insert/remove in the middle: build a new array from slices.

---

## 5. Looping

```bash
# by value (the usual way)
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done

# by index (when you need the position)
for i in "${!fruits[@]}"; do
    echo "$i: ${fruits[$i]}"
done

# C-style (contiguous arrays only)
for (( i = 0; i < ${#fruits[@]}; i++ )); do
    echo "${fruits[i]}"
done
```

---

## 6. Everyday array recipes

### Join with a separator

```bash
arr=(a b c)
(IFS=,; echo "${arr[*]}")                # a,b,c   (subshell keeps IFS change private)
printf -v joined '%s,' "${arr[@]}"; joined=${joined%,}     # alternative
```

### Sort

```bash
sorted=( $(printf '%s\n' "${arr[@]}" | sort) )      # ❌ breaks on spaces
mapfile -t sorted < <(printf '%s\n' "${arr[@]}" | sort)   # ✅
```

### Unique values

```bash
mapfile -t uniq < <(printf '%s\n' "${arr[@]}" | sort -u)
```

### Contains?

```bash
contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ $item == "$needle" ]] && return 0
    done
    return 1
}
contains "banana" "${fruits[@]}" && echo "yes"
```

### Largest number

```bash
nums=(4 19 7 12)
max=${nums[0]}
for n in "${nums[@]}"; do (( n > max )) && max=$n; done
echo "$max"        # 19
```

### Filter

```bash
big=()
for n in "${nums[@]}"; do
    (( n > 5 )) && big+=("$n")
done
```

---

## 7. Arrays and functions

Pass with `"${arr[@]}"`; the function receives them as `"$@"`:

```bash
print_all() {
    local item
    for item in "$@"; do echo "- $item"; done
}
print_all "${fruits[@]}"
```

A function can **fill** an array by printing lines and the caller using `mapfile`:

```bash
list_logs() { find . -name "*.log" -print; }
mapfile -t logs < <(list_logs)
```

---

## 8. Associative arrays (dictionaries)

Keys can be **text**, not just numbers (Bash 4+):

```bash
declare -A age                          # -A is REQUIRED
age[Asha]=29
age[Ravi]=34
age=([Mina]=41 [Karan]=25)              # (this REPLACES the contents)

declare -A color=([apple]=red [banana]=yellow [grape]=purple)
```

```bash
echo "${color[apple]}"                  # red
echo "${!color[@]}"                     # all KEYS   (order not guaranteed)
echo "${color[@]}"                      # all VALUES
echo "${#color[@]}"                     # how many pairs

for key in "${!color[@]}"; do
    echo "$key is ${color[$key]}"
done

[[ -v color[apple] ]] && echo "apple key exists"      # key test (Bash 4.3+)
[[ -n ${color[kiwi]:-} ]] || echo "kiwi missing"      # works in older 4.x too
unset 'color[banana]'                                  # delete a key
```

**Order is not guaranteed.** If you need sorted output: `printf '%s\n' "${!color[@]}" | sort`.

### Classic use: counting

```bash
declare -A count
for word in red blue red green blue red; do
    (( count[$word]++ ))
done
for w in "${!count[@]}"; do echo "$w: ${count[$w]}"; done | sort
# blue: 2
# green: 1
# red: 3
```

(One loop = the `sort | uniq -c` pipeline, but you can use the data inside Bash.)

---

## 9. Debug an array: `declare -p`

```bash
declare -p fruits
# declare -a fruits=([0]="apple" [1]="banana" [2]="cherry")
declare -p color
# declare -A color=([grape]="purple" [banana]="yellow" [apple]="red" )
```

Your best friend when an array "isn't what you expect".

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| `arr=$(cmd)` | one **string**, not an array | `mapfile -t arr < <(cmd)` or `arr=( ... )` |
| `arr=($(cmd))` | splits on spaces, globs expand | `mapfile -t` |
| `${arr[@]}` unquoted | items with spaces break | `"${arr[@]}"` |
| `echo $arr` | only element 0 | `echo "${arr[@]}"` |
| `$arr[1]` | prints `$arr` then `[1]` | `${arr[1]}` |
| associative array without `declare -A` | keys become numeric (all `0`) | `declare -A` |
| `unset arr[1]` unquoted | glob chars may expand | `unset 'arr[1]'` |
| `${#arr}` | length of element 0 | `${#arr[@]}` |
| empty array with `set -u` on Bash < 4.4 | "unbound variable" | `${arr[@]+"${arr[@]}"}` or Bash 4.4+ |
| `for i in {0..${#arr[@]}}` | braces don't take variables | `for i in "${!arr[@]}"` |

---

## ✅ Summary

- `arr=(a "b c" d)` · `${arr[0]}` · `"${arr[@]}"` · `${#arr[@]}` · `${!arr[@]}` · `arr+=(x)`
- Load data with `mapfile -t arr < file` / `< <(cmd)`; globs `(*.txt)`; `read -ra`
- Loop with `for x in "${arr[@]}"`, or by index with `"${!arr[@]}"`
- Associative: `declare -A d; d[key]=value; "${!d[@]}"` keys, `"${d[@]}"` values
- Debug with `declare -p`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

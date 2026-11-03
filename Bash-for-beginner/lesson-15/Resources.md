# Lesson 15 — Resources

## 📋 Cheat Sheet

**Indexed arrays**

| Goal | Syntax |
|------|--------|
| Create | `a=(x "y z" w)` · `a=()` · `declare -a a` |
| Element | `${a[0]}` · last: `${a[-1]}` |
| All (safe) | `"${a[@]}"` |
| Count | `${#a[@]}` |
| Indices | `${!a[@]}` |
| Slice | `${a[@]:1:2}` |
| Append | `a+=(new)` |
| Set one | `a[2]=val` |
| Delete one | `unset 'a[1]'` |
| Re-pack | `a=("${a[@]}")` |
| From glob | `a=(*.txt)` |
| From file lines | `mapfile -t a < file` |
| From command | `mapfile -t a < <(cmd)` |
| Split string | `IFS=, read -ra a <<< "x,y,z"` |
| Copy args | `a=("$@")` |
| Join | `( IFS=,; echo "${a[*]}" )` |
| Sort | `mapfile -t s < <(printf '%s\n' "${a[@]}" \| sort)` |
| Debug | `declare -p a` |

**Associative arrays (Bash 4+)**

| Goal | Syntax |
|------|--------|
| Declare | `declare -A d` |
| Set | `d[key]=value` · `declare -A d=([k1]=v1 [k2]=v2)` |
| Get | `${d[key]}` |
| Keys / values / count | `"${!d[@]}"` / `"${d[@]}"` / `${#d[@]}` |
| Key exists? | `[[ -v d[key] ]]` |
| Delete | `unset 'd[key]'` |
| Count words | `(( d[$w]++ ))` |

**Golden rules:** `"${a[@]}"` always quoted · `mapfile`, not `a=($(cmd))` · `declare -A` for dictionaries · braces always: `${a[0]}`

---

## 🏋️ Exercises

Work in `~/bash-practice/ex15`.

**Level A: Easy**
1. Create an array of 4 colours and print the second one.
2. Print how many elements it has.
3. Print all elements, one per line (use `printf`).
4. Add a fifth colour, then print the last one.

**Level B: Medium**
5. Loop over the array and print `1: red`, `2: green`... (numbering from 1).
6. Create `files` from `*.txt` (make some, including one with a space) and print the count and each name in brackets.
7. Read the lines of a file into an array and print the **last line**.
8. Split `"2026-10-11"` on `-` into `year`, `month`, `day` using an array.
9. Join an array `(a b c)` into the string `a-b-c`.
10. Remove the second element from an array and re-pack it.

**Level C: Challenge**
11. Given `nums=(4 19 7 12 3)`, print the **sum**, the **maximum**, and the **average** (1 decimal, use awk).
12. Reverse an array without `tac` or `rev` and print it.
13. Write `contains NEEDLE ARRAY...` and use it for a validity check of an argument against `(start stop restart)`.
14. Count how many times each word appears in `words.txt` using an **associative array**, and print a sorted result.
15. Write `unique ARRAY...` that prints elements without duplicates, **keeping the original order** (hint: associative array as a "seen" set).
16. (Think!) What's the difference between `"${a[@]}"` and `"${a[*]}"`? When would you want `*`?
17. (Think!) After `unset 'a[1]'`, why does `a[1]` disappear but `${#a[@]}` shrink while indices don't renumber?
18. (Think!) Why is `files=($(ls))` a bad idea, and what's the right way?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
# 1-4
colors=(red green blue yellow)
echo "${colors[1]}"                       # green
echo "${#colors[@]}"                      # 4
printf '%s\n' "${colors[@]}"
colors+=(purple); echo "${colors[-1]}"    # purple

# 5
i=1
for c in "${colors[@]}"; do echo "$i: $c"; (( i++ )); done
# or: for i in "${!colors[@]}"; do echo "$((i+1)): ${colors[i]}"; done

# 6
touch a.txt "b c.txt" d.txt
files=(*.txt)
echo "${#files[@]} files"
for f in "${files[@]}"; do echo "[$f]"; done

# 7
mapfile -t lines < file.txt
echo "${lines[-1]}"
# (older Bash: echo "${lines[${#lines[@]}-1]}")

# 8
IFS=- read -r -a d <<< "2026-10-11"
year=${d[0]} month=${d[1]} day=${d[2]}
echo "$year / $month / $day"

# 9
a=(a b c)
( IFS=-; echo "${a[*]}" )                 # a-b-c

# 10
a=(one two three four)
unset 'a[1]'
a=("${a[@]}")
echo "${a[@]}"                            # one three four

# 11
nums=(4 19 7 12 3)
sum=0; max=${nums[0]}
for n in "${nums[@]}"; do
    (( sum += n ))
    (( n > max )) && max=$n
done
echo "sum=$sum max=$max"
awk -v s="$sum" -v c="${#nums[@]}" 'BEGIN {printf "avg=%.1f\n", s/c}'

# 12
arr=(a b c d)
rev=()
for (( i = ${#arr[@]} - 1; i >= 0; i-- )); do rev+=("${arr[i]}"); done
echo "${rev[@]}"                          # d c b a

# 13
contains() {
    local needle="$1" x; shift
    for x in "$@"; do [[ $x == "$needle" ]] && return 0; done
    return 1
}
valid=(start stop restart)
contains "$1" "${valid[@]}" || { echo "Usage: $0 start|stop|restart" >&2; exit 2; }

# 14
declare -A count
while read -r w; do (( count[$w]++ )); done < <(tr -s ' ' '\n' < words.txt)
for w in "${!count[@]}"; do echo "$w ${count[$w]}"; done | sort

# 15
unique() {
    declare -A seen
    local x
    for x in "$@"; do
        if [[ -z ${seen[$x]:-} ]]; then
            seen[$x]=1
            echo "$x"
        fi
    done
}
unique b a b c a d                        # b a c d  (first-seen order kept)

# 16
# "${a[@]}" → every element as its own word (use for passing/looping).
# "${a[*]}" → ONE word, elements joined by the first character of IFS.
# Use * to build a single string: ( IFS=,; echo "${a[*]}" ).

# 17
# unset removes that one element only. Bash arrays are sparse: the other
# indices keep their numbers. ${#a[@]} counts existing elements.
# Use  a=("${a[@]}")  to re-pack.

# 18
# $(ls) output is word-split and glob-expanded: names with spaces break and
# ls output isn't reliable. Use:   files=(*)      or      mapfile -t files < <(find ... )
```

</details>

---

## 🐞 Common beginner errors

| Message / symptom | Cause | Fix |
|-------------------|-------|-----|
| `declare: -A: invalid option` | Bash 3.2 (macOS) | install Bash 4+ |
| only first element printed | `echo $arr` | `echo "${arr[@]}"` |
| items with spaces split | unquoted `${arr[@]}` | `"${arr[@]}"` |
| `bad array subscript` | `arr[$key]` with empty key | validate the key |
| associative values all land in `[0]` | missing `declare -A` | declare it |
| `arr=$(cmd)` → one big string | not an array assignment | `mapfile -t arr < <(cmd)` |
| unexpected `[1]` gaps after `unset` | arrays are sparse | `arr=("${arr[@]}")` |
| `unbound variable` on empty array (Bash < 4.4) | `set -u` + empty array | upgrade, or `${arr[@]+"${arr[@]}"}` |
| `{0..${#a[@]}}` doesn't expand | braces before variables | `"${!a[@]}"` or `seq` |
| changes inside `cmd \| while` lost | subshell | `done < <(cmd)` |

---

## 💡 Habits of pro coders

1. **Arrays for lists, never space-separated strings.**
2. **`"${arr[@]}"`**: quoted, with `@`, every time.
3. **`mapfile -t`** to load lines. Never `arr=($(...))`.
4. **`declare -p arr`** to inspect.
5. **`local -a`** / **`local -A`** inside functions.
6. **Collect then act:** gather matches in an array, check the count, show a preview, then operate.
7. For dictionaries, remember **order is undefined**: sort keys when printing.

## 📚 Extra resources

- **`help declare`**, **`help mapfile`**
- **mywiki.wooledge.org/BashGuide/Arrays** and **/BashFAQ/005**
- **Bash Reference Manual**, section "Arrays"
- **shellcheck.net:** SC2206/SC2207 warn about `arr=($(cmd))`

## 🧠 Self-check

1. How do you get the number of elements? The indices?
2. What does `"${arr[@]}"` do that `${arr[@]}` doesn't?
3. How do you load a file's lines into an array?
4. What's an associative array and what must you write to create one?
5. Why does `unset 'a[1]'` leave a gap?
6. Why is `arr=$(cmd)` not an array?

## ➡️ Next: Lesson 16 — String Manipulation (`${var#}`, `${var%}`, `${var//}`, case, padding, split/join)

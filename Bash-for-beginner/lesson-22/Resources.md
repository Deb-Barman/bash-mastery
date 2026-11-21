# Lesson 22 — Resources

## 📋 Cheat Sheet

**curl**

| Goal | Command |
|------|---------|
| safe default | `curl -fsS -m 20 URL` |
| follow redirects | `curl -fsSL URL` |
| save to file | `-o name` · `-O` (remote name) |
| headers only | `-I` · both: `-i` · debug: `-v` |
| status code only | `curl -s -o /dev/null -w '%{http_code}' URL` |
| POST JSON | `curl -fsS -H 'Content-Type: application/json' -d '{"a":1}' URL` · `--json '{…}'` |
| data from file | `-d @body.json` |
| token | `-H "Authorization: Bearer $TOKEN"` |
| upload | `-F 'file=@x.jpg'` |
| retries | `--retry 3 --retry-delay 2 --retry-all-errors` |
| resume | `-C -` |
| URL-encode | `--data-urlencode 'q=a b'` |

**HTTP status:** `2xx` ok · `3xx` redirect · `4xx` client error (`401` login, `403` forbidden, `404` missing, `429` slow down) · `5xx` server error (retry)

**jq**

| Goal | Command |
|------|---------|
| pretty print | `jq .` |
| field (raw) | `jq -r '.name'` |
| array item | `.[0]` · all: `.[]` |
| nested | `.a.b.c` |
| filter | `.[] \| select(.city=="Pune")` |
| map / length | `map(.id)` · `length` |
| CSV | `.[] \| [.id,.name] \| @csv` |
| missing → empty | `.next // empty` |
| build JSON | `jq -n --arg n "$name" '{name:$n}'` |

**Network checks:** `ping -c3 host` · `nc -zv host 443` · `(exec 3<>/dev/tcp/host/443)` · `dig +short host` · `ss -ltn` · `ip -brief addr`

**ssh family**

```bash
ssh-keygen -t ed25519            ssh-copy-id user@host
ssh user@host 'cmd'              ssh -o BatchMode=yes -o ConnectTimeout=5 user@host cmd
scp file host:/path/             scp -r dir host:/path/
rsync -avzn src/ host:/dst/      # dry run first!   then without -n
ssh -L 8080:localhost:80 host    # port forward
```

**rsync slash rule:** `src/` = contents of src · `src` = the folder itself

---

## 🏋️ Exercises

Practice server: in a folder with some files run `python3 -m http.server 8000 --bind 127.0.0.1 &` (stop it later with `kill %1`). Then use `http://127.0.0.1:8000/`.

**Level A: Easy**
1. Fetch the directory listing page quietly (no progress bar) and print it.
2. Print only the HTTP status code of `/`.
3. Print the status code of `/does-not-exist`.
4. Save a file from the server as `copy.txt` using `-o`.

**Level B: Medium**
5. Make `curl` **fail with a non-zero exit status** for the missing page, and print `missing` when that happens.
6. Show only the response headers of `/`.
7. Download a file and verify it against a SHA-256 checksum you create beforehand.
8. Given `data.json` containing `[{"n":"a","v":1},{"n":"b","v":5}]`, print the names with `jq` (or Python if `jq` is missing).
9. Build the JSON `{"title":"Say \"hi\""}` safely with `jq` or Python and print it.
10. Check whether port 8000 is open using only Bash (`/dev/tcp`).

**Level C: Challenge**
11. Write `status.sh URL...` that prints `URL → CODE (TIME s)` for each URL (`-w`, with a 5-second timeout).
12. Write `wait-for.sh HOST PORT [SECONDS]` that waits until a port opens (default 30 s) and exits 1 on timeout.
13. Write `fetch-json.sh URL` with timeouts, `-f`, 3 retries with back-off, and output only the body.
14. Write a pagination loop that keeps calling `.../items?page=N` until the JSON has no `next`.
15. Write the `rsync` command (with dry-run first) that mirrors `~/photos/` to `user@server:/backup/photos/` and removes files deleted locally.
16. (Think!) Why does a `404` give exit status 0 with plain `curl`? What does `-f` change?
17. (Think!) Why is `curl https://site/install.sh | bash` risky, and what is the safer way?
18. (Think!) Why should you never build JSON with `echo "{\"name\": \"$name\"}"`?

---

## ✅ Answers

<details>
<summary>Click only after trying!</summary>

```bash
B=http://127.0.0.1:8000

# 1
curl -sS "$B/"

# 2
curl -sS -o /dev/null -w '%{http_code}\n' "$B/"

# 3
curl -sS -o /dev/null -w '%{http_code}\n' "$B/does-not-exist"      # 404

# 4
curl -fsS -o copy.txt "$B/notes.txt"

# 5
curl -fsS -o /dev/null "$B/does-not-exist" 2>/dev/null || echo "missing"

# 6
curl -sS -I "$B/"

# 7
sha256sum notes.txt > notes.sha256
curl -fsS -o downloaded.txt "$B/notes.txt"
echo "$(cut -d' ' -f1 notes.sha256)  downloaded.txt" | sha256sum -c -

# 8
jq -r '.[].n' data.json
# without jq:
python3 -c 'import json; [print(x["n"]) for x in json.load(open("data.json"))]'

# 9
jq -n --arg t 'Say "hi"' '{title: $t}'
# or:
T='Say "hi"' python3 -c 'import os, json; print(json.dumps({"title": os.environ["T"]}))'

# 10
(exec 3<> /dev/tcp/127.0.0.1/8000) 2>/dev/null && echo open || echo closed

# 11  status.sh
#!/usr/bin/env bash
for url in "$@"; do
    out=$(curl -sS -m 5 -o /dev/null -w '%{http_code} (%{time_total}s)' "$url" 2>&1) || out="FAILED: $out"
    echo "$url → $out"
done

# 12  wait-for.sh
#!/usr/bin/env bash
host=$1 port=$2 limit=${3:-30}
for (( i = 0; i < limit; i++ )); do
    if (exec 3<> "/dev/tcp/$host/$port") 2>/dev/null; then
        echo "$host:$port is open"; exit 0
    fi
    sleep 1
done
echo "timed out waiting for $host:$port" >&2
exit 1

# 13  fetch-json.sh
#!/usr/bin/env bash
url=$1
delay=1
for attempt in 1 2 3; do
    if curl -fsS -m 10 "$url"; then exit 0; fi
    (( attempt < 3 )) && { echo "retry in ${delay}s" >&2; sleep "$delay"; (( delay *= 2 )); }
done
echo "giving up on $url" >&2
exit 1

# 14
page=1
while [[ -n $page ]]; do
    resp=$(curl -fsS "$B/items?page=$page")
    jq -r '.items[]' <<< "$resp"
    page=$(jq -r '.next // empty' <<< "$resp")
done

# 15
rsync -avzn --delete ~/photos/ user@server:/backup/photos/     # look at the output!
rsync -avz  --delete ~/photos/ user@server:/backup/photos/

# 16
# The request itself succeeded: the server answered. HTTP errors are a
# successful transport of a "no". With -f, curl turns responses >= 400 into
# exit status 22 so that if/|| in your script work.

# 17
# You run code you have not read, which can change between your inspection
# and your download (or be truncated). Safer: download to a file, read it,
# check a published checksum/signature, then run it.

# 18
# Quotes, backslashes and newlines inside $name break the JSON (or can inject
# extra fields). Let jq/a JSON library escape the value.
```

</details>

---

## 🐞 Common beginner errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| script continues after a 404/500 | no `-f` | `curl -fsS` |
| hangs forever | no timeout | `-m 20 --connect-timeout 5` |
| URL with `&` cut off | unquoted | `"…?a=1&b=2"` |
| `curl: (60) SSL certificate problem` | missing CA / proxy / wrong clock | fix the cert/CA; **don't** use `-k` |
| `jq: command not found` | not installed | `apt install jq` / `brew install jq` |
| `parse error` from jq | the body wasn't JSON (HTML error page) | use `-f`; check `-i` output |
| `Permission denied (publickey)` | key not installed on the server | `ssh-copy-id`, check `~/.ssh` permissions (700/600) |
| ssh hangs in a script | password prompt | `-o BatchMode=yes` |
| rsync copies into `dst/src/` | missing trailing slash | `src/` |
| rsync deleted files | `--delete` without a dry run | `-n` first |
| `429 Too Many Requests` | no rate limiting | `sleep`, obey `Retry-After`, cache |
| token leaked in `ps` / history | secret in the command line | env var / `-K` config / protected file |

---

## 💡 Habits of pro coders

1. **`curl -fsS -m N`** as the default, always.
2. **Capture the status separately** from the body (`-w '%{http_code}'`).
3. **Use `jq`** (or a real JSON library) both for reading and for building JSON.
4. **Retry transient failures (5xx, timeouts) with back-off**, never retry 4xx blindly.
5. **Respect rate limits** and cache what you can.
6. **Secrets only from the environment or protected files**; rotate them if leaked.
7. **Verify downloads**; never `curl | bash` unseen.
8. **`rsync -n` first**, keys + `BatchMode` for ssh automation.

## 📚 Extra resources

- **`man curl`** and **everything.curl.dev**: the free book by curl's author
- **jqlang.github.io/jq/manual**, **jqplay.org**: interactive jq playground
- **httpbin.org:** a public test API (try `curl https://httpbin.org/get`)
- **MDN "HTTP" guide** (developer.mozilla.org): methods, status codes, headers
- **`man rsync`**, **`man ssh_config`**, **ssh.com/academy**

## 🧠 Self-check

1. What do `-f`, `-s`, `-S`, `-m` and `-L` do in `curl`?
2. How do you get only the HTTP status code?
3. How do you send JSON with a token?
4. Why build JSON with `jq`, not with string concatenation?
5. What does the trailing slash mean in `rsync src/ dst/`?
6. What are three safe habits for secrets and downloads?

## ➡️ Next: Lesson 23 — Real Projects (backup, log analyzer, file organizer, project scaffolder)

> 🏁 **Level 5 complete!** Your scripts can run in parallel, on a schedule, and across the network.

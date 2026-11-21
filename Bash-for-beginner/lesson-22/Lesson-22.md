# Lesson 22 — Networking & APIs

**Level 5 · Automation · Time: ~80 minutes**

---

## 🎯 What you will learn

- Talk to the web from Bash with **`curl`** (and `wget`)
- Call **APIs**: GET, POST, headers, tokens, status codes
- Handle **JSON** with `jq` (and a fallback)
- Write a reliable **API client**: retries, errors, pagination
- Check networks and ports (`ping`, `nc`, `/dev/tcp`, `dig`, `ss`)
- Work on other machines with **`ssh`**, **`scp`**, **`rsync`**
- Keep secrets and downloads **safe**

> Most "automation" today means calling an API: GitHub, Slack, weather, your own servers. Bash plus `curl` and `jq` can do all of it.

---

## 1. How the web talks: a 60-second refresher

```
https://api.example.com:443/v1/users?page=2
└─┬─┘   └──────┬──────┘└┬┘ └───┬───┘ └──┬──┘
scheme       host      port   path    query
```

| Method | Meaning | Typical use |
|--------|---------|-------------|
| `GET` | read | fetch a page / list users |
| `POST` | create | send a form / create a record |
| `PUT` / `PATCH` | replace / update | edit a record |
| `DELETE` | remove | delete a record |

| Status | Meaning |
|--------|---------|
| `200` OK · `201` Created · `204` No Content | success |
| `301`/`302` | redirect (follow with `-L`) |
| `400` bad request · `401` not logged in · `403` not allowed · `404` not found · `429` too many requests | **your** mistake |
| `500` error · `502`/`503`/`504` | **server's** problem (often worth a retry) |

---

## 2. `curl`: the Swiss Army knife

```bash
curl https://example.com                   # GET, print the body
curl -s https://example.com                # -s silent (no progress bar)
curl -sS URL                               # silent but still show ERRORS  ← good script default
curl -fsS URL                              # + -f: fail (exit 22) on HTTP errors like 404/500
curl -fsSL URL                             # + -L: follow redirects
curl -o page.html URL                      # save to a named file
curl -O URL                                # save using the remote file name
curl -I URL                                # headers only (HEAD request)
curl -i URL                                # headers + body
curl -v URL                                # verbose: see the whole conversation (debugging)
curl -m 10 URL                             # give up after 10 seconds
curl -w '%{http_code}\n' -o /dev/null -s URL     # print ONLY the status code
```

### Sending data

```bash
curl -X POST -d 'name=asha&age=29' URL                         # form data
curl -H 'Content-Type: application/json' -d '{"name":"Asha"}' URL     # JSON (implies POST)
curl --json '{"name":"Asha"}' URL                               # shorthand (curl 7.82+)
curl -X PUT -H 'Content-Type: application/json' -d @body.json URL      # data from a file
curl -X DELETE URL
curl --data-urlencode 'q=hello world & more' URL                # safe URL-encoding
curl -F 'file=@photo.jpg' URL                                   # file upload (multipart)
```

### Authentication

```bash
curl -H "Authorization: Bearer $TOKEN" URL         # token (most modern APIs)
curl -u user:password URL                           # basic auth (avoid typing passwords!)
```

### Reliability flags

| Flag | Meaning |
|------|---------|
| `-f` | HTTP errors (≥ 400) become a failing exit status |
| `-m 10` / `--connect-timeout 5` | total / connect time limits |
| `--retry 3 --retry-delay 2` | retry transient errors |
| `--retry-all-errors` | retry on any error too (curl 7.71+) |
| `-C -` | resume a partial download |
| `-L` | follow redirects |

⚠️ **Never use `-k`** (ignore TLS certificate errors) except on a throw-away test server.

---

## 3. `wget`, downloads, and verifying them

```bash
wget https://example.com/file.zip           # download
wget -q -O - https://example.com            # quiet, to stdout (like curl -s)
wget -c URL                                 # continue a partial download
```

Verify what you download:

```bash
curl -fsSLO https://example.com/tool.tar.gz
curl -fsSLO https://example.com/tool.tar.gz.sha256
sha256sum -c tool.tar.gz.sha256             # "tool.tar.gz: OK"
```

🚫 **Never** `curl URL | bash` blindly. Download, **read**, then run.

---

## 4. JSON with `jq`

APIs speak JSON. `jq` is "`sed` for JSON" (`sudo apt install jq` / `brew install jq`).

```bash
echo '{"name":"Asha","langs":["bash","python"],"age":29}' > p.json

jq . p.json                     # pretty print
jq '.name' p.json               # "Asha"
jq -r '.name' p.json            # Asha   (-r raw: no quotes; use this in scripts)
jq '.langs[0]' p.json           # "bash"
jq '.langs | length' p.json     # 2
jq -r '.langs[]' p.json         # bash / python (one per line)
```

Arrays of objects:

```bash
# users.json: [{"id":1,"name":"Asha","city":"Delhi"}, {"id":2,"name":"Ravi","city":"Pune"}]
jq -r '.[].name' users.json                                  # every name
jq '.[] | select(.city == "Pune")' users.json                # filter
jq -r '.[] | [.id, .name] | @csv' users.json                 # CSV rows
jq 'map(.name)' users.json                                   # a new array
jq '[.[] | select(.city=="Delhi")] | length' users.json      # count
```

### Build JSON safely: never with string concatenation

```bash
name='Asha "The Great"'
bad="{\"name\": \"$name\"}"                      # ❌ broken JSON (unescaped quotes)
good=$(jq -n --arg name "$name" '{name: $name}') # ✅ jq escapes everything
curl --json "$good" URL
```

No `jq`? `python3 -c 'import sys, json; …'` can do the job (see `Code.sh`).

---

## 5. A reliable API client pattern

```bash
API="https://api.example.com/v1"
: "${API_TOKEN:?set API_TOKEN}"

api() {                                  # api METHOD PATH [json-body]
    local method=$1 path=$2 body=${3:-} out status
    out=$(mktemp)
    status=$(curl -sS -m 20 -X "$method" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H 'Content-Type: application/json' \
        ${body:+-d "$body"} \
        -o "$out" -w '%{http_code}' "$API$path") || { rm -f "$out"; return 1; }
    if [[ $status =~ ^2 ]]; then
        cat "$out"; rm -f "$out"
    else
        echo "API error $status on $method $path: $(cat "$out")" >&2
        rm -f "$out"; return 1
    fi
}

api GET /users | jq -r '.[].name'
```

### Retry with back-off (Lesson 17 + 14)

```bash
retry() { local n=1 max=$1 delay=$2; shift 2
    until "$@"; do
        (( n >= max )) && return 1
        sleep "$delay"; (( n++, delay *= 2 ))      # 2s, 4s, 8s ...
    done
}
retry 4 1 curl -fsS -m 10 "$URL"
```

### Pagination

```bash
page=1
while [[ -n $page ]]; do
    resp=$(api GET "/items?page=$page")
    jq -r '.items[]' <<< "$resp"
    page=$(jq -r '.next // empty' <<< "$resp")      # empty when there is no next page
done
```

Be kind to APIs: obey rate limits (`429`, `Retry-After` header), `sleep` between calls, cache results.

---

## 6. Checking the network

```bash
ping -c 3 example.com               # reachable? (-c 3 = three tries)
nc -zv example.com 443              # is port 443 open? (netcat)
curl -sS -o /dev/null -w '%{http_code} %{time_total}s\n' URL   # status + total time

# pure Bash, no extra tools: /dev/tcp
if (exec 3<> /dev/tcp/example.com/443) 2> /dev/null; then echo "port open"; fi

dig +short example.com              # DNS lookup  (or: nslookup, getent hosts example.com)
ss -ltn                             # my listening TCP ports (Linux)
ip -brief addr                      # my IP addresses (Linux; macOS: ifconfig)
curl -s https://ifconfig.me         # my public IP
```

A raw HTTP request by hand, using `/dev/tcp` (it demystifies HTTP):

```bash
exec 3<> /dev/tcp/example.com/80
printf 'GET / HTTP/1.0\r\nHost: example.com\r\n\r\n' >&3
cat <&3
exec 3>&-
```

---

## 7. SSH: remote control

```bash
ssh-keygen -t ed25519 -C "my laptop"          # make a key pair (~/.ssh/id_ed25519 + .pub)
ssh-copy-id user@server                       # install your public key on the server
ssh user@server                               # log in
ssh user@server 'uptime; df -h /'             # run commands, print the output, come back
ssh -o BatchMode=yes -o ConnectTimeout=5 user@server true   # script-friendly: never ask for a password, fail fast
```

`~/.ssh/config` makes everything short:

```
Host web
    HostName 203.0.113.10
    User deploy
    IdentityFile ~/.ssh/id_ed25519
    Port 22
```

```bash
ssh web 'systemctl status nginx'             # now "web" is a name
ssh -L 8080:localhost:80 web                 # forward my port 8080 to the server's port 80
```

Run a whole script remotely:

```bash
ssh web 'bash -s' < local-script.sh
ssh web bash -s -- arg1 arg2 < local-script.sh       # with arguments
```

### Copying files

```bash
scp file.txt web:/tmp/                        # copy to a server
scp web:/var/log/app.log .                    # copy from a server
scp -r folder web:/backup/                    # a folder

rsync -avz folder/ web:/backup/folder/        # smart sync: only changes are sent
rsync -avz --delete folder/ web:/backup/folder/    # also remove files deleted locally
rsync -avzn folder/ web:/backup/folder/       # -n = DRY RUN: show what would happen first!
tar czf - folder | ssh web 'tar xzf - -C /backup'  # stream a tar over ssh
```

**The trailing-slash rule of rsync:** `folder/` = "the **contents** of folder"; `folder` = "the folder itself". Use `-n` first!

---

## 8. Security habits

| Do | Don't |
|----|-------|
| keep tokens in **environment variables** or files with `chmod 600` | put secrets in the command line (visible in `ps`, history) |
| `curl -K config-file` or `-H @file` / read from a file | commit tokens to Git |
| verify checksums/signatures of downloads | `curl URL \| bash` from strangers |
| `ssh` keys with passphrases + `ssh-agent` | share one key between everyone |
| least privilege: a read-only token for read-only jobs | use your admin token everywhere |
| keep `StrictHostKeyChecking` on | `-k` / `StrictHostKeyChecking=no` in production |
| rotate and revoke leaked tokens immediately | assume nobody noticed |

```bash
# read the token from a file with tight permissions
TOKEN=$(< ~/.config/myapp/token)       # chmod 600 the file
curl -H "Authorization: Bearer $TOKEN" ...
```

Note: `curl -H "…$TOKEN"` is still visible in `ps` while running. For stricter safety: `curl -K - <<< "header = \"Authorization: Bearer $TOKEN\""`.

---

## ⚠️ Gotchas

| Mistake | Effect | Fix |
|---------|--------|-----|
| no `-f` | HTTP 404/500 looks like success | `curl -fsS` |
| no `-m` | script hangs forever | `-m 20 --connect-timeout 5` |
| unquoted URL with `&` | shell cuts the command | quote: `"https://x/?a=1&b=2"` |
| building JSON with `printf`/`echo` | broken on quotes, newlines | `jq -n --arg` |
| parsing JSON with `grep`/`sed` | breaks easily | `jq` |
| `ssh` asks for a password in a script | hangs | keys + `-o BatchMode=yes` |
| `rsync folder` vs `folder/` | wrong nesting | think "contents vs folder", test with `-n` |
| `rsync --delete` without `-n` | surprise deletions | always dry-run first |
| ignoring `429`/`Retry-After` | banned token | back off, cache |
| `-k` to "fix" certificate errors | man-in-the-middle risk | fix the certificate/CA instead |
| token in the script file | leaks via Git | environment or protected file |

---

## ✅ Summary

- `curl -fsS -m 20 URL` is the safe default; `-H`, `-d`/`--json`, `-o`, `-w '%{http_code}'`, `-L`
- JSON → **`jq -r`**; build JSON with `jq -n --arg`, never by string concatenation
- A good client: timeouts, status checks, retries with back-off, pagination, rate-limit respect
- `ping`, `nc -z`, `/dev/tcp`, `dig`, `ss` for checking networks
- `ssh` (keys, `config`, remote commands), `scp`, **`rsync -avzn`** (dry-run first!)
- Secrets never on the command line or in Git; verify downloads; never `curl | bash`

## ➡️ Next

Open **`Code.md`**, run **`Code.sh`**, then do the exercises in **`Resources.md`**.

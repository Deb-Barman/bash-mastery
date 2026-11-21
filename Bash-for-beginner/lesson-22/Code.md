# Lesson 22 — Code Explained

**Run it:**

```bash
bash Code.sh
```

Needs `curl` and `python3`. **No internet is used.** The script writes a tiny web server (`api.py`), starts it on `127.0.0.1` (your own machine only) on a random free port, talks to it, and stops it again with a `trap`. Everything lives in `~/bash-practice/lesson22-demo` (deleted at the end). Port numbers and timings will differ on your machine.

---

## The demo server

`api.py` (about 60 lines of Python, standard library only) pretends to be a small API:

| Endpoint | Behaviour |
|----------|-----------|
| `GET /hello.txt` | plain text |
| `GET /api/users` | a JSON list of three users |
| `GET /api/secure` | `200` only with `Authorization: Bearer secret-token`, otherwise `401` |
| `GET /api/flaky` | fails with `503` twice, succeeds on every third call |
| `GET /api/items?page=N` | 3 items per page plus a `next` page number |
| `POST /api/echo` | answers `201` with the JSON you sent, or `400` for bad JSON |

How it starts:

```bash
python3 api.py port.txt &          # the server writes its port number into port.txt
SERVER_PID=$!
trap cleanup EXIT                  # stop it however the script ends
for _ in {1..50}; do [[ -s port.txt ]] && break; sleep 0.1; done     # wait until it is ready
```

Starting a server and **waiting until it's ready** (never just `sleep 2` and hope) is a pattern you'll use a lot.

---

## Helpers

- `port_open HOST PORT` uses `exec 3<> /dev/tcp/HOST/PORT` inside a subshell. Bash itself opens the TCP connection, and the exit status says whether it worked. No `nc` needed.
- `jget PATH` is a tiny JSON reader built on Python (dotted paths such as `0.name` or `received.name`). It's here so the lesson works **even without `jq`**; with `jq` installed you'd write `jq -r '.[0].name'`.

---

## Part 2: curl basics

| Command | Learn |
|---------|-------|
| `curl -sS URL` | `-s` hides the progress bar, `-S` still shows real errors |
| `curl -I` | headers only (`HEAD`) |
| `-o /dev/null -w 'status: %{http_code}\n'` | print **only** the HTTP status |
| 404 **without** `-f` | `curl` exits **0**. The request "worked", the server just said no |
| 404 **with** `-f` | exit **22**, so `if curl -f …` and `||` work as you expect |
| `-w '%{time_total}'` | timing info, handy for monitoring |

---

## Part 3: download and verify

`sha256sum` writes a checksum file, and `sha256sum -c` checks it: `OK`. We then **append a line** to the file and check again → `FAILED`. This is exactly how you detect a corrupted or tampered download (compare against a checksum published by the vendor, over a separate channel if possible).

---

## Parts 4 to 6: JSON

- **Reading:** `jget 0.name < users.json` prints the first user's name. With `jq`: `jq -r '.[].name'`.
- **Sending:** `-X POST -H 'Content-Type: application/json' -d '{...}'`. The server echoes the object back with status 201. Broken JSON gets **400**.
- **Building JSON safely:** gluing text with quotes inside produces `{"name": "Asha "The Great""}`, which is **invalid**. A JSON library (Python's `json.dumps`, or `jq -n --arg`) escapes the inner quotes, so the round trip through the server works. Passing values through the **environment** (`NAME="$name" python3 -c '…os.environ["NAME"]…'`) avoids any quoting trouble between Bash and Python.

---

## Part 7: tokens

Three calls to the same URL: no token → `401`, wrong token → `401`, right token → `200` with the secret. In your own scripts the token comes from an **environment variable or a `chmod 600` file**, never from the command line or the Git history.

---

## Part 8: retry with back-off

```bash
retry 5 1 curl -fsS -o /dev/null "$BASE/api/flaky"
```

`retry MAX DELAY command…` runs the command until it succeeds, waiting `DELAY` seconds, **doubling** each time (`(( n++, delay *= 2 ))`: two arithmetic expressions separated by a comma). Bash arithmetic is **integer-only**, so delays are whole seconds. The plain call before it counted as call 1 (`503`), the first call inside `retry` failed (call 2, `503`), and the next succeeded (call 3). `-f` makes `503` count as failure; without it, `retry` would think the first call worked.

---

## Part 9: the `api()` client

The function from the lesson in action:

1. creates a temp file for the body (`mktemp`)
2. runs `curl` with a timeout (`-m 10`), a token header, `-o body` and `-w '%{http_code}'` so the **status** is captured separately from the **body**
3. if the status starts with `2` → print the body; otherwise print `API error 404 on GET /api/missing: …` to stderr and `return 1`
4. `${body:+-d "$body"}` adds `-d "$body"` **only if** `body` is non-empty (Lesson 10's `:+`)

One well-tested function like this makes every later call a one-liner.

---

## Part 10: pagination

```bash
while [[ -n $page ]]; do
    resp=$(api GET "/api/items?page=$page")
    ...
    page=<the "next" field, empty when null>
done
```

Three pages (1 2 3 / 4 5 6 / 7), then `next` is `null`, so `page` becomes empty and the loop ends. Real APIs may use `next` URLs, cursors or `Link` headers, but the loop shape is identical: **fetch, process, ask for the next, stop when there isn't one.**

---

## Part 11: HTTP by hand

```bash
exec 3<> "/dev/tcp/127.0.0.1/$PORT"
printf 'GET /hello.txt HTTP/1.0\r\nHost: localhost\r\n\r\n' >&3
head -n 1 <&3
exec 3>&-
```

`exec 3<> …` opens a read/write connection on file descriptor 3. We write a raw request (note the `\r\n`) and read the first line of the answer: `HTTP/1.0 200 OK`. This is what `curl` does for you; seeing it once makes HTTP less mysterious.

---

## Part 12: what's installed

The script checks for `jq`, `wget`, `ssh`, `scp`, `rsync`, `nc`, `dig`. It only **shows** the ssh and rsync commands (they need a real remote machine), including the **dry-run first** habit: `rsync -avzn`.

---

## 🧪 Experiments

1. Add `-v` to one `curl` command to see the whole conversation (headers both ways).
2. Call `$BASE/api/users` with `curl -s | python3 -m json.tool` for pretty-printed JSON.
3. Add a `--max-time 0.001` to a call and observe the timeout error (exit 28).
4. Change `retry 5 1` to `retry 2 1`: the retry gives up (the server needs 3 calls).
5. Write `top-city.sh`, which fetches `/api/users` and prints the city with the most users.
6. If `jq` is installed, redo Part 4, 5 and 10 with `jq` instead of Python.

---

## ✅ New words in this file

`curl -fsS -m -o -I -w '%{http_code}' -H -d -X --json` · HTTP methods and status codes · `sha256sum -c` · `jq -r` / `--arg` · `exec 3<> /dev/tcp/host/port` · `mktemp` · `${var:+…}` · `(( a++, b *= 2 ))` · `trap … EXIT` for stopping a server · `ssh` / `scp` / `rsync -avzn`

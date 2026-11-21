#!/usr/bin/env bash
# ==========================================================
# Lesson 22 - Code.sh
# Topic : curl, HTTP status codes, JSON, auth, retries,
#         pagination, an API client function, /dev/tcp,
#         building JSON safely, ssh/rsync (shown, not run)
# Run   : bash Code.sh
# Safe  : talks ONLY to a tiny web server that this script
#         starts on 127.0.0.1 (your own machine, random port)
#         and stops again. No internet access is needed.
# Needs : curl and python3.
# ==========================================================

for tool in curl python3; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "This lesson needs '$tool'. Please install it and run again."
        exit 1
    fi
done

DEMO="$HOME/bash-practice/lesson22-demo"
if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- A TINY API SERVER (written to a file, then started) ---
cat > api.py << 'EOF'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

state = {"flaky": 0}
USERS = [{"id": 1, "name": "Asha", "city": "Delhi"},
         {"id": 2, "name": "Ravi", "city": "Pune"},
         {"id": 3, "name": "Mina", "city": "Delhi"}]
ITEMS = list(range(1, 8))

class H(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send_any(self, code, body, ctype="application/json"):
        if not isinstance(body, str):
            body = json.dumps(body)
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path == "/hello.txt":
            self.send_any(200, "Hello from the demo server\n", "text/plain")
        elif u.path == "/api/users":
            self.send_any(200, USERS)
        elif u.path == "/api/secure":
            if self.headers.get("Authorization") == "Bearer secret-token":
                self.send_any(200, {"secret": "42"})
            else:
                self.send_any(401, {"error": "unauthorized"})
        elif u.path == "/api/flaky":
            state["flaky"] += 1
            if state["flaky"] % 3 != 0:
                self.send_any(503, {"error": "busy, try again"})
            else:
                self.send_any(200, {"ok": True})
        elif u.path == "/api/items":
            page = int(q.get("page", ["1"])[0])
            per = 3
            chunk = ITEMS[(page - 1) * per: page * per]
            nxt = page + 1 if page * per < len(ITEMS) else None
            self.send_any(200, {"items": chunk, "next": nxt})
        else:
            self.send_any(404, {"error": "not found"})

    def do_HEAD(self):
        u = urlparse(self.path)
        if u.path == "/hello.txt":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", "27")
            self.end_headers()
        else:
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(n)
        if self.path == "/api/echo":
            try:
                obj = json.loads(raw or b"{}")
            except ValueError:
                self.send_any(400, {"error": "bad json"})
                return
            self.send_any(201, {"received": obj})
        else:
            self.send_any(404, {"error": "not found"})

srv = HTTPServer(("127.0.0.1", 0), H)
open(sys.argv[1], "w").write(str(srv.server_address[1]))
srv.serve_forever()
EOF

echo "hello downloads" > payload.txt

python3 api.py port.txt &
SERVER_PID=$!
cleanup() {
    kill "$SERVER_PID" 2> /dev/null
    wait "$SERVER_PID" 2> /dev/null
}
trap cleanup EXIT

# wait (up to ~5 s) until the server has written its port
for _ in {1..50}; do
    [[ -s port.txt ]] && break
    sleep 0.1
done
PORT=$(< port.txt)
BASE="http://127.0.0.1:$PORT"
echo "Demo server running at $BASE (PID $SERVER_PID)"
echo ""

# --- helpers -----------------------------------------------
# port_open HOST PORT: pure Bash, no extra tools
port_open() {
    (exec 3<> "/dev/tcp/$1/$2") 2> /dev/null
}

# jget PATH: read JSON on stdin, print the value at a dotted path (a.b.0.c)
jget() {
    python3 -c '
import sys, json
d = json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d = d[int(k)] if isinstance(d, list) else d[k]
print(json.dumps(d) if isinstance(d, (dict, list)) else d)
' "$1"
}

# --- PART 1: is the port open? -----------------------------
echo "== Part 1: is the server reachable? =="
if port_open 127.0.0.1 "$PORT"; then echo "port $PORT is OPEN   (checked with /dev/tcp, no extra tools)"; fi
if port_open 127.0.0.1 1;       then echo "port 1 is open"; else echo "port 1 is CLOSED"; fi
echo ""

# --- PART 2: curl basics -----------------------------------
echo "== Part 2: curl basics =="
echo "-- GET a text file (-sS = silent but show errors) --"
curl -sS "$BASE/hello.txt"
echo "-- headers only (-I) --"
curl -sS -I "$BASE/hello.txt" | tr -d '\r' | sed -n '1p;/^Content-Type/p;/^Content-Length/p'
echo "-- just the status code (-w) --"
curl -sS -o /dev/null -w 'status: %{http_code}\n' "$BASE/hello.txt"
curl -sS -o /dev/null -w 'status: %{http_code}\n' "$BASE/nothing-here"
echo "-- without -f, a 404 looks like success (exit status 0) --"
curl -sS "$BASE/nothing-here" > /dev/null; echo "exit status: $?"
echo "-- with -f, a 404 becomes a failure (exit status 22) --"
curl -fsS "$BASE/nothing-here" > /dev/null 2>&1; echo "exit status: $?"
echo "-- timing information --"
curl -sS -o /dev/null -w 'total time: %{time_total}s, size: %{size_download} bytes\n' "$BASE/hello.txt"
echo ""

# --- PART 3: saving and verifying files --------------------
echo "== Part 3: download and verify =="
curl -fsS -o hello-copy.txt "$BASE/hello.txt"
echo "saved $(wc -c < hello-copy.txt) bytes to hello-copy.txt"
sha256sum hello-copy.txt > hello-copy.sha256
sha256sum -c hello-copy.sha256
echo "tamper with the file, then check again:"
echo "evil" >> hello-copy.txt
sha256sum -c hello-copy.sha256 2>&1 | sed 's/^/   /' | head -n 2
echo ""

# --- PART 4: JSON GET --------------------------------------
echo "== Part 4: reading JSON =="
curl -fsS "$BASE/api/users" > users.json
echo "raw: $(cat users.json | cut -c1-70)..."
echo "first user's name : $(jget 0.name < users.json)"
echo "second user's city: $(jget 1.city < users.json)"
if command -v jq > /dev/null 2>&1; then
    echo "-- the same with jq --"
    jq -r '.[] | select(.city == "Delhi") | .name' users.json | sed 's/^/   /'
else
    echo "(jq is not installed: install it with 'sudo apt install jq' or 'brew install jq'."
    echo " Example once you have it:  jq -r '.[].name' users.json)"
fi
echo ""

# --- PART 5: POST JSON -------------------------------------
echo "== Part 5: sending JSON (POST) =="
resp=$(curl -fsS -X POST -H 'Content-Type: application/json' -d '{"name":"Karan","age":25}' "$BASE/api/echo")
echo "server replied: $resp"
echo "received name : $(jget received.name <<< "$resp")"
code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"name":' "$BASE/api/echo")
echo "broken JSON gets status $code (400 = bad request)"
echo ""

# --- PART 6: building JSON safely --------------------------
echo "== Part 6: build JSON safely =="
name='Asha "The Great"'
bad="{\"name\": \"$name\"}"
echo "string concatenation: $bad"
if python3 -c 'import json,sys; json.loads(sys.argv[1])' "$bad" 2> /dev/null; then
    echo "   -> valid"
else
    echo "   -> INVALID JSON (the inner quotes were not escaped)"
fi
good=$(NAME="$name" python3 -c 'import os, json; print(json.dumps({"name": os.environ["NAME"]}))')
echo "built by a JSON library: $good   -> valid"
if command -v jq > /dev/null 2>&1; then
    echo "with jq: $(jq -n --arg name "$name" '{name: $name}')"
fi
echo "round trip through the server: $(curl -fsS -H 'Content-Type: application/json' -d "$good" "$BASE/api/echo")"
echo ""

# --- PART 7: authentication --------------------------------
echo "== Part 7: tokens =="
echo "no token         -> status $(curl -sS -o /dev/null -w '%{http_code}' "$BASE/api/secure")"
echo "wrong token      -> status $(curl -sS -o /dev/null -w '%{http_code}' -H 'Authorization: Bearer nope' "$BASE/api/secure")"
API_TOKEN="secret-token"
echo "correct token    -> status $(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $API_TOKEN" "$BASE/api/secure")"
echo "response body    -> $(curl -fsS -H "Authorization: Bearer $API_TOKEN" "$BASE/api/secure")"
echo "(in real scripts the token comes from an environment variable or a chmod 600 file,"
echo " never typed into the command line or committed to Git)"
echo ""

# --- PART 8: retries ---------------------------------------
echo "== Part 8: a flaky server and retry with back-off =="
echo "plain call, no retry:"
curl -sS -o /dev/null -w '   status %{http_code}\n' "$BASE/api/flaky"

retry() {                          # retry MAX DELAY command...
    local n=1 max=$1 delay=$2
    shift 2
    until "$@"; do
        if (( n >= max )); then
            echo "   giving up after $n attempts" >&2
            return 1
        fi
        echo "   attempt $n failed, waiting ${delay}s..." >&2
        sleep "$delay"
        (( n++, delay *= 2 ))          # whole seconds: Bash arithmetic is integer-only
    done
    echo "   succeeded on attempt $n"
}
retry 5 1 curl -fsS -o /dev/null "$BASE/api/flaky"
echo ""

# --- PART 9: an API client function ------------------------
echo "== Part 9: an api() client function with error handling =="
api() {                            # api METHOD PATH [json-body]
    local method=$1 path=$2 body=${3:-} out status
    out=$(mktemp)
    status=$(curl -sS -m 10 -X "$method" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H 'Content-Type: application/json' \
        ${body:+-d "$body"} \
        -o "$out" -w '%{http_code}' "$BASE$path") || { rm -f "$out"; return 1; }
    if [[ $status =~ ^2 ]]; then
        cat "$out"
        rm -f "$out"
    else
        echo "API error $status on $method $path: $(cat "$out")" >&2
        rm -f "$out"
        return 1
    fi
}
echo "api GET /api/secure      -> $(api GET /api/secure)"
echo "api POST /api/echo       -> $(api POST /api/echo '{"hello":"world"}')"
echo "api GET /api/missing     ->"
api GET /api/missing 2>&1 | sed 's/^/   /'
echo ""

# --- PART 10: pagination -----------------------------------
echo "== Part 10: pagination (follow 'next' until there is none) =="
page=1
all=()
while [[ -n $page ]]; do
    resp=$(api GET "/api/items?page=$page")
    items=$(python3 -c 'import sys, json; print(" ".join(map(str, json.load(sys.stdin)["items"])))' <<< "$resp")
    echo "   page $page -> items: $items"
    all+=($items)
    page=$(python3 -c 'import sys, json; n = json.load(sys.stdin)["next"]; print("" if n is None else n)' <<< "$resp")
done
echo "collected ${#all[@]} items in total: ${all[*]}"
echo ""

# --- PART 11: raw HTTP with /dev/tcp -----------------------
echo "== Part 11: HTTP by hand with /dev/tcp (no curl!) =="
exec 3<> "/dev/tcp/127.0.0.1/$PORT"
printf 'GET /hello.txt HTTP/1.0\r\nHost: localhost\r\n\r\n' >&3
head -n 1 <&3 | tr -d '\r'
exec 3>&-
echo "(That first line is the status line of the response: curl does all this for you.)"
echo ""

# --- PART 12: what is installed ----------------------------
echo "== Part 12: remote-work tools on this machine =="
for tool in jq wget ssh scp rsync nc dig; do
    if command -v "$tool" > /dev/null 2>&1; then
        printf '   %-6s installed\n' "$tool"
    else
        printf '   %-6s not installed\n' "$tool"
    fi
done
echo ""
echo "Commands you will use (shown, NOT run; they need a real server):"
cat << 'EOF'
   ssh-keygen -t ed25519 -C "my laptop"
   ssh-copy-id user@server
   ssh -o BatchMode=yes -o ConnectTimeout=5 user@server 'uptime'
   scp report.txt user@server:/tmp/
   rsync -avzn  project/ user@server:/backup/project/    # -n = dry run FIRST
   rsync -avz   project/ user@server:/backup/project/
EOF
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo server stopped, demo folder removed. Run me again anytime!"

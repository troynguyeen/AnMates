#!/usr/bin/env bash
# Load-test runner for AnMates API
# Usage: ./run.sh [options]
#   -v <n>   Peak virtual users (default: 500)
#   -u <n>   Pre-created user pool size (default: 100)
#   -c       Remove result files before running
#   -h       Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VUS=500
USER_POOL=500
CLEAN=0

usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while getopts "v:u:ch" opt; do
  case $opt in
    v) VUS="$OPTARG" ;;
    u) USER_POOL="$OPTARG" ;;
    c) CLEAN=1 ;;
    h) usage ;;
    *) echo "Unknown option: -$OPTARG"; exit 1 ;;
  esac
done

# ── colours ──────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'
YELLOW='\033[1;33m'; WHITE='\033[1;37m'; RESET='\033[0m'

banner() { echo -e "\n${CYAN}==> $1${RESET}"; }
ok()     { echo -e "    ${GREEN}$1${RESET}"; }
warn()   { echo -e "    ${YELLOW}[warn] $1${RESET}"; }
die()    { echo -e "\n${RED}[ERROR] $1${RESET}"; exit 1; }

open_browser() {
  # Works in WSL (Windows), macOS, and Linux desktops
  local url="$1"
  if command -v cmd.exe &>/dev/null; then
    cmd.exe /c start "$url" 2>/dev/null || true   # WSL / Windows
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$url" &>/dev/null || true            # Linux desktop
  elif command -v open &>/dev/null; then
    open "$url" || true                             # macOS
  fi
}

# ── preflight ────────────────────────────────────────────────────────────────
banner "Preflight checks"
command -v docker &>/dev/null || die "docker not found in PATH"
docker compose version &>/dev/null || die "docker compose plugin not available"
ok "docker compose: OK"
[[ -f "$SCRIPT_DIR/k6-script.js" ]] || die "k6-script.js not found"
ok "k6-script.js: found"

# ── clean previous results ────────────────────────────────────────────────────
if [[ $CLEAN -eq 1 ]]; then
  banner "Cleaning previous results"
  rm -f "$SCRIPT_DIR/results/raw.json" "$SCRIPT_DIR/results/report.html"
  ok "results cleared"
fi
mkdir -p "$SCRIPT_DIR/results"

# ── tear down any leftover containers ────────────────────────────────────────
banner "Tearing down previous stack (if any)"
docker compose down --remove-orphans &>/dev/null || true
ok "done"

# ── run ───────────────────────────────────────────────────────────────────────
banner "Starting stack  (db + api build + k6 load test)"
echo -e "    Peak VUs  : ${WHITE}$VUS${RESET}"
echo -e "    User pool : ${WHITE}$USER_POOL${RESET}"
echo -e "    Dashboard : ${WHITE}http://localhost:5665${RESET}"
echo -e "    This takes ~4 minutes. Press Ctrl+C to abort.\n"

START_TS=$(date +%s)
export USER_POOL

# Start stack in background so we can open the browser while it runs
docker compose up --build --abort-on-container-exit &
COMPOSE_PID=$!

# Wait for k6 dashboard to be ready (up to 60 s), then open browser
banner "Waiting for k6 dashboard on port 5665"
DASHBOARD_URL="http://localhost:5665"
for i in $(seq 1 30); do
  if curl -sf "$DASHBOARD_URL" -o /dev/null 2>/dev/null; then
    ok "Dashboard ready"
    echo -e "    Opening ${WHITE}${DASHBOARD_URL}${RESET} in your browser..."
    open_browser "$DASHBOARD_URL"
    break
  fi
  sleep 2
done

# Wait for docker compose to finish
wait $COMPOSE_PID || true

banner "Tearing down stack"
docker compose down --remove-orphans &>/dev/null || true
ok "containers removed"

# ── parse results ─────────────────────────────────────────────────────────────
RAW="$SCRIPT_DIR/results/raw.json"
[[ -f "$RAW" ]] || die "raw.json not found — test may have failed before k6 wrote output"

banner "Parsing results"

python3 - "$RAW" "$START_TS" "$VUS" "$USER_POOL" <<'PYEOF'
import sys, json, math, time

raw_file  = sys.argv[1]
start_ts  = int(sys.argv[2])
peak_vus  = int(sys.argv[3])
user_pool = int(sys.argv[4])

durations      = []
status_codes   = {}
data_sent      = 0.0
data_recv      = 0.0
main_reqs      = 0
setup_reqs     = 0
vu_samples     = []
first_time     = None
last_time      = None
err_samples    = []   # k6 custom error_rate metric (already excludes expected 409s)

with open(raw_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("type") != "Point":
            continue

        t = obj["data"].get("time")
        if t:
            if first_time is None:
                first_time = t
            last_time = t

        metric = obj.get("metric")
        val    = obj["data"].get("value", 0)
        tags   = obj["data"].get("tags", {})

        if metric == "http_req_duration":
            durations.append(val)
        elif metric == "http_reqs":
            grp = tags.get("group", "")
            if "setup" in grp:
                setup_reqs += 1
            else:
                main_reqs += 1
            s = tags.get("status")
            if s:
                status_codes[s] = status_codes.get(s, 0) + 1
        elif metric == "error_rate":
            err_samples.append(val)
        elif metric == "vus":
            vu_samples.append(int(val))
        elif metric == "data_sent":
            data_sent += val
        elif metric == "data_received":
            data_recv += val

def pct(arr, p):
    if not arr:
        return 0.0
    s = sorted(arr)
    idx = max(0, math.ceil(p / 100.0 * len(s)) - 1)
    return round(s[idx], 2)

total_sec = 0
if first_time and last_time:
    from datetime import datetime, timezone
    fmt = "%Y-%m-%dT%H:%M:%S.%fZ"
    t0 = datetime.strptime(first_time[:26] + "Z", fmt).replace(tzinfo=timezone.utc)
    t1 = datetime.strptime(last_time[:26]  + "Z", fmt).replace(tzinfo=timezone.utc)
    total_sec = round((t1 - t0).total_seconds())

rps      = round(main_reqs / total_sec, 1) if total_sec > 0 else 0
max_vu   = max(vu_samples) if vu_samples else 0
s2xx     = sum(v for k, v in status_codes.items() if k.startswith("2"))
s4xx     = sum(v for k, v in status_codes.items() if k.startswith("4"))
s5xx     = sum(v for k, v in status_codes.items() if k.startswith("5"))
s409     = status_codes.get("409", 0)
# Use the k6 custom error_rate metric which correctly excludes expected 409 (duplicate wishlist)
err_rate = round(sum(err_samples) / len(err_samples) * 100, 2) if err_samples else \
           round((s4xx - s409 + s5xx) / main_reqs * 100, 2) if main_reqs > 0 else 0.0

p95 = pct(durations, 95)
p99 = pct(durations, 99)

slo_p95  = p95 < 500
slo_p99  = p99 < 1000
slo_err  = err_rate < 1.0
all_pass = slo_p95 and slo_p99 and slo_err

CYAN  = "\033[0;36m"
GREEN = "\033[0;32m"
RED   = "\033[0;31m"
WHITE = "\033[1;37m"
GRAY  = "\033[0;90m"
RST   = "\033[0m"

def badge(ok):
    return f"{GREEN}PASS{RST}" if ok else f"{RED}FAIL{RST}"

sep = WHITE + ("=" * 59) + RST
now = time.strftime("%Y-%m-%d %H:%M")

print(f"\n{sep}")
print(f"  {WHITE}ANMATES API LOAD TEST REPORT  --  {now}{RST}")
print(sep)

print(f"\n  {CYAN}SETUP{RST}")
print(f"  User pool  : {user_pool} tokens")
print(f"  Peak VUs   : {max_vu}")
print(f"  Test time  : {total_sec}s")

print(f"\n  {CYAN}THROUGHPUT{RST}")
print(f"  Total reqs : {main_reqs}")
print(f"  Avg req/s  : {rps}")
print(f"  Data sent  : {round(data_sent/1024/1024, 2)} MB")
print(f"  Data recv  : {round(data_recv/1024/1024, 2)} MB")

print(f"\n  {CYAN}LATENCY (ms){RST}")
print(f"  p50  :  {pct(durations, 50)}")
print(f"  p75  :  {pct(durations, 75)}")
print(f"  p90  :  {pct(durations, 90)}")
print(f"  p95  :  {p95}  (SLO: p95<500ms)   [{badge(slo_p95)}]")
print(f"  p99  :  {p99}  (SLO: p99<1000ms)  [{badge(slo_p99)}]")
print(f"  max  :  {pct(durations, 100)}")

print(f"\n  {CYAN}ERRORS{RST}")
print(f"  2xx        :  {s2xx}")
print(f"  4xx real   :  {s4xx - s409}")
print(f"  5xx        :  {s5xx}")
print(f"  409 (dup)  :  {s409}  (expected — duplicate wishlist entries)")
print(f"  Rate       :  {err_rate}%  (SLO: rate<1%)  [{badge(slo_err)}]")

print(f"\n  {CYAN}STATUS BREAKDOWN{RST}")
for k in sorted(status_codes):
    note = "  (expected)" if k == "409" else ""
    print(f"  {k}  :  {status_codes[k]}{note}")

print()
if all_pass:
    print(f"  {GREEN}RESULT: ALL SLOs PASSED{RST}")
else:
    print(f"  {RED}RESULT: ONE OR MORE SLOs FAILED{RST}")
print(sep)
print(f"  {GRAY}HTML report: load-test/results/report.html{RST}")
print(f"  {GRAY}Raw data:    load-test/results/raw.json{RST}\n")

sys.exit(0 if all_pass else 1)
PYEOF

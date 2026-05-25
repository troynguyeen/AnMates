#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# start.sh — AnMates local dev launcher
# Supports: macOS (OrbStack / Docker Desktop) · Linux · Windows (WSL2 / Git Bash)
# Usage:  ./start.sh
# Custom: WEB_PORT=3000 FLUTTER_BIN=/path/to/flutter ./start.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[AnMates]${NC} $1"; }
warn()  { echo -e "${YELLOW}[AnMates]${NC} $1"; }
error() { echo -e "${RED}[AnMates]${NC} $1"; exit 1; }

# ── Config (override via env vars) ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$SCRIPT_DIR/anmates-api"
FLUTTER_DIR="$SCRIPT_DIR/anmates_flutter"
WEB_PORT="${WEB_PORT:-54180}"
API_PORT="${API_PORT:-8080}"

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  MINGW*|CYGWIN*|MSYS*) PLATFORM="windows" ;;
  *) PLATFORM="unknown" ;;
esac

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  AnMates — Local Dev Launcher  [${PLATFORM}]${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 1. Detect Flutter binary ──────────────────────────────────────────────────
if [[ -n "${FLUTTER_BIN:-}" ]]; then
  FLUTTER="$FLUTTER_BIN"
elif command -v flutter &>/dev/null; then
  FLUTTER="$(command -v flutter)"
elif [[ -f "/opt/homebrew/bin/flutter" ]]; then
  FLUTTER="/opt/homebrew/bin/flutter"
elif [[ -f "$HOME/flutter/bin/flutter" ]]; then
  FLUTTER="$HOME/flutter/bin/flutter"
else
  error "Flutter not found. Set FLUTTER_BIN=/path/to/flutter or add flutter to PATH.\nSee: https://docs.flutter.dev/get-started/install"
fi
log "Flutter: $FLUTTER"

# ── 2. Detect LAN IP ──────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "macos" ]]; then
  LAN_IP=$(ipconfig getifaddr en0 2>/dev/null \
         || ipconfig getifaddr en1 2>/dev/null \
         || echo "localhost")
elif [[ "$PLATFORM" == "linux" || "$PLATFORM" == "windows" ]]; then
  LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' \
         || hostname -I 2>/dev/null | awk '{print $1}' \
         || echo "localhost")
else
  LAN_IP="localhost"
fi
log "LAN IP: $LAN_IP"

# ── 3. Update hardcoded API URLs in Flutter source ────────────────────────────
log "Updating Flutter API URLs → http://$LAN_IP:$API_PORT"
_sed() {
  if [[ "$PLATFORM" == "macos" ]]; then
    sed -i '' "$1" "$2"
  else
    sed -i "$1" "$2"
  fi
}
for file in \
    "$FLUTTER_DIR/lib/services/api_client.dart" \
    "$FLUTTER_DIR/lib/services/auth_service.dart"
do
  [[ -f "$file" ]] || continue
  _sed "s|http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:$API_PORT|http://$LAN_IP:$API_PORT|g" "$file"
  _sed "s|ws://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:$API_PORT|ws://$LAN_IP:$API_PORT|g"   "$file"
  _sed "s|http://localhost:$API_PORT|http://$LAN_IP:$API_PORT|g" "$file"
  _sed "s|ws://localhost:$API_PORT|ws://$LAN_IP:$API_PORT|g"     "$file"
done

# ── 4. Setup Docker host ──────────────────────────────────────────────────────
if [[ "$PLATFORM" == "macos" ]]; then
  if [[ -S "$HOME/.orbstack/run/docker.sock" ]]; then
    export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"
    DOCKER_RUNTIME="OrbStack"
  elif [[ -S "$HOME/.docker/run/docker.sock" ]]; then
    export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
    DOCKER_RUNTIME="Docker Desktop"
  elif [[ -S "/var/run/docker.sock" ]]; then
    export DOCKER_HOST="unix:///var/run/docker.sock"
    DOCKER_RUNTIME="Docker"
  else
    # OrbStack not running — try to start it
    warn "OrbStack not running. Starting..."
    open -a OrbStack 2>/dev/null || error "Docker not found.\nmacOS: Install OrbStack → https://orbstack.dev\n  OR: Install Docker Desktop → https://www.docker.com/products/docker-desktop"
    log "Waiting for OrbStack..."
    for i in {1..20}; do
      [[ -S "$HOME/.orbstack/run/docker.sock" ]] && break
      sleep 2
      [[ $i == 20 ]] && error "OrbStack did not start. Open it manually and retry."
    done
    export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"
    DOCKER_RUNTIME="OrbStack"
  fi
elif [[ "$PLATFORM" == "linux" ]]; then
  if [[ -S "/var/run/docker.sock" ]]; then
    export DOCKER_HOST="unix:///var/run/docker.sock"
    DOCKER_RUNTIME="Docker Engine"
  else
    error "Docker not running.\nLinux: sudo systemctl start docker"
  fi
else
  # Windows Git Bash / WSL2 — Docker Desktop manages the socket
  DOCKER_RUNTIME="Docker Desktop"
fi
log "Docker runtime: $DOCKER_RUNTIME ✓"

# ── 5. Verify docker is accessible ───────────────────────────────────────────
docker info &>/dev/null || error "Cannot connect to Docker daemon ($DOCKER_RUNTIME).\nMake sure Docker is running and try again."

# ── 6. Start backend ──────────────────────────────────────────────────────────
log "Starting Go API + PostgreSQL..."
cd "$API_DIR"

# Check .env exists
[[ -f ".env" ]] || error ".env file not found in anmates-api/\nCopy from .env.example: cp .env.example .env\nThen fill in the values."

docker compose up -d 2>&1 | grep -E "Started|Running|Created|Healthy|Warning|error" || true

log "Waiting for backend health check..."
for i in {1..30}; do
  if curl -sf "http://localhost:$API_PORT/health" &>/dev/null; then
    log "Backend healthy ✓"
    break
  fi
  sleep 2
  if [[ $i == 30 ]]; then
    echo ""
    warn "Backend not responding. Check logs:"
    warn "  docker compose logs api"
    warn "  docker compose logs db"
    error "Backend not healthy after 60s."
  fi
done

# ── 7. Build Flutter web ──────────────────────────────────────────────────────
log "Building Flutter web..."
cd "$FLUTTER_DIR"
"$FLUTTER" pub get --no-example 2>&1 | grep -E "Got|Resolving|Changed|error|Error" || true
"$FLUTTER" build web --release 2>&1 | grep -E "Built|Compiling|error|Error" || true
log "Flutter web built ✓"

# ── 8. Start web server ───────────────────────────────────────────────────────
# Kill any process holding the port (SIGKILL, not SIGTERM) then wait until free.
_free_port() {
  local port="$1"
  lsof -ti:"$port" 2>/dev/null | xargs kill -9 2>/dev/null || true
  for i in {1..10}; do
    lsof -ti:"$port" &>/dev/null || break
    sleep 1
  done
}
_free_port "$WEB_PORT"

cd "$FLUTTER_DIR/build/web"
python3 -m http.server "$WEB_PORT" --bind 0.0.0.0 2>&1 | while IFS= read -r line; do
  echo -e "${GREEN}[WEB flutter]${NC} $line"
done &
WEB_PIPE_PID=$!
# Verify server actually bound the port (not just "started" the process)
for i in {1..5}; do
  lsof -ti:"$WEB_PORT" &>/dev/null && break
  sleep 1
  [[ $i == 5 ]] && error "Web server failed to bind port $WEB_PORT"
done
log "Web server started ✓"

# ── 9. Open browser ───────────────────────────────────────────────────────────
APP_URL="http://localhost:$WEB_PORT"
case "$PLATFORM" in
  macos)   open "$APP_URL" 2>/dev/null || true ;;
  linux)   xdg-open "$APP_URL" 2>/dev/null || true ;;
  windows) start "$APP_URL" 2>/dev/null || true ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  AnMates is running!${NC}"
echo ""
echo -e "  Flutter web   →  ${CYAN}http://localhost:$WEB_PORT${NC}"
echo -e "  LAN (mobile)  →  ${CYAN}http://$LAN_IP:$WEB_PORT${NC}"
echo -e "  Go API        →  ${CYAN}http://localhost:$API_PORT${NC}"
echo -e "  API health    →  ${CYAN}http://localhost:$API_PORT/health${NC}"
echo ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 10. Stream all logs ───────────────────────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}[WEB flutter]${NC}  Flutter web  · port $WEB_PORT"
echo -e "  ${CYAN}[API go-fiber]${NC}  Go backend   · port $API_PORT"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Starts docker log stream in background; updates LOG_PID.
# Arg: number of tail lines (0 = only new lines after rebuild)
_start_log_stream() {
  cd "$API_DIR"
  docker compose logs -f --tail="${1:-20}" api 2>&1 | while IFS= read -r line; do
    clean="${line#*| }"
    echo -e "${CYAN}[API go-fiber]${NC} $clean"
  done &
  LOG_PID=$!
}

# Kills web server + log stream silently.
_stop_services() {
  # Kill tracked PIDs first
  kill "$WEB_PIPE_PID" "$LOG_PID" 2>/dev/null || true
  # Kill all remaining children of this script (python3, docker compose logs, etc.)
  # "docker compose logs -f" holds the pipe open and won't get SIGPIPE while idle,
  # so we must kill it explicitly rather than relying on wait.
  pkill -P $$ 2>/dev/null || true
  # Fixed pause instead of blocking wait — prevents hang when signals are blocked.
  sleep 0.3
}

_ACTION=""

# Ctrl+C handler: stop output, show menu, set _ACTION, return.
_cleanup() {
  trap '' INT TERM   # block re-entry while menu is shown
  echo ""
  _stop_services

  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}  AnMates — bạn muốn làm gì?${NC}"
  echo ""
  echo -e "  ${GREEN}[1]${NC} Stop & Exit  — dừng và thoát containers, giải phóng RAM/CPU"
  echo -e "       ${GREEN}→${NC} chạy lại ./start.sh để tiếp tục"
  echo -e "  ${CYAN}[2]${NC} Rebuild     — build lại code mới + restart API"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  printf "  Chọn [1/2]: "
  read -r _ACTION </dev/tty

  trap _cleanup INT TERM   # re-enable for next Ctrl+C
}

trap _cleanup INT TERM
_start_log_stream 20

# ── Main loop ─────────────────────────────────────────────────────────────────
# Loops only when rebuild is requested (option 2), exits on 1 or 3.
while true; do
  wait "$WEB_PIPE_PID" || true

  case "${_ACTION}" in
    2)
      _ACTION=""
      echo ""
      log "Rebuild Go API Docker image..."
      cd "$API_DIR"
      docker compose build api 2>&1 | grep -E "#[0-9]+|Built|Error|error" || true

      log "Restarting API container..."
      docker compose up -d api 2>&1 | grep -E "Started|Running|Created|Healthy|Warning|error" || true

      log "Waiting for backend health check..."
      for i in {1..30}; do
        if curl -sf "http://localhost:$API_PORT/health" &>/dev/null; then
          log "Backend healthy ✓"; break
        fi
        sleep 2
        [[ $i == 30 ]] && warn "Backend not responding after rebuild."
      done

      log "Restarting web server..."
      _free_port "$WEB_PORT"
      cd "$FLUTTER_DIR/build/web"
      python3 -m http.server "$WEB_PORT" --bind 0.0.0.0 2>&1 | while IFS= read -r line; do
        echo -e "${GREEN}[WEB flutter]${NC} $line"
      done &
      WEB_PIPE_PID=$!

      _start_log_stream 0   # tail=0 → only new logs after rebuild
      log "AnMates running ✓ — Ctrl+C for options"
      ;;

    *)
      # Option 1 (or any key) = stop containers to free resources
      echo ""
      log "Dừng containers — giải phóng RAM/CPU..."
      cd "$API_DIR"
      docker compose stop 2>&1 | grep -E "Stopped|Warning|error" || true
      log "Containers đã dừng. Chạy lại ./start.sh để tiếp tục."
      exit 0
      ;;
  esac
done

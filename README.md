# AnMates — Dev Setup Guide

Cross-platform guide for macOS, Linux, and Windows developers.

---

## Prerequisites

### 1. Docker

Docker runs the Go API + PostgreSQL backend.

#### macOS
**Option A — OrbStack** (recommended, faster, lighter):
```bash
# Download from https://orbstack.dev
# Or via Homebrew:
brew install orbstack
```

**Option B — Docker Desktop**:
Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

#### Linux
```bash
# Ubuntu / Debian
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # log out and back in after this
```

```bash
# Fedora / RHEL
sudo dnf install -y docker docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

#### Windows

Install **Docker Desktop** with WSL2 backend:
1. Enable WSL2: open PowerShell as Admin → `wsl --install`
2. Download Docker Desktop: [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
3. During install: check **"Use WSL 2 instead of Hyper-V"**
4. After install: Docker Desktop → Settings → Resources → WSL Integration → enable your distro

Verify: open **WSL terminal** (Ubuntu) and run `docker --version`

---

### 2. Flutter SDK

#### macOS
```bash
brew install flutter
# Or download from https://docs.flutter.dev/get-started/install/macos
```

#### Linux
```bash
sudo snap install flutter --classic
# Or: https://docs.flutter.dev/get-started/install/linux
```

#### Windows (in WSL2)
```bash
# Inside WSL2 Ubuntu terminal:
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

Verify: `flutter --version`

---

### 3. Python 3

Used to serve the Flutter web build.

- **macOS**: pre-installed
- **Linux**: `sudo apt-get install -y python3`
- **Windows WSL2**: `sudo apt-get install -y python3`

---

## Quick Start (1 command)

```bash
cd AnMatesApp
chmod +x start.sh   # first time only (macOS/Linux/WSL2)
./start.sh
```

> **Windows (PowerShell / CMD):** Use WSL2 or Git Bash to run `./start.sh`.
> PowerShell does not support bash scripts. Open **Ubuntu** (WSL2) or **Git Bash** and run from there.

The script automatically:
1. Detects your Flutter binary
2. Detects your WiFi LAN IP and updates API URLs in Flutter source
3. Starts OrbStack/Docker if not running
4. Starts Go API + PostgreSQL via `docker compose up -d`
5. Waits for backend health check
6. Builds Flutter web (`flutter build web --release`)
7. Serves app at `http://localhost:54180`
8. Opens your browser

---

## Access URLs

| | URL |
|-|-----|
| **App (this machine)** | `http://localhost:54180` |
| **App (phone / other device on same WiFi)** | `http://<YOUR-LAN-IP>:54180` |
| **Go API** | `http://localhost:8080` |
| **API health check** | `http://localhost:8080/health` |

Your LAN IP is printed when `./start.sh` runs. Example: `http://192.168.1.77:54180`

---

## Environment Variables (anmates-api/.env)

Create `anmates-api/.env` before first run (copy from `.env.example`):

```bash
cp anmates-api/.env.example anmates-api/.env
# Then edit the file and fill in the values
```

Required values:

```env
DATABASE_URL=postgres://postgres:<DB_PASS>@db:5432/anmates?sslmode=disable
DB_PASS=your_password_here
JWT_SECRET=your_secret_here
JWT_ACCESS_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d
PORT=8080
ENV=development
```

---

## Customise Ports

```bash
WEB_PORT=3000 API_PORT=9090 ./start.sh
```

Or set a custom Flutter binary path:

```bash
FLUTTER_BIN=/path/to/flutter ./start.sh
```

---

## Stop the App

```bash
# Stop web server: press Ctrl+C in the terminal running start.sh

# Stop backend Docker containers:
cd anmates-api
docker compose down
```

On macOS with OrbStack:
```bash
DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock docker compose down
```

---

## Manual Setup (if start.sh fails)

### Step 1 — Configure environment

```bash
cp anmates-api/.env.example anmates-api/.env
# Edit anmates-api/.env with your values
```

### Step 2 — Start backend

**macOS (OrbStack):**
```bash
cd anmates-api
export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock
docker compose up -d
```

**macOS (Docker Desktop) / Linux / Windows WSL2:**
```bash
cd anmates-api
docker compose up -d
```

Check logs if something fails:
```bash
docker compose logs -f api
docker compose logs -f db
```

### Step 3 — Build & serve Flutter web

```bash
cd anmates_flutter
flutter pub get
flutter build web --release
cd build/web
python3 -m http.server 54180 --bind 0.0.0.0
```

Open browser: `http://localhost:54180`

---

## Project Structure

```
AnMatesApp/
├── start.sh                  ← One-command launcher
├── README.md                 ← This guide
├── anmates-api/              ← Go backend (Fiber v2 + PostgreSQL)
│   ├── main.go
│   ├── docker-compose.yml
│   ├── .env                  ← Environment variables (DO NOT commit)
│   ├── .env.example          ← Template
│   ├── handlers/             ← HTTP handlers
│   ├── db/                   ← Migrations & pool
│   └── models/
└── anmates_flutter/          ← Flutter UI
    ├── lib/
    │   ├── main.dart
    │   ├── services/         ← API client, Auth, Match, Places
    │   └── views/            ← Discover (map), Match, Chat, Profile
    └── pubspec.yaml
```

---

## Troubleshooting

### Docker not found / not running

**macOS:** Install OrbStack ([orbstack.dev](https://orbstack.dev)) or Docker Desktop. The script will try to auto-start OrbStack.

**Linux:**
```bash
sudo systemctl start docker
```

**Windows:** Make sure Docker Desktop is running. Open Docker Desktop from the Start menu, wait for it to fully start, then retry.

---

### Backend not healthy after 60s

```bash
cd anmates-api
docker compose logs api   # look for the specific error
docker compose logs db    # check postgres startup
```

Common causes:
- `.env` file missing → `cp .env.example .env` and fill in values
- Port 8080 already in use → `lsof -ti:8080 | xargs kill -9`
- Database password mismatch → check `DB_PASS` in `.env`

---

### Port already in use

```bash
# Web server port
lsof -ti:54180 | xargs kill -9

# API port
lsof -ti:8080 | xargs kill -9
```

**Windows WSL2:**
```bash
# Use netstat to find the PID:
netstat -ano | findstr :54180
taskkill /PID <pid> /F
```

---

### Flutter build errors — missing packages

```bash
cd anmates_flutter
flutter pub get
flutter clean
flutter build web --release
```

---

### GPS shows wrong location

Browser blocks the Geolocation API on non-HTTPS origins (e.g. `http://192.168.x.x`).

**Fix on localhost (`http://localhost:54180`):**
1. Click the 🔒 icon in Chrome's address bar
2. Set Location → **Allow**
3. Reload the page

**Fix when testing on phone via LAN IP:**
GPS is blocked on plain HTTP. Use the **search bar** in the map view to type your area name (e.g. "Thủ Đức") to manually set the location. The map will move and reload nearby places.

---

### IP changed after switching WiFi

Just re-run `./start.sh` — it auto-detects the new LAN IP and updates the Flutter source files.

---

### Windows: `./start.sh` not working in PowerShell

Use **WSL2** (Ubuntu) or **Git Bash** instead:
- WSL2: press Win, search "Ubuntu", open it, navigate to the project, run `./start.sh`
- Git Bash: right-click project folder → "Git Bash Here" → `./start.sh`

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Register |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/refresh` | Refresh token |
| GET | `/api/profile` | Get profile |
| PUT | `/api/profile` | Update profile |
| GET | `/api/matches` | Match suggestions |
| POST | `/api/matches/:id/accept` | Accept match |
| GET | `/api/conversations` | Conversation list |
| GET | `/api/matches/:id/messages` | Message history |
| WS | `/ws/chat/:matchId` | WebSocket chat |

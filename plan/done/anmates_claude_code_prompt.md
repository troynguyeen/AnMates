# Ăn Mates — Backend MVP

## App
Mobile app (Flutter) kết nối người có cùng sở thích ăn uống. Core loop: user tạo wishlist món ăn → match với người khác overlap ≥ 2 món → chat realtime → "Nồi Lẩu" tích điểm tương tác → paywall level 3.

## Constraints tuyệt đối
- Chạy ổn trên 1 vCPU / 1GB RAM VPS (~$48/năm, DataOnline VN)
- Không dùng managed services nào (không RDS, Redis, SQS)
- Solo dev — không over-engineer

## Stack (không đề xuất thay đổi)
- Language: Go
- HTTP: Fiber v2
- DB: PostgreSQL 16 self-hosted
- WebSocket: gorilla/websocket
- Auth: JWT stateless (access 15m + refresh in DB)
- Cache: Go sync.Map in-process (không Redis)
- Infra: Docker Compose + systemd + Nginx (SSL only) + Cloudflare Free

## PostgreSQL config bắt buộc
```
shared_buffers=64MB  effective_cache_size=256MB
work_mem=2MB  max_connections=20
```

## Project structure
```
anmates-api/
├── main.go
├── config/        env loading
├── handlers/      auth, matching, chat, user
├── middleware/    JWT, rate limit, logger
├── models/        structs
├── db/            pgx pool + raw SQL
├── ws/            WebSocket hub + client
├── Dockerfile     multi-stage, FROM scratch (~8MB binary)
└── docker-compose.yml
```

## Database schema (dùng raw SQL migration, không ORM)
```sql
users(id uuid PK, email unique, password_hash, name, avatar_url, bio, created_at)

wishlists(id uuid PK, user_id FK, food_name, food_category, created_at)
  INDEX: (user_id), (food_category)
  food_category ENUM: bun|pho|com|lau|bbq|cafe|trang_mieng|other

matches(id uuid PK, user_a_id FK, user_b_id FK, status, score float, created_at)
  INDEX: (user_a_id), (user_b_id)
  UNIQUE: (LEAST(user_a_id,user_b_id), GREATEST(user_a_id,user_b_id))

messages(id uuid PK, match_id FK, sender_id FK, content, msg_type, created_at)
  INDEX: (match_id, created_at DESC)

noi_lau_progress(match_id FK PK, points int default 0, level int default 1, last_activity)

refresh_tokens(id uuid PK, user_id FK, token_hash, expires_at, created_at)
  INDEX: (token_hash), (expires_at)
```

## API endpoints

### Auth
```
POST /api/auth/register   { name, email, password }
POST /api/auth/login      { email, password } → { access_token, refresh_token }
POST /api/auth/refresh    { refresh_token }   → { access_token }
POST /api/auth/logout
```

### User
```
GET  /api/profile
PUT  /api/profile         { name, avatar_url, bio }
```

### Wishlist
```
GET    /api/wishlist
POST   /api/wishlist      { food_name, food_category }
DELETE /api/wishlist/:id
```

### Matching
```
GET /api/matches
→ query users có wishlist overlap ≥ 2 món
→ score = Jaccard: |A∩B| / |A∪B|
→ exclude: đã match, đã block, chính mình
→ return: [{ userId, name, avatar, overlap_count, overlap_foods[], score }]
```

### Chat
```
POST /api/matches/:id/accept
GET  /api/matches/:id/messages?cursor=&limit=50
WS   /ws/chat/:matchId
     message types: { type: "message|typing|read", payload: {...} }
     Nồi Lẩu: +1pt per message, +5pt per day streak
```

### Nồi Lẩu
```
GET /api/matches/:id/progress
→ { points, level, next_threshold, locked }
→ level thresholds: [0, 10, 30, 60, 100]
→ level ≥ 3 → locked: true (paywall)
```

## API response format (nhất quán tuyệt đối)
```go
// Success
{ "success": true, "data": {...}, "meta": { "page": 1, "total": 100 } }

// Error
{ "success": false, "error": { "code": "UNAUTHORIZED", "message": "..." } }

// Error codes: UNAUTHORIZED | NOT_FOUND | VALIDATION_ERROR |
//              MATCH_NOT_FOUND | CHAT_LOCKED | RATE_LIMITED
```

## Coding rules
1. Handler tối đa 50 dòng — dài hơn thì tách helper
2. Tất cả DB query dùng raw SQL với pgx/v5, không GORM
3. Mọi error handle explicit — không panic, không ignore
4. Endpoint có auth dùng middleware, không check token trong handler
5. DB pool: MaxConns=10, MinConns=2, MaxConnLifetime=1h
6. context.WithTimeout(30s) cho mọi DB query
7. Graceful shutdown: trap SIGTERM, đóng pool, đóng WS connections
8. Log: JSON structured { time, level, method, path, status, latency, error }

## Dockerfile
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o api .

FROM scratch
COPY --from=builder /app/api /api
EXPOSE 8080
ENTRYPOINT ["/api"]
```

## docker-compose.yml
```yaml
version: '3.8'
services:
  api:
    build: .
    restart: unless-stopped
    ports: ["127.0.0.1:8080:8080"]
    env_file: .env
    depends_on: [db]
    deploy:
      resources:
        limits: { memory: 128M }
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    volumes: ["pgdata:/var/lib/postgresql/data"]
    environment:
      POSTGRES_PASSWORD: ${DB_PASS}
      POSTGRES_DB: anmates
    command: >
      postgres -c shared_buffers=64MB -c effective_cache_size=256MB
               -c work_mem=2MB -c max_connections=20
    deploy:
      resources:
        limits: { memory: 120M }
volumes:
  pgdata:
```

## .env
```
DATABASE_URL=postgres://postgres:CHANGE_ME@db:5432/anmates
JWT_SECRET=CHANGE_ME_32_CHARS_MINIMUM
JWT_ACCESS_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d
PORT=8080
ENV=production
```

## Memory budget (hard limits)
```
OS Ubuntu minimal   ~120 MB
PostgreSQL tuned     ~80 MB
Go API under load    ~80 MB
Nginx                ~15 MB
──────────────────────────
Total               ~295 MB  (còn ~729 MB headroom)
```

## Build order
P0 (build trước): migrations → auth → wishlist → matching → chat WebSocket → noi_lau
P1 (sau): push notification FCM, block/report
P2 (defer): Trust Score, Gom Kèo viral

Bắt đầu từ P0. Hỏi nếu cần clarify business logic.

---
name: anmates-architecture
description: Phase 1 system architecture, data model, module organization, integration points
metadata:
  type: project
---

# ĂN MATES — System Architecture (Phase 1)

> Authoritative spec: `plan/lastest/handoff/anmate-design-handoff.md`. This file is the agent-facing condensed version.

---

## System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                    ĂNMATES — PHASE 1                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐                                           │
│  │  Flutter App     │       Apple Vision / Google ML Kit       │
│  │  iOS 15+ / A10+  │       (on-device liveness)                │
│  └────────┬─────────┘                                            │
│           │ REST + WebSocket                                     │
│           ▼                                                      │
│  ┌──────────────────────────────────────────────────────┐       │
│  │      Go Backend (Gin)                                │       │
│  │  Auth · Profile · Discovery · Swipe · Match · Chat   │       │
│  │  Letter · Booking · Selfie · Geofence · Review       │       │
│  │  Trust · Reports · Push · Export                     │       │
│  └────┬──────────┬──────────┬─────────┬─────────────────┘       │
│       │          │          │         │                          │
│  PostgreSQL   Redis    Map API   APNs+FCM                       │
│  +PostGIS    (cache,  (Google    (push)                         │
│  +pgvector?  hold,    /Mapbox    SMS GW (VN)                    │
│              ratelimit) polygons)                                │
│                                                                  │
│  Crashlytics / Sentry                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Organization

### Backend (Go)

```
anmates-api/
├── cmd/                       # entry points
│   └── server/main.go
├── internal/
│   ├── auth/                  # OTP, JWT, Apple ID, face verify
│   ├── profile/               # users, tastes, photos, derived
│   ├── discovery/             # home, restaurants, wishlist
│   ├── swipe/                 # deck, cooldown, mutual check
│   ├── match/                 # match lifecycle, inbox groups
│   ├── chat/                  # WS, message store, PII redaction, Vibe scorer
│   ├── letter/                # compose, expiry, quota
│   ├── booking/               # state machine, soft-hold, calendar sync
│   ├── selfie/                # liveness, anti-replay, embedding match
│   ├── geofence/              # polygon check, ETA, T-15/T+25 jobs
│   ├── review/                # double-blind, reveal logic
│   ├── trust/                 # event ledger, recovery job
│   ├── safety/                # blocks, reports, pause/delete, export
│   ├── push/                  # token mgmt, notification dispatch
│   └── platform/              # shared: logging, errors, validation, idempotency
├── handlers/                  # HTTP route handlers
├── ws/                        # WebSocket hub + room state
├── jobs/                      # background workers (cron-style)
├── db/
│   ├── migrations/            # versioned SQL
│   ├── queries/               # sqlc query files
│   └── seeds/                 # curated restaurant data
├── config/                    # env loading
├── middleware/                # auth, rate-limit, logging
└── tests/                     # integration tests
```

### Frontend (Flutter)

```
anmates_flutter/
├── lib/
│   ├── main.dart
│   ├── config/                # theme, routes, env
│   ├── shared/
│   │   ├── widgets/           # primitives (Button, Chip, Card, VibeRing, TrustBadge)
│   │   ├── services/          # API client, WS client, location service, push service
│   │   └── utils/             # formatters, validators
│   ├── features/              # feature-first
│   │   ├── onboarding/        # Screens 01-10
│   │   ├── discovery/         # Screens 09b, 10b, 11
│   │   ├── swipe/             # Screen 12
│   │   ├── match/             # Screen 13
│   │   ├── chat/              # Screens 14, 15, 16
│   │   ├── letter/            # Screens 18, 19, N6
│   │   ├── booking/           # Screens 17, 20, 21
│   │   ├── review/            # Screen 22
│   │   ├── profile/           # Screens 23, 24, N1
│   │   ├── safety/            # Screens N3, N4, N5
│   │   └── settings/          # Screen N2
│   └── providers/             # Riverpod providers
├── test/                      # widget tests
├── integration_test/          # E2E test scenarios
├── assets/
│   ├── screens/<NN>/          # per-screen asset bundle
│   └── lotties/               # animations
└── pubspec.yaml
```

---

## Data Model (minimum schema per handoff §4)

```
users
  id, phone_hash, apple_user_id?, dob, name, nickname,
  personality_score (0-100), created_at, last_active_at,
  status (active|paused|deleted)

profile_derived
  user_id, zodiac, ngu_hanh, numerology, show_in_public (bool)

tastes
  user_id, cuisine_tags[], vibe_tags[]

photos
  id, user_id, url, is_main, order_idx,
  nsfw_score, face_detected, ocr_phone_detected

identity_verifications
  user_id, face_embedding (vector),
  liveness_score, verified_at, last_redo_at

restaurants
  id, name, district, geo_polygon (PostGIS GEOMETRY POLYGON),
  genres[], vibes[], price_range, hours,
  status (active|closed|delisted),
  interested_count (denormalized, updated 15min)

wishlist
  user_id, restaurant_id, added_at

swipes
  id, swiper_id, target_id, restaurant_id, direction, created_at
  -- index: (swiper_id, restaurant_id, created_at) for 24h cooldown
  -- index: (swiper_id, target_id, restaurant_id) for dedupe

matches
  id, user_a, user_b, restaurant_id, created_at,
  hello_window_until, status (active|expired|blocked|deleted)

chat_rooms
  id, match_id, vibe_score (0-100), last_message_at, archived_at?

messages
  id, room_id, sender_id, body, voice_url?, media_url?,
  redacted_pii (bool), created_at

vibe_events  -- calibration data for Phase 2
  id, room_id, message_id, delta, signals_json, created_at

letters
  id, sender_id, receiver_id, restaurant_id, body, ps_line,
  mood_chips[], proposed_at, expires_at,
  status (sent|opened|accepted|declined|expired)

bookings
  id, match_id?, letter_id?, restaurant_id, scheduled_at,
  status (pending|confirmed|cancelled|completed|no_show),
  voucher_eligible, soft_hold_until,
  created_user_id, other_user_id

booking_events
  booking_id, type (depart|late|checkin|cancel|...), actor_id,
  payload_json, created_at

reviews
  id, booking_id, reviewer_id, target_id, chips[],
  freeform_text, venue_review_text, venue_media[],
  submitted_at, revealed_at

trust_events
  id, user_id, delta, reason_code, related_booking_id?,
  related_report_id?, created_at

reports
  id, reporter_id, target_id, category, evidence_urls[],
  status (open|investigating|resolved|dismissed), created_at

blocks
  blocker_id, target_id, created_at

iap_waitlist  -- placeholder
  email, opted_in_at, source_screen

push_tokens
  user_id, token, platform (ios|android), updated_at

sessions
  user_id, refresh_token_hash, device_id, issued_at, expires_at

device_metadata
  user_id, device_id, model, os, app_version

consent_log  -- Nghị định 13/2023
  user_id, consent_type, granted, granted_at
```

### Mandatory Indexes

| Table | Index | Purpose |
|---|---|---|
| `users` | `phone_hash` UNIQUE | Login lookup |
| `users` | `apple_user_id` UNIQUE WHERE NOT NULL | Apple Sign-in |
| `restaurants` | GIST(`geo_polygon`) | Geofence ST_Within |
| `restaurants` | `district, status` | Discovery |
| `swipes` | (`swiper_id`, `restaurant_id`, `created_at`) | 24h cooldown |
| `matches` | (`user_a`, `user_b`) UNIQUE | Dedupe |
| `matches` | (`user_a`, `status`), (`user_b`, `status`) | Inbox |
| `chat_rooms` | `last_message_at` | Archive job |
| `messages` | (`room_id`, `created_at` DESC) | Pagination |
| `bookings` | (`status`, `scheduled_at`) | Geofence jobs |
| `bookings` | (`created_user_id`, `status`) | "Me" view |
| `trust_events` | (`user_id`, `created_at` DESC) | Ledger |
| `reports` | (`status`, `created_at`) | T&S queue |
| `letters` | (`receiver_id`, `status`) | Inbox |
| `letters` | (`sender_id`, `status`) | Sent box |

---

## Key Flows

### Onboarding (Screens 01–10)
```
Splash (01)
  → 3 edu carousel (02, 03, 04) — each has "Skip"
  → Login (05): Phone+OTP OR Apple ID
  → OTP entry (06) — 6-digit, 90s TTL
  → Face verify (07) — liveness on-device + server anti-replay
  → Profile (08) — name, nickname, DOB, personality slider, auto-derive
  → Tastes (09a) — pick ≥5 cuisine + ≥1 vibe
  → Photos (10a) — ≤3, 1 main, NSFW+face+OCR checks
  → Home (09b) — first content view; permission location prompt here
```

### Match Loop
```
Home (09b)
  → Restaurant detail (11) — see live "X người cũng thèm quán này"
  → "+ Wishlist" OR "Tìm Mate ăn cùng"
  → Dining swipe deck (12) — scoped to this restaurant
  → Swipe right on Mate
  → Server: insert swipe, check mutual
  → Mutual right → Match screen (13) — full-bleed celebration
  → Chat enters Inbox "Mới match" (14)
  → 24h hello window starts
```

### Chat → Vibe → First Date
```
Chat room (15: Nồi 42 locked)
  → Each message: server PII-redact, score Vibe delta, persist, broadcast
  → Vibe accumulates
  → Crosses 70 → server emits `vibe_unlock` event
  → Chat header shows unlocked state (16: Nồi 72 unlocked)
  → "Đặt First Date" CTA active
  → Tap → First Date scheduler (17)
  → Pick date/time → POST /bookings → status=pending, 15min soft-hold
  → Receiver accepts → status=confirmed → calendar sync
```

### Letter (alternative path)
```
Letter composer (N6)
  → Pick receiver + restaurant + date + mood chips + freeform + P.S.
  → POST /letters (quota check)
  → Receiver inbox shows "Kèo mới · Lá thư từ Mate" (18)
  → Tap → Postcard render (19)
  → Accept → server creates booking pending → flow joins (17)
```

### Day-of
```
T-45 push "Lên đường với [Mate]"
  → Selfie xuất phát (20) — front cam only, liveness, overlays
  → POST /bookings/:id/depart (selfie + overlay_meta)
  → Status = on_the_way
  → Live Tracking card (21) — abstract ETA, NOT map
  → At 320m → proximity push
  → Geofence polygon enter → auto check-in event
  → Server: insert booking_event(checkin) + trust_event(+2 if on time)
  → T+30 of LATER check-in → Review prompt (22) — anonymous double-blind
```

### Trust Update (always via ledger)
```
Action triggers (check-in / no-show / cancel / review / report)
  → Server: INSERT INTO trust_events (delta, reason_code, ...)
  → users.trust_score is a derived VIEW: 100 + SUM(delta), clamp [0,100]
  → User sees update in Trust Dashboard (24)
  → NEVER UPDATE users.trust_score directly
```

---

## Background Jobs

| Job | Cadence | Module |
|---|---|---|
| Hello-window expiry | Hourly | match |
| Chat auto-archive (7-day idle) | Daily | chat |
| Letter expiry (7-day TTL) | Hourly | letter |
| Soft-hold release | Per-event (Redis TTL) | booking |
| Geofence T-15 status check | Per-booking trigger | geofence |
| Geofence T+25 no-show | Per-booking trigger | geofence |
| Review reveal (both-or-48h) | Per-event + hourly sweep | review |
| Trust recovery (+2 / 30d clean) | Daily | trust |
| Social proof recount | Every 15min | discovery |
| Restaurant ranking re-rank | Every 15min | discovery |

Job framework: `gocron` or Postgres-backed queue (river / asynq).

---

## Integration Points

### Map / Geofence
- Provider: Google Maps OR Mapbox (decision pending)
- Polygons sourced per restaurant (≥200 curated before D-7)
- ETA queries: provider direction API, polled every 60s during active booking only
- Storage: `restaurants.geo_polygon` as PostGIS GEOMETRY POLYGON SRID 4326

### Liveness
- iOS: Apple Vision framework (`VNDetectFaceLandmarksRequest` + custom blink detection)
- Android: Google ML Kit Face Detection
- Server-side: re-validate signals JSON + anti-replay (timestamp + embedding similarity window)

### Push
- APNs: app key + topic configured
- FCM: server key
- Categories with action buttons (e.g., "Báo trễ" inline from push)

### SMS
- Primary: VN gateway (Viettel/Vinaphone/Mobifone) — to be selected
- iOS SMS auto-fill: requires OTP message format `<#> 123456 is your AnMates code. ABCD1234`
- Android SMS Retriever: requires hash in message

### Crash Analytics
- Single provider (Crashlytics or Sentry — pick one)
- Includes: stack trace, breadcrumbs, device metadata, user_id (consented)

---

## Performance Targets

| Metric | Target |
|---|---|
| App cold start | ≤2.5s p75 (iPhone 12 baseline) |
| Home payload TTFB | ≤400ms p95 |
| WS reconnect | ≤3s after network restore |
| Geofence query | ≤100ms p95 |
| Auth endpoints | ≤300ms p95 |
| Discovery list | ≤500ms p95 |
| Chat message dispatch (in-app) | ≤500ms p95 end-to-end |
| Crash-free sessions | ≥99.5% |

---

## Security & Privacy

### PII Handling
- Phone: stored as HMAC-SHA256 hash with backend secret
- Selfie raw: discarded immediately after embedding
- DOB: never returned to other users
- Location: per-booking scope, purged 24h post-completion
- Chat: PII redaction server-side BEFORE persist

### Auth
- JWT signed HS256 (or RS256 if multi-service)
- Access 15min, refresh 7d rotating
- Tokens stored in OS secure storage on client

### Network
- TLS 1.2+ required
- HSTS enabled
- Certificate pinning (Flutter `http_certificate_pinning`) recommended

### Compliance (Nghị định 13/2023)
- Consent log per category
- Data export endpoint (async zip)
- 14-day soft-delete then hard delete + anonymize

---

## Deployment (Phase 1)

### Local dev
- Docker Compose: Go app + Postgres + PostGIS + Redis
- Seed data: 50+ test restaurants in TP.HCM
- Hot reload via `air` or `gow`

### Soft-launch (D1)
- Single region (TP.HCM)
- Managed Postgres (Supabase / AWS RDS / Render)
- Managed Redis
- Container backend (Render / Railway / Fly.io)
- CDN for static assets (CloudFlare)

### Public launch (D+14)
- Same infra, scale up
- Monitoring: provider dashboards + Crashlytics + custom analytics

---

## Roles (Phase 1)

| Role | Access |
|---|---|
| Guest | Splash + 3 edu screens (no persistence) |
| Unverified | Resume onboarding only |
| Verified Mate | **Full app, no tier, no paywall** |
| T&S Mod | Admin tool (web) — pause/unpause, resolve reports |
| Customer Support | Admin tool — read Trust ledger, manual adjust |
| Ops | Admin tool — restaurant CMS, voucher rules |

Admin tool is OUT of Phase 1 in-app scope but Day-1 needed externally (separate scope).

---

This architecture is the source for code structure decisions. Backend Agent + Frontend Agent must align module names to this layout for clean PRs.

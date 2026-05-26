---
name: anmates-shared-decisions
description: Architecture decisions, constraints, and known risks per handoff v1.0 (25.05.2026)
metadata:
  type: project
---

# ĂN MATES — Shared Architecture Decisions (Phase 1)

> **Authoritative source:** `plan/lastest/handoff/anmate-design-handoff.md`. When these decisions and the handoff disagree, **handoff wins**.

---

## DECISION 0 — Phase 1 Strategy: "Ultimate-for-all"

**Decision:** No tiers. No paywall. No IAP. Every verified Mate gets every feature.

**Implications:**
- No IAP UI, no receipt validation, no entitlements engine in Phase 1.
- Tab Mình has ONE placeholder card "Gói ĂnMates — Coming soon" with email opt-in only.
- Trust Score is measured + displayed but **does NOT gate anything**.
- Chat rooms unlimited (technical cap 200, not commercial).
- Vibe multiplier fixed ×1 for everyone.

**Why:** Need behavior data to size Phase 2 perks correctly. Less surface = less risk at launch.

**Impact on agents:**
- Backend Agent: do NOT build `subscriptions`, `entitlements`, `receipt_validation` tables / endpoints.
- Backend Agent: DO build `iap_waitlist` table (email opt-in).
- Frontend Agent: do NOT build 25/26/27/28 IAP screens. DO build N7 "Coming soon" placeholder.
- QA Agent: do NOT write IAP tests. DO verify gating absence (Trust <80 still gets full app).

---

## DECISION 1 — Tech Stack

**Mobile:** Flutter (chosen for native Live Activities iOS + Foreground Service Android support)
- Min OS: iOS 15 / Android 10 (API 29)
- State management: Riverpod (recommended) or Bloc — Frontend Agent chooses
- Routing: GoRouter

**Backend:** Go + Gin
- ORM: sqlc preferred (typed queries) — Backend Agent decides
- Postgres + PostGIS extension

**Geofence:** **Polygon** (not radius) — requires polygon data for ≥200 curated venues
- Map provider: Google Maps OR Mapbox (decision pending — needs sourcing)

**Push:** APNs + FCM

**Liveness:** Apple Vision (iOS) + Google ML Kit (Android), on-device

**SMS:** VN gateway (Viettel/Vinaphone/Mobifone) + iOS SMS auto-fill + Android SMS Retriever API

**Crash:** Crashlytics or Sentry (one, not both)

**Chat backend:** OPEN QUESTION — handoff lists only `WS /chat/:room_id`, suggests in-house. Stream Chat is OPTIONAL.
- Recommendation: in-house WS first (control over PII redaction + Vibe scoring), revisit if scale issues.

---

## DECISION 2 — Authentication

**Phase 1 paths:**
1. Phone + OTP (6-digit, TTL 90s, max 5 attempts/req, 3 req / 15min / phone)
2. Apple ID Sign-in (alternative — still requires face verify + profile)

**Open question:** Apple ID path — also capture phone number for safety contact? Need decision before building.

**JWT:**
- Access token TTL: 15 min
- Refresh token TTL: 7 days (rotating on refresh)
- Stored in Keychain (iOS) / Keystore (Android)

**Face verify:**
- On-device liveness (Apple Vision / Google ML Kit)
- Server-side anti-replay (timestamp + freshness check)
- Raw selfie **discarded immediately** after embedding generation
- Embedding stored as vector (pgvector or array)

**Fallback:** CCCD/CMND manual review (SLA ≤24h) if face verify fails repeatedly — Trust & Safety pipeline.

---

## DECISION 3 — Data Model

**Source:** Handoff §4. Single source of truth. Backend Agent implements verbatim, then evolves only via PR + architect approval.

**Critical tables:**
- `users` (phone_hash, apple_user_id?, dob, name, nickname, personality_score, status)
- `profile_derived` (zodiac, ngu_hanh, numerology, show_in_public)
- `tastes` (cuisine_tags[], vibe_tags[])
- `photos` (NSFW score, face_detected, ocr_phone_detected)
- `identity_verifications` (face_embedding, liveness_score)
- `restaurants` (**geo_polygon** — NOT lat/lng circle)
- `wishlist`, `swipes`, `matches`, `chat_rooms`, `messages`
- `vibe_events` (signals_json — calibration data for Phase 2)
- `letters` (mood_chips, body, ps_line, status)
- `bookings` (state machine), `booking_events`
- `reviews` (chips, freeform, double-blind reveal logic)
- `trust_events` (delta, reason_code, related_booking_id)
- `reports`, `blocks`
- `iap_waitlist` (placeholder)
- `push_tokens`, `sessions`, `device_metadata`, `consent_log`

**Indexes (mandatory):**
- `restaurants.geo_polygon` — GIST (PostGIS spatial)
- `bookings(status, scheduled_at)`
- `trust_events(user_id, created_at DESC)`
- `matches(user_a, user_b, status)`
- `swipes(swiper_id, restaurant_id, created_at)` — for 24h cooldown check

**Anti-PII rules:**
- `phone_hash` — store hash not plaintext (HMAC-SHA256 with backend secret)
- DOB never returned to other Mates — only derived fields
- Selfie raw never persisted

---

## DECISION 4 — Chat Architecture

**Phase 1 approach:** Custom WebSocket + Postgres message store (NOT Stream Chat).

**Reasons:**
- PII redaction must happen server-side before persist (Stream's hooks are weaker)
- Vibe scoring needs synchronous access to message content
- Cost: in-house cheaper at Phase 1 scale (<10k MAU expected)

**Server-side processing per message:**
1. Receive message via WS
2. Run PII redaction (Vietnamese phone regex + URL + Zalo/TG handles)
3. Score Vibe delta (length, latency, reciprocity, media signals)
4. Persist to `messages` (with `redacted_pii` boolean)
5. Update `chat_rooms.vibe_score` + `last_message_at`
6. Log to `vibe_events` for Phase 2 calibration
7. Broadcast to other Mate's WS

**Reconnect:** ≤3s client-side, with backoff. Server keeps room state warm 60s.

**Auto-archive job:** Daily cron, marks rooms idle ≥7 days as archived (no delete).

**Hello window job:** Hourly cron, expires matches with zero messages at 24h.

---

## DECISION 5 — Vibe Meter Calculation

**Formula (Phase 1 baseline — calibrate in Phase 2):**

```
vibe_delta = base_score * signal_multipliers

base_score = 1.0 per message

signal_multipliers (multiplicative, capped):
  length:
    <20 chars     → 0.5
    20-50 chars   → 1.0
    >50 chars     → 1.2
  
  latency (since other side's last message):
    <2 min        → 1.2
    2-30 min      → 1.0
    30 min - 24h  → 0.7
    >24h          → 0.4
  
  reciprocity (turn-taking ratio in last 10 msgs):
    balanced (40-60% from each)  → 1.2
    skewed (>70% from one side)  → 0.7
  
  media bonus:
    voice note    → +0.3
    photo         → +0.2
  
  ice-breaker chip used:
    +0.2 (first 3 uses per room only)

vibe_score = clamp(0, 100, accumulated_deltas)
```

**Unlock threshold:** 70.

**Phase 1: multiplier ×1 for everyone.** Log all signals to `vibe_events` for analysis.

---

## DECISION 6 — Trust Score Engine

**Phase 1 rule: MEASURED, NOT GATING.**

**Initial value:** 100 at `signup_complete`.

**Ledger pattern (mandatory):**
- All score changes via `trust_events` insert
- Never UPDATE `users.trust_score` directly
- `users.trust_score` = derived view: `100 + SUM(delta)`, clamped [0, 100]

**Phase 1 deltas (from handoff §B):**

| Event | Delta | Trigger |
|---|---|---|
| On-time check-in | +2 | geofence enter ≤ scheduled + 5' |
| Review with photo | +3 | review submitted + ≥1 media |
| 5★ rating from Mate | +1 | counter-review chips "đúng giờ" + "dễ tám" |
| Late 5-15' notified | 0 | "Báo trễ" in T-30 → T+0 |
| Late 15-30' no notice | −3 | geofence enter late + no báo trễ |
| No-show | **−10** | no geofence enter in T → T+25 |
| Cancel ≥24h | 0 | cancel ≤ scheduled − 24h |
| Cancel <24h, ≥2h | −3 | cancel in 24h-2h window |
| Cancel <2h | −5 | cancel sát giờ |
| Report confirmed | −15 | T&S case closed "confirmed" |

**No paid recovery in Phase 1.** Recovery only via behavior.

**Idempotency:** Every trust event references `related_booking_id` (or `report_id`). Duplicate triggers on same booking_id are no-ops.

**Auto-forgiveness (V1.1 stretch):** If traffic data shows congestion, waive late penalty. Need data source decision.

---

## DECISION 7 — Geofence (Polygon, not Radius)

**Decision:** Use polygon shapes per venue, not radius.

**Why:** Tiệm mì on a busy street with a thin storefront fails radius logic (false positives from passersby). Polygon = real venue boundary.

**Data sourcing (OPEN QUESTION):**
- Map provider API (Google Places polygons, Mapbox tilesets)
- Manual draw via admin tool
- Need ≥200 polygons curated before D-7 launch

**Implementation:**
- PostGIS `ST_Within(user_point, restaurant.geo_polygon)` check
- Idempotent: ledger `booking_events(type='checkin')` prevents double-fire
- Proximity alert at 320m boundary (separate radius check, performance-only)

**Fallback:** If venue lacks polygon, manual check-in via UI button (both Mates confirm).

---

## DECISION 8 — Live Tracking (NOT a full map)

**Decision:** Card-style abstract tracker (Screen 21), not embedded map.

**Why:**
- Privacy: real-time map of other person = creep factor + battery
- Battery: foreground GPS drains; geofence + background fetch is sufficient for status
- Brand: ĂnMates is intentional + warm, not surveillance

**Implementation:**
- Status pill: "Đang đến · ETA 12'", "Báo trễ 10'", "Đã đến"
- Stylized abstract route (progress dots)
- Map ONLY in Phase 2 (opt-in "expand map" CTA, ghost-state in Phase 1)

**ETA source:** Map provider direction API, polled every 60s by client when booking is active (T-45 → T+25).

---

## DECISION 9 — Selfie Xuất Phát (Mandatory)

**Decision:** Mandatory selfie before "Xác nhận đi" can fire.

**Why:** Anti-no-show, anti-bot, fairness signal to other Mate.

**Rules:**
- Front camera only
- Library upload disabled at OS layer (image_picker source: camera)
- On-device liveness (blink + head turn detect)
- Server-side anti-replay: embedding must be fresh (compare hash window, reject duplicates within 24h)
- Overlays: sticker, text, mood chip, emoji palette
- Visible to other Mate after their own action (mutual reveal pattern, anti-griefing)

**Storage:** Raw discarded after embedding. Stylized version (with overlay) persisted for the booking only, purged 24h post-completion.

---

## DECISION 10 — Letters (Lá thư)

**Decision:** Bypass Vibe gate. Anti-spam via quota.

**Quota (Phase 1):**
- Max 3 pending letters per sender
- Same sender→receiver: 14-day cooldown after decline/expire
- OPEN: rate-limit is total or per-receiver — need product decision

**State machine:**
```
sent → opened → accepted | declined | expired (7-day TTL)
```

**Accepted letter → creates a booking** directly in `pending` state (same flow as Vibe-unlocked First Date).

---

## DECISION 11 — Booking State + Soft-hold

**State machine:**
```
pending → confirmed → completed | no_show
                   ↘ cancelled
       ↘ declined (by receiver)
       ↘ expired (soft-hold released)
```

**Soft-hold:** Pending booking holds restaurant slot for 15 min. Other matches browsing same restaurant + same time block see slot grayed out.

**Implementation:** Slot key = `restaurant_id + scheduled_at_hour`. Redis SETEX with 15min TTL.

---

## DECISION 12 — Review (Double-blind)

**Trigger:** T+30 min after the LATER of the two check-ins.

**Form:**
- 5 positive chips (multi-select)
- 1 cautious chip (multi-select)
- Freeform ≤280 chars
- Optional venue review (text + ≤3 photos + 1 video)

**Double-blind reveal:** Reviews shown to each other ONLY when:
- Both have submitted, OR
- T+48h elapsed (whichever first)

**Report path:** Any negative chip + "Báo cáo" CTA → safety pipeline + Trust −15 if T&S confirms.

---

## DECISION 13 — Permissions & Privacy

**Staggering (per handoff §6.4):**
- Camera: requested at face verify only
- Location: requested AFTER first Home view (after user sees value)
- Notification: requested AFTER first match (concrete value moment)

**Backend never exposes:**
- DOB
- Plaintext phone
- Raw selfie

**User rights (Nghị định 13/2023):**
- Export data: zip via async job, downloadable link
- Delete: 14-day soft-delete window, then hard delete with PII anonymization

---

## DECISION 14 — Anti-spam & Rate Limits

| Surface | Limit |
|---|---|
| OTP request | 3 per 15 min per phone |
| OTP verify | 5 attempts per request |
| New matches | 30 per 24h per user |
| Active chat rooms | 200 (technical cap) |
| Pending letters | 3 simultaneous |
| Letter to same receiver after decline | 14-day cooldown |
| Swipe deck request | 60 per minute |
| Voice note | 60 sec max length |
| Photo upload | 3 per profile |
| Review media | 3 photos + 1 video per review |

---

## DECISION 15 — Soft-launch + Public Launch

- **D1 (soft-launch):** Q1 only, 200 closed-beta Mates.
- **D+14 (public launch):** 5 districts (Q1, Q3, Q5, Q7, Bình Thạnh).
- **Restaurant pool prep:** ≥200 curated venues across launch districts before D-7.

---

## Known Risks & Mitigations (from handoff §8.2)

| Risk | Mitigation |
|---|---|
| Thin restaurant pool at launch | Curate ≥200 across Q1/Q3/Q5 before D-7 |
| Chat spam (unlimited rooms) | 30 match/24h cap, 7-day auto-archive, server PII redaction |
| Face verify failure rate | Fallback CCCD manual review SLA ≤24h |
| Live Tracking battery drain | Geofence + background fetch, no foreground GPS |
| Onboarding counter "5 bước" mismatch | Reset to 6/6 or drop counter on face verify screen |

---

## Cross-agent Rules

1. **API contracts are LAW** — locked once published. Backend cannot change without architect approval.
2. **Data model is shared** — Backend owns migrations, Frontend reads schema from API responses (typed via OpenAPI codegen).
3. **Error response format is standard:** `{ error: code, message: vi_string, details?: {} }`.
4. **Breaking change protocol:** PR + architect approval + Frontend + QA notified before merge.
5. **Testing in parallel:** Frontend uses mock API, Backend tests with fixtures. E2E waits for both.
6. **Memory is compressed:** Agents share task results, not chat histories.

---

These decisions are locked for Phase 1 unless explicitly updated via PR + architect approval. When in doubt: re-read handoff doc first.

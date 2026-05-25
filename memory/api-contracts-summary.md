---
name: anmates-api-contracts
description: Phase 1 REST + WebSocket endpoint catalog (handoff §5, expanded)
metadata:
  type: reference
---

# ĂN MATES — API Contracts (Phase 1)

> **Status:** Catalog locked per handoff §5. Detailed request/response schemas live in OpenAPI doc (TBD generation). This file is the agent-facing summary.

## Base

```
Dev:  http://localhost:8080/api/v1
Prod: https://api.anmates.io/api/v1
```

**Auth header:** `Authorization: Bearer <access_jwt>`

**Standard error response:**
```json
{ "error": "code_string", "message": "Vietnamese message", "details": {} }
```

---

## Section 1 — Auth & Onboarding

### `POST /auth/otp/request`
Request 6-digit OTP for phone.
- Body: `{ phone: "+84..." }`
- Rate-limit: 3 / 15min / phone
- Response: `{ request_id, expires_at }` (TTL 90s)
- Errors: `OTP_RATE_LIMITED`, `INVALID_PHONE_FORMAT`

### `POST /auth/otp/verify`
Verify OTP, return JWT pair.
- Body: `{ request_id, code }`
- Max attempts: 5 per request_id
- Response: `{ access_token, refresh_token, user_id, onboarding_step }`
- Errors: `OTP_INVALID`, `OTP_EXPIRED`, `OTP_MAX_ATTEMPTS`

### `POST /auth/apple`
Apple ID Sign-in alternative.
- Body: `{ identity_token, authorization_code, nonce }`
- Open Q: also capture phone for safety contact?
- Response: `{ access_token, refresh_token, user_id, onboarding_step, requires_phone? }`

### `POST /auth/refresh`
Rotate token pair.
- Body: `{ refresh_token }`
- Response: `{ access_token, refresh_token }` (old refresh invalidated)

### `POST /verify/face`
Multipart upload selfie for liveness verification.
- Multipart: `selfie` (image), `liveness_signals` (JSON: blink_count, head_turn_angle)
- Server: anti-replay check, embedding generation, raw discard
- Response: `{ verified: bool, retry_count, embedding_id }`
- Errors: `FACE_LIVENESS_FAILED`, `FACE_REPLAY_DETECTED`, `FACE_NO_FACE`

### `POST /me/profile`
Set / update profile (called during onboarding + later edit).
- Body: `{ name, nickname, dob, personality_score, tastes: { cuisine_tags[], vibe_tags[] }, show_derived_in_public: bool }`
- Server: auto-derives `zodiac`, `ngu_hanh`, `numerology` from DOB
- Response: full user object including derived fields

### `POST /me/photos`
Upload photo (max 3 per user).
- Multipart: `photo`, `is_main` bool
- Server checks: NSFW score, face detect, OCR phone/URL
- Response: `{ id, url, is_main, order_idx }`
- Errors: `PHOTO_NSFW`, `PHOTO_NO_FACE`, `PHOTO_OCR_PHONE`, `PHOTO_LIMIT`

### `PATCH /me/photos/:id/order`
Reorder photos.
- Body: `{ order_idx: 0..2 }`

### `DELETE /me/photos/:id`
Delete photo (cannot delete main without replacement).

---

## Section 2 — Discovery

### `GET /home`
Home feed (district + time-slot ranking, refreshed every 15min).
- Query: `district`, `time_slot` (morning|noon|evening), `lat?`, `lng?`
- Response: `{ greeting: "...", search_placeholder, genres[], vibes[], hot_nearby: [restaurants], rails: [...] }`

### `GET /restaurants/:id`
Restaurant detail.
- Response: includes hero, rating, distance, price range, % hợp gu overlap, vibe breakdown, live `interested_count` (last 2h within 2km)

### `POST /wishlist/:restaurant_id`
Add restaurant to user's wishlist.

### `DELETE /wishlist/:restaurant_id`
Remove from wishlist.

### `GET /me/wishlist`
List wishlist with sub-tabs.
- Query: `sub_tab` = `saved` | `visited`
- Response: `{ districts: [{ name, restaurants: [...] }], best_mates_rail?: [...] }`

### `GET /restaurants/:id/swipe-pool`
Deck of Mates who added this restaurant.
- Response: array of Mate cards (avatar, name, age, trust_badge, distance, status_quip, taste_overlap_pct, added_at_relative)
- Cooldown filter: excludes Mates user has swiped in last 24h for this restaurant

---

## Section 3 — Swipe & Match

### `POST /swipes`
Submit swipe.
- Body: `{ restaurant_id, target_user_id, direction: "right"|"left"|"super" }`
- Rate-limit: 60/min (deck request), 30 matches/24h
- Response: `{ matched: bool, match_id?, hello_window_until? }`

### `POST /matches/check`
Server-side mutual-swipe check (mostly internal/admin — handoff lists it).

### `GET /matches/:id`
Match metadata.
- Response: `{ id, user_a, user_b, restaurant_id, vibe_score, hello_window_until, status, chat_room_id }`

### `GET /me/matches`
Inbox listing 4 groups.
- Response: `{ new_matches: [...], chatting: [...], best_mate: [...], yesterday: [...] }`

---

## Section 4 — Chat (WebSocket + REST)

### `WS /chat/:room_id`
Real-time chat connection.

**Client → Server messages:**
```json
{ "type": "message", "body": "...", "media_url?": "..." }
{ "type": "typing", "is_typing": true }
{ "type": "voice_note", "url": "..." }
```

**Server → Client events:**
```json
{ "type": "message", "message": { ... full message ... }, "vibe_delta": 1.2, "vibe_score": 43 }
{ "type": "vibe_unlock" } // fired when crossing 70
{ "type": "redacted", "message_id": "...", "redaction_reason": "phone" }
{ "type": "typing", "user_id": "...", "is_typing": true }
{ "type": "presence", "user_id": "...", "online": true }
```

### `POST /messages`
REST fallback for sending message (if WS unavailable).
- Body: `{ room_id, body, media_url? }`
- Server runs PII redaction before persist
- Returns message object

### `GET /matches/:id/vibe`
Current Vibe score.
- Response: `{ score, threshold: 70, unlocked: bool, last_updated_at }`

### `GET /chat/:room_id/messages`
Message history.
- Query: `cursor` (timestamp), `limit` (default 30)
- Response: `{ messages: [...], next_cursor? }`

---

## Section 5 — Letters (Lá thư)

### `POST /letters`
Compose & send letter.
- Body: `{ receiver_id, restaurant_id, body, ps_line, mood_chips[], proposed_at }`
- Rate-limit: 3 pending per sender, 14-day cooldown to same receiver after decline/expire
- Response: `{ letter_id, expires_at }` (7-day TTL)
- Errors: `LETTER_QUOTA_EXCEEDED`, `LETTER_RECEIVER_COOLDOWN`

### `GET /letters/:id`
Receiver views letter (postcard render).

### `POST /letters/:id/respond`
Receiver responds.
- Body: `{ action: "accept" | "decline", reply_text? }`
- On accept: server creates a `bookings` row in `pending` state, returns `booking_id`

### `GET /me/letters`
List letters by box.
- Query: `box` = `inbox` | `sent`

---

## Section 6 — Bookings

### `POST /bookings`
Create booking (from Vibe-unlocked chat OR letter accept).
- Body: `{ match_id?, letter_id?, restaurant_id, scheduled_at }`
- Server: creates `pending` + Redis soft-hold 15min on `restaurant_id + hour_block`
- Response: `{ booking_id, status: "pending", soft_hold_until }`
- Errors: `SLOT_TAKEN`, `VIBE_NOT_UNLOCKED`

### `POST /bookings/:id/accept`
Receiver accepts pending booking.
- Response: `{ status: "confirmed", calendar_event_ics? }`

### `POST /bookings/:id/decline`
Receiver declines.

### `POST /bookings/:id/depart`
Sender / receiver action with mandatory selfie.
- Multipart: `selfie`, `overlay_meta` (sticker/text/mood/emoji), `liveness_signals`
- Server: anti-replay + embedding match against onboarding embedding
- Response: `{ status: "on_the_way", departed_at }`
- Errors: `SELFIE_REPLAY_DETECTED`, `SELFIE_LIVENESS_FAILED`, `SELFIE_FACE_MISMATCH`

### `POST /bookings/:id/late`
Notify "Báo trễ" with delay choice.
- Body: `{ minutes: 5 | 10 | 15 }`
- Response: `{ status: "running_late", new_eta }`

### `POST /bookings/:id/checkin`
Manual check-in fallback (geofence handles auto).
- Server: validates user is within polygon OR manual confirmation gate (both Mates must confirm)
- Response: `{ status: "checked_in", checked_in_at, trust_delta: 2 }`
- Errors: `GEOFENCE_NOT_AVAILABLE`, `OUT_OF_POLYGON`

### `POST /bookings/:id/cancel`
Cancel with Trust penalty preview.
- Body: `{ confirm: bool, reason? }`
- If `confirm: false` → returns penalty preview only (no commit)
- If `confirm: true` → commits cancellation + Trust event
- Response: `{ penalty_preview: { delta, reason_code, time_to_scheduled }, committed: bool }`

### `POST /bookings/:id/review`
Submit anonymous double-blind review.
- Body: `{ chips[], freeform, venue_review?: { text, media_urls[] } }`
- Response: `{ review_id, reveal_at }` (when both submit OR T+48h)
- Side effect: Trust event (+3 if media present, +1 if 5★ counter chips)

### `GET /me/bookings`
List bookings by status.
- Query: `status?`, `cursor?`
- Response: paginated bookings

---

## Section 7 — Trust & Safety

### `GET /me/trust`
Current Trust dashboard.
- Response: `{ score, status: "perfect"|"trusted"|"limited", badge_pct?, recent_events: [...] }`

### `GET /me/trust/events`
Paginated trust ledger.
- Query: `cursor?`, `limit?`
- Response: `{ events: [...], next_cursor? }`

### `POST /reports`
File a report.
- Body: `{ target_id, category: enum, evidence_urls[], note? }`
- Response: `{ report_id, status: "open" }`

### `POST /blocks`
Block a user.
- Body: `{ target_id }`

### `DELETE /blocks/:user_id`
Unblock.

### `POST /me/account/pause`
Pause account (during T&S review or self-paused).

### `POST /me/account/resume`
Resume from paused state.

### `POST /me/account/delete`
Initiate 14-day soft-delete.
- Response: `{ deletes_at, export_job_id? }` (export starts in parallel)

### `GET /me/account/export`
Async data export job.
- Response: `{ job_status: "pending"|"ready"|"failed", download_url?, expires_at }`

---

## Section 8 — Geolocation

### `POST /location/update`
Background location ping (batched).
- Body: `{ booking_id?, lat, lng, accuracy_m, timestamp }`
- Server: Redis SETEX for last-known (TTL 5min), batch flush to DB every 30s
- Auth: per-booking scope (no general location upload)

### `GET /location/tracking/:booking_id`
Get Mate's status for active booking.
- Response: `{ status: "on_the_way"|"running_late"|"arrived", eta_seconds?, last_update_at }` (NO raw coords — only status + ETA)

---

## Section 9 — Misc / Placeholder

### `POST /iap/waitlist`
Phase 1 placeholder for IAP email opt-in.
- Body: `{ email, source_screen }`
- Response: `{ opted_in: true }`

### `GET /me/devices`
List logged-in devices.

### `POST /push/register-token`
Register APNs/FCM token.
- Body: `{ token, platform: "ios"|"android" }`

### `PATCH /me/push/preferences`
Update notification category toggles.

---

## Background Jobs (server-side, not API)

| Job | Cadence | Purpose |
|---|---|---|
| Hello-window expiry | Hourly | Mark matches with 0 messages at 24h as expired |
| Chat auto-archive | Daily | Archive rooms idle ≥7 days, freeze Vibe |
| Letter expiry | Hourly | Mark letters in `sent`/`opened` >7d as expired |
| Soft-hold release | Per-event (Redis TTL) | Release booking soft-holds at 15min |
| Geofence T-15 check | Per-booking trigger | Determine on-the-way / running-late status |
| Geofence T+25 no-show | Per-booking trigger | Mark `no_show`, fire Trust −10 |
| Review reveal | Per-event | Reveal at both-submit OR T+48h |
| Trust recovery | Daily | Apply +2 per 30-day clean window |
| Social proof recount | Every 15min | Update `restaurants.interested_count` |
| Restaurant ranking | Every 15min | "Hot quanh bạn" rail re-rank |

---

## Versioning & Breaking Changes

- All endpoints prefixed `/api/v1/`
- Breaking changes → `/api/v2/` (no in-place v1 break during Phase 1)
- Deprecation notice in `Deprecation` header at least 30 days before removal
- OpenAPI spec auto-generated from Go handler annotations, hosted at `/api/v1/docs/`

---

## Agent Integration Notes

**Frontend Agent:**
- All endpoints assume `Authorization: Bearer <jwt>` except `/auth/*` and `/iap/waitlist`
- Use typed client (generated from OpenAPI) — do NOT hand-write request shapes
- Handle 401 → trigger refresh + retry once; refresh fail → logout + navigate to login
- Handle WS reconnect with exponential backoff (1s, 2s, 4s, 8s, max 16s)

**Backend Agent:**
- Validate every body field server-side (do not trust client validation)
- All trust-mutating actions → `trust_events` ledger insert, NEVER UPDATE `users.trust_score`
- All booking transitions → `booking_events` ledger insert
- Idempotency: clients send `Idempotency-Key` header on POSTs that create resources; server dedupes within 5min window

**QA Agent:**
- Contract test: each endpoint with valid + invalid bodies, check status code + error code match
- Load test critical paths: `/swipes`, `/messages`, `/location/update`, `/restaurants/:id/swipe-pool`
- E2E: full journey trace from `/auth/otp/request` → `/bookings/:id/review`

---
name: anmates-domain-glossary
description: Phase 1 terminology, business rules, and brand voice glossary
metadata:
  type: reference
---

# ĂN MATES — Domain Glossary (Phase 1)

## Brand Voice & Identity

### Ăn miết
Brand voice phrase meaning "continue eating together / keep meeting up." Used as terminal-state retention phrase. Never anglicized — diacritics must render.

### Tagline
> "Một chạm — Ăn miết" (canonical short form for Phase 1 surfaces)

---

## Core Entities

### Mate
A user who has completed verification (phone + OTP + face liveness + profile + tastes + photos). Pre-verification user = "Unverified."

### Best Mate
A Mate with whom the user has shared **≥3 completed First Dates / Kèo**. Highlighted in Wishlist tab "Kèo đã đi qua" + Tab Mình rail.

### Kèo
Vietnamese slang for "deal/plan." In ĂnMates = **one booking = một kèo**. Used in copy: "Kèo mới", "Kèo đã đi qua", "Báo kèo".

### First Date
Brand-specific term for the **first in-person meal between two Mates**. Distinct copy treatment in scheduling screen (Screen 17). Subsequent meals are just "kèo."

### Lá thư
Unilateral handwritten-style invitation card that **bypasses the Vibe gate** (does NOT require Vibe ≥70). Sender composes mood chips + freeform + P.S.; receiver gets a postcard-rendered notification (Screen 19).

**Rate-limits (Phase 1):**
- Max 3 pending letters per user simultaneously
- Same sender→receiver: 14-day cooldown after decline/expire
- Open question: rate-limit is total or per-receiver

---

## Matching & Discovery

### Place-first matching
**Core differentiator.** Unlike Tinder (profile-first), ĂnMates matches users who **already share a dining intent on the same specific restaurant**.

Flow:
1. User browses Home / Restaurant detail
2. User sees "X người quanh đây cũng đang thèm quán này" (live count)
3. User taps "Tìm Mate ăn cùng" → enters Dining Swipe scoped to that restaurant
4. Swipe right on Mates who also added this restaurant
5. Mutual right → Match → Chat room opens

### Dining swipe
Card deck **scoped to a single restaurant**. Leaving the restaurant context resets the deck. Each Mate card shows:
- Avatar, name, age, Trust badge
- Distance
- Status quip (short user-set line)
- Taste tag overlap with viewer
- Chip "Cũng vừa thêm quán này · N phút trước"

**Cooldown:** 24h cooldown per (user, restaurant) pair after a pass.

### Super-like (swipe up)
Available in deck. Counts as right-swipe + boost (priority surface in target's incoming queue). No quota limit in Phase 1 (technical anti-abuse rate limit only).

### Hot quanh bạn
Home rail that re-ranks restaurants every 15 minutes based on current swipes / wishlist adds within the user's district + matching time slot.

---

## Chat & Vibe

### Vibe meter (a.k.a. "Nồi Lẩu")
Per-chat-room score 0–100. Measures conversation health.

**Signals logged** (calibration-only in Phase 1):
- Message length
- Reply latency (lower = better, with diurnal normalization)
- Reciprocity (turn-taking balance)
- Media use (voice notes, photos)

**Phase 1 speed:** ×1 multiplier for everyone. No paid acceleration.

**Threshold 70:** Unlocks the **"Đặt First Date"** CTA in chat header.

**Below 70:** First Date CTA hidden / locked state shown (Screen 15 = "Nồi 42 khoá", Screen 16 = "Nồi 72 mở").

### Hello window (24h)
After match, both users have 24 hours to send the first message. Zero messages → match auto-archives. Visible countdown in chat header.

### Auto-archive (7-day idle)
Active chat with no message in 7 days → archived. Vibe **freezes at the last value** (does not decay).

### PII auto-redaction
Server-side regex + entity recognition redacts in real-time:
- Vietnamese phone patterns (+84, 09x, 03x, 07x, 08x, 05x)
- Zalo IDs
- Telegram handles (@username)
- Common URL patterns

Replaced with `[liên hệ bị ẩn]`. User cannot disable.

### Voice note
Press-hold to record (max 60s), slide-to-cancel pattern. Played inline with waveform.

### Chat inbox 4 groups (Screen 14)
1. **Mới match** — match accepted, no first message yet (24h window active)
2. **Đang tám** — active conversation
3. **Best Mate** — chats with someone who is also a Best Mate
4. **Hôm qua** — last-activity yesterday (urgency to re-engage)

---

## Booking / First Date

### Soft-hold
When booking enters `pending`, restaurant is **soft-held for 15 minutes**. Other Mates browsing the same restaurant see slot unavailable. If receiver doesn't accept in 15 min → released.

### Booking state machine
```
pending → confirmed → completed (both checked-in)
       ↘ declined
       ↘ cancelled
       ↘ no_show (only one or zero checked-in)
```

### Voucher 50k
"Vì chốt nhanh" — conditional voucher displayed at booking screen. Released **only when both Mates check-in on time**. Funded by co-marketing with restaurants (NOT IAP-dependent).

### Calendar sync
Confirmed booking writes to native calendar (iOS Calendar / Google Calendar) on user opt-in.

---

## Day-of Flow

### Selfie xuất phát (Pre-departure selfie)
**Required** before "Xác nhận đi" action. 
- Front camera only
- Library upload disabled
- On-device liveness (blink + head turn)
- Server-side anti-replay (timestamp + fresh embedding)
- Overlays allowed: sticker, text, mood chip, emoji
- Mood chips: 😎 confident · 🥰 excited · 😅 nervous · 🤘 ready

3 action buttons:
- **Xác nhận đi** (primary) — selfie sent, status → "on the way"
- **Báo trễ** — picks 5 / 10 / 15+ minutes, notifies Mate
- **Nhắc 5 phút** — snooze (max 3 times)

### Live Tracking
**NOT a full map.** Card-style ETA tracker (Screen 21):
- Status pill: "Đang đến · ETA 12'"
- Stylized abstract route (not real cartography)
- Mate avatar
- Progress dots toward restaurant

Uses **geofence + background fetch**, NOT foreground GPS (battery + privacy).

### Auto check-in
On geofence polygon enter (not radius — must be polygon shape of venue):
- Both Mates see "Đã đến" status
- Trust event `+2` fires if ≤ scheduled + 5 minutes
- Idempotent (re-enter does not double-count)

**Manual fallback:** If GPS fails or restaurant lacks polygon, server allows manual check-in via UI button (requires Mate to also confirm).

### Proximity notification
At ≤320m from venue, push "Bạn đã sắp tới — chuẩn bị nha!"

### Soft-check / No-show
- Late >15' with no "Báo trễ" → soft-check sent
- No geofence enter by T+25 → status `no_show`, Trust −10

---

## Trust Score (Phase 1: measured, NOT gating)

### Initial value
**100 points** at signup_complete.

### Thresholds (display only — no gating)
- **≥90** → "Perfect Mate" badge (gold, ✨ icon, top X% positioning)
- **80–89** → "Trusted" badge (Glaucous)
- **<80** → "Limited" label

### Phase 1 rule
**Trust does NOT gate any feature.** Chat unlimited, swipe unlimited, booking unlimited regardless of score.

### Recovery
Positive-behavior only:
- On-time check-in: +2
- Review with photo: +3 (open Q: 1 photo or 2?)
- 5★ rating: +1

No paid recovery in Phase 1 (no Trust Booster, no Amnesty, no Freeze).

### Auto-forgiveness (V1.1)
If realtime traffic data shows delay is traffic-caused (not lying user), waive the late penalty. Data source TBD.

### Sổ cái (ledger)
Every Trust event recorded with `delta`, `reason_code`, `related_booking_id`, `timestamp`. Visible to user in Trust Dashboard (Screen 24).

---

## Identity & Profile

### Auto-derived from DOB
Calculated read-only fields:
- **Cung (Zodiac)** — Western 12 sign
- **Ngũ hành (Five Elements)** — Wood/Fire/Earth/Metal/Water based on birth year
- **Numerology** — life path number

**User toggle:** "Không hiển thị trên profile public" (default ON for show; user can hide).

### Photos
- Max 3
- 1 must be marked `is_main`
- Server-side checks: NSFW, face presence, OCR for embedded phone/URL (reject if found)
- Reorderable

### Status quip
Short user-set line shown on swipe card. Max 60 chars. Examples: "Hôm nay nhịn cay", "Đi ăn được không nhỉ?"

---

## Safety & Moderation

### Block
Removes user from each other's swipe pool + chat list. From: profile page, chat header, inbox swipe-left action.

### Unmatch
Soft variant of block — removes from chat list but doesn't blacklist from future swipes.

### Report
Categories:
1. Hành vi không phù hợp
2. Ảnh giả / catfishing
3. Hăm doạ / harassment
4. Lừa đảo / scam
5. Khác

Evidence upload supported. Goes to T&S queue.

### Pause account
Temporary status during T&S review. User cannot match / chat but data preserved.

### Delete account + export
- Triggers 14-day soft-delete (can resume)
- Async job generates zip of user data (Nghị định 13/2023)
- After 14 days → hard delete, anonymize residual rows

### Cancel booking
Always shows **Trust penalty preview** before confirm:
- ≥24h before → 0 penalty
- 24h–2h → −3
- <2h → −5

---

## Genres (Cuisine Categories)

| Tag | Meaning |
|---|---|
| Lẩu | Hotpot |
| Nướng | BBQ / grilled |
| Café | Coffee shop |
| Ăn vặt | Street snacks |
| Cơm | Rice dishes |
| Mì / Phở | Noodles |
| Hải sản | Seafood |
| Chay | Vegetarian |
| Tráng miệng | Dessert |

---

## Vibes (Ambiance Tags)

| Tag | Meaning |
|---|---|
| Máy lạnh | Air-conditioned |
| Vỉa hè | Sidewalk seating |
| Khuất hẻm | Hidden alley |
| Sang chảnh | Upscale, photogenic |
| Ồn ào | Lively, loud |
| Yên tĩnh | Quiet, intimate |
| Outdoor | Open-air |
| Rooftop | Rooftop |

---

## Taste Tags (User Profile)

**Heat:**
- 🌶️ Không cay
- 🌶️🌶️ Cay vừa
- 🌶️🌶️🌶️ Cay cấp 3

**Dietary:**
- 🌱 Không hành
- 🌱 Chay
- 🦐 Hải sản OK

**Conversation:**
- 💬 Thích tám chuyện
- 📷 Hay chụp hình
- 🎵 Mê nhạc lounge

---

## Notifications & Push

### Categories (settings togglable)
- Match mới
- Tin nhắn chat
- Lá thư
- Nhắc kèo (booking reminder)
- Live tracking updates
- Promotion / partner deals

### Push windows (passive activation)
- 8:00–11:00
- 11:00–14:00
- 17:00–20:00

---

## Error Codes (key examples)

| Code | Meaning |
|---|---|
| `LIMIT_ACTIVE_CHATS_TECHNICAL` | 200 active rooms reached (anti-abuse) |
| `MATCH_RATE_LIMITED` | >30 matches in 24h |
| `LETTER_QUOTA_EXCEEDED` | >3 pending letters |
| `LETTER_RECEIVER_COOLDOWN` | 14-day cooldown active |
| `OTP_RATE_LIMITED` | 3+ OTP requests in 15 min |
| `FACE_LIVENESS_FAILED` | Liveness check did not pass |
| `BOOKING_SOFT_HOLD_EXPIRED` | 15-min soft-hold released |
| `GEOFENCE_NOT_AVAILABLE` | Restaurant lacks polygon, manual check-in required |

---

## Glossary Quick-reference Table

| Term | One-line definition |
|---|---|
| Mate | Verified user |
| Best Mate | ≥3 completed Kèo with same person |
| Kèo | One booking |
| First Date | The first in-person Kèo between two Mates |
| Lá thư | Unilateral invitation bypassing Vibe gate |
| Vibe meter / Nồi Lẩu | 0–100 score per chat room |
| Trust Score | 0–100 behavior score (measured, not gating in P1) |
| Ăn miết | Brand voice for "keep dining together" |
| Hello window | 24h after match to send first message |
| Soft-hold | 15-min restaurant slot hold during pending booking |
| Auto-archive | 7-day idle → chat archived, Vibe frozen |

---

This glossary is the canonical source. When ambiguity arises in copy or logic, reference here before implementing.

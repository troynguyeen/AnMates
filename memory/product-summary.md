---
name: anmates-product-overview
description: Product vision, Phase 1 Ultimate-for-all strategy, target users, KPIs
metadata:
  type: project
---

# ĂN MATES — Product Summary (Phase 1 v1.0, 25.05.2026)

## TL;DR

ĂnMates Phase 1 launches as **"Ultimate-for-all"**: every verified user gets the **entire feature set** of the app — no tiers, no paywall, no IAP. Goal is to maximize retention + behavioral data in the first 8 weeks to calibrate Phase 2 monetization.

## Vision

Solve **"Hôm nay ăn gì?"** and **"Ai đi cùng?"** via a **place-first** matching loop in TP.HCM, before expanding nationally.

## Phase 1 Strategy: Ultimate-for-all

### Why no IAP in Phase 1
1. Remove friction while user base is small.
2. Need real behavioral data (Vibe events, Trust events, completion rates) to size Phase 2 perk tiers — not assumptions.
3. Reduce launch surface = fewer bugs.

### What's IN scope (build & ship)
- Onboarding (Splash → 3 edu screens → Phone+OTP → Face verify → Profile → Tastes → Photos)
- Discovery (Home, search, genre/vibe rails, "Hot quanh bạn")
- Restaurant detail + Wishlist
- **Dining swipe** (deck scoped to one restaurant)
- Match + Chat (Inbox 4 groups, voice notes, PII auto-redact)
- **Vibe meter** (0–100, threshold 70 unlocks First Date)
- **Lá thư (Letters)** — unilateral invitation bypassing Vibe gate
- First Date scheduling (calendar, voucher 50k conditional)
- **Selfie xuất phát** (live selfie before departure, no library upload)
- **Live Tracking** (card-style ETA, NOT full map)
- Auto check-in via geofence **polygon** (not radius)
- Anonymous double-blind review (T+30 after later check-in)
- **Trust Score** (0–100, measured but NOT gating any feature)
- Tab Mình (Profile, Album, Wishlist, Best Mates, Trust dashboard, Settings)
- Safety: Block, Report, Pause, Cancel booking, Delete account + data export

### What's OUT of scope Phase 1
- IAP / billing / receipt validation
- Trust Booster, Instant Amnesty, Trust Freeze, Forgiveness
- Golden Match Pool, Ghost Tracking, Peak Hour Priority
- Vibe ×1.5, Point ×1.2 multipliers
- Deal Radar, Cashback 100k
- Group dining (≥3 Mate)
- Multi-language (VN-only)
- Tablet / desktop
- Referral / invite-friend (Phase 2)

### Coming soon (placeholder only)
One entry in Tab Mình:
```
GÓI ĂN MATES
✨ Đang mở toàn bộ tính năng miễn phí trong giai đoạn ra mắt.
   Các gói VIP sẽ xuất hiện trong những bản cập nhật sắp tới.

[Đăng ký nhận tin khi gói ra mắt]
```
→ Email opt-in modal → `iap_waitlist` table.

---

## KPIs (8 weeks post-launch)

| Metric | Target | Source |
|---|---|---|
| Activation rate | ≥60% complete onboarding (B6) | `signup_complete` |
| D7 retention | ≥35% | session_open day 7 |
| First match → first chat | ≥80% within 24h | timestamp delta |
| Vibe ≥70 / chat started | ≥25% | match.vibe snapshot |
| First Date confirmed → both check-in | ≥70% | `booking_both_checked_in` |
| Trust events / WAU | ≥0.4 | trust_event count / WAU |
| Review submit rate | ≥65% | review_submitted / completed_booking |
| Crash-free sessions | ≥99.5% | Crashlytics |

---

## Personas (unchanged)

**Persona A — The Social Explorer**: Gen Z, new to city, fast swipe → match flow.

**Persona B — The Reserved Foodie** (MVP focus): mid-20s designer/professional, deep vibe-check first, needs trust signals (Live Tracking, double-blind review, Vibe ≥70 gate).

---

## Tech Stack (Phase 1)

- **Mobile**: Flutter (iOS 15+ / Android 10+ / API 29)
- **Backend**: Go (Gin) + PostgreSQL + PostGIS
- **Chat**: WebSocket + custom message store (Stream Chat OPTIONAL — TBD with arch)
- **Liveness**: Apple Vision / Google ML Kit (on-device)
- **SMS**: VN gateway (Viettel/Vinaphone/Mobifone) + Apple SMS auto-fill + Google SMS Retriever
- **Map / geofence**: Google Maps OR Mapbox (decision pending, polygon required not radius)
- **Push**: APNs + FCM
- **Crash analytics**: Crashlytics / Sentry

---

## Critical Logic Adjustments for Phase 1

### Chat rooms — unlimited per user
- No commercial limit on concurrent chats.
- Auto-archive room after **7 days no message** (Vibe freezes at stop point).
- 24h hello window — no hello → match expires.
- **Technical** quota (anti-abuse): ≤200 active rooms/user → reject with code `LIMIT_ACTIVE_CHATS_TECHNICAL`.
- Anti-spam: ≤30 new matches/24h/user; spam pattern detection → T&S soft-flag.

### Vibe meter — fixed ×1 speed
- No multiplier. Log all signals (length, latency, reciprocity, media use) for Phase 2 calibration.

### Trust Score — measured, NOT gating
- Still calculated, still displayed (badges ≥90 Perfect Mate / 80–89 Trusted / <80 Limited).
- **DOES NOT gate any feature.** Low trust still gets full app.
- Recovery only via positive behavior: on-time check-in (+2), review with photo (+3), 5★ rating (+1).
- Badge ≥90 is social signal only.

### Voucher 50k — kept
- "Chốt nhanh + both on-time" voucher remains. Funded by co-marketing with restaurants, NOT IAP-dependent.

### Lá thư (Letters) — anti-spam quota
- Max **3 pending letters per user** simultaneously.
- Same sender→receiver: decline/expire blocks new letter for 14 days.

---

## Trust Event Delta Table (FINAL for Phase 1)

| Event | Delta | Trigger |
|---|---|---|
| On-time check-in | +2 | Geofence enter ≤ scheduled_at + 5' |
| Review with photo | +3 | Review submitted + ≥1 image/video |
| 5★ rating from Mate | +1 | Counter-review chips "đúng giờ" + "dễ tám" |
| Late 5–15' with notice | 0 | "Báo trễ" used in T-30 → T+0 window |
| Late 15–30' no notice | −3 | Geofence enter late + no "Báo trễ" |
| No-show | **−10** | No geofence enter in T → T+25' |
| Cancel ≥24h | 0 | Cancel ≤ scheduled_at − 24h |
| Cancel <24h, ≥2h | −3 | Cancel between 24h and 2h before |
| Cancel <2h | −5 | Cancel sat giờ |
| Report confirmed by T&S | −15 | After case "confirmed" |

---

## Roadmap (8-week sprint plan)

| Week | Track | Milestone |
|---|---|---|
| W1–2 | Foundation | Schema, auth, OTP, face verify, profile, photos |
| W3–4 | Discovery + Chat infra | Home, restaurant detail, wishlist, swipe, WS, PII redaction, vibe meter |
| W5 | Match → chat → schedule | E2E happy path runnable; Letter sender+receiver |
| W6 | Day-of + Review | Selfie, Live Tracking, geofence, auto check-in; anonymous review + Trust ledger |
| W7 | Safety + Polish | Block, report, cancel, pause, delete; empty/loading/error, haptic, a11y |
| W8 | Hardening | Crash budget, perf, store submission |

**Soft-launch D1:** 1 district (Q1), 200 closed beta users.
**Public launch D+14:** 5 districts (Q1, Q3, Q5, Q7, Bình Thạnh).

---

## Non-functional Requirements

### Performance
- App cold start ≤2.5s p75 (iPhone 12 / Android equivalent)
- Home payload TTFB ≤400ms p95
- WS chat reconnect ≤3s after network restore

### Privacy & Safety
- Raw selfie **discarded immediately** after embedding.
- DOB never exposed — only derived values (zodiac, ngũ hành, numerology) and only if user toggle ON.
- Phone masked in all Mate-facing surfaces.
- Nghị định 13/2023 compliance: user can export + delete data.

### Mobile
- Permission staggering: camera at face verify · location after first Home view · push after first match.
- Live Tracking uses geofence + background fetch — NOT foreground GPS.
- SMS auto-fill native.
- Haptic + sound on: Match, Vibe unlock, Letter open, Auto check-in.

---

## Open Questions (need Product/Design before build)

1. Voucher 50k funding: ĂnMates or restaurant? All venues or only partners?
2. Geofence polygon data source for ≥200 curated venues?
3. Trust event "+3 review with image": minimum 1 image or 2?
4. Letter rate-limit: 3 total or per-receiver?
5. Apple ID login: skip OTP but also skip phone number capture?
6. Auto-forgiveness for traffic: realtime traffic data available? If not → V1.1.
7. Email vendor for IAP waitlist (Mailchimp / Sendgrid)?
8. Trust badge top X%: fixed threshold or dynamic percentile?
9. "Giờ vàng" badge on restaurants without gating (since Peak Hour Priority is Phase 2)?
10. A/B test wording on Coming Soon CTA (`Đăng ký nhận tin` vs `Bật notify`)?

---

## Current State (2026-05-25)

- ✅ Handoff doc v1.0 finalized in `plan/lastest/handoff/`
- ✅ 30+ design HTML files in `plan/lastest/design/`
- ✅ Agent team initialized
- ✅ Memory rewritten to reflect Phase 1 scope
- ⏳ Awaiting: confirmation of open questions + task assignment kickoff

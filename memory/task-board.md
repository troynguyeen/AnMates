---
name: anmates-task-board
description: Phase 1 task scaffolding aligned to handoff §10 (8-week sprint plan)
metadata:
  type: project
---

# ĂN MATES — Phase 1 Task Board

> **Status:** Scaffold ready. Detailed per-task specs (acceptance criteria, exact deliverables) generated on demand when user kicks off execution. User-stated workflow: "agent team trước, task sau."

> **Source:** Handoff §2.1 (scope) + §10 (timeline). All IAP-related work removed (Phase 2). All gating-based work removed (Trust is measured-only in Phase 1).

---

## Sprint Tracks (Per Handoff §10)

| Week | Track | Theme |
|---|---|---|
| W1–2 | Foundation | Schema, auth, OTP, face verify, profile, photos |
| W3–4 | Discovery | Home, restaurant detail, wishlist, swipe pool |
| W3–4 | Chat infra | WS, message store, PII redaction, vibe meter |
| W5 | Match → chat → schedule | E2E happy path runnable |
| W5 | Letter | Sender composer + receiver flow |
| W6 | Day-of | Selfie, Live Tracking, geofence, auto check-in |
| W6 | Review | Anonymous double-blind + Trust event ledger |
| W7 | Safety | Block, report, cancel, pause, delete account |
| W7 | Polish | Empty/loading/error states, haptic, accessibility pass |
| W8 | Hardening | Crash budget, perf, store submission |

---

## Backend Tasks (Go)

### W1–2 · Foundation
- **BE-001** Schema + migrations (all tables in architecture §Data Model)
- **BE-002** Auth: OTP request/verify (VN SMS gateway integration)
- **BE-003** Auth: JWT issue + refresh rotation, secure session store
- **BE-004** Auth: Apple ID Sign-in handler (resolve phone capture open Q)
- **BE-005** Face verify: liveness signal validation + anti-replay + embedding store
- **BE-006** Profile: create/update, auto-derive zodiac/ngu_hanh/numerology
- **BE-007** Tastes: cuisine + vibe tag CRUD
- **BE-008** Photos: upload, NSFW/face/OCR checks, reorder, delete
- **BE-009** Seed: ≥50 curated restaurants (TP.HCM Q1) with geo_polygon

### W3–4 · Discovery
- **BE-010** GET /home with district + time-slot ranking
- **BE-011** GET /restaurants/:id with % hợp gu calculation
- **BE-012** Wishlist add/remove/list with sub-tab grouping
- **BE-013** Swipe pool query (with 24h cooldown filter)
- **BE-014** "Hot quanh bạn" 15min recount job
- **BE-015** Social proof recount job (per-restaurant interested_count)

### W3–4 · Chat infra
- **BE-016** WebSocket hub + room state management
- **BE-017** Message persist with PII auto-redaction (phone/Zalo/TG/URL regex)
- **BE-018** Vibe scorer service (signals JSON + delta calc per §Decision 5)
- **BE-019** Vibe event logger (for Phase 2 calibration)
- **BE-020** Hello-window expiry job (hourly)
- **BE-021** Chat auto-archive job (daily, 7-day idle threshold)
- **BE-022** Voice note upload + signed URL serving

### W5 · Match flow
- **BE-023** POST /swipes with rate-limit (60/min) and mutual check
- **BE-024** Match creation + match notification (push + inbox)
- **BE-025** Inbox 4-group query (new / chatting / best_mate / yesterday)
- **BE-026** Anti-spam: 30 matches/24h cap; spam pattern soft-flag

### W5 · Letter
- **BE-027** POST /letters with quota (3 pending) + cooldown (14d per receiver)
- **BE-028** Letter accept → auto-create booking pending
- **BE-029** Letter expiry job (7-day TTL)

### W6 · Booking
- **BE-030** Booking state machine (pending → confirmed → completed/no_show/cancelled)
- **BE-031** Soft-hold Redis SETEX 15min on `restaurant_id + hour_block`
- **BE-032** Calendar sync (iOS ICS export + Google Calendar API)
- **BE-033** Voucher 50k eligibility check (both check-in on time)

### W6 · Day-of
- **BE-034** Selfie xuất phát: liveness + anti-replay + embedding match
- **BE-035** Location update batch (Redis last-known + 30s DB flush)
- **BE-036** Geofence polygon check (PostGIS ST_Within)
- **BE-037** Geofence T-15 status job (on the way / running late detection)
- **BE-038** Geofence T+25 no-show job (status + Trust −10)
- **BE-039** Auto check-in (polygon enter event → idempotent ledger entry)
- **BE-040** Manual check-in fallback (both Mates confirm UI)
- **BE-041** Proximity push at 320m

### W6 · Review + Trust
- **BE-042** Review submit (chips + freeform + venue media)
- **BE-043** Double-blind reveal logic (both submit OR T+48h)
- **BE-044** Trust event ledger (append-only) + derived score view
- **BE-045** Trust event triggers for all Phase 1 deltas (per handoff §B)
- **BE-046** Trust recovery job (+2 per 30-day clean)

### W7 · Safety
- **BE-047** Block / unmatch (mutual removal from pool + chat)
- **BE-048** Report submit + T&S queue
- **BE-049** Account pause / resume
- **BE-050** Account delete (14-day soft-delete + hard delete worker)
- **BE-051** Data export async job (zip generation + signed URL)
- **BE-052** Consent log per category
- **BE-053** Cancel booking with Trust penalty preview

### W7 · Push + Misc
- **BE-054** Push token registration (APNs + FCM)
- **BE-055** Notification preferences CRUD
- **BE-056** IAP waitlist email opt-in endpoint

### W8 · Hardening
- **BE-057** OpenAPI doc generation + Swagger UI
- **BE-058** Performance pass: index audit, slow query log
- **BE-059** Load test: swipe pool, message dispatch, location update
- **BE-060** Idempotency-Key middleware for all POST creators

---

## Frontend Tasks (Flutter)

### W1 · Foundation
- **FE-001** Project init (Flutter, Riverpod, GoRouter, env loading)
- **FE-002** Theme implementation (Brand system tokens from Brand system.html)
- **FE-003** Component primitives (Button, Chip, Card, Input, Avatar, VibeRing, TrustBadge, **AppLoader**, **Sparkle**) — see design-system.md for AppLoader 3-mode spec + Sparkle twinkle spec
- **FE-004** API client (typed, generated from OpenAPI)
- **FE-005** Secure storage (Keychain / Keystore for tokens)

### W1–2 · Onboarding screens (01–10)
- **FE-006** Screen 01 Splash — radial wisteria→Berry Crush gradient bg, 6–8 twinkling Sparkles, animated logo entrance + idle breathing pulse, brand wordmark + tagline, AppLoader.splash mode with caption "Đang nhóm lửa nồi lẩu...". Full animation timeline + reduce-motion fallback in design-system.md §Splash Screen.
- **FE-007** Screens 02–04 edu carousel — see design-system.md §Onboarding Edu Carousel for full per-screen animation specs. Includes: shared framework (page indicator morph, swipe/CTA carousel transition, "Bỏ qua" modal, arrow nudge); Screen 02 (4 genre cards cascading drop + ghost tap demo); Screen 03 (3 fanned Mate cards + counter ticking 0→15 + ghost swipe-right demo); Screen 04 (hotpot + Vibe ring filling 0→72% + chat bubbles popping + lock→unlock burst at threshold + steam particles). Reuses Sparkle primitive. Reduce-motion fallbacks specified per screen.
- **FE-008** Screen 05 Login (phone + Apple ID) — entrance cascade, input focus/error states, Apple button after OR divider → design-system.md §Auth Flow §Screen 05
- **FE-009** Screen 06 OTP (6-digit, auto-fill iOS/Android, countdown, retry) — slot scale-in cascade, per-digit pop, auto-advance, success cell flip, SMS auto-fill cascade → design-system.md §Auth Flow §Screen 06
- **FE-010** Screen 07 Face verify — circular camera + 4-step liveness ring fill, per-step transitions, completion sparkle burst → design-system.md §Auth Flow §Screen 07
- **FE-011** Screen 08 Profile — DOB-completion auto-derive reveal moment (sparkle on unveil), personality slider live label, derived toggle → design-system.md §Profile Setup §Screen 08
- **FE-012** Screen 09a Gu ẩm thực — chip cascade entrance, chip pop selection, live counter tick with scale punch, CTA enable glow at threshold → design-system.md §Profile Setup §Screen 09a
- **FE-013** Screen 10a Photo upload — 3 slots cascade, upload determinate AppLoader.topBar, NSFW/OCR rejection animation, drag-reorder → design-system.md §Profile Setup §Screen 10a

### W3 · Discovery + Wishlist screens
- **FE-014** Screen 09b Home — first-time cascade entrance (greeting → search → rails), genre/vibe rail snap scroll, restaurant card tap shared-element transition, pull-to-refresh sparkle, social proof 🔥 pulse → design-system.md §Discovery §Screen 09b
- **FE-015** Bottom nav 4 tabs — icon scale + label color + indicator bar morph (Khám phá / Wishlist / Chat / Mình)
- **FE-016** Screen 11 Restaurant detail — shared-element hero zoom from card, social proof banner spring entrance, 92% match score tick, dish chip cascade, % hợp gu + CTAs → design-system.md §Discovery §Screen 11
- **FE-017** Screen 10b Wishlist — sub-tab cross-slide, district filter chip morph + list re-flow, Best Mates rail with avatar ring pulse → design-system.md §Discovery §Screen 10b
- **FE-018** Search bar with voice input

### W4 · Swipe + Match
- **FE-019** Screen 12 Dining swipe deck — card drag physics (rotation + colored hint chips), super-like sparkle burst, deck cross-fade transitions, empty state with hotpot illustration + sparkles → design-system.md §Match Flow §Screen 12
- **FE-020** Cooldown UI (24h state on deck) + rate-limit banner
- **FE-021** Screen 13 Match full-bleed CELEBRATION — bg burst, 15+ sparkle confetti, headline type-in, dual avatar fly-in with collision sparkle, primary CTA glow pulse, brand match jingle, haptic SUCCESS → design-system.md §Match Flow §Screen 13

### W4–5 · Chat screens
- **FE-022** Screen 14 Inbox (4 groups) — section sequential fade-in, row cascade per section, "đang gõ" 3-dot pulse, hello-window urgency color shift, swipe-left action buttons → design-system.md §Chat §Screen 14
- **FE-023** Screen 15 Chat locked (Nồi <70) — header, Vibe band entrance, message bubble fly-in/from-side, send/receive animations → design-system.md §Chat §Screens 15/16
- **FE-024** Screen 16 Chat unlocked (Nồi ≥70) — IN-PLACE unlock moment when crossing 70 (lock flip + ring burst + sparkles + haptic + bg warm shift), propose card spring slide-up, CTA pulse → design-system.md §Chat §Screens 15/16
- **FE-025** Vibe meter ring component — incremental fill on message send (200ms ease-out), unlock moment haptic + color burst + 6 sparkles emanate (shared between FE-023, FE-024, FE-007)
- **FE-026** Chat suggestion chips — gentle horizontal bob idle, tap-to-fill input
- **FE-027** Voice note (press-hold + slide-to-cancel waveform expand)
- **FE-028** WebSocket client (reconnect + offline queue)
- **FE-029** PII-redacted message render (`[liên hệ bị ẩn]` placeholder italic + ℹ icon toast)
- **FE-030** 24h hello window countdown header (urgency color shift <2h amber, <30min red)

### W5 · Letter screens
- **FE-031** Screen N6 Letter composer — receiver/restaurant/date pickers, mood chip multi-select, freeform char count, postcard preview bottom sheet, envelope-fly-away send animation → design-system.md §Supplementary §Screen N6
- **FE-032** Screen 18 Letter inbox notification — eyebrow wiggle, envelope fly-in with seal shimmer + 3 idle sparkles, envelope-open transition to Screen 19 → design-system.md §Booking & Letter §Screen 18
- **FE-033** Screen 19 Letter detail postcard — postcard slide-out from envelope, body reveals line-by-line, proposal card spring entrance, tags pop, signature scribbles in (handwritten wipe), accept = postcard tilt + sparkle burst, decline = fold-back animation → design-system.md §Booking & Letter §Screen 19

### W5 · First Date schedule
- **FE-034** Screen 17 Calendar grid — voucher banner shimmer + 2 sparkles, calendar cell row cascade, day cell tap spring + state morph, time slot cascade, soft-hold countdown banner (amber <2min, green on confirm, gray on expire) → design-system.md §Booking & Letter §Screen 17
- **FE-035** Voucher 50k display logic + shimmer animation
- **FE-036** Booking confirmation modal
- **FE-037** Calendar sync integration (iOS Calendar + Google Calendar)

### W6 · Day-of screens
- **FE-038** T-45 push handling + deep link to Screen 20
- **FE-039** Screen 20 Selfie xuất phát — camera power-on zoom, overlay tool rail entrance, countdown urgency (default → Berry Crush → red shake), mood overlay drag/pinch, capture flash + AppLoader liveness check → design-system.md §Day-of Flow §Screen 20
- **FE-040** 3-action button bar (Xác nhận đi 🛵 primary / Báo trễ / Nhắc 5')
- **FE-041** Báo trễ modal (5/10/15+ min chips)
- **FE-042** Screen 21 Live Tracking CARD — status pill entrance, abstract route line draw left→right, Mate avatar dot smooth slide on updates, ETA tick, proximity (320m) ring pulse + push, auto check-in moment (restaurant icon burst + 6 sparkles + `+2` float-up + haptic), both-checked-in 10-sparkle celebration → design-system.md §Day-of Flow §Screen 21
- **FE-043** Background location service (geofence + background fetch, NO foreground GPS)
- **FE-044** Auto check-in event handling + UI confirmation toast
- **FE-045** Proximity push handling (320m banner with auto-dismiss 5s)

### W6 · Review
- **FE-046** Screen 22 Anonymous review — chip cascade entrance, multi-select scale-pop with category color, freeform char count live, media attach (+3 sparkle ack), submit animation → wait state with reveal countdown → design-system.md §Anonymous Review §Screen 22
- **FE-047** Double-blind reveal moment — both-submit trigger or T+48h, card flip 180° with sparkle burst, side-by-side review reveal

### W7 · Tab Mình + Trust
- **FE-048** Screen 23 Tab Mình — profile block entrance, stats tick from 0, album cascade grid, taste chip cascade. **Phase 1 swap:** GÓI ĂN MATES section MUST use N7 Coming Soon card (NOT the IAP UI shown in design) → design-system.md §Profile Dashboard §Screen 23
- **FE-049** Screen 24 Trust dashboard — score tick from 0 (800ms ease-out weighty), ≥90 PERFECT MATE badge + sparkle burst, ledger cascade with delta tick, real-time score change moment (scale punch + ring fill + float-up delta). **Phase 1:** REMOVE `Giới hạn 1 phòng chat` copy → design-system.md §Profile Dashboard §Screen 24
- **FE-050** Screen N1 Profile edit — modal slide-up, photo drag-reorder with lift + shadow, tag chip add/remove, save with AppLoader.overlay → design-system.md §Supplementary §Screen N1
- **FE-051** Screen N2 Settings — list slide-in, toggle switch standard, subscreen navigation, logout confirmation → design-system.md §Supplementary §Screen N2
- **FE-052** Screen N7 Coming Soon Gói ĂnMates — Wisteria→Berry Crush gradient card, ✨ continuous twinkle, CTA pulse, email opt-in modal with success toast → design-system.md §Supplementary §Screen N7

### W7 · Safety
- **FE-053** Screen N3 Block / Report — modal slide-up, category row select with checkmark, evidence upload determinate progress, 2-step confirm with destructive button → design-system.md §Supplementary §Screen N3
- **FE-054** Screen N4 Cancel booking — penalty preview prominent with red pulse, optional reason, long-press or 2-step confirm to prevent accidental cancel → design-system.md §Supplementary §Screen N4
- **FE-055** Screen N5 Delete account + export — multi-step warning, export AppLoader.overlay, type-to-confirm gate, 14-day soft-delete confirmation → design-system.md §Supplementary §Screen N5

### W7 · Polish
- **FE-056** Empty / loading / error states across all screens
- **FE-057** Haptic + sound pass (Match, Vibe unlock, Letter open, Auto check-in)
- **FE-058** Accessibility pass (dynamic type, screen reader, contrast)
- **FE-059** VN localization dictionary + audit (zero hard-coded strings)

### W8 · Hardening
- **FE-060** Snapshot tests per screen (vs reference HTML)
- **FE-061** Integration tests for critical flows
- **FE-062** App icons + launch screen + store assets
- **FE-063** App Store + Play Store submission package

---

## QA Tasks

### W2 · QA Foundation
- **QA-001** Test plan template + bug tracking setup
- **QA-002** Auth flow E2E (phone, OTP, Apple ID, face verify)
- **QA-003** Profile + photos validation (NSFW, OCR, face)

### W3–4 · QA Discovery + Chat
- **QA-004** Discovery + wishlist (filters, distance sort, social proof accuracy)
- **QA-005** Swipe + cooldown + match logic
- **QA-006** Chat: PII redaction coverage (test all VN phone patterns, Zalo, TG, URLs)
- **QA-007** Vibe scoring: 8 / 15 / 16 / 20 messages produce expected scores within tolerance

### W5 · QA Match + Letter
- **QA-008** Letter quota + cooldown enforcement
- **QA-009** Letter → booking auto-creation
- **QA-010** Hello window expiry job
- **QA-011** Chat auto-archive (7-day idle)

### W6 · QA Day-of + Review
- **QA-012** Selfie liveness + anti-replay (mock embedding scenarios)
- **QA-013** Geofence polygon check (in / out / boundary)
- **QA-014** T-15 status detection + T+25 no-show
- **QA-015** All Trust event deltas fire correctly with idempotency
- **QA-016** Double-blind review reveal (both-submit + T+48h)

### W7 · QA Safety + Polish
- **QA-017** Block / unmatch / report flows
- **QA-018** Cancel booking penalty preview
- **QA-019** Account pause / delete / export (zip download)
- **QA-020** Accessibility audit

### W8 · QA Hardening
- **QA-021** Load test critical endpoints (swipe pool, messages, location)
- **QA-022** Crash budget verification (≥99.5% sessions)
- **QA-023** Performance: cold start, TTFB, WS reconnect
- **QA-024** Regression sweep across all P0 screens
- **QA-025** Device matrix: iPhone 12, iPhone 15, Pixel 7, Samsung A54

### Continuous
- **QA-026** Visual conformance per screen (vs reference HTML, 8 criteria from handoff §A.1)
- **QA-027** API contract tests (per endpoint, valid + invalid bodies)
- **QA-028** E2E golden path: register → home → swipe → match → chat → vibe 70 → schedule → depart → check-in → review

---

## Design Tasks (P0 — needed before engineering can build)

Per handoff §A "Màn cần thiết kế bổ sung" — these 7 screens don't have reference files yet:

- **DS-N1** Profile edit (drag reorder, tag edit, derived display toggle)
- **DS-N2** Settings (push categories, location, language, devices, blocklist)
- **DS-N3** Block / Report (modal, 5 categories, evidence upload, 2-step confirm)
- **DS-N4** Cancel booking (Trust penalty preview pre-confirm)
- **DS-N5** Delete account + export (14-day soft-delete confirm, zip link)
- **DS-N6** Letter composer (receiver/restaurant/date pickers + mood chips + freeform + P.S. + preview)
- **DS-N7** Coming Soon Gói ĂnMates placeholder card + email opt-in modal

**Blocker:** Design must deliver before W2 end to unblock engineering W3 onward.

---

## Cross-cutting Tasks

- **X-000** Design: export Sparkle SVGs (4-point + 6-point variants) for `assets/sparkles/` — blocks FE-003 + FE-006
- **X-001** Decide map provider (Google Maps vs Mapbox) — needed before BE-036/BE-037 polygon implementation
- **X-002** Source ≥200 venue polygons for launch districts (Q1, Q3, Q5, Q7, Bình Thạnh) — needed before D-7
- **X-003** Pick SMS provider + format approval for iOS auto-fill template
- **X-004** Pick crash analytics (Crashlytics OR Sentry — not both)
- **X-005** Pick chat backend approach (in-house WS recommended; Stream Chat alternative)
- **X-006** Resolve open questions from handoff §9 (10 items)
- **X-007** Admin tool scope (separate repo / app) — T&S mod, CS, Ops Day-1 needed
- **X-008** Coverage target sign-off (suggested: BE 70%, FE 60%)

---

## Open Questions to Resolve Before Build (Handoff §9)

1. Voucher 50k funding (ĂnMates vs restaurant)
2. Geofence polygon data source
3. "Review with photo" — 1 or 2 photos minimum
4. Letter rate-limit — total vs per-receiver
5. Apple ID path — capture phone for safety contact?
6. Auto-forgiveness traffic data — available in Phase 1 or V1.1?
7. IAP waitlist email vendor (Mailchimp / Sendgrid)
8. Trust badge "top X%" — fixed threshold or percentile?
9. "Giờ vàng" badge surface logic (without Peak Hour Priority)
10. Coming Soon CTA wording A/B (Đăng ký nhận tin vs Bật notify)

---

## Task Status Tracking

Per task, agent reports back to `/memory/tasks/{TASK-ID}-result.md`:

```markdown
# {TASK-ID} Result

**Status:** in_progress | completed | blocked
**Owner:** Backend | Frontend | QA | Design
**Started:** YYYY-MM-DD
**Completed:** YYYY-MM-DD

## Deliverables
- file paths or screens shipped

## Acceptance criteria met
- [ ] criterion 1
- [ ] criterion 2

## Blockers
- description + needed resolution

## Notes for next task / dependent agents
```

---

## How Architect Assigns Tasks

When user kicks off execution:

1. Architect reviews task-board + cross-cutting blockers (X-* items)
2. Decides W1 batch (BE-001..009, FE-001..005, QA-001)
3. Spawns specialized agent(s) with:
   - Task ID(s)
   - Pointer to `/memory/MEMORY.md`
   - Pointer to relevant context file (`agents/<role>/CONTEXT.md`)
   - Pointer to relevant design references (screen file paths)
4. Agent works in isolation, reports back via task-result file
5. Architect reviews, marks done, unblocks dependents, assigns next batch

---

**Current state:** Scaffold complete. Ready for user to confirm W1 task assignment + resolve cross-cutting blockers.

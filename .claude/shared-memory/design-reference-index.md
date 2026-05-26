---
name: anmates-design-reference-index
description: Maps every screen to its design HTML reference, feature, and conformance task
metadata:
  type: reference
---

# ĂN MATES — Design Reference Index

> **Source:** Handoff §12 Appendix A. Reference files live in `plan/lastest/design/`. Agent code-gen UI must open these files side-by-side and validate against 8 conformance criteria in `design-system.md` §"Visual Conformance Criteria".

> **File naming:** Vietnamese diacritics are escaped with underscore in filenames (e.g., `Ch_n qu_n` = "Chọn quán"). Keep filenames exactly as-is; bash escape spaces.

> **Read FIRST before any code-gen:** `Brand system.html` + `Logo studies.html`.

---

## Screen → Feature → Reference Map

| # | Screen | Feature | Reference path | Priority |
|---|---|---|---|---|
| 01 | Splash | App launch + loader | `plan/lastest/design/01 _ Splash.html` | P0 |
| 02 | Onboard · Chọn quán | Edu carousel 1/3 | `plan/lastest/design/02 _ Onboard _ Ch_n qu_n.html` | P0 |
| 03 | Onboard · Social proof | Edu carousel 2/3 | `plan/lastest/design/03 _ Onboard _ Social proof.html` | P0 |
| 04 | Onboard · Nồi lẩu | Edu carousel 3/3 | `plan/lastest/design/04 _ Onboard _ N_i l_u.html` | P0 |
| 05 | Đăng nhập | Phone + Apple ID | `plan/lastest/design/05 _ _ng nh_p.html` | P0 |
| 06 | OTP | 6-digit OTP entry | `plan/lastest/design/06 _ OTP.html` | P0 |
| 07 | Face verify | Liveness capture | `plan/lastest/design/07 _ Face verify.html` | P0 |
| 08 | Thông tin cá nhân | Profile + auto-derive | `plan/lastest/design/08 _ Th_ng tin c_ nh_n.html` | P0 |
| 09a | Gu ẩm thực | Taste tag picker | `plan/lastest/design/09 _ Gu _m th_c.html` | P0 |
| 09b | Khám phá / Home | Discovery home | `plan/lastest/design/09 _ Kh_m ph_ _Home_.html` | P0 |
| 10a | Tải ảnh lên profile | Photo uploader | `plan/lastest/design/10 _ T_i _nh l_n profile.html` | P0 |
| 10b | Wishlist theo quận | Wishlist (2 sub-tabs) | `plan/lastest/design/10 _ Wishlist _theo qu_n_.html` | P0 |
| 11 | Chi tiết quán | Restaurant detail | `plan/lastest/design/11 _ Chi ti_t qu_n.html` | P0 |
| 12 | Dining swipe | Swipe pool theo quán | `plan/lastest/design/12 _ Dining swipe.html` | P0 |
| 13 | Match | Mutual match screen | `plan/lastest/design/13 _ Match_.html` | P0 |
| 14 | Giao diện chat (Inbox) | Chat list 4 nhóm | `plan/lastest/design/14 _ Giao di_n chat _Inbox_.html` | P0 |
| 15 | Chat · Nồi 42 (locked) | Vibe-locked state | `plan/lastest/design/15 _ Chat _ N_i 42_ _kho_.html` | P0 |
| 16 | Chat · Nồi 72 (unlocked) | Vibe-unlocked + propose card | `plan/lastest/design/16 _ Chat _ N_i 72_ _m_.html` | P0 |
| 17 | Đặt lịch hẹn | Calendar + booking + voucher | `plan/lastest/design/17 _ _t l_ch h_n.html` | P0 |
| 18 | Kèo mới · Lá thư từ Mate | Inbound letter notification | `plan/lastest/design/18 _ K_o m_i _ L_ th_ t_ Mate.html` | P0 |
| 19 | Chi tiết kèo · Lá thư viết tay | Postcard render + reply | `plan/lastest/design/19 _ Chi ti_t k_o _ L_ th_ vi_t tay.html` | P0 |
| 20 | Nhắc kèo · Selfie xuất phát | Live selfie + sticker | `plan/lastest/design/20 _ Nh_c k_o _ Selfie xu_t ph_t.html` | P0 |
| 21 | Live Tracking | Card-style ETA tracker | `plan/lastest/design/21 _ Live Tracking.html` | P0 |
| 22 | Đánh giá ẩn danh | Double-blind review | `plan/lastest/design/22 _ _nh gi_ _n danh.html` | P0 |
| 23 | Tab Mình | Profile + settings entry | `plan/lastest/design/23 _ Tab M_nh.html` | P0 |
| 24 | Trust dashboard | Trust ledger view | `plan/lastest/design/24 _ Trust dashboard.html` | P0 |
| — | Brand system | Tokens, lockup, palette, type | `plan/lastest/design/Brand system.html` | **READ FIRST** |
| — | Logo studies | 4 logo variants + scale | `plan/lastest/design/Logo studies.html` | **READ FIRST** |

---

## Phase 1 SKIP (designs exist for Phase 2)

| # | Screen | Status |
|---|---|---|
| 25 | IAP overview (3 tiers) | SKIP — Phase 2 |
| 26 | IAP Plus | SKIP — Phase 2 |
| 27 | IAP Gold | SKIP — Phase 2 |
| 28 | IAP Ultimate | SKIP — Phase 2 |

Replaced in Phase 1 by Screen N7 "Coming Soon" placeholder (see below).

---

## Screens NEEDING design (no reference yet — design team P0 deliverable for W2)

| # | Screen | Required inputs |
|---|---|---|
| N1 | Profile edit | Drag reorder photos, edit taste tags, edit intro line, toggle "không hiển thị cung/ngũ hành" |
| N2 | Settings | Push categories, location, language, logged-in devices, blocklist |
| N3 | Block / Report | Modal with 5 categories, evidence upload, 2-step confirm |
| N4 | Cancel booking | Trust penalty preview before confirm, optional reason |
| N5 | Delete account + export | 14-day soft-delete confirm, link to zip download |
| N6 | Letter composer | Picker (receiver, restaurant, date) + mood chips + freeform + P.S. + preview |
| N7 | Coming Soon Gói ĂnMates | Placeholder card in Tab Mình + email opt-in modal |

**Blocker risk:** Without these designs, FE-031, FE-050..055, FE-052 are blocked starting W3. Design must commit delivery date.

---

## Screen → Frontend Task Mapping

| Screen | Owner FE Tasks |
|---|---|
| 01 | FE-006 |
| 02–04 | FE-007 |
| 05 | FE-008 |
| 06 | FE-009 |
| 07 | FE-010 |
| 08 | FE-011 |
| 09a | FE-012 |
| 09b | FE-014, FE-015, FE-018 |
| 10a | FE-013 |
| 10b | FE-017 |
| 11 | FE-016 |
| 12 | FE-019, FE-020 |
| 13 | FE-021, FE-057 |
| 14 | FE-022 |
| 15 | FE-023, FE-025, FE-029, FE-030 |
| 16 | FE-024, FE-025 (unlock haptic), FE-026 |
| 17 | FE-034, FE-035, FE-036, FE-037 |
| 18 | FE-032 |
| 19 | FE-033, FE-057 (letter open haptic) |
| 20 | FE-038, FE-039, FE-040, FE-041 |
| 21 | FE-042, FE-043, FE-044, FE-045 |
| 22 | FE-046, FE-047 |
| 23 | FE-048, FE-052 |
| 24 | FE-049 |
| N1 | FE-050 |
| N2 | FE-051 |
| N3 | FE-053 |
| N4 | FE-054 |
| N5 | FE-055 |
| N6 | FE-031 |
| N7 | FE-052 |

---

## Conformance Workflow per Screen (per handoff §A.2)

```
1. Open Brand system.html + Logo studies.html — confirm tokens before any code
2. Code-gen primitives first (Button, Chip, Card, Input, Avatar, VibeRing, TrustBadge)
3. For each screen:
   a. Open reference HTML side-by-side
   b. Walk through 8 conformance criteria from design-system.md
   c. Note current state shown in reference (default | loading | empty | error | success)
   d. Build all 5 states even if reference shows only one
4. Snapshot test: capture gen UI, place beside reference screenshot
5. Save conformance result to /memory/tasks/{FE-TASK-ID}/conformance-<NN>.md with pass/fail
```

---

## Asset & Naming Convention

Per handoff §A.3:

| Layer | Convention | Example |
|---|---|---|
| Screen widget | `Screen<NN><Name>` | `Screen11RestaurantDetail` |
| Route | `/<feature>/<sub>` | `/restaurant/:id`, `/match/:id/chat` |
| Asset folder | `assets/screens/<NN>/` | `assets/screens/11/hero-ramen.jpg` |
| Snapshot | `__snapshots__/<NN>_<state>.png` | `__snapshots__/11_default.png` |

`<NN>` always zero-padded 2-digit. For N1..N7 supplementary screens, use prefix `N` (e.g., `ScreenN6LetterComposer`, `assets/screens/N6/`, `__snapshots__/N6_default.png`).

---

## Quick Reference for Agents

**Frontend agent:**
- Before any code: open the relevant reference file in browser
- During code: keep it side-by-side
- Before PR: snapshot diff + 8-criteria walkthrough

**QA agent:**
- Visual conformance is a P0 acceptance gate
- Each screen must hit all 8 criteria
- Reference HTML is source of truth — when in doubt, diff against it

**Architect:**
- Track design supply for N1..N7 weekly until delivered
- Block dependent FE tasks if design slips past W2

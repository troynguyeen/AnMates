# ĂN MATES — Autonomous Agent Team Memory Index

**Status:** Aligned to Phase 1 handoff v1.0 (25.05.2026) ✅ · Awaiting task kickoff

**Source of truth:** `plan/lastest/handoff/anmate-design-handoff.md` (this file's content derives from it)

**Start here:** [Orchestration README](ORCHESTRATION-README.md) — system + protocol overview

---

## Global Shared Context (Read-Only for Agents)

| File | Purpose |
|---|---|
| [product-summary.md](product-summary.md) | Phase 1 "Ultimate-for-all" strategy, KPIs, scope in/out |
| [architecture-overview.md](architecture-overview.md) | System design, data model, module layout, jobs |
| [api-contracts-summary.md](api-contracts-summary.md) | REST + WebSocket endpoints catalog |
| [domain-glossary.md](domain-glossary.md) | Mate, Best Mate, Kèo, First Date, Lá thư, Vibe meter, Trust |
| [design-system.md](design-system.md) | FINAL color tokens, typography, conformance criteria |
| [design-reference-index.md](design-reference-index.md) | Screen → reference HTML file map (P0 for FE) |
| [shared-decisions.md](shared-decisions.md) | Locked architecture decisions, constraints, risks |

---

## Execution

| File | Purpose |
|---|---|
| [task-board.md](task-board.md) | W1–W8 task scaffold (BE-001..060, FE-001..063, QA-001..028, DS-N1..N7) |
| [ORCHESTRATION-README.md](ORCHESTRATION-README.md) | How the multi-agent system works, memory governance |

---

## Agent Working Memory (Private)

| File | Purpose |
|---|---|
| [agents/flutter/FE-CONTEXT.md](agents/flutter/FE-CONTEXT.md) | Flutter agent role, patterns, collaboration rules |
| [agents/backend/BE-CONTEXT.md](agents/backend/BE-CONTEXT.md) | Go agent role, patterns, optimization, security |
| [agents/qa/QA-CONTEXT.md](agents/qa/QA-CONTEXT.md) | QA agent strategies, bug reports, regression |

---

## Task-Specific Memory (Created per task)

- Scratchpads: `/memory/tasks/{TASK-ID}/`
- Results: `/memory/tasks/{TASK-ID}-result.md`
- Conformance checks: `/memory/tasks/{FE-TASK-ID}/conformance-<NN>.md`

---

## Critical Phase 1 Reminders

- **No IAP. No tiers. No paywall.** Trust Score is measured-only — does NOT gate any feature.
- **All verified Mates get every feature.**
- **Vibe multiplier ×1 for everyone** — log signals for Phase 2 calibration.
- **Chat rooms unlimited** (technical cap 200, not commercial).
- **Letters (Lá thư) bypass Vibe gate** — anti-spam via 3-pending + 14-day cooldown quota.
- **Live Tracking is a CARD, not a map** — geofence + background fetch, no foreground GPS.
- **Selfie xuất phát is mandatory** before depart action — front camera only, no library upload.
- **Geofence is POLYGON, not radius** — needs polygon data source decision + sourcing.
- **PII redaction is server-side** before persist — Vietnamese phone, Zalo, TG, URL patterns.
- **Trust changes always via ledger** — never UPDATE users.trust_score directly.

---

## System Status

| Component | Status | Notes |
|---|---|---|
| Product context | ✅ Aligned to handoff v1.0 | TL;DR through §12 captured |
| Architecture | ✅ Data model + module layout locked | sqlc + Gin + PostGIS |
| API catalog | ✅ Endpoint inventory | Full schemas via OpenAPI (TBD generation) |
| Design system | ✅ FINAL tokens captured | Berry Crush #B8336A, etc. |
| Screen reference | ✅ 27 screens mapped + 7 needed | DS-N1..N7 blocks W3 if not delivered |
| Tasks | ✅ Scaffold ready | 60 BE + 63 FE + 28 QA + 7 design + 8 X-cutting |
| Agent contexts | ✅ Pre-existing, still valid | Minor decision updates needed |
| Execution | ⏳ Awaiting kickoff | User said "agent team trước, task sau" |

---

## Quick Navigation

**Architect (you):**
1. Read [ORCHESTRATION-README.md](ORCHESTRATION-README.md)
2. Monitor [task-board.md](task-board.md) — pick W1 batch when user kicks off
3. Resolve cross-cutting blockers [X-001..X-008]

**Backend Agent:**
1. [BE-CONTEXT.md](agents/backend/BE-CONTEXT.md)
2. [api-contracts-summary.md](api-contracts-summary.md)
3. [shared-decisions.md](shared-decisions.md) §Decisions 1, 3, 4, 6
4. [architecture-overview.md](architecture-overview.md) §Data Model

**Frontend Agent:**
1. [FE-CONTEXT.md](agents/flutter/FE-CONTEXT.md)
2. [design-system.md](design-system.md) — read before any UI work
3. [design-reference-index.md](design-reference-index.md) — open HTML side-by-side
4. `plan/lastest/design/Brand system.html` + `Logo studies.html` — READ FIRST

**QA Agent:**
1. [QA-CONTEXT.md](agents/qa/QA-CONTEXT.md)
2. [task-board.md](task-board.md) §QA section — acceptance per task
3. [design-system.md](design-system.md) §Visual Conformance Criteria

---

## Phase 1 Timeline

| Week | Focus |
|---|---|
| W1–2 | Foundation: schema, auth, OTP, face, profile, photos |
| W3–4 | Discovery + Chat infra: home, restaurant, swipe, WS, PII, Vibe |
| W5 | Match → chat → schedule + Letter sender/receiver |
| W6 | Day-of: selfie, Live Tracking, geofence, auto check-in + Review + Trust ledger |
| W7 | Safety: block, report, cancel, pause, delete + Polish |
| W8 | Hardening: crash budget, perf, store submission |

Soft-launch D1: 1 district (Q1), 200 closed-beta Mates.
Public launch D+14: 5 districts (Q1, Q3, Q5, Q7, Bình Thạnh).

---

**Last updated:** 2026-05-25 (memory re-aligned to handoff v1.0)
**Ready to execute:** Yes, pending user kickoff

# ĂN MATES — Knowledge & Context Index

> **Operational index** (current-task, plan, changelog, resolutions, sessions): see [INDEX.md](INDEX.md).
> **This file** = the static knowledge map: product, architecture, design, decisions, glossary.

**Status:** Aligned to Phase 1 handoff v1.0 (25.05.2026) ✅

**Source of truth:** `plan/lastest/handoff/anmate-design-handoff.md` (content below derives from it)

**Start here:** [ORCHESTRATION-README.md](ORCHESTRATION-README.md) — multi-agent system + protocol overview

---

## Global Shared Context (Read-Only for Agents)

| File | Purpose |
|---|---|
| [product-summary.md](product-summary.md) | Phase 1 "Ultimate-for-all" strategy, KPIs, scope in/out |
| [architecture-overview.md](architecture-overview.md) | System design, data model, module layout, jobs |
| [api-contracts-summary.md](api-contracts-summary.md) | REST + WebSocket endpoints catalog (canonical Phase 1) |
| [api-contracts.md](api-contracts.md) | Live mirror of **implemented** endpoints (coder updates as shipped) |
| [domain-glossary.md](domain-glossary.md) | Mate, Best Mate, Kèo, First Date, Lá thư, Vibe meter, Trust |
| [design-system.md](design-system.md) | FINAL color tokens, typography, conformance criteria |
| [design-reference-index.md](design-reference-index.md) | Screen → reference HTML file map (P0 for FE) |
| [shared-decisions.md](shared-decisions.md) | 15 locked Phase 1 architecture decisions, constraints, risks |
| [decisions.md](decisions.md) | Runtime ADRs (new decisions during agent work) |

---

## Execution

| File | Purpose |
|---|---|
| [task-board.md](task-board.md) | W1–W8 task scaffold (BE-001..060, FE-001..063, QA-001..028, DS-N1..N7) |
| [ORCHESTRATION-README.md](ORCHESTRATION-README.md) | How the multi-agent system works, memory governance |
| [current-task.md](current-task.md) | Active task: goal, status, owner |
| [plan.md](plan.md) | Step-by-step plan for current task |
| [blockers.md](blockers.md) | Open blockers needing escalation |
| [changelog.md](changelog.md) | Append-only event log |

---

## Agent Definitions (Real Files)

| Agent | File | Role |
|---|---|---|
| team-leader | [.claude/agents/team-leader.md](../agents/team-leader.md) | Plans, dispatches coder → qa, resolves blockers |
| coder | [.claude/agents/coder.md](../agents/coder.md) | Implements Go + Flutter changes, updates api-contracts.md |
| qa | [.claude/agents/qa.md](../agents/qa.md) | Runs tests, smoke-tests API, captures screenshots, writes qa-reports |

---

## Confirmed Resolutions & Sessions

| Dir | Purpose |
|---|---|
| [resolutions/](resolutions/) | User-confirmed fixes (R-NNN files) — primary lookup for recurring problems |
| [sessions/](sessions/) | Chronological session logs (YYYY-MM-DD-slug.md) |
| [qa-reports/](qa-reports/) | Per-run QA reports |
| [screenshots/baseline/](screenshots/baseline/) | Approved visual-regression baselines |
| [screenshots/latest/](screenshots/latest/) | Latest screenshots from current run |

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
| Agent contexts | ✅ team-leader / coder / qa active | See `.claude/agents/` |
| Execution | ⏳ Awaiting kickoff | User said "agent team trước, task sau" |

---

## Quick Navigation

**Main assistant / Architect (you):**
1. Read [INDEX.md](INDEX.md) — operational file map + read-order
2. Read [INSTRUCTIONS.md](INSTRUCTIONS.md) — write protocols + query patterns
3. Read [ORCHESTRATION-README.md](ORCHESTRATION-README.md) — multi-agent system overview
4. Skim [resolutions/INDEX.md](resolutions/INDEX.md) — known fixes
5. Monitor [task-board.md](task-board.md) — pick W1 batch when user kicks off
6. Resolve cross-cutting blockers [X-001..X-008]

**Backend (coder agent, Go side):**
1. [.claude/agents/coder.md](../agents/coder.md)
2. [api-contracts-summary.md](api-contracts-summary.md) — canonical endpoint catalog
3. [shared-decisions.md](shared-decisions.md) §Decisions 1, 3, 4, 6
4. [architecture-overview.md](architecture-overview.md) §Data Model
5. Update [api-contracts.md](api-contracts.md) when endpoints ship

**Frontend (coder agent, Flutter side):**
1. [.claude/agents/coder.md](../agents/coder.md)
2. [design-system.md](design-system.md) — read before any UI work
3. [design-reference-index.md](design-reference-index.md) — open HTML side-by-side
4. `plan/lastest/design/Brand system.html` + `Logo studies.html` — READ FIRST

**QA agent:**
1. [.claude/agents/qa.md](../agents/qa.md)
2. [task-board.md](task-board.md) §QA section — acceptance per task
3. [design-system.md](design-system.md) §Visual Conformance Criteria
4. [api-contracts.md](api-contracts.md) — smoke-test target

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

**Last updated:** 2026-05-26 (merged from `memory/` into `shared-memory/`)
**Ready to execute:** Yes, pending user kickoff

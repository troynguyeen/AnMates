---
name: orchestration-system
description: Autonomous multi-agent orchestration for ĂN MATES Phase 1 (Ultimate-for-all)
metadata:
  type: project
---

# ĂN MATES — Autonomous Agent Team Orchestration

## Current Status (2026-05-25)

**Memory aligned to handoff v1.0** ✅ · **Awaiting user kickoff for task assignment**

User-stated workflow: "agent team trước, task sau" — agents/memory first, then task execution.

---

## What Has Been Set Up

### Global Shared Memory (`.claude/shared-memory/*.md`)

> All static-knowledge files (product/architecture/design/decisions) and runtime files (current-task/plan/changelog/blockers) now live together in `.claude/shared-memory/`. See [INDEX.md](INDEX.md) for the full operational file map and [KNOWLEDGE-INDEX.md](KNOWLEDGE-INDEX.md) for the static-knowledge map.

| File | Authoritative |
|---|---|
| [product-summary.md](product-summary.md) | Phase 1 strategy = Ultimate-for-all, NO IAP |
| [architecture-overview.md](architecture-overview.md) | Module layout, data model, jobs |
| [api-contracts-summary.md](api-contracts-summary.md) | Endpoint catalog |
| [domain-glossary.md](domain-glossary.md) | Brand voice + terminology |
| [design-system.md](design-system.md) | FINAL color tokens (Berry Crush #B8336A) |
| [design-reference-index.md](design-reference-index.md) | Screen → HTML reference map |
| [shared-decisions.md](shared-decisions.md) | 15 locked decisions |
| [task-board.md](task-board.md) | W1–W8 scaffold (~160 tasks across BE/FE/QA/Design/X-cutting) |

### Agent Definitions (`.claude/agents/<role>.md`)

- **team-leader** — Plans, dispatches coder → qa, resolves blockers
- **coder** — Implements Go + Flutter changes (both stacks; Riverpod for FE, Gin/sqlc/PostGIS for BE), updates `api-contracts.md` when endpoints ship
- **qa** — Visual conformance, contract testing, regression, screenshot baselines

### Task Memory (`.claude/shared-memory/sessions/` + `qa-reports/`)

- `sessions/YYYY-MM-DD-<slug>.md` — chronological session log per task
- `qa-reports/YYYY-MM-DD-<feature>.md` — per-run QA results
- `resolutions/R-NNN-<slug>.md` — user-confirmed fixes (permanent reference)

---

## System Architecture (Roles)

```
                   ┌──────────────────────┐
                   │  Architect (Claude)  │
                   │  - assigns tasks     │
                   │  - reviews outputs   │
                   │  - resolves blockers │
                   │  - owns memory       │
                   └──────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
       ┌──────────┐   ┌──────────┐    ┌──────────┐
       │ Frontend │   │ Backend  │    │   QA     │
       │ (Flutter)│   │  (Go)    │    │ Tester   │
       └──────────┘   └──────────┘    └──────────┘
              │               │               │
              └───────────────┴───────────────┘
                              │
                     (no direct agent-to-agent
                      communication — all
                      through Architect)
```

**Why no direct agent comms:**
- Prevents context pollution (each agent has bounded context)
- Architect maintains single source of truth
- Memory stays compressed (no raw chat histories shared)

---

## Phase 1 Decisions That Shape Tasks

### Removed from task-board (relative to v0 plan)
- ❌ IAP screens (25–28)
- ❌ Trust Booster / Amnesty / Freeze / Forgiveness
- ❌ Golden Match Pool, Ghost Tracking, Peak Hour Priority
- ❌ Vibe ×1.5, Point ×1.2 multipliers
- ❌ Deal Radar, Cashback 100k
- ❌ Trust gating logic (low-trust → chat limit)
- ❌ Subscription validation endpoints

### Added to task-board (per handoff)
- ✅ Lá thư (Letters) — full sender + receiver flow
- ✅ Selfie xuất phát — liveness + anti-replay
- ✅ Live Tracking — CARD style (not map)
- ✅ Geofence POLYGON checks (not radius)
- ✅ Server-side PII auto-redaction in chat
- ✅ 7-day chat auto-archive job
- ✅ 24h hello window job
- ✅ 15-min booking soft-hold
- ✅ Calendar sync (iOS + Google)
- ✅ Apple ID Sign-in alternative
- ✅ Voice notes in chat
- ✅ Account pause + delete + data export (Nghị định 13/2023)
- ✅ Coming Soon Gói ĂnMates placeholder (email opt-in)

---

## Workflow (When User Kicks Off)

### 1. Architect picks W1 batch
Typical W1 assignment:
- Backend: BE-001 schema, BE-002 OTP, BE-003 JWT, BE-005 face verify, BE-006 profile, BE-008 photos
- Frontend: FE-001 setup, FE-002 theme, FE-003 primitives
- QA: QA-001 test plan
- Design: confirm DS-N1..N7 timeline

### 2. Cross-cutting blockers resolved
Before W1 truly starts, decisions needed:
- X-001 Map provider (Google Maps vs Mapbox)
- X-003 SMS provider + format
- X-004 Crash analytics (Crashlytics vs Sentry)
- X-005 Chat backend (in-house WS confirmed)
- X-006 10 open questions from handoff §9

### 3. Agent receives task
Architect spawns agent with:
- Task ID(s)
- Pointer to `.claude/shared-memory/MEMORY.md`
- Pointer to relevant context file
- Pointer to relevant design references (for FE)
- Cross-cutting decision answers (if affects task)

### 4. Agent executes
- Creates `.claude/shared-memory/tasks/{TASK-ID}/` scratchpad
- Implements per spec
- Writes tests
- Submits PR / change set

### 5. Agent reports back
Writes `.claude/shared-memory/tasks/{TASK-ID}-result.md`:
```markdown
# {TASK-ID} Result

**Status:** completed
**Owner:** Backend
**Deliverables:** files, endpoints, screens
**Acceptance criteria met:** checklist
**Blockers / follow-up:** notes for next task
```

### 6. Architect reviews + unblocks
- Verifies deliverables
- Updates task-board status
- Identifies newly-unblocked tasks
- Assigns next batch

---

## Communication Protocol

### Agent → Architect
**Message format** (lightweight, ≤200 words):
```markdown
## {TASK-ID} update

**State:** in_progress | blocked | done
**What changed:** 1-2 sentences
**Blocker (if any):** specific question + needed input
**Next:** what I'd do next if unblocked
```

### Architect → Agent
**Task assignment:**
```markdown
## {TASK-ID} assignment

**Spec:** see task-board.md → BE-XXX
**Required context:**
  - .claude/shared-memory/api-contracts-summary.md §Auth
  - .claude/shared-memory/shared-decisions.md §Decision 2
**Forbidden context:**
  - IAP-related anything
**Acceptance:** [bulleted criteria]
**Estimated effort:** S | M | L
```

---

## Memory Governance Rules

| Rule | Why |
|---|---|
| Agents read global memory, never write | Single source of truth |
| Only Architect writes global memory | Prevents conflicting updates |
| Agents write own context + task memory | Isolated working state |
| Compress before storing | Memory window discipline |
| Archive completed task memory after 30d | Prevent stale data accumulation |
| Memory references handoff doc | Handoff = canonical source |
| When handoff conflicts memory, handoff wins | Always re-derive from handoff |

---

## Context Pollution Prevention

| Mechanism | Effect |
|---|---|
| No raw chat histories across agents | Each agent starts fresh per task |
| Task memory is ephemeral | Agent X can't see Agent Y's scratchpad |
| Forbidden context lists in task assignments | "Don't load IAP stuff for this task" |
| Architect-mediated message passing | Lightweight summaries, not transcripts |
| Per-task scratchpad isolation | Agent's working memory doesn't leak |

---

## Known Cross-cutting Blockers

| ID | Description | Owner |
|---|---|---|
| X-001 | Map provider (Google Maps vs Mapbox) | Architect + user |
| X-002 | ≥200 venue polygons sourced for launch districts | Ops + Architect |
| X-003 | SMS provider + auto-fill format | Architect + user |
| X-004 | Crash analytics (Crashlytics vs Sentry) | Architect + user |
| X-005 | Chat backend (in-house WS confirmed; Stream optional) | Architect |
| X-006 | 10 open questions from handoff §9 | Product + Architect |
| X-007 | Admin tool scope (separate repo / app) | Architect + user |
| X-008 | Coverage target sign-off | Architect + user |

These should be answered before or during W1 to avoid mid-sprint rework.

---

## Definition of Done (per handoff §11)

A feature is "done" when:
1. UI matches design spec in ALL states (default, loading, empty, error, success)
2. API has OpenAPI doc + integration test
3. Analytics events fire correctly
4. 100% strings via VN dictionary — zero hard-code
5. Accessibility: dynamic type, screen reader labels, contrast ≥AA
6. Regression pass on iPhone 12, iPhone 15, Pixel 7, Samsung A54
7. Crashlytics 0 P0, ≤3 P1 issues pending

---

## Files in this directory

```
.claude/
├── agents/                                # Real agent definitions
│   ├── team-leader.md
│   ├── coder.md
│   └── qa.md
└── shared-memory/                         # All memory (static + runtime) — this dir
    ├── INDEX.md                           # Operational file map + read-order per role
    ├── INSTRUCTIONS.md                    # Directory structure + write protocols
    ├── USAGE.md                           # How to dispatch the agent team
    ├── KNOWLEDGE-INDEX.md                 # Static-knowledge navigation
    ├── ORCHESTRATION-README.md            # This file
    │
    ├── # Static knowledge (read-only for agents) -----
    ├── product-summary.md                 # Phase 1 strategy + KPIs
    ├── architecture-overview.md           # System + data + jobs
    ├── api-contracts-summary.md           # Canonical Phase 1 endpoint catalog
    ├── domain-glossary.md                 # Brand voice + terminology
    ├── design-system.md                   # Tokens + conformance criteria
    ├── design-reference-index.md          # Screen → HTML reference
    ├── shared-decisions.md                # 15 locked Phase 1 decisions
    ├── task-board.md                      # ~160 tasks scaffolded
    │
    ├── # Runtime (mutable) -----
    ├── current-task.md                    # Active task: goal, status, owner
    ├── plan.md                            # Step-by-step plan for current task
    ├── decisions.md                       # Runtime ADRs (new during agent work)
    ├── blockers.md                        # Open blockers needing escalation
    ├── changelog.md                       # Append-only event log
    ├── api-contracts.md                   # Live mirror of implemented endpoints
    │
    ├── resolutions/                       # User-confirmed fixes (R-NNN files)
    ├── sessions/                          # Chronological session logs
    ├── qa-reports/                        # Per-run QA reports
    └── screenshots/{baseline,latest}/     # Visual regression
```

---

## Ready ✅

The system is initialized + aligned to handoff v1.0. Awaiting user signal to:
1. Resolve cross-cutting blockers
2. Kick off W1 task batch
3. Begin 8-week sprint execution

---

**Last updated:** 2026-05-26 (memory + shared-memory merged into single `shared-memory/` dir)

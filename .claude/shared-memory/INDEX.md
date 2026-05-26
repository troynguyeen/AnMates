# Shared Memory Index (Operational)

> **New here?** Read [INSTRUCTIONS.md](INSTRUCTIONS.md) first — it explains the full directory structure, when to write resolutions vs sessions, and Claude's query patterns.
>
> **Looking for static knowledge** (product, architecture, design, locked decisions, glossary)? See [KNOWLEDGE-INDEX.md](KNOWLEDGE-INDEX.md).

This directory is the **single source of truth** for the AnMates agent team — both the static Phase 1 knowledge (product/architecture/design/decisions) and the runtime state (current-task/plan/changelog/resolutions). Every agent reads from here on start and writes back on finish. New agents register themselves below.

## Read Order on Start

Every agent MUST read [INSTRUCTIONS.md](INSTRUCTIONS.md) + this file first, then the role-specific files listed for its role. Main assistant also skims [resolutions/INDEX.md](resolutions/INDEX.md) for known-fix lookup.

| Role | Required reads |
|------|---------------|
| main assistant | `INSTRUCTIONS.md`, `KNOWLEDGE-INDEX.md`, `current-task.md`, `blockers.md`, `changelog.md` (tail), **`resolutions/INDEX.md`** (tag lookup against user's question), `decisions.md`, `shared-decisions.md` |
| team-leader | `KNOWLEDGE-INDEX.md`, `current-task.md`, `plan.md`, `decisions.md`, `shared-decisions.md`, `task-board.md`, `blockers.md`, `changelog.md` (tail), latest `qa-reports/*.md` |
| coder | `current-task.md`, `plan.md`, `decisions.md`, `shared-decisions.md`, `api-contracts.md`, `api-contracts-summary.md`, `architecture-overview.md`, `design-system.md` (FE only), `blockers.md` |
| qa | `current-task.md`, `changelog.md` (tail), `api-contracts.md`, `task-board.md` §QA, `design-system.md` §Visual Conformance Criteria, latest `screenshots/baseline/` |
| any new agent | `current-task.md` + `KNOWLEDGE-INDEX.md` + whatever it needs to do its job |

## Files

### Operational (runtime / mutable)

| File | Purpose | Writers |
|------|---------|---------|
| `INSTRUCTIONS.md` | Full directory structure + write protocols + query patterns | main assistant (when conventions evolve) |
| `USAGE.md` | Human-readable how-to-use guide for the agent team | main assistant (updates when conventions change) |
| `current-task.md` | Active task: goal, status, owner, started_at | team-leader (primary), others update status |
| `plan.md` | Step-by-step plan for current task | team-leader |
| `decisions.md` | Runtime ADRs (new decisions during agent work) | team-leader |
| `changelog.md` | Append-only event log: timestamp, agent, action, files | all agents (append only) |
| `blockers.md` | Open blockers needing escalation | qa, coder (raise); team-leader (resolve) |
| `api-contracts.md` | **Live mirror** of implemented Go endpoints (subset of canonical catalog) | coder (writes when endpoints ship); qa (reads) |

### Static Knowledge (Phase 1, read-only for agents)

| File | Purpose | Writers |
|------|---------|---------|
| `KNOWLEDGE-INDEX.md` | Navigation map for static-knowledge files | main assistant (when knowledge re-aligns to handoff) |
| `ORCHESTRATION-README.md` | Multi-agent system architecture + governance | main assistant |
| `product-summary.md` | Phase 1 "Ultimate-for-all" strategy, KPIs, scope in/out | main assistant (re-derived from handoff) |
| `architecture-overview.md` | System design, data model, module layout, jobs | main assistant |
| `api-contracts-summary.md` | **Canonical** Phase 1 REST + WS endpoint catalog | main assistant |
| `domain-glossary.md` | Mate, Best Mate, Kèo, First Date, Lá thư, Vibe, Trust | main assistant |
| `design-system.md` | FINAL color tokens, typography, conformance criteria | main assistant |
| `design-reference-index.md` | Screen → reference HTML file map | main assistant |
| `shared-decisions.md` | 15 locked Phase 1 architecture decisions | main assistant (only when handoff updates) |
| `task-board.md` | W1–W8 task scaffold (~160 tasks) | main assistant (status); team-leader (assignment) |

### Subdirectories

| Path | Purpose | Writers |
|------|---------|---------|
| `resolutions/INDEX.md` | **Tag + error-keyword index** of confirmed solutions — primary lookup for recurring problems | main assistant |
| `resolutions/R-NNN-<slug>.md` | One file per **user-confirmed** resolution. Permanent reference, sequential ID | main assistant (only after user confirmation) |
| `resolutions/TEMPLATE.md` | Frontmatter + section template for new resolutions | bootstrap (frozen) |
| `sessions/<date>-<slug>.md` | Chronological session log: decisions, deliverables, key facts | main assistant (chat session) |
| `qa-reports/<date>-<feature>.md` | Per-run QA report (test results, screenshots, regressions) | qa |
| `screenshots/baseline/` | Approved baseline images for visual regression | qa (after manual approval) |
| `screenshots/latest/` | Most recent screenshots from this run | qa |

## Write Protocol (mandatory for every agent)

```
ON START:
  1. Read INDEX.md
  2. Read role-required files above
  3. Print to stdout: "📥 Loaded memory: <comma-separated files>"

ON FINISH:
  1. Append to changelog.md: | YYYY-MM-DD HH:MM | <agent> | <action> | <files> |
  2. Update role-specific files (see Files table)
  3. Update current-task.md status: planning | coding | qa | done | blocked
  4. If blocked: append entry to blockers.md with reason + suggested fix
```

## Agent Registry

| Agent | Model | Status |
|-------|-------|--------|
| team-leader | claude-opus-4-7 | active |
| coder | claude-sonnet-4-6 | active |
| qa | claude-sonnet-4-6 | active |

## Session Log Convention

The **main assistant** (the chat session the user is talking to directly — not a Task-spawned sub-agent) must save a session log to `sessions/YYYY-MM-DD-<slug>.md` at the end of any session that produces deliverables. Contents:

- Date, type, operator, user request
- Decisions made (Q&A table if applicable)
- Deliverables produced (paths)
- Key facts to remember
- Open follow-ups

This is for human tracking and review — not consumed by sub-agents.

## Adding a New Agent

1. Create `.claude/agents/<name>.md` with frontmatter (`name`, `description`, `model`, `tools`).
2. Include the **Write Protocol** above verbatim in the agent's instructions.
3. List the agent's required reads in the table at the top of this file.
4. Register the agent in the **Agent Registry** above.
5. No edits to existing agents are needed.

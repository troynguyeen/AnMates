# Session — Bootstrap Agent Team

> **Path migration note (2026-05-26):** This session predates the move from `.claude/agents/shared-memory/` to `.claude/shared-memory/`. Old paths below are historical — current canonical path is `.claude/shared-memory/`. See [../INSTRUCTIONS.md](../INSTRUCTIONS.md).

**Date:** 2026-05-25
**Type:** bootstrap / initial-setup
**Operator:** main assistant (claude-opus-4-7, this Claude Code chat session)
**User request:** "Tạo 1 team agent gồm: 1 team leader Opus 4.7, 1 coder Sonnet 4.6, 1 QA Sonnet 4.6 có chức năng chụp hình tính năng mới. Define role và skill dựa theo structure project."
**Follow-up request:** "Toàn bộ AI Agent structure dùng chung 1 share memory context; thêm agent mới thì trỏ về chung."
**Operational mode:** Autonomous — user prefers velocity, no re-asking once aligned.

---

## Decisions reached (Q&A from brainstorming)

| # | Question | Decision |
|---|----------|----------|
| 1 | Agent location | Project-scoped: `.claude/agents/` (commit-able, tailored to AnMates) |
| 2 | Screenshot method | Playwright via `npx` headless Chromium against `localhost:54180` |
| 3 | Orchestration | Sequential: plan → code → QA → loop (max 3 retries) |
| 4 | Coder scope | Full-stack: Flutter (Dart) + Go (Fiber) |
| 5 | QA responsibilities | All four: run tests, smoke API, write new tests, visual regression |
| 6 | Shared memory location | Project: `.claude/agents/shared-memory/` (persistent, commit-able) |
| 7 | Memory schema | INDEX.md + per-topic files |
| 8 | Read/write protocol | Mandatory read on start, write on finish (enforced by each agent prompt) |

---

## Deliverables produced

### Agents (`.claude/agents/`)
- `team-leader.md` — Opus 4.7, tools `*`, orchestrator
- `coder.md` — Sonnet 4.6, tools `Read, Write, Edit, Bash, Glob, Grep`, full-stack implementer
- `qa.md` — Sonnet 4.6, same tools, Playwright + test runner + visual regression

### Shared memory (`.claude/agents/shared-memory/`)
- `INDEX.md` — schema description, file table, write protocol, agent registry, add-new-agent steps
- `current-task.md` — empty template, status = idle
- `plan.md` — empty template
- `decisions.md` — ADR template, no entries
- `changelog.md` — header + bootstrap row
- `blockers.md` — template, no entries
- `api-contracts.md` — seeded with endpoints from `AnMatesApp/README.md`
- `qa-reports/.gitkeep`
- `screenshots/baseline/.gitkeep`
- `screenshots/latest/.gitkeep`
- `sessions/` — **this directory**, for assistant session logs

### Spec
- `docs/superpowers/specs/2026-05-25-agent-team-design.md` — full design with acceptance criteria

---

## Key architectural facts to remember

1. **Stateless sub-agents.** In Claude Code, every Task-spawned agent starts cold. Persistence is achieved purely via the file-based `shared-memory/` directory — not via any built-in state passing.
2. **Memory protocol is enforced in agent prompts**, not by tooling. Each agent has explicit ON START / ON FINISH instructions.
3. **Agents are independent.** No cross-references between `team-leader.md`, `coder.md`, `qa.md`. Adding a 4th agent only requires:
   - New file under `.claude/agents/`
   - Copy the Write Protocol from `INDEX.md` verbatim
   - Add a row to INDEX.md "Agent Registry"
4. **Tool permissions are least-privilege.** `team-leader: *` (orchestration), `coder` and `qa` share a read/write/edit/bash/glob/grep set (no Task = no nested agents).
5. **QA never edits production code.** Only test directories + shared-memory.
6. **Coder never spawns agents.** No Task tool.
7. **`./start.sh` must be running before QA runs.** QA does not launch the app.

---

## Convention for future session logs

From now on, every assistant session that produces deliverables saves a session log here at:

```
.claude/agents/shared-memory/sessions/YYYY-MM-DD-<slug>.md
```

Slug examples: `bootstrap`, `feature-discover-filter`, `bugfix-auth-refresh`, `refactor-ws-chat`.

Each log should contain:
- Date, type, operator (which Claude session), user request (verbatim if short)
- Decisions made (Q&A table if there was brainstorming)
- Deliverables produced (paths)
- Key facts worth re-reading next time
- Open follow-ups (if any)

---

## Open follow-ups

- [ ] First real task run: dispatch `team-leader` with a small feature to validate the full plan→code→QA loop end-to-end
- [ ] Approve initial baseline screenshots once a feature is verified pass (manual: copy from `screenshots/latest/` to `screenshots/baseline/`)
- [ ] Optional: install Playwright into the project (`npm i -D playwright @playwright/test pixelmatch && npx playwright install chromium`) to avoid first-run download delay

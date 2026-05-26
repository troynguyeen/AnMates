# Session — Usage Guide

> **Path migration note (2026-05-26):** This session predates the move from `.claude/agents/shared-memory/` to `.claude/shared-memory/`. Old paths below are historical — current canonical path is `.claude/shared-memory/`. See [../INSTRUCTIONS.md](../INSTRUCTIONS.md).

**Date:** 2026-05-25
**Type:** documentation
**Operator:** main assistant (claude-opus-4-7)
**User request:** "Hướng dẫn tôi sử dụng ai agent team"

## Decisions

- Saved as a permanent reference doc at `shared-memory/USAGE.md` (not in `sessions/`) because it's evergreen, not session-specific.
- Registered in `INDEX.md` Files table.
- Created this session log as a pointer.

## Deliverables

- `.claude/agents/shared-memory/USAGE.md` — 11-section usage guide (prerequisites, invocation, workflow diagram, monitoring, results review, common scenarios, retry loop, reset, extensibility, troubleshooting, tips)
- `.claude/agents/shared-memory/INDEX.md` — added USAGE.md row

## Key facts

- Entry point is always `team-leader`. User never calls coder/qa directly.
- Two invocation patterns documented: `/agents team-leader "..."` and natural language.
- Real-time monitoring via tail of `current-task.md`, `changelog.md`, `blockers.md`.
- Screenshot baseline promotion is manual — guide shows the `cp` command.
- 5 common scenarios covered with example prompts (feature, bug, backend-only, UI-only, refactor).

## Open follow-ups

- [ ] First real-task dry run to validate the guide against actual behavior

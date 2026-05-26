# AnMates Project Instructions for Claude

## Shared Memory Protocol (MANDATORY every session)

This project maintains a structured project memory at **`.claude/shared-memory/`** — shared by main assistant + sub-agents (team-leader, coder, qa). Treat this as your **first-look context** every session.

### On START of every prompt (before any other action)

1. **Read these files (in this order)**:
   - `.claude/shared-memory/INSTRUCTIONS.md` — **READ FIRST** — full directory structure + write protocols
   - `.claude/shared-memory/current-task.md` — what's active right now + status
   - `.claude/shared-memory/blockers.md` — open issues needing attention
   - `.claude/shared-memory/changelog.md` (tail ~20 lines) — recent activity
   - **`.claude/shared-memory/resolutions/INDEX.md`** — tag + error-keyword lookup for **already-solved problems**

2. **Tag-match user's question** against `resolutions/INDEX.md`:
   - If a tag/error keyword matches → **read the full `R-NNN-<slug>.md` file** before proposing a fix
   - Don't re-investigate problems already solved + user-confirmed

3. **Announce briefly**: "📥 Loaded shared-memory: <key-files>, resolutions matched: <R-NNN or none>" — one line.

### On FINISH of any session producing deliverables

Two paths depending on whether user has **confirmed** the fix works:

**Path A — User confirmed ("done", "đã test ok", "works") → write a RESOLUTION:**

1. Pick next free `R-NNN` from `resolutions/INDEX.md` (zero-padded 3 digits)
2. Copy `resolutions/TEMPLATE.md` → `resolutions/R-NNN-<short-kebab-slug>.md`, fill in frontmatter + all sections
3. Append row to `resolutions/INDEX.md` **Resolutions Table** with tags
4. Add error-keyword mappings if user's error string is grep-able
5. Re-use existing tags from Tag glossary; add new ones only if essential
6. Also write a `sessions/YYYY-MM-DD-<slug>.md` for chronological context (optional but recommended)
7. Append row to `changelog.md` mentioning the new `R-NNN`
8. Update `current-task.md` (status → done, link R-NNN) + `blockers.md` if applicable

**Path B — Work done but NOT user-confirmed yet → write a SESSION log only:**

1. Create `sessions/YYYY-MM-DD-<kebab-slug>.md` with: TL;DR → Root cause → Solution → Files changed → Verification (pending) → Open follow-ups → Key facts
2. Append row to `changelog.md`
3. Update `current-task.md` status

When user later confirms, **migrate the session to a resolution** (Path A steps 1-5) without deleting the session.

### What goes into shared-memory vs auto-memory

- **`.claude/shared-memory/`** (this repo): **project-specific** — code paths, config gotchas, decisions about AnMates, session history. Survives across users/machines (committed to git).
- **`~/.claude/projects/.../memory/`** (auto-memory): **cross-project user preferences** — how the user likes to work, their role, feedback patterns. Not shared with collaborators.

When in doubt about project context → write to shared-memory. When in doubt about user preference → write to auto-memory.

---

## Project Tech Stack Quick Reference

- **Mobile/Web UI**: Flutter (Dart, `anmates_flutter/`). Flutter binary at `/opt/homebrew/bin/flutter`.
- **Backend**: Go Fiber (`anmates-api/`), Postgres via pgxpool.
- **Auth**: Firebase Phone OTP → Firebase ID token → Go backend issues JWT.
- **Firebase project**: `anmates-studio` (Blaze plan, Phone provider enabled).
- **Local dev**:
  - Backend: `cd AnMatesApp && ./start.sh` → API at `:8080`, Flutter web at `:54180`
  - **Web access MUST use `http://127.0.0.1:54180`** (not `localhost`) for Firebase reCAPTCHA to validate — see `sessions/2026-05-26-firebase-phone-otp-resolved.md`.

## Agent Team

For multi-step features spanning Flutter + Go, dispatch via `team-leader` agent (it orchestrates `coder` + `qa`). For single-file edits or quick fixes, main assistant handles directly. See `.claude/shared-memory/USAGE.md`.

## Velocity Preferences

- User wants velocity: assign permissions, pick sensible defaults, don't re-ask after alignment.
- Avoid asking clarifying questions when project context (shared-memory) + Firebase/Flutter docs give a clear answer.
- Refactor proactively when touching a file: deprecated APIs (`withOpacity` → `withValues(alpha:)`), hardcoded values that belong in config.

# AnMates Agent Team — Usage Guide

How to use the 3-agent team (`team-leader` + `coder` + `qa`) to ship features in the AnMates project.

---

## 1. Prerequisites (one-time)

```bash
# Make sure the app is running BEFORE you ask QA to screenshot anything:
cd AnMatesApp && ./start.sh
# This starts Go API at :8080 and Flutter web at :54180
```

Optional (skip first-run delay for Playwright):
```bash
cd /Users/thanhit/Downloads/AnMates
npm i -D playwright pixelmatch
npx playwright install chromium
```

---

## 2. The entry point: always invoke `team-leader`

You **never** call `coder` or `qa` directly. The team-leader orchestrates them.

### Two ways to invoke

**Option A — Slash command (preferred):**
```
/agents team-leader "Add a 'Block user' button on the profile detail view that calls POST /api/users/:id/block"
```

**Option B — Natural language:**
```
"Use the team-leader agent to add a Block user feature."
```

Claude Code will dispatch the team-leader sub-agent automatically. The leader reads shared memory, plans, dispatches coder → qa, and reports back.

---

## 3. What happens behind the scenes

```
You → team-leader
        ├─ Reads shared-memory/INDEX.md + current-task.md + plan.md
        ├─ Asks you 1-3 clarifying questions (if needed)
        ├─ Writes plan.md
        ├─ Updates current-task.md (status: coding)
        ├─ Dispatches coder
        │     └─ coder reads plan, implements, runs `flutter analyze` + `go build`
        │        updates api-contracts.md (if endpoints changed) + changelog.md
        ├─ Updates current-task.md (status: qa)
        ├─ Dispatches qa
        │     └─ qa reads changelog, runs flutter test + go test
        │        smoke-tests API endpoints, captures Playwright screenshots
        │        writes qa-reports/YYYY-MM-DD-<feature>.md
        │        updates changelog.md
        └─ If qa PASS → reports done; if FAIL → loops back to coder (max 3 retries)
```

---

## 4. Monitoring progress (look at shared-memory)

While the team is working, you can inspect these files in real time:

| File | What you see |
|------|--------------|
| `shared-memory/current-task.md` | What they're doing right now |
| `shared-memory/plan.md` | The current plan |
| `shared-memory/changelog.md` | Append-only audit log of every step |
| `shared-memory/blockers.md` | Stuck on something? |
| `shared-memory/qa-reports/` | QA results once finished |
| `shared-memory/screenshots/latest/` | Newest screenshots |

Tip: keep the changelog open in a side panel for a live activity feed.

---

## 5. Reviewing results

After team-leader reports done, check:

1. **The QA report** at `shared-memory/qa-reports/<date>-<feature>.md`
   - Verdict (PASS / FAIL)
   - Test counts, API smoke results, visual diff %
2. **Screenshots** at `shared-memory/screenshots/latest/<feature>-NN-<step>.png`
3. **Changed files** — `git status` and `git diff` show what coder touched
4. **API contract changes** — `shared-memory/api-contracts.md` if endpoints moved

### Promoting screenshots to baseline (manual approval)

After you visually verify a screenshot is correct, promote it:
```bash
cp .claude/agents/shared-memory/screenshots/latest/<feature>-01-home.png \
   .claude/agents/shared-memory/screenshots/baseline/
```
Next QA run will compare against this baseline.

---

## 6. Common scenarios

### Add a feature (full-stack)
```
/agents team-leader "Add a 'Super Like' button on Discover that calls POST /api/matches/:id/super-like and shows a flame animation"
```

### Bug fix
```
/agents team-leader "Fix: refresh token isn't being saved after login — users get logged out on app reload"
```

### Backend-only change
```
/agents team-leader "Add a rate limit middleware: max 10 login attempts per IP per minute, return 429"
```
(coder skips Flutter, qa skips screenshots, focuses on API smoke + go test)

### UI-only tweak
```
/agents team-leader "Make the match card corner radius 16px instead of 8px, and add a 1px border in #E5E5E5"
```
(coder skips Go, qa focuses on visual regression against baseline)

### Refactor
```
/agents team-leader "Refactor lib/services/api_client.dart to use Dio instead of http package — same public API, no behavior change"
```
(qa heavy on regression test + visual diff)

---

## 7. When QA loops back

If qa reports FAIL, team-leader re-dispatches coder with the blocker. You don't have to do anything — just watch `changelog.md` and `blockers.md`.

Cap is **3 retries**. After 3 failed loops, team-leader stops, sets `current-task.md` status to `blocked`, and asks you for direction.

---

## 8. Resetting state between tasks

The team automatically updates `current-task.md` to `done` when finished. To start clean:

```bash
# Clear latest screenshots before next run (optional)
rm -f .claude/agents/shared-memory/screenshots/latest/*.png

# Archive an old QA report you don't need
# (everything in qa-reports/ stays as historical record by default)
```

---

## 9. Adding a new agent later

Example: add a `designer` agent that creates Figma-style mockups before coder starts.

1. Create `.claude/agents/designer.md` with frontmatter:
   ```yaml
   ---
   name: designer
   description: Creates UI mockups before implementation
   model: sonnet
   tools: Read, Write, Edit, Bash
   ---
   ```
2. Copy the **Write Protocol** block from `INDEX.md` into the agent's instructions (ON START / ON FINISH).
3. Edit `INDEX.md`:
   - Add a row to the **Read Order** table
   - Add a row to the **Agent Registry** table
4. Tell team-leader about it in the next request: "Use designer before coder for this UI task."

No edits to `team-leader.md`, `coder.md`, or `qa.md` needed.

---

## 10. Troubleshooting

| Symptom | Fix |
|---------|-----|
| QA says "app not reachable at :54180" | Run `./start.sh` first |
| `npx playwright` fails on first run | Run `npx playwright install chromium` manually |
| Coder added scope the plan didn't have | Check `decisions.md` — they should have logged it. If unjustified, ask team-leader to revert |
| Stuck in retry loop | Read `blockers.md` — usually a flaky test or env issue. Resolve and re-run |
| Visual regression false positive | Threshold is 1% pixel diff. If layout intentionally changed, promote new screenshot to baseline |
| Sub-agent didn't read memory | Check changelog.md — every agent prints `📥 Loaded memory: ...` on start. If missing, the agent file's prompt may have been edited |

---

## 11. Tips

- **Be specific in the request.** "Add login" → team-leader will ask 3 questions. "Add login that validates email regex and shows red error text below the field" → leader plans directly.
- **Trust the team-leader's plan.** If it asks a clarifying question, the question saves time later.
- **Use the changelog as a session journal.** Every PR-worthy change has a trail.
- **Don't edit production code in parallel** while a task is running — coder may overwrite. Wait for done.
- **Session logs in `sessions/`** are written by the main chat assistant (the one you're talking to right now), separate from the team's changelog. Both are useful — changelog = atomic events, session log = human-readable summary.

# Changelog

Append-only event log. Every agent appends one row on finish.

| Timestamp (UTC) | Agent | Action | Files touched |
|-----------------|-------|--------|---------------|
| 2026-05-25 | main-assistant (bootstrap) | initialize shared-memory directory | INDEX.md, current-task.md, plan.md, decisions.md, blockers.md, api-contracts.md, changelog.md |
| 2026-05-25 | main-assistant (bootstrap) | create agent definitions | .claude/agents/team-leader.md, coder.md, qa.md |
| 2026-05-25 | main-assistant (bootstrap) | write design spec | docs/superpowers/specs/2026-05-25-agent-team-design.md |
| 2026-05-25 | main-assistant (bootstrap) | add sessions/ convention | sessions/2026-05-25-bootstrap.md, INDEX.md |
| 2026-05-25 | main-assistant | write usage guide | USAGE.md, INDEX.md, sessions/2026-05-25-usage-guide.md |
| 2026-05-25 22:50 | team-leader | diagnose INVALID_APP_CREDENTIAL Firebase Phone Auth; root cause = Firebase Console config (SHA Android / APNs iOS / authorized domains Web); raise BLOCKER-001 for user action | current-task.md, plan.md, blockers.md, sessions/2026-05-25-fix-invalid-app-credential.md |
| 2026-05-25 23:25 | main-assistant | install gcloud CLI, generate debug keystore, register Android SHA-1/SHA-256 to Firebase, re-download google-services.json, audit phone OTP readiness via Identity Toolkit REST API (Blaze ✅, phone provider ✅, FCM ✅, VN-only SMS region ✅); iOS APNs/entitlements remain user manual | ~/.android/debug.keystore, android/app/google-services.json, sessions/2026-05-25-otp-real-phone-checklist.md |

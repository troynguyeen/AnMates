# API Contracts

Shared schema between **coder** (who implements endpoints) and **qa** (who smoke-tests them). Updated by coder whenever an endpoint is added/changed; read by qa to build curl-based smoke tests.

Base URL: `http://localhost:8080`

## Endpoints (baseline — copied from AnMatesApp/README.md)

| Method | Path | Auth | Request | Response (200) | Notes |
|--------|------|------|---------|----------------|-------|
| POST | `/api/auth/register` | none | `{email, password, name}` | `{access_token, refresh_token}` | |
| POST | `/api/auth/login` | none | `{email, password}` | `{access_token, refresh_token}` | |
| POST | `/api/auth/refresh` | refresh | `{refresh_token}` | `{access_token}` | |
| GET  | `/api/profile` | access | — | `{id, email, name, ...}` | |
| PUT  | `/api/profile` | access | `{name?, bio?, ...}` | `{id, email, name, ...}` | |
| GET  | `/api/matches` | access | — | `[{id, user, ...}, ...]` | |
| POST | `/api/matches/:id/accept` | access | — | `{ok: true}` | |
| GET  | `/api/conversations` | access | — | `[{id, peer, last_message}, ...]` | |
| GET  | `/api/matches/:id/messages` | access | — | `[{from, body, ts}, ...]` | |
| WS   | `/ws/chat/:matchId` | access (query token) | — | bidirectional `{type, payload}` | |

## Update Protocol

When **coder** adds or modifies an endpoint:
1. Add/update its row in the table above.
2. If response shape is complex, attach JSON example below in `### Schema details`.
3. Bump the `Last updated` line at the bottom.

## Schema details

_(Empty — add JSON examples when needed.)_

---
**Last updated:** 2026-05-25 (bootstrap)

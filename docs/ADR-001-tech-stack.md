# ADR-001: Backend Tech Stack Selection

- **Status:** Accepted
- **Date:** 2026-05-22
- **Deciders:** Solution Architect (.NET), DevOps
- **Supersedes:** Original plan referencing NestJS/Go

## Context

AnMates MVP launches to 50 curated users in HCMC, with a scale target of 1M MAU / 20k CCU within 18 months. Team is 2 engineers (1 SA fluent in .NET, 1 DevOps). Original plan specified NestJS/Go which the team has no production experience with. Pivoting backend platform mid-project would delay launch by an estimated 4-6 weeks.

## Decision

We adopt **ASP.NET Core 9** as the backend runtime, structured as a **Modular Monolith** with strict bounded contexts, deployable as a single container today and splittable into microservices when load metrics demand it.

### Stack Summary

| Concern | Choice | Rationale |
|---|---|---|
| Runtime | ASP.NET Core 9 (LTS path: 8) | Team expertise; equal performance to Go/Node for our workload |
| Architecture | Modular Monolith (Wishlist, Match, Chat, Escrow, Identity modules) | Single deploy unit for 50 users; modules have own DI scopes & namespaces for clean future extraction |
| ORM | EF Core 9 + Npgsql + NetTopologySuite | Native PostGIS support via `geography(Point, 4326)` |
| Realtime | SignalR with Redis backplane | Built into .NET; backplane configured day-1 so horizontal scaling needs no code change |
| Background Jobs | Hangfire (PostgreSQL storage) | Avoids new infra (no RabbitMQ); dashboard included; PG-backed survives restarts |
| Auth | ASP.NET Core Identity + JWT (access 15m) + Refresh Token (rotating, 30d) | Self-hosted; password hashing & lockout baked in |
| Database | PostgreSQL 16 + PostGIS 3.4 (single instance MVP; primary+replica from Phase 2) | PostGIS is the only realistic VN-self-host option for geo workloads |
| Cache & Rate Limit Backend | Redis 7 (single instance MVP, Sentinel from Phase 2) | Doubles as SignalR backplane; persists token-bucket state |
| Object Storage | MinIO (S3-compatible) | Self-host; swap to S3/R2/Wasabi later by changing endpoint only |
| Reverse Proxy / TLS | Caddy 2 | Auto Let's Encrypt; HTTP/2 + HTTP/3; one-line config vs Nginx |
| Observability | Serilog → Loki, Grafana, Prometheus, Sentry self-host | All self-hosted; free tier sufficient for MVP |
| Container Runtime | Docker + Docker Compose (MVP), migrate to k3s/Talos at ~50k users | Compose handles 50 users; k3s when we need orchestration |
| CI/CD | GitHub Actions → SSH deploy to VPS | Free for private repo; no extra service |
| Payments | MoMo Business + ZaloPay (webhook receivers) | Hold escrow with licensed providers — we do not handle funds directly |
| Push | Firebase Cloud Messaging (free tier only) | Only carve-out from "self-host everything" — Apple/Google monopoly on push transport |

## Rate Limiting Policy

- **Limit:** 1 request per 2 seconds per principal (0.5 RPS sustained)
- **Burst:** 5 tokens
- **Partition key:** authenticated user ID; fallback to client IP (extracted via `ForwardedHeaders` from Caddy)
- **Backend:** Redis token-bucket via atomic Lua script
- **Response on exceed:** `HTTP 429` with `Retry-After` (seconds) and `X-RateLimit-*` headers
- **Bypass:** internal `/health`, `/metrics`, SignalR negotiate (limited separately at 1 RPS)

## Consequences

### Positive
- Team ships day-1 in a stack they know cold
- SignalR + Identity + Hangfire + EF Core eliminate ~30% of infrastructure decisions we'd otherwise make
- Modular monolith preserves microservices migration path without paying the cost now
- All persistence layers (PG, Redis, MinIO) are self-host and migrate-friendly

### Negative
- No managed services means DevOps owns backup, patching, and HA. Mitigated by Phase-2 plan to evaluate managed PG (Supabase / Neon) once budget allows.
- SignalR locks realtime to the .NET ecosystem. Acceptable: Flutter has solid `signalr_netcore` client.
- LLM features (Trip Planner, AI moderation) deferred — not in MVP scope.

## Scale-Up Triggers

| Trigger | Action |
|---|---|
| > 500 DAU sustained | Move Postgres to dedicated VPS; add daily streaming WAL backup |
| > 2k CCU on chat | Promote SignalR to its own service tier; Redis Sentinel |
| > 5k DAU | PG read replica for matching queries |
| > 50k DAU | Migrate Compose → k3s, extract Chat + Match into separate deployments |
| > 200k DAU | Multi-region; sharded PG; managed Kafka for events |

## Open Items

- Confirm VPS provider (Hetzner FSN1 vs AWS Singapore vs VNG) — DevOps to benchmark VN latency in Sprint 1.
- Confirm whether mobile is Flutter (per SCRUM doc) or Swift (per existing repo). This ADR does not block on it.

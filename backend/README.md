# AnMates Backend

ASP.NET Core 9 modular monolith. See [ADR-001](../docs/ADR-001-tech-stack.md) for stack rationale.

## Layout

```
backend/
├── AnMates.sln
├── Dockerfile                     # multi-stage, non-root, alpine runtime
├── Directory.Build.props          # nullable on, warnings-as-errors, .NET 9
└── src/
    ├── AnMates.Domain/            # entities + enums, no infra deps
    ├── AnMates.Infrastructure/    # EF Core DbContext, PostGIS config, migrations
    └── AnMates.Api/               # composition root, controllers, SignalR hubs
        └── RateLimiting/          # Redis token-bucket middleware
```

## Local dev

```bash
# 1. Start infra (postgres + redis + minio) from the infra/ folder
cd ../infra
cp .env.example .env && $EDITOR .env
docker compose up -d postgres redis minio

# 2. Apply migrations
cd ../backend
dotnet tool restore
dotnet ef database update --project src/AnMates.Infrastructure --startup-project src/AnMates.Api

# 3. Run the API
dotnet run --project src/AnMates.Api
# → http://localhost:8080/swagger
```

## Production build

```bash
# Compose the whole stack
cd infra
docker compose --env-file .env up -d --build
```

## Generate a migration

```bash
dotnet ef migrations add <Name> \
  --project src/AnMates.Infrastructure \
  --startup-project src/AnMates.Api \
  --output-dir Migrations
```

## Verifying the rate limiter

The middleware enforces 1 request per 2 seconds (burst 5) per principal.
Quick smoke test with the swagger health endpoint excluded (it's on the bypass list);
hit any controller route instead:

```bash
# Send 7 rapid requests; expect 5 × 200 then 2 × 429 with Retry-After.
for i in 1 2 3 4 5 6 7; do
  curl -s -o /dev/null -w "HTTP %{http_code}  Retry-After=%header{Retry-After}\n" \
    http://localhost:8080/api/me
done
```

## Module boundaries

Each business module lives in its own folder under `AnMates.Api/Modules/*` (added
in subsequent sprints): `Identity`, `Wishlist`, `Match`, `Chat`, `Escrow`. Modules
talk to each other through application services in `AnMates.Application` (added in
Sprint 2) — never via direct DbContext usage across module boundaries. This keeps
the future extraction into microservices cheap.

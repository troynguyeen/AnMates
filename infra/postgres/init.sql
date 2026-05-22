-- Bootstrap script: runs once on first container start, before EF Core migrations.
-- EF Core handles tables; this file only enables extensions and tunes DB-level settings.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- fuzzy text search on place names
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuid()

-- Application role with least privilege; EF migrations run as POSTGRES_USER (superuser)
-- on first deploy, then we revoke and use the app role for runtime.
-- For MVP simplicity we keep one role; revisit at Phase 2.

-- Default to UTC.  All timestamps in tables use `timestamptz`.
ALTER DATABASE anmates SET timezone TO 'UTC';

-- Better full-text defaults for Vietnamese place names.
ALTER DATABASE anmates SET default_text_search_config TO 'simple';

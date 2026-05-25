-- 003_onboarding.sql — extend user profile + tastes + photos + identity_verifications
-- for the Phase 1 onboarding flow.

-- Extended profile fields on users.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS nickname             text,
  ADD COLUMN IF NOT EXISTS dob                  date,
  ADD COLUMN IF NOT EXISTS personality_score    int  NOT NULL DEFAULT 50
    CHECK (personality_score >= 0 AND personality_score <= 100),
  ADD COLUMN IF NOT EXISTS zodiac               text,
  ADD COLUMN IF NOT EXISTS ngu_hanh             text,
  ADD COLUMN IF NOT EXISTS numerology           text,
  ADD COLUMN IF NOT EXISTS show_derived_public  boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS onboarding_step      text NOT NULL DEFAULT 'pending'
    CHECK (onboarding_step IN
      ('pending','face_verified','profile','tastes','photos','done'));

-- Tastes (single row per user — cuisine + vibe tags).
CREATE TABLE IF NOT EXISTS user_tastes (
  user_id       uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  cuisine_tags  text[] NOT NULL DEFAULT '{}',
  vibe_tags     text[] NOT NULL DEFAULT '{}',
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- Photos (max 3 enforced at handler level; one row per photo).
CREATE TABLE IF NOT EXISTS user_photos (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url            text NOT NULL,                       -- may be data: URL for Phase 1
  is_main        boolean NOT NULL DEFAULT false,
  order_idx      int     NOT NULL DEFAULT 0,
  nsfw_score     real,                                -- nullable in Phase 1 (Phase 2 fills)
  face_detected  boolean,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_photos_user_order
  ON user_photos(user_id, order_idx);

-- Only one main photo per user.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_photos_main_per_user
  ON user_photos(user_id) WHERE is_main = true;

-- Identity verifications (Phase 1: liveness only, no embedding storage).
CREATE TABLE IF NOT EXISTS identity_verifications (
  user_id         uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  verified_at     timestamptz NOT NULL DEFAULT now(),
  liveness_score  real        NOT NULL DEFAULT 1.0,
  last_redo_at    timestamptz
);

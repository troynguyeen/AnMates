-- 001_initial.sql — bootstrap schema for AnMates MVP.
-- Single migration: tables + indexes + constraints in one file.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email         text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  name          text NOT NULL,
  avatar_url    text,
  bio           text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE wishlists (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  food_name     text NOT NULL,
  food_category text NOT NULL CHECK (food_category IN
    ('bun','pho','com','lau','bbq','cafe','trang_mieng','other')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, food_name)
);
CREATE INDEX idx_wishlists_user ON wishlists(user_id);
CREATE INDEX idx_wishlists_food_name ON wishlists(food_name);
CREATE INDEX idx_wishlists_category ON wishlists(food_category);

CREATE TABLE matches (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'accepted'
    CHECK (status IN ('pending','accepted','blocked')),
  score       double precision NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (user_a_id <> user_b_id)
);
CREATE INDEX idx_matches_user_a ON matches(user_a_id);
CREATE INDEX idx_matches_user_b ON matches(user_b_id);
CREATE UNIQUE INDEX uq_matches_pair ON matches(
  LEAST(user_a_id, user_b_id),
  GREATEST(user_a_id, user_b_id)
);

CREATE TABLE messages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id   uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    text NOT NULL,
  msg_type   text NOT NULL DEFAULT 'text'
    CHECK (msg_type IN ('text','image','system')),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_messages_match_created ON messages(match_id, created_at DESC);

CREATE TABLE noi_lau_progress (
  match_id      uuid PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
  points        int  NOT NULL DEFAULT 0,
  level         int  NOT NULL DEFAULT 1,
  last_activity timestamptz
);

CREATE TABLE refresh_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

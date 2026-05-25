-- 002_phone_auth.sql — add phone / Firebase UID auth; make email optional.

ALTER TABLE users
  ALTER COLUMN email         DROP NOT NULL,
  ALTER COLUMN password_hash DROP NOT NULL,
  ADD  COLUMN phone          text UNIQUE,
  ADD  COLUMN firebase_uid   text UNIQUE;

-- Ensure at least one identity exists (email OR phone).
ALTER TABLE users
  ADD CONSTRAINT users_identity_check
  CHECK (email IS NOT NULL OR phone IS NOT NULL);

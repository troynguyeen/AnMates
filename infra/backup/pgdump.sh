#!/bin/sh
# Nightly logical backup. Keeps last 14 days locally; ship off-host with restic
# from the host cron — do not bake remote creds into this container.

set -eu

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="/backups/anmates-${STAMP}.sql.gz"

pg_dump \
  --format=custom \
  --no-owner \
  --no-privileges \
  --compress=6 \
  --file="/tmp/anmates-${STAMP}.dump"

gzip -c "/tmp/anmates-${STAMP}.dump" > "$OUT"
rm -f "/tmp/anmates-${STAMP}.dump"

# Verify the dump is readable before we count this run as a success.
pg_restore --list "$OUT" > /dev/null

# Retention: 14 days.
find /backups -type f -name 'anmates-*.sql.gz' -mtime +14 -delete

echo "$(date -u +%FT%TZ) backup ok: $OUT ($(stat -c%s "$OUT") bytes)"

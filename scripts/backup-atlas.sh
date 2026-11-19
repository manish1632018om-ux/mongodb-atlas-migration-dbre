#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found."
  echo "Run: cp .env.example .env"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

: "${ATLAS_URI:?ATLAS_URI is required}"
: "${ATLAS_USERNAME:?ATLAS_USERNAME is required}"
: "${SOURCE_DATABASE:?SOURCE_DATABASE is required}"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"

BACKUP_PATH="$(cd "$BACKUP_DIR" && pwd)"
ARCHIVE="${SOURCE_DATABASE}.archive.gz"

read -rsp "Enter Atlas database password: " ATLAS_PASSWORD
export ATLAS_PASSWORD
echo

echo "Starting Atlas backup for database: $SOURCE_DATABASE"

sudo docker run --rm \
  --network host \
  --user 0 \
  -e ATLAS_URI \
  -e ATLAS_USERNAME \
  -e SOURCE_DATABASE \
  -e ATLAS_PASSWORD \
  -v "$BACKUP_PATH:/backup" \
  mongo:8.0 \
  sh -c '
    mongodump \
      --uri="$ATLAS_URI" \
      --username="$ATLAS_USERNAME" \
      --password="$ATLAS_PASSWORD" \
      --authenticationDatabase=admin \
      --db="$SOURCE_DATABASE" \
      --archive="/backup/'"$ARCHIVE"'" \
      --gzip
  '

unset ATLAS_PASSWORD

echo "Backup completed: $BACKUP_PATH/$ARCHIVE"
ls -lh "$BACKUP_PATH/$ARCHIVE"

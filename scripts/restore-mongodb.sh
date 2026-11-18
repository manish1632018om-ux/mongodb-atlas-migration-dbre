#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found."
  exit 1
fi

set -a
source .env
set +a

: "${SOURCE_DATABASE:?SOURCE_DATABASE is required}"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_PATH="$(cd "$BACKUP_DIR" && pwd)"
ARCHIVE="${SOURCE_DATABASE}.archive.gz"

if [[ ! -f "$BACKUP_PATH/$ARCHIVE" ]]; then
  echo "ERROR: Backup archive not found."
  echo "$BACKUP_PATH/$ARCHIVE"
  exit 1
fi

echo "Restoring database: $SOURCE_DATABASE"
echo "Destination: atlas-migration-lab replica set"

sudo docker run --rm \
  --network atlas-migration-lab_mongo-net \
  --user 0 \
  -v "$BACKUP_PATH:/backup:ro" \
  mongo:8.0 \
  mongorestore \
    --uri="mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0" \
    --archive="/backup/$ARCHIVE" \
    --gzip \
    --stopOnError

echo "Restore command completed successfully."

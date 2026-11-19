#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Starting MongoDB replica set..."
docker compose -f docker/compose.yaml up -d

echo "Waiting for MongoDB containers..."

for node in mongo1 mongo2 mongo3; do
  container="atlas-migration-lab-${node}-1"
  ready=false

  for attempt in {1..30}; do
    echo "Checking $node (attempt $attempt/30)"

    if docker exec "$container" \
      mongosh --quiet --eval 'db.adminCommand({ping:1}).ok' \
      2>/dev/null | grep -qx 1; then
      ready=true
      break
    fi

    sleep 2
  done

  if [[ "$ready" != true ]]; then
    echo "ERROR: $node did not become ready"
    exit 1
  fi
done

echo "Initializing replica set..."

docker exec atlas-migration-lab-mongo1-1 \
  mongosh --quiet --eval '
    const existing = db.getSiblingDB("local").system.replset.findOne();

    if (!existing) {
      rs.initiate({
        _id: "rs0",
        members: [
          { _id: 0, host: "mongo1:27017", priority: 2 },
          { _id: 1, host: "mongo2:27017", priority: 1 },
          { _id: 2, host: "mongo3:27017", priority: 1 }
        ]
      });
    }
  '

echo "Waiting for replica set to become healthy..."

for attempt in {1..60}; do
  if docker exec atlas-migration-lab-mongo1-1 \
    mongosh --quiet --eval '
      const members = rs.status().members;
      const primary = members.filter(m => m.stateStr === "PRIMARY" && m.health === 1);
      const secondary = members.filter(m => m.stateStr === "SECONDARY" && m.health === 1);

      if (primary.length === 1 && secondary.length === 2) {
        print("READY");
      }
    ' 2>/dev/null | grep -qx READY; then

    echo "PASS: Replica set is healthy"
    exit 0
  fi

  echo "Waiting for election and replication (attempt $attempt/60)"
  sleep 2
done

echo "ERROR: Replica set did not become healthy"
exit 1

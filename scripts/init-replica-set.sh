#!/usr/bin/env bash
set -euo pipefail

NODES=(mongo1 mongo2 mongo3)
PREFIX="atlas-migration-lab"

echo "Checking MongoDB readiness..."

for node in "${NODES[@]}"; do
  container="${PREFIX}-${node}-1"
  ready=false

  for attempt in {1..30}; do
    if timeout 10s sudo -n docker exec "$container" \
      mongosh --quiet --eval 'print(db.adminCommand({ping:1}).ok)' \
      2>/dev/null | grep -qx 1; then
      ready=true
      break
    fi
    sleep 2
  done

  if [[ "$ready" != true ]]; then
    echo "ERROR: $node is not ready"
    echo "Check Docker access and container logs."
    exit 1
  fi

  echo "$node is ready"
done

echo "Checking replica-set configuration..."

timeout 20s sudo -n docker exec "${PREFIX}-mongo1-1" \
  mongosh --quiet --eval '
    const existing = db.getSiblingDB("local").system.replset.findOne();

    if (existing) {
      print("Replica set already initialized");
    } else {
      printjson(rs.initiate({
        _id: "rs0",
        members: [
          { _id: 0, host: "mongo1:27017", priority: 2 },
          { _id: 1, host: "mongo2:27017", priority: 1 },
          { _id: 2, host: "mongo3:27017", priority: 1 }
        ]
      }));
    }
  '

echo "Initialization check completed."

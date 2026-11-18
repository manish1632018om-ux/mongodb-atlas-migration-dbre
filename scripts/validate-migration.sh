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

echo "=================================="
echo "MongoDB Migration Validation"
echo "Database: $SOURCE_DATABASE"
echo "=================================="

sudo docker exec \
  -e SOURCE_DATABASE="$SOURCE_DATABASE" \
  atlas-migration-lab-mongo1-1 \
  mongosh --quiet --eval '
    const dbName = process.env.SOURCE_DATABASE;
    const d = db.getSiblingDB(dbName);

    const collections = d.getCollectionNames().sort();

    if (collections.length === 0) {
      print("ERROR: No collections found.");
      quit(1);
    }

    let total = 0;

    collections.forEach(function(name) {
      const count = d.getCollection(name).countDocuments({});
      const indexes = d.getCollection(name).getIndexes();

      print(
        name +
        " | DOCUMENTS => " + count +
        " | INDEXES => " + indexes.length
      );

      total += count;
    });

    print("----------------------------------");
    print("TOTAL DOCUMENTS => " + total);
    print("TOTAL COLLECTIONS => " + collections.length);
    print("IS PRIMARY => " + db.hello().isWritablePrimary);
  '

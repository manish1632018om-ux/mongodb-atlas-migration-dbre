
const status = rs.status();

const primary = status.members.filter(
  member => member.stateStr === "PRIMARY" && member.health === 1
);

const secondaries = status.members.filter(
  member => member.stateStr === "SECONDARY" && member.health === 1
);

if (primary.length !== 1 || secondaries.length !== 2) {
  throw new Error(
    `Replica set unhealthy: ${primary.length} PRIMARY, ${secondaries.length} SECONDARY`
  );
}

print("PASS: Replica set has 1 PRIMARY and 2 SECONDARIES");

const testDB = db.getSiblingDB("dbre_ci_test");
const collection = testDB.getCollection("replication_test");

const testId = new ObjectId();

const result = collection.insertOne(
  { _id: testId, test: "majority_write", createdAt: new Date() },
  { writeConcern: { w: "majority", wtimeout: 10000 } }
);

if (!result.acknowledged) {
  throw new Error("Majority write was not acknowledged");
}

print("PASS: Majority write acknowledged");

const secondary = status.members.find(
  member => member.stateStr === "SECONDARY"
);

const secondaryConnection = new Mongo(
  `mongodb://${secondary.name}/?directConnection=true`
);

secondaryConnection.setReadPref("secondary");

let replicated = false;

for (let attempt = 1; attempt <= 20; attempt++) {
  const document = secondaryConnection
    .getDB("dbre_ci_test")
    .getCollection("replication_test")
    .findOne({ _id: testId });

  if (document) {
    replicated = true;
    break;
  }

  sleep(1000);
}

if (!replicated) {
  throw new Error("Document was not found on secondary");
}

print("PASS: Document replicated to secondary");
print("ALL MONGODB INTEGRATION TESTS PASSED");

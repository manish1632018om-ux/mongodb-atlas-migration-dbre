# MongoDB Atlas Migration & Replica Set Reliability Lab

A hands-on MongoDB Database Reliability Engineering (DBRE) project demonstrating backup-and-restore migration from MongoDB Atlas to a self-managed MongoDB 8.0 replica set running in Docker.

## Architecture

MongoDB Atlas (Source)
        |
        | mongodump --archive --gzip
        v
Compressed BSON Archive
        |
        | mongorestore
        v
Docker MongoDB Replica Set (rs0)
        |
        +-- mongo1:27017 (preferred PRIMARY)
        +-- mongo2:27017 (SECONDARY)
        +-- mongo3:27017 (SECONDARY)

The replica set uses persistent Docker volumes and an isolated bridge network.

## Technology Stack

- MongoDB Atlas
- MongoDB 8.0
- MongoDB Database Tools
- Docker and Docker Compose v2
- Bash scripting
- Ubuntu WSL
- MongoDB replica sets

## Migration Results

| Metric | Result |
|---|---|
| Source database | sample_mflix |
| Collections | 6 |
| Documents restored | 67,661 |
| Restore failures | 0 |
| Indexes on destination | 10 |
| Replica-set members | 3 |

### Collection Validation

| Collection | Documents |
|---|---:|
| comments | 41,079 |
| embedded_movies | 3,483 |
| movies | 21,349 |
| sessions | 1 |
| theaters | 1,564 |
| users | 185 |

Document counts were verified on the PRIMARY and both SECONDARIES.

## Repository Structure

- `docker/compose.yaml` — Three-node MongoDB replica set
- `scripts/init-replica-set.sh` — Replica-set initialization
- `scripts/backup-atlas.sh` — Atlas backup automation
- `scripts/restore-mongodb.sh` — Restore automation
- `scripts/validate-migration.sh` — Document and index count validation
- `.env.example` — Configuration template
- `.gitignore` — Local backup and secret exclusions
- `docs/` — Architecture and operational documentation
- `evidence/` — Sanitized validation evidence

## Reproduce the Lab

### Prerequisites

Docker Engine, Docker Compose v2, Bash, and access to a MongoDB Atlas cluster.

### 1. Configure the environment

    cp .env.example .env

Edit `.env` with your Atlas hostname, username, and source database.

Do not store passwords in `.env`.

### 2. Start MongoDB

    sudo docker compose -f docker/compose.yaml up -d

### 3. Initialize the replica set

    sudo -v
    ./scripts/init-replica-set.sh

### 4. Back up Atlas

    ./scripts/backup-atlas.sh

The script prompts for the Atlas password.

### 5. Restore the backup

    ./scripts/restore-mongodb.sh

Restore into an empty destination database.

### 6. Validate the migration

    ./scripts/validate-migration.sh

Compare the destination counts and index definitions against the source.

## High Availability Testing

In the original migration lab, a controlled PRIMARY stepdown triggered an election.

The newly elected PRIMARY retained the migrated dataset and accepted a majority-acknowledged write. That document was subsequently verified on both SECONDARIES.

These tests were performed in the original lab, not yet repeated in this reproducible Compose environment.

## Troubleshooting Experience

- Resolved Docker backup-directory permission issues.
- Diagnosed Atlas authentication issues during mongodump.
- Resolved a Docker Compose installation mismatch on Ubuntu.
- Diagnosed and repaired a hanging replica-set initialization script.
- Validated replication and restored indexes.

## Security and Limitations

This is an educational, local lab.

- Authentication and TLS are not configured on the destination.
- The migration uses a static BSON backup, not continuous synchronization.
- Zero-downtime cutover was not demonstrated.
- Full document-level source-to-target integrity comparison is not implemented.
- Docker environment variables and process arguments may expose credentials to privileged local users.
- The lab is not a production-ready AWS deployment.
- Database archives and secrets must not be committed to Git.

## Future Enhancements

- Automated source-to-target integrity checks
- Replica-set failover automation
- TLS and authentication
- Backup verification and restore drills
- AWS deployment and infrastructure automation
- Monitoring and alerting integration

## Purpose

Demonstrate practical MongoDB migration, replication, backup and recovery, operational troubleshooting, and database reliability engineering skills.

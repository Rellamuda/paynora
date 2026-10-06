#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# PayNora Production Database Automated Backup Script
# Performs compressed pg_dump snapshot, generates SHA-256 hash, and rotates logs.
# ==============================================================================

BACKUP_DIR="${PAYNORA_BACKUP_DIR:-/home/ubuntu/paynora/backups/postgres}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/paynora_backup_${TIMESTAMP}.sql.gz"
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
CONTAINER_NAME="paynora-postgres"
DB_USER="${POSTGRES_USER:-paynora_user}"
DB_NAME="${POSTGRES_DB:-paynora_db}"
RETENTION_DAYS=14

mkdir -p "${BACKUP_DIR}"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Starting automated database backup for PayNora (${DB_NAME})..."

# Verify postgres container is healthy
if ! docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" | grep -q "${CONTAINER_NAME}"; then
    echo "[ERROR] Container ${CONTAINER_NAME} is not running. Aborting backup." >&2
    exit 1
fi

# Execute pg_dump and pipe directly into gzip
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" "${DB_NAME}" | gzip -9 > "${BACKUP_FILE}"

# Generate checksum
sha256sum "${BACKUP_FILE}" > "${CHECKSUM_FILE}"
FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup completed successfully:"
echo "       File: ${BACKUP_FILE} (${FILE_SIZE})"
echo "       SHA256: $(cat "${CHECKSUM_FILE}")"

# Retention policy: remove backups older than RETENTION_DAYS
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "paynora_backup_*.sql.gz*" -type f -mtime "+${RETENTION_DAYS}" -delete

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup process finished."

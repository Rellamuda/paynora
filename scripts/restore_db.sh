#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# PayNora Production Database Restoration Script
# Restores a compressed pg_dump snapshot into the PostgreSQL container.
# ==============================================================================

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_backup.sql.gz>"
    echo "Example: $0 /home/ubuntu/paynora/backups/postgres/paynora_backup_20261006_230000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"
CONTAINER_NAME="paynora-postgres"
DB_USER="${POSTGRES_USER:-paynora_user}"
DB_NAME="${POSTGRES_DB:-paynora_db}"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "[ERROR] Backup file not found: ${BACKUP_FILE}" >&2
    exit 1
fi

# Verify checksum if .sha256 file exists alongside
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [ -f "${CHECKSUM_FILE}" ]; then
    echo "[INFO] Verifying SHA-256 checksum..."
    (cd "$(dirname "${BACKUP_FILE}")" && sha256sum -c "$(basename "${CHECKSUM_FILE}")")
    echo "[INFO] Checksum verified."
fi

echo "[WARNING] This will restore into ${DB_NAME} on container ${CONTAINER_NAME}."
echo "Restoring ${BACKUP_FILE}..."

gunzip -c "${BACKUP_FILE}" | docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}"

echo "[SUCCESS] Database restoration completed."

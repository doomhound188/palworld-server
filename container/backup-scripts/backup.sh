#!/bin/bash
set -e

# Quick function to generate a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Exit if backups are disabled
if [ "${BACKUP_ENABLED}" != "true" ]; then
    echo "$(timestamp) INFO: Backups are disabled. Skipping backup."
    exit 0
fi

# Check if repository is configured
if [ -z "${BACKUP_REPOSITORY}" ]; then
    echo "$(timestamp) ERROR: BACKUP_REPOSITORY not set. Cannot perform backup."
    exit 1
fi

# Export password for restic
export RESTIC_PASSWORD="${BACKUP_PASSWORD}"

# Initialize repository if it doesn't exist yet
echo "$(timestamp) INFO: Checking if repository needs initialization..."
if ! restic -r "${BACKUP_REPOSITORY}" snapshots &>/dev/null; then
    echo "$(timestamp) INFO: Initializing repository ${BACKUP_REPOSITORY}..."
    restic -r "${BACKUP_REPOSITORY}" init
fi

# Build backup command
BACKUP_PATHS=${BACKUP_PATHS:-"/home/steam/palworld/Pal/Saved"}
BACKUP_CMD="restic -r ${BACKUP_REPOSITORY} backup ${BACKUP_PATHS}"

# Add exclude patterns if specified
if [ -n "${BACKUP_EXCLUDE}" ]; then
    for pattern in ${BACKUP_EXCLUDE}; do
        BACKUP_CMD="${BACKUP_CMD} --exclude=${pattern}"
    done
fi

# Save the world before backup if the API is enabled
if [ -n "${API_ENABLED}" ] && [ "${API_ENABLED}" == "true" ]; then
    echo "$(timestamp) INFO: Saving world before backup..."
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${API_KEY}" \
      "http://127.0.0.1:${API_PORT}/api/v1/save"
    echo "$(timestamp) INFO: World save command sent through API"
    # Give the server a moment to complete the save
    sleep 5
fi

# Run backup
echo "$(timestamp) INFO: Starting backup at $(date)..."
eval "${BACKUP_CMD}"
echo "$(timestamp) INFO: Backup completed at $(date)"

# Prune old backups if retention is set
if [ -n "${BACKUP_RETENTION_DAYS}" ] && [ "${BACKUP_RETENTION_DAYS}" -gt 0 ]; then
    echo "$(timestamp) INFO: Pruning backups older than ${BACKUP_RETENTION_DAYS} days..."
    restic -r "${BACKUP_REPOSITORY}" forget --keep-within "${BACKUP_RETENTION_DAYS}d" --prune
fi
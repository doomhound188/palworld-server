#!/bin/bash
set -e

# Quick function to generate a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Exit if backups are disabled
if [ "${BACKUP_ENABLED}" != "true" ]; then
    echo "$(timestamp) INFO: Backups are disabled. Not setting up cron job."
    exit 0
fi

# Check if repository is configured
if [ -z "${BACKUP_REPOSITORY}" ]; then
    echo "$(timestamp) WARNING: BACKUP_REPOSITORY not set. Cron job will be created but backups will fail."
fi

# Set default backup schedule if not provided
BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-"0 0 * * *"}

# Create cron job for scheduled backups
CRON_FILE="/tmp/backup-cron"
echo "${BACKUP_SCHEDULE} /home/steam/backup-scripts/backup.sh >> /home/steam/backup.log 2>&1" > ${CRON_FILE}

# Install cron job
crontab -l > /tmp/current-crontab 2>/dev/null || true
cat ${CRON_FILE} >> /tmp/current-crontab
crontab /tmp/current-crontab
rm ${CRON_FILE} /tmp/current-crontab

echo "$(timestamp) INFO: Backup cron job installed with schedule: ${BACKUP_SCHEDULE}"
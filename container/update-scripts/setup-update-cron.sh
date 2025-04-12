#!/bin/bash
set -e

# Quick function to generate a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Exit if auto-updates are disabled
if [ "${AUTO_UPDATE_ENABLED}" != "true" ]; then
    echo "$(timestamp) INFO: Auto-updates are disabled. Not setting up cron job."
    exit 0
fi

# Set default update schedule if not provided
AUTO_UPDATE_SCHEDULE=${AUTO_UPDATE_SCHEDULE:-"0 */4 * * *"}

# Create cron job for scheduled updates
CRON_FILE="/tmp/update-cron"
echo "${AUTO_UPDATE_SCHEDULE} /home/steam/update-scripts/check-update.sh >> /home/steam/update.log 2>&1" > ${CRON_FILE}

# Install cron job
crontab -l > /tmp/current-crontab 2>/dev/null || true
cat ${CRON_FILE} >> /tmp/current-crontab
crontab /tmp/current-crontab
rm ${CRON_FILE} /tmp/current-crontab

echo "$(timestamp) INFO: Update check cron job installed with schedule: ${AUTO_UPDATE_SCHEDULE}"
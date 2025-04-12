#!/bin/bash

# Quick function to generate a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# API helper function
call_api() {
  local endpoint=$1
  local method=${2:-GET}
  local data=${3:-""}
  
  if [ -n "$data" ] && [ "$method" == "POST" ]; then
    curl -s -X $method \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${API_KEY}" \
      -d "$data" \
      "http://127.0.0.1:${API_PORT}${endpoint}"
  else
    curl -s -X $method \
      -H "Authorization: Bearer ${API_KEY}" \
      "http://127.0.0.1:${API_PORT}${endpoint}"
  fi
}

# Shutdown function for trap
shutdown() {
    echo "$(timestamp) INFO: Received SIGTERM, shutting down gracefully"
    echo "$(timestamp) INFO: Saving world..."
    
    # Use REST API for graceful shutdown
    if [ -n "${API_ENABLED}" ] && [ "${API_ENABLED}" == "true" ]; then
        # First save the world
        call_api "/api/v1/save" "POST"
        echo "$(timestamp) INFO: World save command sent through API"
        
        # Then shut down the server
        call_api "/api/v1/shutdown" "POST"
        echo "$(timestamp) INFO: Shutdown command sent through API"
    else
        echo "$(timestamp) WARN: API is not enabled, attempting direct shutdown"
        # Fall back to direct signal
        kill -15 $palworld_pid
    fi

    # Wait for port to be released
    while netstat -aln | grep -q $GAME_PORT; do
        sleep 1
    done

    echo "$(timestamp) INFO: Goodbye"
    kill -15 $palworld_pid 
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat /home/steam/image_version)
MAINTAINER=$(cat /home/steam/image_maintainer)
EXPECTED_FS_PERMS=$(cat /home/steam/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Palworld dedicated server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Validate arguments
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="Palworld Containerized"
    echo "$(timestamp) WARN: SERVER_NAME not set, using default: Palworld Containerized"
fi

if [ -z "$SERVER_PASSWORD" ]; then
    echo "$(timestamp) WARN: SERVER_PASSWORD not set, the server will be open to the public"
fi

if [ -z "$GAME_PORT" ]; then
    GAME_PORT="8211"
    echo "$(timestamp) WARN: GAME_PORT not set, using default: 8211"
fi

if [ -z "$SERVER_SLOTS" ]; then
    SERVER_SLOTS="32"
    echo "$(timestamp) WARN: SERVER_SLOTS not set, using default: 32"
fi

if [ -z "$API_ENABLED" ]; then
    API_ENABLED="true"
    echo "$(timestamp) WARN: API_ENABLED not set, using default: true"
fi

if [ -z "$API_PORT" ]; then
    API_PORT="8000"
    echo "$(timestamp) WARN: API_PORT not set, using default: 8000"
fi

if [ -z "$API_KEY" ]; then
    # Generate a random API key if not provided
    API_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
    echo "$(timestamp) WARN: API_KEY not set, generated random key: ${API_KEY}"
    echo "$(timestamp) WARN: Store this key for external API access!"
fi

# Set default backup values if not provided
if [ -z "$BACKUP_ENABLED" ]; then
    BACKUP_ENABLED="false"
    echo "$(timestamp) INFO: BACKUP_ENABLED not set, using default: false"
fi

if [ "$BACKUP_ENABLED" == "true" ] && [ -z "$BACKUP_REPOSITORY" ]; then
    echo "$(timestamp) WARN: BACKUP_ENABLED is true but BACKUP_REPOSITORY is not set. Backups will fail!"
fi

if [ -z "$BACKUP_SCHEDULE" ]; then
    BACKUP_SCHEDULE="0 0 * * *"
    echo "$(timestamp) INFO: BACKUP_SCHEDULE not set, using default: 0 0 * * * (daily at midnight)"
fi

if [ -z "$BACKUP_RETENTION_DAYS" ]; then
    BACKUP_RETENTION_DAYS="7"
    echo "$(timestamp) INFO: BACKUP_RETENTION_DAYS not set, using default: 7 days"
fi

if [ -z "$BACKUP_PATHS" ]; then
    BACKUP_PATHS="/home/steam/palworld/Pal/Saved"
    echo "$(timestamp) INFO: BACKUP_PATHS not set, using default: ${BACKUP_PATHS}"
fi

if [ -z "$BACKUP_BEFORE_UPDATE" ]; then
    BACKUP_BEFORE_UPDATE="true"
    echo "$(timestamp) INFO: BACKUP_BEFORE_UPDATE not set, using default: true"
fi

# Set default auto-update values if not provided
if [ -z "$AUTO_UPDATE_ENABLED" ]; then
    AUTO_UPDATE_ENABLED="false"
    echo "$(timestamp) INFO: AUTO_UPDATE_ENABLED not set, using default: false"
fi

if [ -z "$AUTO_UPDATE_SCHEDULE" ]; then
    AUTO_UPDATE_SCHEDULE="0 */4 * * *"
    echo "$(timestamp) INFO: AUTO_UPDATE_SCHEDULE not set, using default: 0 */4 * * * (every 4 hours)"
fi

# Check for proper save permissions
if ! touch "${PALWORLD_PATH}/Pal/Saved/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of /home/steam/palworld/Pal/Saved is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'chown -R ${EXPECTED_FS_PERMS} /your/palworld/directory'"
    echo ""
    exit 1
fi

rm "${PALWORLD_PATH}/Pal/Saved/test"

# Setup backup cron job if enabled
if [ "${BACKUP_ENABLED}" == "true" ]; then
    echo "$(timestamp) INFO: Setting up backup cron job..."
    # Ensure scripts have execute permissions
    chmod +x /home/steam/backup-scripts/backup.sh
    chmod +x /home/steam/backup-scripts/setup-backup-cron.sh
    /home/steam/backup-scripts/setup-backup-cron.sh
fi

# Setup auto-update cron job if enabled
if [ "${AUTO_UPDATE_ENABLED}" == "true" ]; then
    echo "$(timestamp) INFO: Setting up auto-update cron job..."
    # Ensure scripts have execute permissions
    chmod +x /home/steam/update-scripts/check-update.sh
    chmod +x /home/steam/update-scripts/setup-update-cron.sh
    /home/steam/update-scripts/setup-update-cron.sh
fi

# Install/Update Palworld
echo "$(timestamp) INFO: Updating Palworld Dedicated Server"
/home/steam/steamcmd/steamcmd.sh +force_install_dir "$PALWORLD_PATH" +login anonymous +app_update 2394010 validate +quit

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Palworld Dedicated Server"
    exit 1
fi

# Palworld looks for steamclient.so here, so lets make sure it exists here
mkdir -p /home/steam/.steam/sdk64/
cp /home/steam/steamcmd/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so 

# Create log directory if it doesn't exist
if ! [ -d "${PALWORLD_PATH}/Pal/Saved/Logs/" ]; then
    mkdir -p "${PALWORLD_PATH}/Pal/Saved/Logs/"
fi

# Copy example server config if not already present
if ! [ -f "${PALWORLD_CONFIG}" ]; then
    echo "$(timestamp) INFO: Palworld server config not present, copying example"
    mkdir -p "${PALWORLD_PATH}/Pal/Saved/Config/LinuxServer"
    touch ${PALWORLD_CONFIG}
    cat /home/steam/palworld/DefaultPalWorldSettings.ini > ${PALWORLD_CONFIG}
# Config may be present but empty, check for that too
elif [ $(ls -l ${PALWORLD_CONFIG} | awk '{print $5}') -eq 0 ]; then
    echo "$(timestamp) INFO: Palworld server config empty, copying example"
    cat /home/steam/palworld/DefaultPalWorldSettings.ini > ${PALWORLD_CONFIG}
fi

# Update config for basic game settings
sed -i "s/ServerName=\"[^\"]*\"/ServerName=\"${SERVER_NAME}\"/" $PALWORLD_CONFIG
sed -i "s/PublicPort=\"[^\"]*\"/PublicPort=\"${GAME_PORT}\"/" $PALWORLD_CONFIG
sed -i "s/ServerPlayerMaxNum=\"[^\"]*\"/ServerPlayerMaxNum=\"${SERVER_SLOTS}\"/" $PALWORLD_CONFIG

# Set server password if provided
if [ -n "$SERVER_PASSWORD" ]; then
    sed -i "s/ServerPassword=\"[^\"]*\"/ServerPassword=\"${SERVER_PASSWORD}\"/" $PALWORLD_CONFIG
else
    sed -i "s/ServerPassword=\"[^\"]*\"/ServerPassword=\"\"/" $PALWORLD_CONFIG
fi

# Configure REST API settings
if [[ "${API_ENABLED}" == "true" ]]; then
    # Create API configuration file if needed
    PALWORLD_API_CONFIG="${PALWORLD_PATH}/Pal/Saved/Config/LinuxServer/APIMeta.json"
    if [ ! -f "${PALWORLD_API_CONFIG}" ]; then
        echo "$(timestamp) INFO: Creating API configuration file"
        cat > "${PALWORLD_API_CONFIG}" << EOL
{
  "Enabled": true,
  "Port": ${API_PORT},
  "APIKey": "${API_KEY}",
  "AllowedOrigins": ["*"]
}
EOL
    else
        # Update existing API config
        echo "$(timestamp) INFO: Updating API configuration"
        # Use jq if available, otherwise do simple sed replacements
        if command -v jq >/dev/null; then
            TMP_FILE=$(mktemp)
            jq ".Enabled = true | .Port = ${API_PORT} | .APIKey = \"${API_KEY}\"" "${PALWORLD_API_CONFIG}" > "${TMP_FILE}"
            mv "${TMP_FILE}" "${PALWORLD_API_CONFIG}"
        else
            sed -i "s/\"Enabled\":[^,]*/\"Enabled\": true/g" "${PALWORLD_API_CONFIG}"
            sed -i "s/\"Port\":[^,]*/\"Port\": ${API_PORT}/g" "${PALWORLD_API_CONFIG}"
            sed -i "s/\"APIKey\":[^,]*/\"APIKey\": \"${API_KEY}\"/g" "${PALWORLD_API_CONFIG}"
        fi
    fi
    echo "$(timestamp) INFO: API enabled on port ${API_PORT}"
else
    echo "$(timestamp) INFO: API disabled by configuration"
fi

# Start crond service for backups and auto-updates
if [ "${BACKUP_ENABLED}" == "true" ] || [ "${AUTO_UPDATE_ENABLED}" == "true" ]; then
    echo "$(timestamp) INFO: Starting cron service for scheduled tasks"
    crond
fi

echo ""
echo " ____       _                      _     _ "
echo "|  _ \ __ _| |_      _____  _ _ __| | __| |"
echo "| |_) / _\` | \ \ /\ / / _ \| | '__| |/ _\` |"
echo "|  __/ (_| | |\ V  V / (_) | | |  | | (_| |"
echo "|_|   \__,_|_| \_/\_/ \___/|_|_|  |_|\__,_|"
echo "                                           "
echo "$(timestamp) INFO: Launching Palworld Dedicated Server"
echo "-----------------------------------------------------------"
echo "Server Name: ${SERVER_NAME}"
echo "Server Password: ${SERVER_PASSWORD:-Not Set (Public Server)}"
echo "Game Port: ${GAME_PORT}"
echo "Max Players: ${SERVER_SLOTS}"
echo "API Enabled: ${API_ENABLED}"
if [[ "${API_ENABLED}" == "true" ]]; then
    echo "API Port: ${API_PORT}"
    echo "API Key: ${API_KEY}"
fi
if [[ "${BACKUP_ENABLED}" == "true" ]]; then
    echo "Backup Schedule: ${BACKUP_SCHEDULE}"
    echo "Backup Repository: ${BACKUP_REPOSITORY}"
    echo "Backup Retention: ${BACKUP_RETENTION_DAYS} days"
fi
if [[ "${AUTO_UPDATE_ENABLED}" == "true" ]]; then
    echo "Auto Update Schedule: ${AUTO_UPDATE_SCHEDULE}"
fi
echo "Server Container Image Version: ${IMAGE_VERSION}"
echo ""
echo ""

# Launch Palworld
${PALWORLD_PATH}/PalServer.sh -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -EpicApp=Palserver &
palworld_pid=$!

# Wait a bit for the server to start
sleep 10

# Test the API if enabled
if [[ "${API_ENABLED}" == "true" ]]; then
    echo "$(timestamp) INFO: Testing API connection..."
    SERVER_INFO=$(call_api "/api/v1/server")
    
    if [ -n "$SERVER_INFO" ]; then
        echo "$(timestamp) INFO: API connection successful"
    else
        echo "$(timestamp) WARN: Could not connect to API - server may still be starting"
    fi
fi

wait $palworld_pid

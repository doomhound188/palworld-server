#!/bin/bash
set -e

# Quick function to generate a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Exit if auto-updates are disabled
if [ "${AUTO_UPDATE_ENABLED}" != "true" ]; then
    echo "$(timestamp) INFO: Auto-updates are disabled. Skipping update check."
    exit 0
fi

# Function to get the installed version
get_installed_version() {
    if [ -f "${PALWORLD_PATH}/steamapps/appmanifest_2394010.acf" ]; then
        grep '"buildid"' ${PALWORLD_PATH}/steamapps/appmanifest_2394010.acf | awk -F'"' '{print $4}'
    else
        echo ""
    fi
}

# Function to get the latest version from Steam
get_latest_version() {
    steamcmd +login anonymous +app_info_print 2394010 +quit | grep -A 2 '^\s*"public"\s*$' | grep -m 1 '"buildid"' | awk '{print $2}' | tr -d '",'
}

# Update Palworld if needed
update_server() {
    local installed_version latest_version
    installed_version=$(get_installed_version)
    latest_version=$(get_latest_version)

    if [ -z "$installed_version" ]; then
        echo "$(timestamp) INFO: No installed version found, updating Palworld Dedicated Server"
    elif [ "$installed_version" == "$latest_version" ]; then
        echo "$(timestamp) INFO: Palworld Dedicated Server is already up to date (version $installed_version)"
        return
    else
        echo "$(timestamp) INFO: Updating Palworld Dedicated Server from version $installed_version to $latest_version"
        
        # Perform backup before update if enabled
        if [ "${BACKUP_BEFORE_UPDATE}" == "true" ] && [ "${BACKUP_ENABLED}" == "true" ]; then
            echo "$(timestamp) INFO: Performing backup before update..."
            /home/steam/backup-scripts/backup.sh
        fi
        
        # Save the world before update if the API is enabled
        if [ -n "${API_ENABLED}" ] && [ "${API_ENABLED}" == "true" ]; then
            echo "$(timestamp) INFO: Saving world before update..."
            curl -s -X POST \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer ${API_KEY}" \
              "http://127.0.0.1:${API_PORT}/api/v1/save"
            echo "$(timestamp) INFO: World save command sent through API"
            # Give the server a moment to complete the save
            sleep 5
        fi
    fi

    # Run the update
    echo "$(timestamp) INFO: Running Palworld Dedicated Server update..."
    /home/steam/steamcmd/steamcmd.sh +force_install_dir "$PALWORLD_PATH" +login anonymous +app_update 2394010 validate +quit

    if [ $? != 0 ]; then
        echo "$(timestamp) ERROR: steamcmd was unable to successfully update Palworld Dedicated Server"
        exit 1
    fi
    
    # Restart the server if it was already running
    if netstat -aln | grep -q $GAME_PORT; then
        echo "$(timestamp) INFO: Update complete, restarting server..."
        
        # Use API to shutdown if enabled
        if [ -n "${API_ENABLED}" ] && [ "${API_ENABLED}" == "true" ]; then
            curl -s -X POST \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer ${API_KEY}" \
              "http://127.0.0.1:${API_PORT}/api/v1/shutdown"
            echo "$(timestamp) INFO: Shutdown command sent through API"
        else
            # Find the PID and kill directly - this is not ideal but works as fallback
            PID=$(pgrep -f PalServer.sh)
            if [ -n "$PID" ]; then
                echo "$(timestamp) INFO: Sending shutdown signal to PID $PID"
                kill -15 $PID
            fi
        fi
    fi
}

echo "$(timestamp) INFO: Running scheduled update check..."
update_server
echo "$(timestamp) INFO: Update check completed"

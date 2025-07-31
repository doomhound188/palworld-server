# palworld-server
[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/palworld-dedicated-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/palworld-dedicated-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/palworld-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/palworld-server)

Containerized Palworld dedicated server

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.

## Features

- **Automatic Updates**: Server automatically updates on container start
- **Scheduled Auto-Updates**: Configure automatic updates on a schedule
- **Automatic Backups**: Schedule automated backups of your server data
- **Graceful Shutdown**: Properly saves the world when container is stopped
- **REST API Support**: Manage your server remotely with Palworld's official REST API
- **Persistent Storage**: Retain server data between container restarts
- **Configurable**: Easily adjust server settings via environment variables
- **Enhanced Logging**: Detailed timestamped logs for better debugging
- **Resource Efficient**: Optimized container image size
- **Permission Checking**: Validates proper volume permissions on startup

## Usage

The processes within the container do **NOT** run as root. Everything runs as the user steam (gid:10000/uid:10000). If you exec into the container, you will drop into `/home/steam` as the steam user. Palworld will be installed to `/home/steam/palworld`. Any persistent volumes should be mounted to `/home/steam/palworld/Pal/Saved`.

### Ports

| Port | Protocol | Default |
| ---- | -------- | ------- |
| Game Port | UDP | 8211 |
| API Port | TCP | 8000 |

### Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| SERVER_NAME | Name for the Server | Palworld Containerized | False |
| SERVER_PASSWORD | Password for the server | None | False |
| GAME_PORT | Port for server connections | 8211 | False |
| SERVER_SLOTS | Number of slots for connections (Max 32) | 32 | False |
| API_ENABLED | Enable or disable REST API functionality | true | False |
| API_PORT | Port for REST API connections | 8000 | False |
| API_KEY | Authentication key for the REST API | Random generated | False |

#### Backup Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| BACKUP_ENABLED | Enable automated backups | false | False |
| BACKUP_REPOSITORY | Restic repository URL/path | None | True if backups enabled |
| BACKUP_PASSWORD | Password for the Restic repository | None | True if backups enabled |
| BACKUP_SCHEDULE | Cron schedule for backups | 0 0 * * * (daily at midnight) | False |
| BACKUP_RETENTION_DAYS | Number of days to keep backups | 7 | False |
| BACKUP_PATHS | Paths to backup | /home/steam/palworld/Pal/Saved | False |
| BACKUP_EXCLUDE | Space separated list of exclude patterns | None | False |
| BACKUP_BEFORE_UPDATE | Whether to backup before updating | true | False |

#### Auto-Update Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| AUTO_UPDATE_ENABLED | Enable automatic updates | false | False |
| AUTO_UPDATE_SCHEDULE | Cron schedule for update checks | 0 */4 * * * (every 4 hours) | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker volume create palworld-persistent-data # Only run this 1 time
docker run \
  --detach \
  --name palworld-server \
  --mount type=volume,source=palworld-persistent-data,target=/home/steam/palworld/Pal/Saved \
  --publish 8211:8211/udp \
  --publish 8000:8000/tcp \
  --env=SERVER_NAME="Palworld Containerized Server" \
  --env=SERVER_SLOTS=32 \
  --env=SERVER_PASSWORD="ChangeThisPlease" \
  --env=GAME_PORT=8211 \
  --env=API_ENABLED=true \
  --env=API_PORT=8000 \
  --env=API_KEY="your_secure_api_key_here" \
  --env=BACKUP_ENABLED=true \
  --env=BACKUP_REPOSITORY="s3:https://s3.amazonaws.com/your-bucket-name" \
  --env=BACKUP_PASSWORD="YourSecureBackupPassword" \
  --env=AUTO_UPDATE_ENABLED=true \
  --restart unless-stopped \
  sknnr/palworld-dedicated-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` and `default.env` files out of the `container` directory to your local machine. You can leave the `compose.yaml` file unchanged. Edit the `default.env` file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains both the env file and the compose file, simply run:

```bash
docker compose up -d -f compose.yaml
```

To bring the container down:

```bash
docker compose down -f compose.yaml
```

compose.yaml :
```yaml
services:
  palworld:
    image: sknnr/palworld-dedicated-server:latest
    ports:
      - "8211:8211/udp"
      - "8000:8000/tcp"
    environment:
      # Server settings
      - SERVER_NAME=Palworld Containerized Server
      - SERVER_PASSWORD=PleaseChangeMe
      - GAME_PORT=8211
      - SERVER_SLOTS=32
      
      # API settings
      - API_ENABLED=true
      - API_PORT=8000
      - API_KEY=your_secure_api_key_here
      
      # Backup settings
      - BACKUP_ENABLED=false
      - BACKUP_REPOSITORY=
      - BACKUP_PASSWORD=
      - BACKUP_SCHEDULE=0 0 * * *
      - BACKUP_RETENTION_DAYS=7
      - BACKUP_PATHS=/home/steam/palworld/Pal/Saved
      - BACKUP_EXCLUDE=
      - BACKUP_BEFORE_UPDATE=true
      
      # Auto-update settings
      - AUTO_UPDATE_ENABLED=false
      - AUTO_UPDATE_SCHEDULE=0 */4 * * *
    volumes:
      - palworld-persistent-data:/home/steam/palworld/Pal/Saved
    restart: unless-stopped

volumes:
  palworld-persistent-data:
```

default.env :
```bash
# Server settings
SERVER_NAME="Palworld Containerized"
SERVER_PASSWORD="ChangeMePlease"
GAME_PORT="8211"
SERVER_SLOTS="32"

# API settings
API_ENABLED="true"
API_PORT="8000"
API_KEY="your_secure_api_key_here"

# Backup settings
BACKUP_ENABLED="false"
BACKUP_REPOSITORY=""
BACKUP_PASSWORD=""
BACKUP_SCHEDULE="0 0 * * *"
BACKUP_RETENTION_DAYS="7"
BACKUP_PATHS="/home/steam/palworld/Pal/Saved"
BACKUP_EXCLUDE=""
BACKUP_BEFORE_UPDATE="true"

# Auto-update settings
AUTO_UPDATE_ENABLED="false"
AUTO_UPDATE_SCHEDULE="0 */4 * * *"
```

### Podman

To run the container in Podman, run the following command:

```bash
podman volume create palworld-persistent-data # Only run this 1 time
podman run \
  --detach \
  --name palworld-server \
  --mount type=volume,source=palworld-persistent-data,target=/home/steam/palworld/Pal/Saved \
  --publish 8211:8211/udp \
  --publish 8000:8000/tcp \
  --env=SERVER_NAME="Palworld Containerized Server" \
  --env=SERVER_SLOTS=32 \
  --env=SERVER_PASSWORD="ChangeThisPlease" \
  --env=GAME_PORT=8211 \
  --env=API_ENABLED=true \
  --env=API_PORT=8000 \
  --env=API_KEY="your_secure_api_key_here" \
  --env=BACKUP_ENABLED=true \
  --env=BACKUP_REPOSITORY="s3:https://s3.amazonaws.com/your-bucket-name" \
  --env=BACKUP_PASSWORD="YourSecureBackupPassword" \
  docker.io/sknnr/palworld-dedicated-server:latest
```

### Using the REST API

This container supports Palworld's official REST API for server management. The API allows you to:

1. Get server information
2. View player lists
3. Save the world
4. Kick or ban players
5. Shutdown the server gracefully
6. And more

To use the REST API:

```bash
# Get server information
curl -H "Authorization: Bearer your_secure_api_key_here" http://your-server-ip:8000/api/v1/server

# Save the world
curl -X POST -H "Authorization: Bearer your_secure_api_key_here" http://your-server-ip:8000/api/v1/save

# Shutdown server gracefully
curl -X POST -H "Authorization: Bearer your_secure_api_key_here" http://your-server-ip:8000/api/v1/shutdown

# Get player list
curl -H "Authorization: Bearer your_secure_api_key_here" http://your-server-ip:8000/api/v1/players

# Kick a player (replace PLAYER_ID with actual ID)
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer your_secure_api_key_here" \
  -d '{"playerId": "PLAYER_ID"}' http://your-server-ip:8000/api/v1/players/kick
```

For more API endpoints and details, check the official Palworld API documentation at https://docs.palworldgame.com/category/rest-api

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.

## Backups

The container includes a built-in backup system using [Restic](https://restic.net/) which can automatically back up your server data on a schedule. To enable backups, you need to set the appropriate environment variables.

### Basic Backup Configuration

```bash
docker run \
  --detach \
  --name palworld-server \
  --mount type=volume,source=palworld-persistent-data,target=/home/steam/palworld/Pal/Saved \
  --publish 8211:8211/udp \
  --publish 8000:8000/tcp \
  --env=SERVER_NAME="Palworld Containerized Server" \
  --env=SERVER_SLOTS=32 \
  --env=SERVER_PASSWORD="ChangeThisPlease" \
  --env=API_ENABLED=true \
  --env=API_KEY="your_secure_api_key_here" \
  --env=BACKUP_ENABLED=true \
  --env=BACKUP_REPOSITORY="s3:https://s3.amazonaws.com/your-bucket-name" \
  --env=BACKUP_PASSWORD="YourSecureBackupPassword" \
  sknnr/palworld-dedicated-server:latest
```

### Backup Repository Types

Restic supports various repository types including:

- Local: `/path/to/repository`
- S3: `s3:https://s3.amazonaws.com/bucket_name`
- SFTP: `sftp:user@host:/path`
- Rest Server: `rest:https://user:pass@host:8000/`

For complete details on repository types, see the [Restic documentation](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html).

## Automatic Updates

The container supports two methods of updating:

1. **On Startup**: The server automatically checks for updates when the container starts
2. **Scheduled Updates**: The server can check for updates on a regular schedule

### Configuring Scheduled Updates

To enable scheduled update checks, set the following environment variables:

```bash
--env=AUTO_UPDATE_ENABLED=true
--env=AUTO_UPDATE_SCHEDULE="0 */4 * * *"  # Check every 4 hours
```

### Using Watchtower with Docker

You can also use Watchtower to automatically update your running Docker containers. To use Watchtower:

1. Run Watchtower:

   ```bash
   docker run -d \
     --name watchtower \
     -v /var/run/docker.sock:/var/run/docker.sock \
     containrrr/watchtower
   ```

2. Configure Watchtower (optional):

   ```bash
   docker run -d \
     --name watchtower \
     -v /var/run/docker.sock:/var/run/docker.sock \
     containrrr/watchtower \
     --interval 300 \
     --notifications email \
     --notification-email-from watchtower@example.com \
     --notification-email-to you@example.com \
     --notification-email-server smtp.example.com \
     --notification-email-server-port 587 \
     --notification-email-server-user user@example.com \
     --notification-email-server-password password
   ```

### Using Built-in Update Functions in Podman

Podman supports automatic updates with the `io.containers.autoupdate` label.

1. Ensure your Podman run command includes the `--label io.containers.autoupdate=registry` option:

   ```bash
   podman run \
     --detach \
     --name palworld-server \
     --mount type=volume,source=palworld-persistent-data,target=/home/steam/palworld/Pal/Saved \
     --publish 8211:8211/udp \
     --publish 8000:8000/tcp \
     --env=SERVER_NAME="Palworld Containerized Server" \
     --env=SERVER_PASSWORD="ChangeThisPlease" \
     --label io.containers.autoupdate=registry \
     docker.io/sknnr/palworld-dedicated-server:latest
   ```

2. Create a systemd unit file for auto-update:

   ```ini
   [Unit]
   Description=Podman auto-update service
   Wants=network-online.target
   After=network-online.target

   [Service]
   Type=oneshot
   ExecStart=/usr/bin/podman auto-update
   ```

3. Create a systemd timer to run the update service daily:

   ```ini
   [Unit]
   Description=Run Podman auto-update daily

   [Timer]
   OnCalendar=daily
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```

4. Enable and start the timer:

   ```bash
   sudo systemctl enable podman-auto-update.timer
   sudo systemctl start podman-auto-update.timer
   ```

## Graceful Shutdown

The container has been configured to gracefully shutdown when it receives a SIGTERM signal (e.g., when running `docker stop`). The shutdown process:

1. Saves the game world via the REST API
2. Initiates a clean server shutdown
3. Waits for the server to fully terminate before exiting

This helps prevent world corruption and data loss.

## Troubleshooting

### Connectivity

If you are having issues connecting to the server once the container is deployed, I promise the issue is not with this image. You need to make sure that the port 8211/udp (or whichever ones you decide to use) are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running. After this has been done correctly and you are still experiencing issues, your internet service provider (ISP) may be blocking the ports and you should contact them to troubleshoot.

### Storage

I recommend having Docker or Podman manage the volume that gets mounted into the container. However, if you absolutely must bind mount a directory into the container you need to make sure that on your container host the directory you are bind mounting is owned by 10000:10000 by default (`chown -R 10000:10000 /path/to/directory`). If the ownership of the directory is not correct the container will not start as the server will be unable to persist the savegame.

### API Connection Issues

If you're having trouble connecting to the REST API:

1. Verify that `API_ENABLED` is set to `true`
2. Ensure the API port (default: 8000) is properly published
3. Make sure you're using the correct API key
4. Check your firewall settings to allow TCP traffic on the API port
5. The API may take a few moments to start after the server itself starts

### Backup Issues

If backups aren't working:
1. Check that `BACKUP_ENABLED` is set to `true`
2. Verify that `BACKUP_REPOSITORY` and `BACKUP_PASSWORD` are set correctly
3. Check the backup logs with `docker exec palworld-server cat /home/steam/backup.log`
4. Make sure the repository is accessible from the container

### Auto-Update Issues

If automatic updates aren't working:
1. Verify that `AUTO_UPDATE_ENABLED` is set to `true`
2. Check the update logs with `docker exec palworld-server cat /home/steam/update.log`
3. Ensure the container has internet access to reach the Steam servers
4. If using cron schedules, confirm your cron syntax is correct

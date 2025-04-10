# palworld-server
[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/palworld-dedicated-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/palworld-dedicated-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/palworld-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/palworld-server)

Containerized Palworld dedicated server

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.

## Notice - Please Read
There is currently a bug where if you try to direct connect to your password protected server the game will not prompt you for the password and you will fail to join. If you can find your server in the server browser it will work just fine. However, another problem is that you may not be able to find your server in the server browser due to the shear amount of servers. This container image is built so that your server *should* show up in the list, but I have had some issues finding them.

A workaround for directly connecting to password protected servers has been shared here: https://steamcommunity.com/app/1623730/discussions/0/4132683013931609911/

## Features

- **Automatic Updates**: Server automatically updates on container start
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
  --restart unless-stopped \
  sknnr/palworld-dedicated-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` and `default.env` files out of the `container` directory to your local machine. You can leave the `compose.yaml` file uncahnged. Edit the `default.env` file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains both the env file and the compose file, simply run:

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
      - SERVER_NAME=Palworld Containerized Server
      - SERVER_PASSWORD=PleaseChangeMe
      - GAME_PORT=8211
      - SERVER_SLOTS=32
      - API_ENABLED=true
      - API_PORT=8000
      - API_KEY=your_secure_api_key_here
    volumes:
      - palworld-persistent-data:/home/steam/palworld/Pal/Saved
    restart: unless-stopped

volumes:
  palworld-persistent-data:
```

default.env :
```bash
SERVER_NAME="Palworld Containerized"
SERVER_PASSWORD="ChangeMePlease"
GAME_PORT="8211"
SERVER_SLOTS="32"
API_ENABLED="true"
API_PORT="8000"
API_KEY="your_secure_api_key_here"
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

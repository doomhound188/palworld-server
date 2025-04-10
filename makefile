# Image values
REGISTRY := "localhost"
IMAGE := "palworld-test"
IMAGE_REF := $(REGISTRY)/$(IMAGE)

# Git commit hash
HASH := $(shell git rev-parse --short HEAD)

# Buildah/Podman Options
CONTAINER_NAME := "palworld-test"
VOLUME_NAME := "palworld-data-test"
BUILDAH_BUILD_OPTS := --format docker -f ./container/Containerfile
PODMAN_RUN_OPTS := --name $(CONTAINER_NAME) -d --mount type=volume,source=$(VOLUME_NAME),target=/home/steam/palworld/Pal/Saved \
					-p 8211:8211/udp -p 8000:8000/tcp \
					--env=SERVER_NAME='Palworld Server Test' \
					--env=SERVER_PASSWORD='PleaseChangeMe' \
					--env=GAME_PORT=8211 \
					--env=SERVER_SLOTS=32 \
					--env=API_ENABLED=true \
					--env=API_PORT=8000 \
					--env=API_KEY='your_secure_api_key_here'

# Makefile targets
.PHONY: build run cleanup logs api-test

build:
	buildah build $(BUILDAH_BUILD_OPTS) -t $(IMAGE_REF):$(HASH) ./container

run:
	podman volume create $(VOLUME_NAME)
	podman run $(PODMAN_RUN_OPTS) $(IMAGE_REF):$(HASH)

logs:
	podman logs -f $(CONTAINER_NAME)

api-test:
	curl -s -H "Authorization: Bearer your_secure_api_key_here" http://localhost:8000/api/v1/server | jq

cleanup:
	podman rm -f $(CONTAINER_NAME)
	podman rmi -f $(IMAGE_REF):$(HASH)
	podman volume rm $(VOLUME_NAME)

#!/bin/bash

set -e

CONTAINER_NAME="cloud1-control"
IMAGE="registry.fedoraproject.org/fedora-toolbox:42"

if podman container exists "$CONTAINER_NAME"; then
    echo "[INFO] Container already exists."

    if ! podman ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        echo "[INFO] Starting container..."
        podman start "$CONTAINER_NAME"
    fi

    echo "[INFO] Entering container..."
    exec podman exec -it "$CONTAINER_NAME" bash
fi

echo "[INFO] Creating container..."

podman run -d \
    --name "$CONTAINER_NAME" \
    -v "$PWD:$HOME/cloud-1" \
    -v "$HOME/.ssh:$HOME/.ssh:ro" \
    -w "$HOME/cloud-1" \
    "$IMAGE" \
    sleep infinity

echo "[INFO] Installing packages..."

podman exec "$CONTAINER_NAME" dnf install -y \
    ansible

echo "[INFO] Container ready."

exec podman exec -it "$CONTAINER_NAME" bash

#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"
IMAGE_NAME="nginx-assignment"

echo "Building Version 1 image..."
docker build -t "${IMAGE_NAME}:v1" -f app/Dockerfile app/v1
echo "Building Version 2 image..."
docker build -t "${IMAGE_NAME}:v2" -f app/Dockerfile app/v2
echo "Loading images into Kind cluster ${CLUSTER_NAME}..."
kind load docker-image "${IMAGE_NAME}:v1" "${IMAGE_NAME}:v2" --name "${CLUSTER_NAME}"
echo "Done. Check local tags with: docker images nginx-assignment"

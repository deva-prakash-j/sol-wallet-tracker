#!/bin/bash

# Build script for Sol Wallet Tracker Docker image with GraalVM Native Image

set -e

IMAGE_NAME="sol-wallet-tracker"
TAG="latest"

echo "🚀 Building Docker image with GraalVM Native Image..."
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""

# Build the Docker image
docker build -t "${IMAGE_NAME}:${TAG}" .

echo ""
echo "✅ Docker image built successfully!"
echo ""
echo "📊 Image information:"
docker images "${IMAGE_NAME}:${TAG}"

echo ""
echo "🎯 To run the container:"
echo "docker run -p 8080:8080 ${IMAGE_NAME}:${TAG}"
echo ""
echo "🔍 To inspect the image:"
echo "docker run --rm -it ${IMAGE_NAME}:${TAG} sh"

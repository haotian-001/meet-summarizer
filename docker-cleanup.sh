#!/bin/bash

# Meet Summarizer Docker Cleanup Script
# This script removes Docker containers and images for cleanup

set -e  # Exit on any error

echo "🧹 Cleaning up Meet Summarizer Docker resources..."

# Configuration
APP_NAME="meet-summarizer"
CONTAINER_NAME="${APP_NAME}-container"
IMAGE_NAME="${APP_NAME}-image"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed."
    exit 1
fi

# Stop and remove container if it exists
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing container: $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    print_status "Container cleaned up."
else
    print_warning "Container $CONTAINER_NAME does not exist."
fi

# Remove image if it exists
if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}:latest$"; then
    print_status "Removing Docker image: $IMAGE_NAME:latest..."
    docker rmi "$IMAGE_NAME:latest" 2>/dev/null || true
    print_status "Image cleaned up."
else
    print_warning "Image $IMAGE_NAME:latest does not exist."
fi

# Optional: Clean up dangling images and containers
read -p "Do you want to clean up all dangling Docker images and containers? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up dangling Docker resources..."
    docker system prune -f
    print_status "Dangling resources cleaned up."
fi

print_status "✅ Docker cleanup completed successfully!"

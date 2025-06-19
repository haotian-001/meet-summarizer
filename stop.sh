#!/bin/bash

# Meet Summarizer Stop Script
# This script stops and removes the Docker container

set -e  # Exit on any error

echo "🛑 Stopping Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
CONTAINER_NAME="${APP_NAME}-container"

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

# Check if container exists and is running
if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping container: $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME"
    print_status "Container stopped successfully."
else
    print_warning "Container $CONTAINER_NAME is not running."
fi

# Check if container exists (stopped)
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Removing container: $CONTAINER_NAME..."
    docker rm "$CONTAINER_NAME"
    print_status "Container removed successfully."
else
    print_warning "Container $CONTAINER_NAME does not exist."
fi

print_status "✅ Meet Summarizer stopped and cleaned up successfully!"

#!/bin/bash

# Meet Summarizer Deployment Script
# This script sets up and runs the application using Docker containers

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
CONTAINER_NAME="${APP_NAME}-container"
IMAGE_NAME="${APP_NAME}-image"
APP_PORT="7860"
DOCKERFILE_PATH="."

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

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This is acceptable for server deployment."
fi

# Get current directory (assuming script is run from the project directory)
CURRENT_DIR=$(pwd)
print_status "Working in directory: $CURRENT_DIR"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Check if .env file exists for environment variables
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating template..."
    cat > .env << 'EOF'
# OpenRouter API Key for LLM calls
OPENROUTER_API_KEY=your_api_key_here
EOF
    print_warning "Please edit .env file and add your OPENROUTER_API_KEY"
    print_warning "Then run this script again."
    exit 1
fi

# Source environment variables
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Check if OPENROUTER_API_KEY is set
if [ -z "$OPENROUTER_API_KEY" ] || [ "$OPENROUTER_API_KEY" = "your_api_key_here" ]; then
    print_error "OPENROUTER_API_KEY is not set in .env file. Please configure it first."
    exit 1
fi

# Stop and remove existing container if running
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping existing container: $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME" || true
    print_status "Removing existing container: $CONTAINER_NAME..."
    docker rm "$CONTAINER_NAME" || true
fi

# Kill any process using the port (in case something else is using it)
print_status "Checking for processes using port $APP_PORT..."
if lsof -ti:$APP_PORT > /dev/null 2>&1; then
    print_warning "Port $APP_PORT is in use. Attempting to free it..."
    lsof -ti:$APP_PORT | xargs -r kill -9 || true
    sleep 2
fi

# Remove old Docker image if it exists
if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}:latest$"; then
    print_status "Removing old Docker image: $IMAGE_NAME..."
    docker rmi "$IMAGE_NAME:latest" || print_warning "Failed to remove old image, continuing..."
fi

# Build Docker image
print_status "Building Docker image: $IMAGE_NAME..."
if ! docker build -t "$IMAGE_NAME:latest" "$DOCKERFILE_PATH"; then
    print_error "Failed to build Docker image!"
    exit 1
fi

print_status "Docker image built successfully!"

# Verify necessary files exist
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found!"
    exit 1
fi

if [ ! -f "app.py" ]; then
    print_error "app.py not found!"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found!"
    exit 1
fi

# Create and start Docker container
print_status "Starting Docker container: $CONTAINER_NAME..."
if ! docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$APP_PORT:7860" \
    --env-file .env \
    -e PYTHONUNBUFFERED=1 \
    -e GRADIO_SERVER_NAME=0.0.0.0 \
    -e GRADIO_SERVER_PORT=7860 \
    "$IMAGE_NAME:latest"; then
    print_error "Failed to start Docker container!"
    exit 1
fi

# Wait a moment for the application to start
print_status "Waiting for application to start..."
sleep 15

# Check if container is running
if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:$APP_PORT"
    print_status "Container name: $CONTAINER_NAME"
    print_status "Docker image: $IMAGE_NAME:latest"

    # Show recent logs
    print_status "Recent application logs:"
    docker logs --tail 10 "$CONTAINER_NAME" || print_warning "No logs available yet"

    print_status "🎉 Deployment completed successfully!"
    print_status "To view logs: docker logs -f $CONTAINER_NAME"
    print_status "To stop the application: docker stop $CONTAINER_NAME"
    print_status "To remove the container: docker rm $CONTAINER_NAME"
else
    print_error "❌ Deployment failed!"
    print_error "Container logs:"
    docker logs "$CONTAINER_NAME" || echo "No logs available"
    exit 1
fi

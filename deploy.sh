#!/bin/bash

# Meet Summarizer Deployment Script
# This script builds and runs Docker containers while removing old ones

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
DOCKER_IMAGE_NAME="meet-summarizer"
CONTAINER_NAME="meet-summarizer-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. Consider using a non-root user with Docker permissions."
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Get current directory (assuming script is run from the project directory)
CURRENT_DIR=$(pwd)
print_status "Working in directory: $CURRENT_DIR"

# Check if .env file exists for environment variables
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating template..."
    cat > .env << EOF
# OpenRouter API Key for LLM calls
OPENROUTER_API_KEY=your_api_key_here
EOF
    print_warning "Please edit .env file and add your OPENROUTER_API_KEY"
    print_warning "Then run this script again."
    exit 1
fi

# Stop and remove existing containers
print_status "Stopping and removing existing containers..."
docker-compose down --remove-orphans || true

# Remove old images and containers to free up space
print_status "Cleaning up old Docker resources..."
# Remove stopped containers
docker container prune -f || true
# Remove unused images
docker image prune -f || true
# Remove unused networks
docker network prune -f || true
# Remove unused volumes (be careful with this)
docker volume prune -f || true

# Remove specific old images of this app if they exist
print_status "Removing old $DOCKER_IMAGE_NAME images..."
docker images | grep "$DOCKER_IMAGE_NAME" | awk '{print $3}' | xargs -r docker rmi -f || true

# Build and start the new container
print_status "Building and starting new container..."
docker-compose up -d --build --force-recreate

# Wait for container to be healthy
print_status "Waiting for container to be ready..."
sleep 15

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:7860"
    print_status "Container status:"
    docker-compose ps

    # Show resource usage
    print_status "Docker system usage:"
    docker system df
else
    print_error "❌ Deployment failed!"
    print_error "Container logs:"
    docker-compose logs
    exit 1
fi

# Show logs
print_status "Recent logs:"
docker-compose logs --tail=20

print_status "🎉 Deployment completed successfully!"
print_status "You can view logs with: docker-compose logs -f"
print_status "To stop the application: docker-compose down"
print_status "To clean up all Docker resources: docker system prune -a"

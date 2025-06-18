#!/bin/bash

# Meet Summarizer Deployment Script for Ubuntu Server
# This script pulls the latest code and rebuilds the Docker container

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
REPO_DIR="/opt/meet-summarizer"
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

# Create app directory if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    print_status "Creating application directory: $REPO_DIR"
    sudo mkdir -p "$REPO_DIR"
    sudo chown $USER:$USER "$REPO_DIR"
fi

# Navigate to the repository directory
cd "$REPO_DIR"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    print_status "Initializing git repository..."
    git init
    # You'll need to add your remote repository URL here
    print_warning "Please set up your git remote repository:"
    print_warning "git remote add origin <your-repo-url>"
    print_warning "Then run this script again."
    exit 1
fi

# Pull the latest changes
print_status "Pulling latest changes from repository..."
git fetch --all
git reset --hard origin/main

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

# Stop existing container if running
print_status "Stopping existing container..."
docker-compose down || true

# Remove old images to free up space (optional)
print_status "Cleaning up old Docker images..."
docker image prune -f || true

# Build and start the new container
print_status "Building and starting new container..."
docker-compose up -d --build

# Wait for container to be healthy
print_status "Waiting for container to be ready..."
sleep 10

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:7860"
    print_status "Container status:"
    docker-compose ps
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

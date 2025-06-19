#!/bin/bash

# Meet Summarizer Docker Compose Deployment Script
# This script uses docker-compose for easier container management

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer with Docker Compose..."

# Configuration
APP_NAME="meet-summarizer"

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

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
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
    cp .env.example .env || {
        cat > .env << 'EOF'
# OpenRouter API Key for LLM calls
OPENROUTER_API_KEY=your_api_key_here
EOF
    }
    print_warning "Please edit .env file and add your OPENROUTER_API_KEY"
    print_warning "Then run this script again."
    exit 1
fi

# Source environment variables
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# Check if OPENROUTER_API_KEY is set
if [ -z "$OPENROUTER_API_KEY" ] || [ "$OPENROUTER_API_KEY" = "your_api_key_here" ] || [ "$OPENROUTER_API_KEY" = "your_openrouter_api_key_here" ]; then
    print_error "OPENROUTER_API_KEY is not set in .env file. Please configure it first."
    exit 1
fi

# Verify necessary files exist
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found!"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found!"
    exit 1
fi

# Stop existing services
print_status "Stopping existing services..."
docker-compose down || docker compose down || true

# Build and start services
print_status "Building and starting services with Docker Compose..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d --build
else
    docker compose up -d --build
fi

# Wait a moment for the application to start
print_status "Waiting for application to start..."
sleep 15

# Check if services are running
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

if $COMPOSE_CMD ps | grep -q "Up"; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:7860"
    
    # Show service status
    print_status "Service status:"
    $COMPOSE_CMD ps

    # Show recent logs
    print_status "Recent application logs:"
    $COMPOSE_CMD logs --tail 10 || print_warning "No logs available yet"

    print_status "🎉 Deployment completed successfully!"
    print_status "To view logs: $COMPOSE_CMD logs -f"
    print_status "To stop the application: $COMPOSE_CMD down"
    print_status "To restart: $COMPOSE_CMD restart"
else
    print_error "❌ Deployment failed!"
    print_error "Service logs:"
    $COMPOSE_CMD logs || echo "No logs available"
    exit 1
fi

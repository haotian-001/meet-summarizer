#!/bin/bash

# Meet Summarizer Deployment Script
# This script sets up and runs the application using uv and virtual environments

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
APP_PORT="7860"
VENV_NAME=".venv"

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

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    print_error "uv is not installed. Please install uv first."
    print_error "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first."
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

# Kill any existing process using the port
print_status "Checking for processes using port $APP_PORT..."
if lsof -ti:$APP_PORT > /dev/null 2>&1; then
    print_warning "Port $APP_PORT is in use. Attempting to free it..."
    lsof -ti:$APP_PORT | xargs -r kill -9 || true
    sleep 2
fi

# Kill any existing Python processes running the app
print_status "Stopping any existing application processes..."
pkill -f "python.*app.py" || true
pkill -f "gradio.*app.py" || true
sleep 2

# Create or recreate virtual environment
print_status "Setting up virtual environment with uv..."
if [ -d "$VENV_NAME" ]; then
    print_status "Removing existing virtual environment..."
    rm -rf "$VENV_NAME"
fi

print_status "Creating new virtual environment..."
uv venv "$VENV_NAME"

# Activate virtual environment
print_status "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

# Verify necessary files exist
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found!"
    exit 1
fi

if [ ! -f "app.py" ]; then
    print_error "app.py not found!"
    exit 1
fi

# Set proxy settings for network access
print_status "Setting up proxy configuration..."
export http_proxy=http://asus:7890
export https_proxy=http://asus:7890

# Install dependencies using uv
print_status "Installing dependencies with uv..."
if ! uv pip install -r requirements.txt; then
    print_error "Failed to install dependencies!"
    exit 1
fi

print_status "Dependencies installed successfully!"

# Set environment variables for the application
export PYTHONUNBUFFERED=1
export GRADIO_SERVER_NAME=0.0.0.0
export GRADIO_SERVER_PORT=7860

# Clear all proxy settings for the application runtime to avoid conflicts
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset all_proxy
unset ALL_PROXY
unset no_proxy
unset NO_PROXY

# Create a PID file to track the application process
PID_FILE="/tmp/${APP_NAME}.pid"

# Start the application in the background
print_status "Starting application..."
nohup python app.py > "/tmp/${APP_NAME}.log" 2>&1 &
APP_PID=$!

# Save the PID for later management
echo $APP_PID > "$PID_FILE"

# Wait a moment for the application to start
print_status "Waiting for application to start..."
sleep 10

# Check if the process is still running
if kill -0 $APP_PID 2>/dev/null; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:$APP_PORT"
    print_status "Process ID: $APP_PID"
    print_status "Virtual environment: $VENV_NAME"
    print_status "Log file: /tmp/${APP_NAME}.log"

    # Show recent logs
    print_status "Recent application logs:"
    tail -10 "/tmp/${APP_NAME}.log" 2>/dev/null || print_warning "No logs available yet"

    print_status "🎉 Deployment completed successfully!"
    print_status "To view logs: tail -f /tmp/${APP_NAME}.log"
    print_status "To stop the application: kill $APP_PID"
    print_status "Or use: pkill -f 'python.*app.py'"
else
    print_error "❌ Deployment failed!"
    print_error "Application logs:"
    cat "/tmp/${APP_NAME}.log" 2>/dev/null || echo "No logs available"
    exit 1
fi

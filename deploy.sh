#!/bin/bash

# Meet Summarizer Deployment Script
# This script sets up and runs the application using Python virtual environment

set -e  # Exit on any error

echo "🚀 Starting deployment of Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
VENV_DIR="venv"
APP_PORT="7860"
PID_FILE="app.pid"

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

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    print_error "pip is not installed. Please install pip first."
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

# Stop existing application if running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        print_status "Stopping existing application (PID: $OLD_PID)..."
        kill "$OLD_PID" || true
        sleep 3
        # Force kill if still running
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            print_warning "Force killing application (PID: $OLD_PID)..."
            kill -9 "$OLD_PID" || true
        fi
    fi
    rm -f "$PID_FILE"
fi

# Kill any process using the port
print_status "Checking for processes using port $APP_PORT..."
if lsof -ti:$APP_PORT > /dev/null 2>&1; then
    print_warning "Port $APP_PORT is in use. Attempting to free it..."
    lsof -ti:$APP_PORT | xargs -r kill -9 || true
    sleep 2
fi

# Install system dependencies if needed (for CentOS/RHEL)
if command -v yum &> /dev/null; then
    print_status "Installing system dependencies with yum..."
    yum install -y gcc gcc-c++ python3-devel || print_warning "Some system packages may already be installed"
elif command -v apt-get &> /dev/null; then
    print_status "Installing system dependencies with apt..."
    apt-get update && apt-get install -y gcc g++ python3-dev python3-venv || print_warning "Some system packages may already be installed"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    print_status "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    print_status "Virtual environment already exists. Updating..."
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install requirements
if [ -f "requirements.txt" ]; then
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
else
    print_error "requirements.txt not found!"
    exit 1
fi

# Create templates directory if it doesn't exist
mkdir -p templates

# Set environment variables for the application
export PYTHONUNBUFFERED=1
export GRADIO_SERVER_NAME=0.0.0.0
export GRADIO_SERVER_PORT=$APP_PORT

# Start the application in background
print_status "Starting Meet Summarizer application..."
nohup python app.py > app.log 2>&1 &
APP_PID=$!

# Save PID for later management
echo $APP_PID > "$PID_FILE"

# Wait a moment for the application to start
print_status "Waiting for application to start..."
sleep 10

# Check if application is running
if ps -p "$APP_PID" > /dev/null 2>&1; then
    print_status "✅ Deployment successful!"
    print_status "Application is running on http://localhost:$APP_PORT"
    print_status "Application PID: $APP_PID"
    print_status "Log file: app.log"

    # Show recent logs
    print_status "Recent application logs:"
    tail -n 10 app.log || print_warning "No logs available yet"

    print_status "🎉 Deployment completed successfully!"
    print_status "To view logs: tail -f app.log"
    print_status "To stop the application: kill $APP_PID or run: ./stop.sh"
else
    print_error "❌ Deployment failed!"
    print_error "Application logs:"
    cat app.log || echo "No log file found"
    exit 1
fi

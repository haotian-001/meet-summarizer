#!/bin/bash

# Meet Summarizer Stop Script
# This script stops the application running with uv and virtual environment

set -e  # Exit on any error

echo "🛑 Stopping Meet Summarizer..."

# Configuration
APP_NAME="meet-summarizer"
APP_PORT="7860"
PID_FILE="/tmp/${APP_NAME}.pid"

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

# Stop application using PID file if it exists
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        print_status "Stopping application with PID: $PID..."
        kill "$PID"
        sleep 2

        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            print_warning "Process still running, force killing..."
            kill -9 "$PID" 2>/dev/null || true
        fi

        print_status "Application stopped successfully."
    else
        print_warning "Process with PID $PID is not running."
    fi

    # Remove PID file
    rm -f "$PID_FILE"
else
    print_warning "PID file not found."
fi

# Kill any remaining Python processes running the app
print_status "Stopping any remaining application processes..."
pkill -f "python.*app.py" || print_warning "No additional processes found."
pkill -f "gradio.*app.py" || true

# Kill any process using the port
if lsof -ti:$APP_PORT > /dev/null 2>&1; then
    print_status "Freeing port $APP_PORT..."
    lsof -ti:$APP_PORT | xargs -r kill -9 || true
fi

print_status "✅ Meet Summarizer stopped and cleaned up successfully!"

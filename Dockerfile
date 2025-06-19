# Use Python 3.11 slim image
FROM python:3.11-slim

# Accept proxy settings as build arguments (optional)
ARG http_proxy
ARG https_proxy

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create templates directory if it doesn't exist
RUN mkdir -p templates

# Expose port 7860 (Gradio default)
EXPOSE 7860

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860

# Set proxy environment variables for runtime
ENV http_proxy=http://asus:7890
ENV https_proxy=http://asus:7890

# Run the application
CMD ["python", "app.py"]

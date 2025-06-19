# Meet Summarizer - Docker Deployment Guide

This document provides comprehensive instructions for deploying the Meet Summarizer application using Docker containers.

## Overview

The deployment has been updated to use Docker containers instead of Python virtual environments, providing:

- ✅ **Containerized deployment** - No more venv management
- ✅ **Consistent environment** - Same runtime across all deployments
- ✅ **Easy cleanup** - Simple container management
- ✅ **Port isolation** - No conflicts with host system
- ✅ **Proxy support** - Built-in proxy configuration for network access

## Available Deployment Methods

### Method 1: Direct Docker (Recommended)
Use the main deployment script that builds and runs Docker containers directly:

```bash
./deploy.sh
```

### Method 2: Docker Compose
Use Docker Compose for more advanced container orchestration:

```bash
./deploy-compose.sh
```

## Deployment Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `deploy.sh` | Main deployment | Builds Docker image and runs container |
| `deploy-compose.sh` | Compose deployment | Uses docker-compose for orchestration |
| `stop.sh` | Stop application | Stops and removes the running container |
| `docker-cleanup.sh` | Cleanup resources | Removes containers and images |

## Pre-Deployment Checklist

1. **Docker Installation**
   ```bash
   # Check if Docker is installed
   docker --version
   docker-compose --version  # Optional, for compose method
   ```

2. **Environment Configuration**
   ```bash
   # Copy and edit environment file
   cp .env.example .env
   # Edit .env and set your OPENROUTER_API_KEY
   ```

3. **File Verification**
   Ensure these files exist:
   - `Dockerfile`
   - `docker-compose.yml`
   - `requirements.txt`
   - `app.py`
   - `templates/template.docx`

## Deployment Process

### Step 1: Environment Setup
```bash
# Clone repository (if not already done)
git clone <repository-url>
cd meet-summarizer

# Set up environment variables
cp .env.example .env
# Edit .env file with your API key
nano .env  # or vim .env
```

### Step 2: Deploy Application
```bash
# Option A: Direct Docker deployment
./deploy.sh

# Option B: Docker Compose deployment
./deploy-compose.sh
```

### Step 3: Verify Deployment
```bash
# Check if container is running
docker ps

# View application logs
docker logs meet-summarizer-container

# Test application
curl http://localhost:7860
```

## Container Management

### Viewing Logs
```bash
# Real-time logs
docker logs -f meet-summarizer-container

# Recent logs (last 50 lines)
docker logs --tail 50 meet-summarizer-container
```

### Container Operations
```bash
# Stop the application
./stop.sh

# Restart container
docker restart meet-summarizer-container

# Access container shell
docker exec -it meet-summarizer-container /bin/bash
```

### Resource Monitoring
```bash
# View container resource usage
docker stats meet-summarizer-container

# View container details
docker inspect meet-summarizer-container
```

## Troubleshooting

### Common Issues and Solutions

1. **Port 7860 already in use**
   ```bash
   # Find and kill process using the port
   lsof -ti:7860 | xargs kill -9
   # Or use the deployment script (it handles this automatically)
   ```

2. **Docker daemon not running**
   ```bash
   # Start Docker service (Linux)
   sudo systemctl start docker
   
   # Start Docker Desktop (macOS/Windows)
   # Open Docker Desktop application
   ```

3. **Permission denied errors**
   ```bash
   # Add user to docker group (Linux)
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

4. **Container fails to start**
   ```bash
   # Check container logs for errors
   docker logs meet-summarizer-container
   
   # Verify environment variables
   docker exec meet-summarizer-container env | grep OPENROUTER
   ```

5. **API key issues**
   ```bash
   # Verify .env file exists and has correct key
   cat .env
   
   # Test API key manually
   curl -H "Authorization: Bearer YOUR_API_KEY" https://openrouter.ai/api/v1/models
   ```

### Debug Mode

To run the container in debug mode:

```bash
# Run container interactively
docker run -it --rm \
  -p 7860:7860 \
  --env-file .env \
  meet-summarizer-image:latest \
  /bin/bash

# Then manually start the application
python app.py
```

## Network Configuration

### Proxy Settings
The Dockerfile includes proxy settings for environments that require them:

```dockerfile
ENV http_proxy=http://asus:7890
ENV https_proxy=http://asus:7890
```

To modify proxy settings:
1. Edit the `Dockerfile`
2. Update the proxy URLs
3. Rebuild the image: `./deploy.sh`

### Port Configuration
To change the application port:

1. **Update Dockerfile**:
   ```dockerfile
   EXPOSE 8080  # Change from 7860
   ENV GRADIO_SERVER_PORT=8080
   ```

2. **Update deployment script**:
   ```bash
   # In deploy.sh, change:
   APP_PORT="8080"
   ```

3. **Redeploy**:
   ```bash
   ./deploy.sh
   ```

## Performance Optimization

### Resource Limits
Add resource limits to prevent container from consuming too much memory:

```bash
# Run with memory limit
docker run -d \
  --name meet-summarizer-container \
  --memory="2g" \
  --cpus="1.0" \
  -p 7860:7860 \
  --env-file .env \
  meet-summarizer-image:latest
```

### Volume Mounts
For persistent data or custom templates:

```bash
# Mount custom templates directory
docker run -d \
  --name meet-summarizer-container \
  -p 7860:7860 \
  --env-file .env \
  -v $(pwd)/templates:/app/templates:ro \
  meet-summarizer-image:latest
```

## Security Considerations

1. **Environment Variables**: Never commit `.env` files to version control
2. **API Keys**: Rotate API keys regularly
3. **Network**: Consider using Docker networks for multi-container setups
4. **Updates**: Regularly update base images and dependencies

## Backup and Recovery

### Backup Configuration
```bash
# Backup environment and configuration
tar -czf meet-summarizer-backup.tar.gz .env templates/ docker-compose.yml
```

### Recovery Process
```bash
# Extract backup
tar -xzf meet-summarizer-backup.tar.gz

# Redeploy
./deploy.sh
```

## Production Deployment

For production environments, consider:

1. **Use Docker Compose** with proper service definitions
2. **Set up reverse proxy** (nginx) for SSL termination
3. **Configure logging** with log rotation
4. **Set up monitoring** and health checks
5. **Use secrets management** for API keys
6. **Configure backup strategy** for data persistence

Example production docker-compose.yml additions:
```yaml
services:
  meet-summarizer:
    # ... existing configuration
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review container logs: `docker logs meet-summarizer-container`
3. Verify all prerequisites are installed
4. Ensure environment variables are correctly set
5. Test with a minimal configuration first

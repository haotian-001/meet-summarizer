# Meet Summarizer ⚡

A powerful AI-powered meeting summarizer that converts meeting transcripts into structured meeting minutes using advanced language models.

## Features

- 📝 **Smart Summarization**: Converts raw meeting transcripts into structured meeting minutes
- 🤖 **Multiple AI Models**: Support for Google Gemini and other leading language models
- 📄 **Word Document Processing**: Upload .docx files and get formatted meeting minutes
- 🎯 **Agenda Management**: AI-generated or manual agenda input
- 🔄 **Self-Reflection**: AI reviews and improves its own output for better accuracy
- 🐳 **Docker Support**: Easy deployment with Docker containers

## Quick Start

### Prerequisites

- Docker installed and running
- OpenRouter API key (for AI model access)

### Docker Deployment (Recommended)

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd meet-summarizer
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env and add your OPENROUTER_API_KEY
   ```

3. **Deploy with Docker**:
   ```bash
   ./deploy.sh
   ```

4. **Access the application**:
   Open your browser and go to `http://localhost:7860`

### Manual Deployment (Alternative)

If you prefer not to use Docker, you can still deploy manually:

1. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables**:
   ```bash
   export OPENROUTER_API_KEY=your_api_key_here
   ```

3. **Run the application**:
   ```bash
   python app.py
   ```

## Usage

1. **Upload a meeting transcript**: Upload a .docx file containing your meeting transcript
2. **Select AI model**: Choose from available models (Google Gemini recommended)
3. **Configure agenda**: Use AI-generated agenda or input manually
4. **Generate summary**: Click "Generate Meeting Minutes" to process
5. **Download result**: Download the formatted meeting minutes as a Word document

## Docker Management

### Available Scripts

- `./deploy.sh` - Build and deploy the application with Docker
- `./stop.sh` - Stop and remove the running container
- `./docker-cleanup.sh` - Clean up Docker images and containers

### Docker Commands

```bash
# View running containers
docker ps

# View application logs
docker logs -f meet-summarizer-container

# Stop the application
docker stop meet-summarizer-container

# Remove the container
docker rm meet-summarizer-container

# Remove the image
docker rmi meet-summarizer-image:latest
```

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# Required: OpenRouter API Key for AI model access
OPENROUTER_API_KEY=your_api_key_here

# Optional: Application settings
GRADIO_SERVER_NAME=0.0.0.0
GRADIO_SERVER_PORT=7860
PYTHONUNBUFFERED=1
```

### Supported Models

- `google/gemini-2.5-flash` (Default, recommended)
- `google/gemini-pro-1.5`
- Additional models can be configured in `app.py`

## File Structure

```
meet-summarizer/
├── app.py                 # Main application file
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── docker-compose.yml    # Docker Compose configuration
├── deploy.sh            # Docker deployment script
├── stop.sh              # Container stop script
├── docker-cleanup.sh    # Docker cleanup script
├── templates/           # Word document templates
│   └── template.docx    # Meeting minutes template
└── .env                 # Environment variables (create from .env.example)
```

## Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Kill process using port 7860
   lsof -ti:7860 | xargs kill -9
   ```

2. **Docker permission denied**:
   ```bash
   # Add user to docker group (Linux)
   sudo usermod -aG docker $USER
   # Then logout and login again
   ```

3. **Container won't start**:
   ```bash
   # Check container logs
   docker logs meet-summarizer-container

   # Check if .env file exists and has correct API key
   cat .env
   ```

4. **API key issues**:
   - Ensure your OpenRouter API key is valid
   - Check that the key is properly set in the `.env` file
   - Verify the key has sufficient credits

### Logs and Debugging

```bash
# View real-time logs
docker logs -f meet-summarizer-container

# View recent logs
docker logs --tail 50 meet-summarizer-container

# Access container shell for debugging
docker exec -it meet-summarizer-container /bin/bash
```

## Development

### Local Development

1. **Set up virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run in development mode**:
   ```bash
   python app.py
   ```

### Building Custom Docker Image

```bash
# Build image with custom tag
docker build -t meet-summarizer:custom .

# Run with custom image
docker run -d --name meet-summarizer-custom -p 7860:7860 --env-file .env meet-summarizer:custom
```

## License

Apache License 2.0 - see LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review application logs for error messages
3. Ensure all prerequisites are properly installed
4. Verify environment variables are correctly set

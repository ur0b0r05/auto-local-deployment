# React Auto Deploy

A complete solution for automatically deploying a React app that displays "Hello XXX," where XXX is set via an environment variable. This setup includes Docker, Nginx, and Cloudflare Tunnel for seamless deployment.

## TL;DR

1. **Clone & Configure:**
   ```bash
   git clone https://github.com/yourusername/react-auto-deploy.git
   cd react-auto-deploy
   make check-prereqs
   ```

2. **Build & Deploy:**
   ```bash
   make setup
   make deploy
   ```

3. **Verify Installation:**
   ```bash
   docker ps
   make logs
   ```

> 🚀 **Your app should now be accessible via the Cloudflare Tunnel URL!**

## Prerequisites

Ensure you have the required tools installed:

```bash
# Verify installations
docker --version
docker-compose --version
git --version
make --version
```

> 💡 **Tip**: If any tool is missing, install it:
> - [Docker](https://docs.docker.com/get-docker/)
> - [Docker Compose](https://docs.docker.com/compose/install/)
> - [Git](https://git-scm.com/downloads)
> - [Make](https://www.gnu.org/software/make/)

## Features

- ✅ React app displaying "Hello XXX"
- ✅ Environment variable support
- ✅ Automated Git-based deployment
- ✅ Dockerized setup with Nginx reverse proxy
- ✅ Cloudflare Tunnel for public access
- ✅ Makefile for simplified setup & deployment

## Project Structure

```
react-auto-deploy/
├── src/                   # React app (Hello XXX)
├── docker/                # Deployment scripts
│   ├── Dockerfile
│   └── post-receive
├── nginx/
│   └── nginx.conf         # Reverse proxy config
├── .env                   # Environment variables
├── Makefile               # Setup & deployment commands
├── docker-compose.yml     # Multi-container setup
└── .gitignore
```

## Installation & Setup

### 1. Clone & Configure

```bash
# Clone the repository
git clone https://github.com/yourusername/react-auto-deploy.git
cd react-auto-deploy

# Verify prerequisites
make check-prereqs

# Copy environment file
cp .env.example .env

# Update .env (optional)
# Example: REACT_APP_NAME=Alice
```

### 2. Build & Deploy

```bash
# Setup and deploy
make setup
make deploy
```

> 🚀 **Done!**
> - Find your Cloudflare Tunnel URL in the output
> - Visit the URL to see "Hello XXX"
> - Modify `REACT_APP_NAME` in `.env` and redeploy to update

### 3. Verify Installation

```bash
# Check running containers
docker ps

# Expected containers:
# - react-auto-deploy-frontend
# - react-auto-deploy-nginx
# - react-auto-deploy-cloudflare-tunnel

# View logs
make logs
```

> ❌ **Issues?**
> 1. Ensure Docker is running: `sudo systemctl status docker`
> 2. Check for port conflicts: `sudo lsof -i :2222 -i :3000`
> 3. Clean and restart: `make clean && make setup`

## Environment Variables

| Variable        | Description                             | Default |
|----------------|-----------------------------------------|---------|
| REACT_APP_NAME | Name displayed in "Hello XXX"         | `XXX`   |
| DOCKER_SSH_PORT | SSH port for Git deployments         | `2222`  |
| DEPLOY_USER    | Deployment username                   | `deploy`|

> ⚙️ **To update displayed name:**
> 1. Edit `.env`: `REACT_APP_NAME=Alice`
> 2. Run: `make deploy`

## Available Commands

```bash
make help           # Show available commands
make check-prereqs  # Verify required tools
make setup         # Initial setup
make deploy        # Deploy the app
make logs          # View logs
make clean         # Reset the setup
```

> 🛠️ **Tip**: Run `make help` to see command descriptions.

## Troubleshooting

### Common Issues & Fixes

1. **Docker not running**
```bash
sudo systemctl start docker
```

2. **Port conflicts**
```bash
sudo lsof -i :2222 -i :3000
```

3. **Deployment fails**
```bash
make logs  # Check logs for details
```

## Security Best Practices

🔒 Secure deployments via:
- **SSH keys** for authentication
- **Nginx** as a reverse proxy
- **Cloudflare Tunnel** for secure public access

> ⚠️ **Never commit `.env` or SSH keys to version control.**

## Development

To modify "Hello XXX":

1. Edit `.env`:
```bash
REACT_APP_NAME=YourName
```

2. Deploy changes:
```bash
make deploy
```

> 💻 **Tip**: Restart without full redeployment:
> ```bash
> docker-compose restart frontend
> ```



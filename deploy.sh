#!/bin/bash
#
# deploy.sh
# This script installs Docker and Docker Compose if missing,
# creates a .env file,
# and builds & starts the deployment via Docker Compose.
#
# Usage:
#   chmod +x deploy.sh
#   sudo ./deploy.sh
#

set -euo pipefail

echo "== Updating package lists =="
sudo apt-get update

echo "== Installing Docker (if not already installed) =="
if ! command -v docker &>/dev/null; then
    sudo apt-get install -y docker.io
else
    echo "Docker is already installed."
fi

echo "== Installing Docker Compose =="
if ! command -v docker-compose &>/dev/null; then
    echo "Docker Compose not found. Installing standalone Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

echo "== Enabling and starting Docker service =="
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version

# We assume that the repository is already cloned and you are in the repository root.

# Create the .env file if it does not exist.
if [ ! -f ".env" ]; then
    echo "== Creating .env file =="
    cat > .env <<EOF
SOCRATA_API_TOKEN=uHoP8dT0q1BTcacXLCcxrDp8z
LAKE_PATH=/app/data/lake
WAREHOUSE_PATH=/app/data/data.duckdb
EOF
    echo ".env file created."
else
    echo ".env file already exists; using existing file."
fi

# Clean up any existing containers (remove volumes and orphaned containers).
echo "== Stopping and cleaning up existing containers =="
docker-compose down --volumes --remove-orphans

# Build the Docker images without using cache for a fresh build.
echo "== Building Docker images =="
docker-compose build --no-cache

# Start the containers in detached mode.
echo "== Starting Docker Compose deployment =="
docker-compose up -d

# Wait a few seconds to let containers initialize.
sleep 5

# List running containers.
echo "== Running containers =="
docker ps

# Retrieve the droplet's public IP.
DROPLET_IP=$(curl -s ifconfig.me)

echo "== Deployment complete! =="
echo "Your Dagster Webserver should be accessible at: http://$DROPLET_IP:3000"

#!/bin/bash

# Exit on error
set -e

# Variables
USER=ubuntu
REPO_URL="https://github.com/VMLVaske/drunken-banana.git"
TARGET_DIR="/home/$USER/drunken-banana"
DOCKER_COMPOSE_VERSION="v2.24.5"

# Install dependencies
apt-get update && apt-get install -y \
    git \
    curl \
    docker.io \
    docker-compose \
    mailutils

# Add ubuntu user to docker group
usermod -aG docker $USER

# Clone repo
if [ ! -d "$TARGET_DIR" ]; then
    git clone $REPO_URL $TARGET_DIR
    chown -R $USER:$USER $TARGET_DIR
fi

# Run setup script
cd $TARGET_DIR/setup
chmod +x setup.sh
sudo -u $USER ./setup.sh

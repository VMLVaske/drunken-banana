#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -e

# Variables
USER=ubuntu
REPO_URL="https://github.com/VMLVaske/drunken-banana.git"
TARGET_DIR="/home/$USER/drunken-banana"

# Update system
apt-get update -y
apt-get install -y \
    git \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker (official way)
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker $USER

# Clone the repo
if [ ! -d "$TARGET_DIR" ]; then
    echo "[+] Cloning repo..." >>/var/log/ghost-setup.log
    sudo -u $USER git clone $REPO_URL $TARGET_DIR >>/var/log/ghost-setup.log 2>&1
fi

# Run the setup script as the ubuntu user
echo "[+] Setting permissions..." >>/var/log/ghost-setup.log
chmod +x $TARGET_DIR/setup/setup.sh >>/var/log/ghost-setup.log 2>&1
echo "[+] Running setup.sh..." >>/var/log/ghost-setup.log
sudo -u $USER bash -c "cd $TARGET_DIR/setup && ./setup.sh" >>/var/log/ghost-setup.log 2>&1

echo "[✓] Userdata script completed successfully." >>/var/log/ghost-setup.log

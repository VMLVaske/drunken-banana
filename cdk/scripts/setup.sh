#!/bin/bash
set -e

# Update system and install base packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx git curl

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Ghost CLI globally
sudo npm install -g ghost-cli

# Create ghost user and setup directory
sudo useradd -m ghostuser || true
sudo mkdir -p /var/www/ghost
sudo chown ghostuser:ghostuser /var/www/ghost
sudo chmod 775 /var/www/ghost

# Install Ghost (local mode)
# Install Ghost
sudo -u ghostuser -H bash -c "cd /var/www/ghost && ghost install local --no-prompt | tee /tmp/ghost-install.log"

# Output Ghost install logs for debugging
sudo cat /tmp/ghost-install.log

# Ensure NGINX directory structure exists
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

# Remove default NGINX config completely (both the file AND the symlink)
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default

# Create Ghost reverse proxy config
sudo bash -c 'cat > /etc/nginx/sites-available/ghost' <<'EOF'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:2368;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the Ghost config
sudo ln -sf /etc/nginx/sites-available/ghost /etc/nginx/sites-enabled/ghost

# Fix broken install if nginx failed earlier
sudo apt install -f -y

# Test and restart NGINX
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

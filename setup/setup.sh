#!/bin/bash

set -e

LOG_FILE="/home/ubuntu/ghost-setup.log"
LOG_DIR="/home/ubuntu/logs"
mkdir -p "$LOG_DIR"

# -----------------------
# Wait until cloud-init / apt is done
# -----------------------
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for other apt processes to finish..."
    sleep 5
done

cd "$(dirname "$0")"

echo "[+] Starting Ghost via Docker Compose..."
docker compose up -d

# -----------------------
# Setup backup cronjob
# -----------------------
echo "[+] Setting up backup cronjob..." >>$LOG_FILE
sudo cp /home/ubuntu/drunken-banana/setup/ghost-backup.sh /usr/local/bin/ghost-backup
sudo chmod +x /usr/local/bin/ghost-backup

# Add cronjob if it doesn't already exist
if ! crontab -l 2>/dev/null | grep -q ghost-backup; then
    (
        # Runs Cronjob every night at 3:00 AM
        #echo "0 3 * * * /usr/local/bin/ghost-backup >> $LOG_DIR/ghost-backup.log 2>&1"
        #For Debugging - run Cronjob every 15 mins
        crontab -l 2>/dev/null
        echo "*/15 * * * * /usr/local/bin/ghost-backup >> $LOG_DIR/ghost-backup.log 2>&1"
    ) | crontab -
fi

# -----------------------
# Mailing out Metadata
# -----------------------
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt lock (mailutils)..."
    sleep 5
done
# Preconfigure Postfix so it doesn't block with an interactive prompt
echo "postfix postfix/mailname string your-domain.com" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Local only'" | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mailutils

# -----------------------
# Install & configure NGINX
# -----------------------
echo "[+] Installing NGINX..."
sudo apt-get install -y nginx

echo "[+] Configuring NGINX to proxy Ghost..."
sudo tee /etc/nginx/sites-available/ghost >/dev/null <<EOF
server {
    listen 80;
    server_name _ default;

    location / {
        proxy_pass http://localhost:2368;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/ghost /etc/nginx/sites-enabled/ghost
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "[✓] NGINX installed and configured."

echo "[✓] Setup complete." >>$LOG_FILE

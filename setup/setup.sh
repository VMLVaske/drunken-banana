#!/bin/bash

set -e

LOG_FILE="/home/ubuntu/ghost-setup.log"

cd "$(dirname "$0")"

echo "[+] Starting Ghost via Docker Compose..."
docker compose up -d

# Setup backup cronjob
echo "[+] Setting up backup cronjob..." >>$LOG_FILE
cp /home/ubuntu/drunken-banana/setup/ghost-backup.sh /usr/local/bin/ghost-backup
chmod +x /usr/local/bin/ghost-backup

# Add cronjob if it doesn't already exist
(crontab -l 2>/dev/null | grep -q ghost-backup) ||
    (
        crontab -l 2>/dev/null
        echo "0 3 * * * /usr/local/bin/ghost-backup >> /var/log/ghost-backup.log 2>&1"
    ) | crontab -

echo "[✓] Setup complete."

#!/bin/bash

set -e

LOG_FILE="/home/ubuntu/ghost-setup.log"
LOG_DIR="/home/ubuntu/logs"
mkdir -p "$LOG_DIR"

# Wait until cloud-init / apt is done
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for other apt processes to finish..."
    sleep 5
done

cd "$(dirname "$0")"

echo "[+] Starting Ghost via Docker Compose..."
docker compose up -d

# Setup backup cronjob
echo "[+] Setting up backup cronjob..." >>$LOG_FILE
sudo cp /home/ubuntu/drunken-banana/setup/ghost-backup.sh /usr/local/bin/ghost-backup
sudo chmod +x /usr/local/bin/ghost-backup

# Add cronjob if it doesn't already exist
(crontab -l 2>/dev/null | grep -q ghost-backup) ||
    (
        crontab -l 2>/dev/null
        # Runs Cronjob every night at 3:00 AM
        #echo "0 3 * * * /usr/local/bin/ghost-backup >> $LOG_DIR/ghost-backup.log 2>&1"
        #For Debugging - run Cronjob every 15 mins
        echo "*/15 * * * * /usr/local/bin/ghost-backup >> $LOG_DIR/ghost-backup.log 2>&1"
    ) | crontab -

# Mailing out Metadata
sudo apt-get install -y mailutils

Internet Site

echo "[✓] Setup complete."

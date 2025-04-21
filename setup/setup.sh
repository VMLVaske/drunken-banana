#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "[+] Starting Ghost via Docker Compose..."
docker compose up -d

echo "[+] Setting up backup cronjob..."
cp ghost-backup.sh /usr/local/bin/ghost-backup
chmod +x /usr/local/bin/ghost-backup

# Cronjob entry (edit path to your liking)
(
    crontab -l 2>/dev/null
    echo "0 3 * * * /usr/local/bin/ghost-backup"
) | crontab -

echo "[✓] Setup complete."

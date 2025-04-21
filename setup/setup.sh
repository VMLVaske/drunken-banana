#!/bin/bash

set -e

LOG_FILE="$HOME/ghost-setup.log"
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"

# Wait until cloud-init / apt is done
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for other apt processes to finish..."
    sleep 5
done

cd "$(dirname "$0")"

echo "[+] Starting Ghost via Docker Compose..."
docker compose up -d

# Create a deployer user with sudo rights (if not already present)
if ! id -u deployer >/dev/null 2>&1; then
    echo "[+] Creating deployer user..."
    sudo adduser --disabled-password --gecos "" deployer
    sudo usermod -aG sudo deployer
    sudo usermod -aG docker deployer
    sudo mkdir -p /home/deployer/.ssh
    sudo cp /home/ubuntu/.ssh/authorized_keys /home/deployer/.ssh/authorized_keys
    sudo chown -R deployer:deployer /home/deployer/.ssh
    sudo chmod 700 /home/deployer/.ssh
    sudo chmod 600 /home/deployer/.ssh/authorized_keys
    echo "[✓] Deployer user created."
else
    echo "[*] Deployer user already exists, skipping creation."
fi

# Setup backup cronjob
echo "[+] Setting up backup cronjob..." >>$LOG_FILE
sudo cp $HOME/drunken-banana/setup/ghost-backup.sh /usr/local/bin/ghost-backup
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

# Mailing out Metadata
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt lock (mailutils)..."
    sleep 5
done
# Preconfigure Postfix so it doesn't block with an interactive prompt
echo "postfix postfix/mailname string your-domain.com" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Local only'" | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mailutils

echo "[✓] Setup complete." >>$LOG_FILE

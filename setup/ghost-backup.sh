#!/bin/bash

set -e

# Create backup dir if it doesn't exist
BACKUP_DIR="/backup"
mkdir -p $BACKUP_DIR

# Define source + destination
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SRC="/home/ubuntu/drunken-banana/setup/ghost-content"
DEST="$BACKUP_DIR/ghost-content-backup-$TIMESTAMP.tar.gz"

# Run the backup
echo "[+] Backing up Ghost content..."
tar -czf "$DEST" "$SRC"

# Log summary
echo "[✓] Backup complete: $DEST"

#!/bin/bash

set -e
EMAIL=${BACKUP_EMAIL:-"fallback@example.com"}

# Create backup dir if it doesn't exist
BACKUP_DIR="/backup"
mkdir -p $BACKUP_DIR

# Create log dir if it doesn't exist
LOG_DIR="/home/ubuntu/logs"
mkdir -p "$LOG_DIR"

# Define source + destination
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SRC="/home/ubuntu/drunken-banana/setup/ghost-content"
DEST="$BACKUP_DIR/ghost-content-backup-$TIMESTAMP.tar.gz"
SUMMARY="$BACKUP_DIR/backup-summary-$TIMESTAMP.log"

# Run the backup
echo "[+] Backing up Ghost content..."
tar -czf "$DEST" "$SRC"

# Get backup file size
SIZE=$(du -h "$DEST" | cut -f1)

# Write summary
echo "Ghost Backup Summary - $TIMESTAMP" >"$SUMMARY"
echo "-------------------------------" >>"$SUMMARY"
echo "Backup File: $DEST" >>"$SUMMARY"
echo "Size: $SIZE" >>"$SUMMARY"
echo "Status: ✅ Successful" >>"$SUMMARY"

# Send email
mail -s "Ghost Backup - $TIMESTAMP" "$EMAIL" <"$SUMMARY"

# Log summary
echo "[✓] Backup complete: $DEST" >>"$LOG_DIR/ghost-backup.log"

#!/bin/bash

# Backup Script - Automates backups of python projects directory
# Purpose: Compress and archive python projects, keep 14 days of backups

# Configuration - Change these to match your setup
SOURCE_DIR="$HOME/Desktop/python projects"
BACKUP_DIR="$HOME/backups"
RETENTION_DAYS=14
LOG_FILE="$BACKUP_DIR/backup.log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get today's date in YYYY-MM-DD format
BACKUP_DATE=$(date +%Y-%m-%d)

# Create backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/backup-$BACKUP_DATE.tar.gz"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start backup process
log_message "Starting backup of $SOURCE_DIR"

# Create the compressed backup
# tar -czf: compress with gzip (-z) and create archive (-c) to file (-f)
tar -czf "$BACKUP_FILE" -C "$HOME/Desktop" "python projects" 2>> "$LOG_FILE"

# Check if tar command succeeded (exit code 0 means success)
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_message "✓ Backup completed successfully. Size: $BACKUP_SIZE"
else
    log_message "✗ Backup FAILED - tar command returned an error"
    exit 1
fi

# Delete backups older than RETENTION_DAYS
# find: search for files
# -mtime +14: files modified more than 14 days ago
# -type f: only files (not directories)
# -delete: remove them
log_message "Cleaning up backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -name "backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

log_message "Backup process completed"
log_message "---"

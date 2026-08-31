#!/bin/bash

# Log Rotation Script - Manages system log files to prevent disk space issues
# Purpose: Rotate, compress, and archive system logs; keep 30 days of history

# Configuration
RETENTION_DAYS=30
LOG_DIR="/var/log"
LOG_FILES=(
    "syslog"
    "auth.log"
    "dmesg"
)

# Get the actual user's home directory (works with sudo)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME="$HOME"
fi

ROTATION_LOG="$USER_HOME/backups/log-rotation.log"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ROTATION_LOG"
}

log_message "Starting log rotation"

# Get today's date
ROTATION_DATE=$(date +%Y-%m-%d)

# Process each log file
for logfile in "${LOG_FILES[@]}"; do
    FULL_PATH="$LOG_DIR/$logfile"
    
    # Check if log file exists
    if [ ! -f "$FULL_PATH" ]; then
        log_message "⚠ Log file not found: $FULL_PATH (skipping)"
        continue
    fi
    
    # Check if file has content (size > 0)
    if [ ! -s "$FULL_PATH" ]; then
        log_message "⚠ Log file is empty: $FULL_PATH (skipping)"
        continue
    fi
    
    # Create rotated filename
    ROTATED_FILE="$FULL_PATH-$ROTATION_DATE"
    
    # Check if we already rotated today (don't rotate twice)
    if [ -f "$ROTATED_FILE.gz" ]; then
        log_message "ℹ Already rotated today: $logfile (skipping)"
        continue
    fi
    
    # Copy the log file to the rotated name
    # We use cp instead of mv so the application keeps writing to the original
    log_message "Rotating: $logfile"
    cp "$FULL_PATH" "$ROTATED_FILE" 2>> "$ROTATION_LOG"
    
    if [ $? -ne 0 ]; then
        log_message "✗ Failed to copy $logfile"
        continue
    fi
    
    # Compress the rotated file
    gzip "$ROTATED_FILE" 2>> "$ROTATION_LOG"
    
    if [ $? -ne 0 ]; then
        log_message "✗ Failed to compress $logfile"
        continue
    fi
    
    # Clear the original log file (truncate to 0 bytes)
    # This lets the application keep writing without interruption
    > "$FULL_PATH"
    
    if [ $? -ne 0 ]; then
        log_message "✗ Failed to truncate $logfile"
        continue
    fi
    
    FILE_SIZE=$(du -h "$ROTATED_FILE.gz" | cut -f1)
    log_message "✓ Rotated: $logfile → $logfile-$ROTATION_DATE.gz ($FILE_SIZE)"
done

# Delete old rotated logs (older than RETENTION_DAYS)
log_message "Cleaning up logs older than $RETENTION_DAYS days"

for logfile in "${LOG_FILES[@]}"; do
    FULL_PATH="$LOG_DIR/$logfile"
    find "$(dirname "$FULL_PATH")" -name "$(basename "$FULL_PATH")-*.gz" -type f -mtime +$RETENTION_DAYS -delete 2>> "$ROTATION_LOG"
done

log_message "✓ Log rotation completed"
log_message "---"

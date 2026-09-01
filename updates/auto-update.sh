#!/bin/bash

# Automated Updates Script - Keeps system patched with security updates
# Purpose: Automatically install security updates and log results

# Get the actual user's home directory (works with sudo)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME="$HOME"
fi

UPDATE_LOG="$USER_HOME/backups/auto-update.log"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$UPDATE_LOG"
}

log_message "Starting automatic update check"

# Update the package list (what updates are available)
# This is safe - it only downloads information, doesn't install anything
log_message "Updating package lists..."
apt-get update >> "$UPDATE_LOG" 2>&1

if [ $? -ne 0 ]; then
    log_message "✗ Failed to update package lists"
    exit 1
fi

# Check if there are security updates available
# apt-get upgrade -s simulates an upgrade without actually doing it
SECURITY_UPDATES=$(apt-get upgrade -s 2>/dev/null | grep -i "security" | wc -l)

if [ "$SECURITY_UPDATES" -eq 0 ]; then
    log_message "✓ No security updates available"
    log_message "System is up to date"
    exit 0
fi

log_message "Found security updates. Installing..."

# Install all available updates (including security ones)
# -y = automatically answer "yes" to prompts
# -o Dpkg::Pre-Install-Pkgs::=/bin/true = don't interrupt on errors
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$UPDATE_LOG" 2>&1

if [ $? -ne 0 ]; then
    log_message "✗ Update installation failed"
    exit 1
fi

log_message "✓ Updates installed successfully"

# Check if a kernel update was installed
# If the running kernel version differs from the installed kernel, reboot is needed
CURRENT_KERNEL=$(uname -r)
INSTALLED_KERNEL=$(dpkg -l | grep "linux-image" | grep "ii" | awk '{ print $2 }' | grep -oP 'linux-image-\K[^-]+' | sort -V | tail -1)

if [ "$CURRENT_KERNEL" != "$INSTALLED_KERNEL" ]; then
    log_message "⚠ KERNEL UPDATE DETECTED"
    log_message "Current kernel: $CURRENT_KERNEL"
    log_message "Installed kernel: $INSTALLED_KERNEL"
    log_message "⚠ System reboot required to activate kernel update"
    log_message "Schedule a reboot at your convenience"
else
    log_message "ℹ No kernel update - reboot not required"
fi

log_message "✓ Automatic update process completed"
log_message "---"

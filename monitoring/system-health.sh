#!/bin/bash

# System Health Monitor Script - Tracks system resource usage
# Purpose: Monitor CPU, memory, and disk usage; alert on thresholds

# Configuration - Alert thresholds (in percentages)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90

# Get the actual user's home directory (works with sudo)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME="$HOME"
fi

HEALTH_LOG="$USER_HOME/backups/system-health.log"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG"
}

# Function to get CPU usage (average over last minute)
get_cpu_usage() {
    # Get the load average (first number) and divide by number of CPUs
    # uptime outputs: "load average: 0.62, 0.55, 0.48"
    # We need just the first number
    local load_avg=$(uptime | grep -oP 'load average: \K[^,]+')
    local cpu_count=$(nproc)
    
    # Convert to percentage: (load / cpu_count) * 100
    echo "scale=0; ($load_avg / $cpu_count) * 100" | bc
}

# Function to get memory usage
get_memory_usage() {
    # Get total and available memory
    # Calculate: (total - available) / total * 100
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{ print $2 }')
    local available=$(echo $mem_info | awk '{ print $7 }')
    
    # Calculate percentage used
    echo "scale=0; (($total - $available) / $total) * 100" | bc
}

# Function to get disk usage
get_disk_usage() {
    # Get disk usage of root filesystem (/)
    # df -h gives human-readable output, we extract the percentage
    df / | awk 'NR==2 { print $5 }' | sed 's/%//'
}

# ===== Main monitoring =====

log_message "Starting system health check"

# Get current values
CPU=$(get_cpu_usage)
MEMORY=$(get_memory_usage)
DISK=$(get_disk_usage)

# Start status message
STATUS_MSG="Status check — CPU: ${CPU}%, Memory: ${MEMORY}%, Disk: ${DISK}%"

# Check thresholds and build alert message
ALERT_MSG=""
ALERT_FLAG=0

if [ "$CPU" -gt "$CPU_THRESHOLD" ]; then
    ALERT_MSG="$ALERT_MSG | ⚠ CPU HIGH: ${CPU}%"
    ALERT_FLAG=1
fi

if [ "$MEMORY" -gt "$MEMORY_THRESHOLD" ]; then
    ALERT_MSG="$ALERT_MSG | ⚠ MEMORY HIGH: ${MEMORY}%"
    ALERT_FLAG=1
fi

if [ "$DISK" -gt "$DISK_THRESHOLD" ]; then
    ALERT_MSG="$ALERT_MSG | ⚠ DISK HIGH: ${DISK}%"
    ALERT_FLAG=1
fi

# Log appropriately
if [ "$ALERT_FLAG" -eq 1 ]; then
    # Something is over threshold - log as warning
    log_message "⚠ WARNING: $STATUS_MSG $ALERT_MSG"
else
    # All good - log as normal status (lighter logging)
    log_message "✓ $STATUS_MSG"
fi

log_message "Health check completed"

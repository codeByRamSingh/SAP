#!/bin/bash

# Script to clean up old SAP logs
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
INSTANCE="00"  # Replace with your instance number
WORK_DIR="/usr/sap/$SID/DVEBMGS$INSTANCE/work"
TRANS_LOG_DIR="/usr/sap/trans/log"
HANA_TRACE_DIR="/usr/sap/$SID/HDB$INSTANCE/$(hostname)/trace"
RETENTION_DAYS=30  # Retain logs for 30 days
CLEANUP_LOG="/usr/sap/$SID/log_cleanup_$(date +%Y%m%d_%H%M%S).log"
EMAIL="admin@example.com"  # Replace with your email

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "${SID,,}adm" ]]; then
    echo "Error: Must run as ${SID,,}adm user" | tee -a $CLEANUP_LOG
    exit 1
fi

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $CLEANUP_LOG
}

# Function to clean up logs in a directory
clean_directory() {
    DIR=$1
    log_message "Cleaning up logs in $DIR older than $RETENTION_DAYS days..."
    if [ -d "$DIR" ]; then
        find $DIR -type f -mtime +$RETENTION_DAYS -exec rm -v {} \; >> /tmp/cleanup_output.txt 2>&1
        if [ $? -eq 0 ]; then
            log_message "Successfully cleaned $DIR: $(cat /tmp/cleanup_output.txt)"
        else
            log_message "Failed to clean $DIR: $(cat /tmp/cleanup_output.txt)"
            mail -s "SAP Log Cleanup Alert: Cleanup Failed for $DIR" $EMAIL < $CLEANUP_LOG
        fi
    else
        log_message "Directory $DIR does not exist."
    fi
}

# Clean up work directory logs
clean_directory "$WORK_DIR"

# Clean up transport logs
clean_directory "$TRANS_LOG_DIR"

# Clean up HANA trace logs
clean_directory "$HANA_TRACE_DIR"

# Check disk space after cleanup
log_message "Disk space after cleanup:"
df -h $WORK_DIR $TRANS_LOG_DIR $HANA_TRACE_DIR >> $CLEANUP_LOG

# Clean up temporary files
rm -f /tmp/cleanup_output.txt

log_message "Log cleanup completed."
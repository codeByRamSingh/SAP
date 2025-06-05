#!/bin/bash

# Script to monitor RFC connections in SAP
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
INSTANCE="00"  # Replace with your instance number
RFC_LOG="/usr/sap/$SID/rfc_monitor_$(date +%Y%m%d_%H%M%S).log"
EMAIL="admin@example.com"  # Replace with your email
RFC_LIST="/usr/sap/$SID/rfc_list.txt"  # File containing RFC destinations (e.g., RFC_DEST1)

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "${SID,,}adm" ]]; then
    echo "Error: Must run as ${SID,,}adm user" | tee -a $RFC_LOG
    exit 1
fi

# Check if RFC list file exists
if [ ! -f "$RFC_LIST" ]; then
    echo "Error: RFC list file $RFC_LIST not found" | tee -a $RFC_LOG
    exit 1
fi

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $RFC_LOG
}

# Test RFC connections
log_message "Starting RFC connection monitoring for $SID..."
while read -r RFC_DEST; do
    if [[ -z "$RFC_DEST" ]]; then
        continue
    fi
    log_message "Testing RFC destination $RFC_DEST..."
    # Use sapcontrol to execute RFC ping (equivalent to SM59 test)
    sapcontrol -nr $INSTANCE -function ExecuteProgram -param "rfcping -dest $RFC_DEST" > /tmp/rfc_output.txt 2>&1
    if grep -q "SUCCESS" /tmp/rfc_output.txt; then
        log_message "RFC destination $RFC_DEST is reachable."
    else
        log_message "RFC destination $RFC_DEST is NOT reachable: $(cat /tmp/rfc_output.txt)"
        mail -s "RFC Monitor Alert: $RFC_DEST Connection Failed" $EMAIL < $RFC_LOG
    fi
done < "$RFC_LIST"

# Clean up
rm -f /tmp/rfc_output.txt

log_message "RFC monitoring completed."
#!/bin/bash

# Script to lock or unlock SAP users (except admins)
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
INSTANCE="00"  # Replace with your instance number
ACTION=$1  # Argument: "lock" or "unlock"
LOG_FILE="/usr/sap/$SID/user_management_$(date +%Y%m%d_%H%M%S).log"
EMAIL="admin@example.com"  # Replace with your email
ADMIN_USERS="SAP*,DDIC,TMADM"  # Admin users to exclude

# Usage check
if [[ "$ACTION" != "lock" && "$ACTION" != "unlock" ]]; then
    echo "Usage: $0 [lock|unlock]" | tee -a $LOG_FILE
    exit 1
fi

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "${SID,,}adm" ]]; then
    echo "Error: Must run as ${SID,,}adm user" | tee -a $LOG_FILE
    exit 1
fi

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Execute user lock/unlock using sapcontrol
log_message "Starting $ACTION operation for users in $SID..."
if [[ "$ACTION" == "lock" ]]; then
    sapcontrol -nr $INSTANCE -function ExecuteProgram -param "su01 -lock -user '*' -exclude $ADMIN_USERS" > /tmp/user_action.txt 2>&1
else
    sapcontrol -nr $INSTANCE -function ExecuteProgram -param "su01 -unlock -user '*' -exclude $ADMIN_USERS" > /tmp/user_action.txt 2>&1
fi

# Check if the operation was successful
if [ $? -eq 0 ]; then
    log_message "Successfully performed $ACTION for users (excluding $ADMIN_USERS)."
else
    log_message "Failed to $ACTION users. Check logs: $(cat /tmp/user_action.txt)"
    mail -s "SAP User Management Alert: $ACTION Failed" $EMAIL < $LOG_FILE
fi

# Clean up
rm -f /tmp/user_action.txt

log_message "$ACTION operation completed."
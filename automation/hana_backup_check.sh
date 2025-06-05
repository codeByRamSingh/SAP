#!/bin/bash

# Script to verify the latest HANA backup status
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
HDB_USER="s4hadm"  # HANA user (same as <sid>adm)
HDB_INSTANCE="00"  # HANA instance number
LOG_FILE="/usr/sap/$SID/backup_check_$(date +%Y%m%d_%H%M%S).log"
EMAIL="admin@example.com"  # Replace with your email

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

# Query the latest backup status using hdbsql
log_message "Checking latest HANA backup status..."
/usr/sap/$SID/HDB$HDB_INSTANCE/exe/hdbsql -i $HDB_INSTANCE -u SYSTEM -p "<SYSTEM_password>" -o /tmp/backup_status.txt <<EOF
SELECT BACKUP_ID, SYS_START_TIME, STATE_NAME FROM M_BACKUP_CATALOG WHERE ENTRY_TYPE_NAME = 'complete data backup' ORDER BY SYS_START_TIME DESC LIMIT 1;
EOF

# Check if backup query succeeded
if [ $? -eq 0 ]; then
    log_message "Backup query executed successfully."
    BACKUP_STATE=$(grep -v "^$" /tmp/backup_status.txt | tail -n 1 | awk -F"|" '{print $3}' | tr -d ' ')
    BACKUP_TIME=$(grep -v "^$" /tmp/backup_status.txt | tail -n 1 | awk -F"|" '{print $2}' | tr -d ' ')
    if [[ "$BACKUP_STATE" == "SUCCESSFUL" ]]; then
        log_message "Latest backup at $BACKUP_TIME was $BACKUP_STATE."
    else
        log_message "Latest backup at $BACKUP_TIME failed with state: $BACKUP_STATE."
        mail -s "HANA Backup Alert: Backup Failed" $EMAIL < $LOG_FILE
    fi
else
    log_message "Failed to query backup status. Check HANA connectivity."
    mail -s "HANA Backup Alert: Query Failed" $EMAIL < $LOG_FILE
fi

# Clean up
rm -f /tmp/backup_status.txt

log_message "Backup check completed."
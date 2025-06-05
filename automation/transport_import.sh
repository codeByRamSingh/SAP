#!/bin/bash

# Script to automate transport imports in SAP
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
TRANSPORT_DIR="/usr/sap/trans"
TP_LOG="/usr/sap/$SID/transport_import_$(date +%Y%m%d_%H%M%S).log"
EMAIL="admin@example.com"  # Replace with your email
TRANSPORT_LIST="/usr/sap/$SID/transport_list.txt"  # File containing transport numbers (e.g., S4HK900123)

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "${SID,,}adm" ]]; then
    echo "Error: Must run as ${SID,,}adm user" | tee -a $TP_LOG
    exit 1
fi

# Check if transport list file exists
if [ ! -f "$TRANSPORT_LIST" ]; then
    echo "Error: Transport list file $TRANSPORT_LIST not found" | tee -a $TP_LOG
    exit 1
fi

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $TP_LOG
}

# Import transports
log_message "Starting transport import for $SID..."
while read -r TRANSPORT; do
    if [[ -z "$TRANSPORT" ]]; then
        continue
    fi
    log_message "Importing transport $TRANSPORT..."
    # Add transport to buffer
    tp addtobuffer $TRANSPORT $SID pf=$TRANSPORT_DIR/bin/TP_DOMAIN_${SID}.PFL >> /tmp/tp_output.txt 2>&1
    if [ $? -ne 0 ]; then
        log_message "Failed to add $TRANSPORT to buffer: $(cat /tmp/tp_output.txt)"
        mail -s "Transport Import Alert: Add to Buffer Failed for $TRANSPORT" $EMAIL < $TP_LOG
        continue
    fi
    # Import transport
    tp import $TRANSPORT $SID client=100 pf=$TRANSPORT_DIR/bin/TP_DOMAIN_${SID}.PFL U128 >> /tmp/tp_output.txt 2>&1
    RETURN_CODE=$?
    if [ $RETURN_CODE -eq 0 ]; then
        log_message "Successfully imported $TRANSPORT."
    elif [ $RETURN_CODE -eq 4 ]; then
        log_message "Imported $TRANSPORT with warnings (RC=4). Check logs."
    else
        log_message "Failed to import $TRANSPORT (RC=$RETURN_CODE): $(cat /tmp/tp_output.txt)"
        mail -s "Transport Import Alert: Import Failed for $TRANSPORT" $EMAIL < $TP_LOG
    fi
done < "$TRANSPORT_LIST"

# Clean up
rm -f /tmp/tp_output.txt

log_message "Transport import completed."
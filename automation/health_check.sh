#!/bin/bash

# Script to perform SAP system health check
# Run as <sid>adm user (e.g., s4hadm)

# Variables
SID="S4H"  # Replace with your SAP SID
INSTANCE="00"  # Replace with your instance number
LOG_FILE="/usr/sap/$SID/health_check_$(date +%Y%m%d_%H%M%S).log"
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

# Check SAP system status
log_message "Checking SAP system status..."
sapcontrol -nr $INSTANCE -function GetSystemStatus > /tmp/sap_status.txt
if grep -q "GREEN" /tmp/sap_status.txt; then
    log_message "SAP system is running (GREEN)."
else
    log_message "SAP system is NOT running properly. Check logs."
    mail -s "SAP Health Check Alert: System Status Issue" $EMAIL < $LOG_FILE
fi

# Check work processes
log_message "Checking work processes..."
sapcontrol -nr $INSTANCE -function GetProcessList > /tmp/wp_status.txt
if grep -q "RUNNING" /tmp/wp_status.txt; then
    log_message "Work processes are running."
else
    log_message "Work process issue detected. Check SM50/SM66."
    mail -s "SAP Health Check Alert: Work Process Issue" $EMAIL < $LOG_FILE
fi

# Check disk usage
log_message "Checking disk usage..."
df -h /usr/sap/$SID /hana/data /hana/log > /tmp/disk_usage.txt
if df /usr/sap/$SID | awk 'NR==2 {if ($5+0 > 90) print "High usage: "$5}' > /tmp/disk_alert.txt; then
    log_message "Disk usage alert: $(cat /tmp/disk_alert.txt)"
    mail -s "SAP Health Check Alert: Disk Usage High" $EMAIL < /tmp/disk_alert.txt
else
    log_message "Disk usage is within limits."
fi

# Clean up temporary files
rm -f /tmp/sap_status.txt /tmp/wp_status.txt /tmp/disk_usage.txt /tmp/disk_alert.txt

log_message "Health check completed."
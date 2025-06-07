#!/bin/bash
SID=<SID>
INSTANCE=<INR>
USER=${SID}adm
ALERT_EMAIL="admin@example.com"

# Check HANA service status
STATUS=$(su - $USER -c "/usr/sap/$SID/HDB$INSTANCE/exe/sapcontrol -nr $INSTANCE -function GetProcessList" | grep -c "GREEN")

if [ $STATUS -lt 1 ]; then
    echo "HANA services down for $SID" | mail -s "HANA Alert" $ALERT_EMAIL
fi
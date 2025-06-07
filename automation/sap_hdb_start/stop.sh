#!/bin/bash
SID=<SID>  # Replace with your SAP HANA SID
INSTANCE=<INR>  # Replace with instance number
USER=${SID}adm

# Start SAP HANA
su - $USER -c "/usr/sap/$SID/HDB$INSTANCE/exe/sapcontrol -nr $INSTANCE -function Start"

# Stop SAP HANA
su - $USER -c "/usr/sap/$SID/HDB$INSTANCE/exe/sapcontrol -nr $INSTANCE -function Stop"
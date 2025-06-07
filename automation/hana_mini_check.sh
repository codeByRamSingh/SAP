#!/bin/bash
SID=<SID>
INSTANCE=<INR>
USER=${SID}adm
OUTPUT_DIR=/hana/checks
DATE=$(date +%Y%m%d)

# Run Mini-Checks
su - $USER -c "hdbsql -i $INSTANCE -u SYSTEM -p <password> -o $OUTPUT_DIR/minicheck_$DATE.txt \"SELECT * FROM _SYS_STATISTICS.HOST_MINI_CHECK\""
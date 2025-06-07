#!/bin/bash
SID=<SID>
INSTANCE=<INR>
USER=${SID}adm
BACKUP_DIR=/hana/backup
DATE=$(date +%Y%m%d)

# Trigger backup for SYSTEMDB
su - $USER -c "hdbsql -i $INSTANCE -u SYSTEM -p <password> \"BACKUP DATA FOR SYSTEMDB USING FILE ('$BACKUP_DIR/SYSTEMDB_$DATE')\""

# Clean up backups older than 7 days
find $BACKUP_DIR -type f -mtime +7 -exec rm {} \;
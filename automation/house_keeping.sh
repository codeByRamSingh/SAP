#!/bin/bash
SID=<SID>
LOG_DIR=/hana/shared/$SID/global/hdb/log
TRACE_DIR=/hana/shared/$SID/global/hdb/trace
RETENTION_DAYS=7

# Remove old log files
find $LOG_DIR -type f -mtime +$RETENTION_DAYS -exec rm {} \;
find $TRACE_DIR -type f -mtime +$RETENTION_DAYS -exec rm {} \;

# Compress remaining logs
find $LOG_DIR -type f -exec gzip {} \;
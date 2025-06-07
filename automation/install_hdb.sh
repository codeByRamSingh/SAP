#!/bin/bash
SID=<SID>
MEDIA_DIR=/hana/media
CONFIG_FILE=$MEDIA_DIR/configfile.xml

# Create file systems
lvcreate -n lvdata -L 100G datavg
mkfs.xfs /dev/datavg/lvdata
mkdir -p /hana/data
mount /dev/datavg/lvdata /hana/data

# Run silent installation
$MEDIA_DIR/hdblcm --sid=$SID --components=server --configfile=$CONFIG_FILE --batch
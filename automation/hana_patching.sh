#!/bin/bash
PATCH_DIR=/hana/patches
HANA_MEDIA=$PATCH_DIR/SAP_HANA_UPDATE.zip
SID=<SID>
USER=${SID}adm

# Download patch (example with wget)
wget -O $HANA_MEDIA <SAP_patch_URL>

# Extract patch
unzip $HANA_MEDIA -d $PATCH_DIR

# Apply patch
su - $USER -c "$PATCH_DIR/hdbupd --sid=$SID --batch"
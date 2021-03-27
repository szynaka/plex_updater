#!/bin/bash

DL_DIR="/fileshare1/Files/plex"

JSON=$(curl --silent 'https://plex.tv/api/downloads/5.json?channel=plexpass')
PKG_URL=$(echo "$JSON" | jq '.computer.Linux.releases[] | select(.build == "linux-x86_64") | select(.distro == "debian") | .url' | sed 's/"//g')
PKG_SUM=$(echo "$JSON" | jq '.computer.Linux.releases[] | select(.build == "linux-x86_64") | select(.distro == "debian") | .checksum' | sed 's/"//g')
FILE=$(basename "$PKG_URL")

if ! [ -f "$DL_DIR/$FILE" ]; then
    echo "Downloading new Plex $FILE"
    curl --silent "$PKG_URL" > "$DL_DIR/$FILE"
    echo "Checksumming"
    echo "$PKG_SUM $DL_DIR/$FILE" | sha1sum -c 
    if ! [ $? -eq 0 ]; then
        mv "$DL_DIR/$FILE" "$DL_DIR/failed/$FILE"
        echo "Checksum failed.  Removing $FILE"
        exit 1
    fi
    echo "Installing package"
    /usr/bin/dpkg -i --no-force-downgrade "$DL_DIR/$FILE"
    if ! [ $? -eq 0 ]; then
        mv "$DL_DIR/$FILE" "$DL_DIR/failed/$FILE"
        echo "Failed installing $FILE"
        exit 2
    fi
fi

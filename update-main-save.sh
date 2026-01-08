#!/bin/bash

SAVE_DIR="/opt/factorio/saves"
MAIN_SAVE="$SAVE_DIR/savefile.zip"

# Find the latest autosave
LATEST_AUTOSAVE=$(ls -t $SAVE_DIR/_autosave*.zip 2>/dev/null | head -1)

# If there’s no autosave, exit
[ -z "$LATEST_AUTOSAVE" ] && exit 0

# Only overwrite if the autosave is newer than the main save
if [ ! -f "$MAIN_SAVE" ] || [ "$LATEST_AUTOSAVE" -nt "$MAIN_SAVE" ]; then
    # Copy safely to a temp file first
    TMP_FILE="$SAVE_DIR/savefile.tmp.zip"
    cp "$LATEST_AUTOSAVE" "$TMP_FILE"

    # Make sure Factorio owns it
    chown factorio:factorio "$TMP_FILE"

    # Move temp file to main save (atomic)
    mv -f "$TMP_FILE" "$MAIN_SAVE"

    echo "$(date) - Updated savefile.zip from $(basename "$LATEST_AUTOSAVE")"
fi


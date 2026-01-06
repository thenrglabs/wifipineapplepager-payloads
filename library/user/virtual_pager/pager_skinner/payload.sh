#!/bin/bash
# Title: Pager Skinner
# Description: Installs and switches between Virtual Pager UI skins.
# Author: Amilious
# Version: 1.0

# Unique payload name for config storage
PAYLOAD_NAME="pagerskinner"

# Config options
CONFIG_SKIN="current_skin"

# Get the directory where this payload.sh is located
PAYLOAD_DIR="$(dirname "$(realpath "$0")")"

# Check if unzip is available
if ! command -v unzip >/dev/null 2>&1; then
    LOG red "unzip not found. Installing..."
    opkg update
    opkg install unzip
    if [ $? -ne 0 ]; then
        LOG red "Failed to install unzip. Aborting."
        exit 1
    fi
fi

# Define directories
SKINS_DIR="/mmc/root/ui_skins"
BACKUP_DIR="$SKINS_DIR/default"
DARK_DIR="$SKINS_DIR/dark"

# Ensure main skins directory exists
mkdir -p "$SKINS_DIR"
first=0  

# Backup default UI images only if backup doesn't already exist or is empty
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    LOG "Backing up default UI images..."
    mkdir -p "$BACKUP_DIR"
    cp -r /pineapple/ui/images/* "$BACKUP_DIR/"
    LOG green "Backup completed."

    # First run: set current skin to default
    PAYLOAD_SET_CONFIG "$PAYLOAD_NAME" "$CONFIG_SKIN" "default"
    first=1
else
    LOG "Default backup already exists. Skipping backup."
fi

# Install dark theme only if not already present
if [ ! -d "$DARK_DIR" ] || [ -z "$(ls -A "$DARK_DIR" 2>/dev/null)" ]; then
    if [ -f "$PAYLOAD_DIR/dark.zip" ]; then
        LOG "Installing dark theme..."
        mkdir -p "$DARK_DIR"
        unzip -o "$PAYLOAD_DIR/dark.zip" -d "$DARK_DIR"
        LOG green "Dark theme installed successfully!"
    else
        LOG red "dark.zip not found in payload directory."
        LOG red "Place dark.zip alongside payload.sh to install the dark skin."
    fi
else
    LOG "Dark theme already installed. Skipping extraction."
fi

# Get currently stored skin
CURRENT_SKIN=$(PAYLOAD_GET_CONFIG "$PAYLOAD_NAME" "$CONFIG_SKIN")
if [ -z "$CURRENT_SKIN" ]; then
    CURRENT_SKIN="default"
    PAYLOAD_SET_CONFIG "$PAYLOAD_NAME" "$CONFIG_SKIN" "default"
fi
LOG "Currently loaded skin: $CURRENT_SKIN"

# Show information about the app if first run
if [ "$first" -eq 1 ]; then
    PROMPT "A new directory $SKINS_DIR has been created to hold skins. You can add your own skins for the virtual pager if you like."
fi

# Build numbered skin list and prompt text
LOG "\n\n────────────────────────────────────"
LOG "── Available skins ─────────────────"
LOG "────────────────────────────────────"

SKINS=()
i=1
current_index=0
prompt_text=""  # Will build the full prompt string

for dir in "$SKINS_DIR"/*/ ; do
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        skin_name=$(basename "$dir")
        SKINS+=("$skin_name")

        if [ "$skin_name" = "$CURRENT_SKIN" ]; then
            line=" $i) $skin_name  ← current"
            LOG blue "$line"
            current_index=$i
        else
            line=" $i) $skin_name"
            LOG "$line"
        fi

        # Append to prompt_text (preserve newlines for readability in PROMPT)
        prompt_text="${prompt_text}${line}\n"
        ((i++))
    fi
done

LOG "────────────────────────────────────\n"

# Default to 1 if no current skin matched
if [ "$current_index" -eq 0 ]; then
    current_index=1
fi

# Show the full skin list in a PROMPT dialog
PROMPT "Select a skin:\n$prompt_text"

#LOG "Press A to continue to selection..."
#WAIT_FOR_BUTTON_PRESS A

# Use NUMBER_PICKER with pre-selection
SELECTED=$(NUMBER_PICKER "Skin Number (1-$((i-1)))" "$current_index") || {
    LOG red "Selection cancelled."
    exit 0
}

# Validate
if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || [ "$SELECTED" -lt 1 ] || [ "$SELECTED" -gt ${#SKINS[@]} ]; then
    LOG red "Invalid selection."
    exit 1
fi

__spinnerid=$(START_SPINNER "Skinning...")

# Apply chosen skin
CHOSEN_SKIN="${SKINS[$((SELECTED-1))]}"
LOG "Applying skin: $CHOSEN_SKIN ..."

rm -rf /pineapple/ui/images/*
cp -r "$SKINS_DIR/$CHOSEN_SKIN"/* /pineapple/ui/images/

PAYLOAD_SET_CONFIG "$PAYLOAD_NAME" "$CONFIG_SKIN" "$CHOSEN_SKIN"

LOG green "Skin '$CHOSEN_SKIN' applied successfully!"
STOP_SPINNER ${__spinnerid}

LOG "The Virtual Pager UI should now reflect the new skin. If not, clear your browser cache and hard reload!"
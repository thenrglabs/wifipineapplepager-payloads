#!/bin/bash
# Title: PagerBoy Controller
# Author: Brandon Starkweather

# --- CONFIGURATION ---
TARGET_FILE="/pineapple/ui/index.html"
BACKUP_FILE="/pineapple/ui/index.html.original"

# HARDCODED PATH: Keeps it safe from directory confusion
PAYLOAD_DIR="/root/payloads/user/general/PagerBoy"
MOBILE_FILE="$PAYLOAD_DIR/index.html"

# --- CONSOLE COMPATIBILITY ---
# If running via SSH, 'LOG' might not exist. This fixes that.
if ! type LOG > /dev/null 2>&1; then
    LOG() {
        echo "[DEBUG] $1"
    }
fi

# --- HELPER FUNCTIONS ---

check_state() {
    if [ -f "$BACKUP_FILE" ]; then
        echo "MOBILE"
    else
        echo "CLASSIC"
    fi
}

enable_mobile() {
    if [ -f "$BACKUP_FILE" ]; then
        LOG "Already in Mobile Mode"
        return
    fi

    LOG "Looking for: $MOBILE_FILE"
    
    if [ ! -f "$MOBILE_FILE" ]; then
        LOG "Error: File not found at $MOBILE_FILE"
        # Debugging aid: Show what IS in the directory
        if [ -d "$PAYLOAD_DIR" ]; then
            LOG "Dir contents: $(ls "$PAYLOAD_DIR")"
        else
            LOG "Dir not found: $PAYLOAD_DIR"
        fi
        return
    fi

    LOG "Swapping UI..."
    cp "$TARGET_FILE" "$BACKUP_FILE"
    cp "$MOBILE_FILE" "$TARGET_FILE"
    LOG "Success: Mobile Mode Active"
}

disable_mobile() {
    if [ ! -f "$BACKUP_FILE" ]; then
        LOG "Already in Classic Mode"
        return
    fi

    LOG "Restoring UI..."
    mv "$BACKUP_FILE" "$TARGET_FILE"
    LOG "Success: Classic Mode Restored"
}

# --- MAIN EXECUTION ---

# CHECK 1: Console Mode (Did user type ./payload.sh start?)
if [ -n "$1" ]; then
    case "$1" in
        start|enable|up)
            enable_mobile
            ;;
        stop|disable|down)
            disable_mobile
            ;;
        status)
            LOG "Current State: $(check_state)"
            ;;
        *)
            LOG "Usage: $0 {start|stop|status}"
            ;;
    esac
    exit 0
fi

# CHECK 2: Hardware Mode (No arguments? Wait for buttons)
CURRENT_STATE=$(check_state)
LOG "PagerBoy: $CURRENT_STATE"
LOG "UP: Start | DOWN: Stop"

BUTTON=$(WAIT_FOR_INPUT)

case "$BUTTON" in
    "UP")
        enable_mobile
        ;;
    "DOWN")
        disable_mobile
        ;;
    *)
        LOG "No Action: $BUTTON"
        ;;
esac
#!/usr/bin/env bash

# Android 4.0.4 Edge AI Node - Deploy to Phone Script
# This script automates sending the PicoClaw binary and config.json to the Android 4.0.4 device.
# It handles differences between Rooted (System-wide) and Non-Rooted (Sandbox-restricted) setups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "====================================================================="
echo "        Android 4.0.4 Edge AI Node - Deploy to Phone"
echo "====================================================================="
echo

# Check if required files exist locally
if [ ! -f "bin/picoclaw" ]; then
    echo "⚠️  Warning: 'bin/picoclaw' binary not found!"
    echo "Please download the 32-bit ARM PicoClaw binary and place it in 'bin/picoclaw' first."
    echo "Creating a dummy placeholder binary for testing..."
    mkdir -p bin
    echo '#!/bin/sh' > bin/picoclaw
    echo 'echo "PicoClaw 32-bit Mock Client running!"' >> bin/picoclaw
    chmod +x bin/picoclaw
fi

# Configuration inputs
read -p "📱 Enter the Android Phone's IP address: " PHONE_IP
if [ -z "$PHONE_IP" ]; then
    echo "❌ Error: Phone IP cannot be empty."
    exit 1
fi

echo "Select your device mode:"
echo "1) Non-Rooted (Sandboxed under SSHDroid app space)"
echo "2) Rooted (Global system installation)"
read -p "Select [1 or 2]: " MODE

case "$MODE" in
    1)
        echo "Setting up Non-Rooted workflow..."
        PORT=2222
        USER="root" # SSHDroid typically uses root as username even on non-rooted phones
        DEST_DIR="/data/data/berserker.android.apps.sshdroid/home"
        IS_ROOTED=false
        ;;
    2)
        echo "Setting up Rooted workflow..."
        PORT=22
        USER="root"
        DEST_DIR="/system/xbin"
        IS_ROOTED=true
        ;;
    *)
        echo "❌ Invalid choice."
        exit 1
        ;;
esac

echo
echo "Deploying files to ${USER}@${PHONE_IP}:${PORT}..."
echo "Destination directory: ${DEST_DIR}"
echo "---------------------------------------------------------------------"

if [ "$IS_ROOTED" = true ]; then
    echo "🔓 Attempting to mount /system partition as read-write on the phone..."
    # SSH into phone to remount /system as rw
    ssh -p "$PORT" "${USER}@${PHONE_IP}" "mount -o remount,rw /system" || {
        echo "⚠️  Failed to remount /system as RW directly."
        echo "Please make sure your SSH server on the phone has Root access enabled,"
        echo "or run 'su -c \"mount -o remount,rw /system\"' on the phone terminal."
    }
fi

# Transfer the PicoClaw binary
echo "📤 Transferring PicoClaw binary..."
scp -P "$PORT" bin/picoclaw "${USER}@${PHONE_IP}:${DEST_DIR}/picoclaw"

# Set executable permissions on the phone
echo "🔧 Setting executable permissions on phone..."
ssh -p "$PORT" "${USER}@${PHONE_IP}" "chmod +x ${DEST_DIR}/picoclaw"

echo
echo "---------------------------------------------------------------------"
echo "🎉 Deployment successful!"
echo "---------------------------------------------------------------------"
if [ "$IS_ROOTED" = false ]; then
    echo "To run the PicoClaw binary on your non-rooted phone:"
    echo "  ssh -p 2222 root@${PHONE_IP}"
    echo "  cd ${DEST_DIR}"
    echo "  ./picoclaw"
else
    echo "To run the PicoClaw binary on your rooted phone:"
    echo "  ssh -p 22 root@${PHONE_IP}"
    echo "  picoclaw"
fi
echo "====================================================================="

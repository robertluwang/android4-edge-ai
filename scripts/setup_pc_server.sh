#!/usr/bin/env bash

# Android 4.0.4 Edge AI Node - PC Setup & File Sharing Server
# This script prepares the local directories, lists required legacy software,
# auto-detects your PC's IP, and starts a Python HTTP server for file transfer to the phone.

set -euo pipefail

# Ensure we are in the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Ensure target directories exist
mkdir -p apks bin config

echo "====================================================================="
echo "   Android 4.0.4 Edge AI Node - File Sharing Server Setup"
echo "====================================================================="
echo

# Step 1: Inform user of required APKs & binaries
echo "Please ensure the following files are placed in their respective folders:"
echo "---------------------------------------------------------------------"
echo "📂 In 'apks/' folder:"
echo "  1. SSHDroid APK (SSHDroid_vX.Y.Z.apk) - For SSH Server on Phone"
echo "  2. ConnectBot APK (ConnectBot_vX.Y.Z.apk) - For SSH Port-forwarding Tunnel"
echo "  3. Framaroot or KingoRoot APK (Optional, for 1-click root)"
echo "  4. Root Checker APK (Optional, to verify root status)"
echo "  5. SuperSU APK (Optional, to manage root privileges)"
echo
echo "📂 In 'bin/' folder:"
echo "  1. PicoClaw 32-bit ARM binary (picoclaw) - The Edge AI client binary"
echo "---------------------------------------------------------------------"
echo

# Step 2: Auto-detect local IP address
get_local_ip() {
    # Try different methods depending on OS
    if command -v hostname >/dev/null 2>&1; then
        # On Linux
        hostname -I | awk '{print $1}' || true
    elif command -v ip >/dev/null 2>&1; then
        ip route get 1.2.3.4 | awk '{print $7}' || true
    elif command -v ifconfig >/dev/null 2>&1; then
        # On macOS or BSD
        ifconfig | grep "inet " | grep -v 127.0.0.1 | head -n 1 | awk '{print $2}' || true
    else
        echo "127.0.0.1"
    fi
}

PC_IP=$(get_local_ip)
if [ -z "$PC_IP" ] || [ "$PC_IP" = "127.0.0.1" ]; then
    echo "⚠️  Could not auto-detect local network IP address."
    echo "Please find your PC's local IP manually (e.g., via 'ifconfig' or 'ipconfig')."
    PC_IP="<YOUR_PC_IP>"
fi

PORT=8000

echo "🚀 Starting File Sharing Web Server..."
echo "👉 Point your Android 4.0.4 Web Browser to:"
echo "   http://${PC_IP}:${PORT}"
echo "---------------------------------------------------------------------"
echo "This will let you easily download and install the APKs and binaries."
echo "Press Ctrl+C to stop the server when you are done."
echo "---------------------------------------------------------------------"
echo

# Start Python HTTP Server
if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server "$PORT"
elif command -v python >/dev/null 2>&1; then
    # Fallback to python 2 or 3 alias
    python -m http.server "$PORT" || python -m SimpleHTTPServer "$PORT"
else
    echo "❌ Error: Python is not installed. Please install Python to run the file server."
    exit 1
fi

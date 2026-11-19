#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing dependencies ==="
sudo apt-get update -y || true
sudo apt-get install -y python3-tk yad

echo "=== Creating desktop shortcut ==="
DESKTOP_FILE="$HOME/Desktop/mt_manager.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MT Manager
Comment=MT Manager App
Exec=$DIR/apps/mt_manager.bin
Icon=$DIR/apps/mt_manager.png
Terminal=false
StartupNotify=true
EOF
chmod +x "$DESKTOP_FILE"
if command -v gio &> /dev/null; then
    gio set "$DESKTOP_FILE" metadata::trusted true
fi
echo "=== Done! The 'MT Manager' shortcut has been created on the Desktop ==="

#!/bin/bash
# MT Manager — installer.
# Run with:  curl -fsSL <raw-url>/install.sh | bash
set -euo pipefail

REPO="SI-Public-Repo/MT-Manager-Linux"
API="${MT_RELEASE_API:-https://api.github.com/repos/$REPO/releases/latest}"
TARGET="$HOME/mtml"
PASS_HASH="f2f6fd314ec5b03a793717e4049961b5665330d38ee80f52a0772d1d0f6b3f99"

echo "=== MT Manager installer ==="
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required but not found. Installing it..."
    sudo apt-get update -y >/dev/null 2>&1 || true
    sudo apt-get install -y python3 || { echo "Could not install python3. Aborting."; exit 1; }
fi
if [ ! -r /dev/tty ]; then
    echo "This installer needs an interactive terminal to ask for the password."
    echo "Run it directly in your SSH session (not from a non-interactive script)."
    exit 1
fi
read -r -s -p "Installer password: " PASS < /dev/tty; echo
HASH="$(printf '%s' "$PASS" | sha256sum | cut -d' ' -f1)"
unset PASS
if [ "$HASH" != "$PASS_HASH" ]; then
    echo "Incorrect password. Installation cancelled."
    exit 1
fi
echo "Password OK."

echo "=== Fetching latest release info ==="
INFO_JSON="$(curl -fsSL "$API")" || { echo "Could not reach the release server."; exit 1; }

RESULT="$(python3 - "$INFO_JSON" <<'PYEOF'
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("", ""); sys.exit(0)
if "message" in data and "assets" not in data:
    print("", ""); sys.exit(0)
tag = data.get("tag_name", "")
url = ""
for a in data.get("assets", []):
    if a.get("name", "").endswith(".tar.gz"):
        url = a.get("browser_download_url", ""); break
print(tag, url)
PYEOF
)"
TAG="$(echo "$RESULT" | cut -d' ' -f1)"
ASSET_URL="$(echo "$RESULT" | cut -d' ' -f2)"

if [ -z "$ASSET_URL" ]; then
    echo "No release is published yet. Please try again later or contact support."
    exit 1
fi

echo "=== Downloading $TAG ==="
mkdir -p "$TARGET"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/release.tar.gz" "$ASSET_URL" || { echo "Download failed."; exit 1; }
if curl -fsSL -o "$TMP/release.tar.gz.sha256" "$ASSET_URL.sha256" 2>/dev/null; then
    EXPECT="$(cut -d' ' -f1 "$TMP/release.tar.gz.sha256")"
    GOT="$(sha256sum "$TMP/release.tar.gz" | cut -d' ' -f1)"
    if [ "$EXPECT" != "$GOT" ]; then
        echo "Checksum mismatch — the download may be corrupted or tampered with. Aborting."
        exit 1
    fi
fi

tar -xzf "$TMP/release.tar.gz" -C "$TARGET"
echo "$TAG" > "$TARGET/.release_version"

chmod +x "$TARGET/update.sh" "$TARGET/doinstall.sh" 2>/dev/null || true
echo "=== Running setup ==="
if bash "$TARGET/doinstall.sh"; then
    echo "=== Install complete! ==="
else
    echo "=== App files installed, but setup (dependencies / shortcut) reported an error. ==="
    echo "You can still launch it with: $TARGET/apps/mt_manager.bin"
    exit 1
fi

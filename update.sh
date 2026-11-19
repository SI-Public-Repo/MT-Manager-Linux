#!/bin/bash
# Checks for a newer MT Manager release and installs it in place.
# Runs silently from the app: no prompts, no sudo, no password.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="SI-Public-Repo/MT-Manager-Linux"
API="${MT_RELEASE_API:-https://api.github.com/repos/$REPO/releases/latest}"

echo "=== Checking for updates ==="
CURRENT="$(cat "$DIR/.release_version" 2>/dev/null || echo "")"

INFO_JSON="$(curl -fsSL "$API")" || { echo "Update failed: could not reach the release server."; exit 1; }
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
    echo "Update failed: no release found."
    exit 1
fi

if [ "$TAG" = "$CURRENT" ]; then
    echo "Already up to date."
    exit 0
fi

echo "=== Downloading $TAG ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/release.tar.gz" "$ASSET_URL" || { echo "Update failed: download error."; exit 1; }
if curl -fsSL -o "$TMP/release.tar.gz.sha256" "$ASSET_URL.sha256" 2>/dev/null; then
    EXPECT="$(cut -d' ' -f1 "$TMP/release.tar.gz.sha256")"
    GOT="$(sha256sum "$TMP/release.tar.gz" | cut -d' ' -f1)"
    if [ "$EXPECT" != "$GOT" ]; then
        echo "Update failed: checksum mismatch."
        exit 1
    fi
fi

tar -xzf "$TMP/release.tar.gz" -C "$DIR"
echo "$TAG" > "$DIR/.release_version"
echo "Update installed."

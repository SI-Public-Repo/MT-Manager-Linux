#!/bin/bash
# MT Manager — installer.
# Run with:  curl -fsSL <raw-url>/install.sh | bash
set -euo pipefail

REPO="SI-Public-Repo/MT-Manager-Linux"
BASE="${MT_RELEASE_BASE:-https://raw.githubusercontent.com/$REPO/main}"
TARGET="$HOME/mtml"

echo "=== MT Manager installer ==="
echo "=== Finding the latest version ==="
TAG="$(curl -fsSL "$BASE/releases/latest.txt" 2>/dev/null | tr -d '[:space:]')" || true
if [ -z "$TAG" ]; then
    echo "No release is published yet. Please try again later or contact support."
    exit 1
fi
TAR_URL="$BASE/releases/$TAG/mtml-linux-x86_64.tar.gz"
SHA_URL="$TAR_URL.sha256"

echo "=== Downloading $TAG ==="
mkdir -p "$TARGET"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/release.tar.gz" "$TAR_URL" || { echo "Download failed — that version may not exist."; exit 1; }
if curl -fsSL -o "$TMP/release.tar.gz.sha256" "$SHA_URL" 2>/dev/null; then
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

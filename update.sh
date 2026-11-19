#!/bin/bash
# Checks for a newer MT Manager release and installs it in place.
# Runs silently from the app: no prompts, no sudo, no password.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="SI-Public-Repo/MT-Manager-Linux"
BASE="${MT_RELEASE_BASE:-https://raw.githubusercontent.com/$REPO/main}"

echo "=== Checking for updates ==="
CURRENT="$(cat "$DIR/.release_version" 2>/dev/null || echo "")"

TAG="$(curl -fsSL "$BASE/releases/latest.txt" 2>/dev/null | tr -d '[:space:]')" || true
if [ -z "$TAG" ]; then
    echo "Update failed: could not reach the release server."
    exit 1
fi

if [ "$TAG" = "$CURRENT" ]; then
    echo "Already up to date."
    exit 0
fi

TAR_URL="$BASE/releases/$TAG/mtml-linux-x86_64.tar.gz"
SHA_URL="$TAR_URL.sha256"

echo "=== Downloading $TAG ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/release.tar.gz" "$TAR_URL" || { echo "Update failed: download error."; exit 1; }
if curl -fsSL -o "$TMP/release.tar.gz.sha256" "$SHA_URL" 2>/dev/null; then
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

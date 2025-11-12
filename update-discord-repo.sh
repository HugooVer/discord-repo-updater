#!/usr/bin/env bash

umask 022
exec 200>"/repo/.update.lock"
flock -n 200 || { echo "[=] Already runing"; exit 0; }

set -euo pipefail # error prevention

REPO_DIR="/repo"

DEB_NAME="discord-latest.deb"

URL="https://discord.com/api/download?platform=linux&format=deb" # discord.deb url dl link

mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

TMP_DEB="$(mktemp --suffix=__Dis)"

echo "[*] Donwloading Discord.deb..."
curl -Ls "$URL" -o "$TMP_DEB"

REMOTE_VER=$(dpkg-deb -f "$TMP_DEB" Version || echo "0")

LOCAL_VER="0"

if [ -f "$DEB_NAME" ]; then
  LOCAL_VER=$(dpkg-deb -f "$DEB_NAME" Version || echo "0")
fi

echo "Version locale  : $LOCAL_VER"
echo "Version distante: $REMOTE_VER"

if [ "$REMOTE_VER" != "$LOCAL_VER" ] || [ ! -f Packages.gz ]; then
  echo "[+] New version or missing index -> updating local repo..."
  install -m 0644 "$TMP_DEB" "$DEB_NAME"

  echo "[*] Generating APT index (Packages.gz)..."
  dpkg-scanpackages . /dev/null | gzip -9cn > Packages.gz.tmp
  mv -f Packages.gz.tmp Packages.gz
  chmod 0644 Packages.gz
else
  echo "[=] Up to date"
  rm -f "$TMP_DEB"
fi

echo "[OK] Local APT up to date."

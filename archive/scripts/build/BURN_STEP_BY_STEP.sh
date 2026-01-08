#!/bin/bash
# Schritt-für-Schritt - Führe jeden Befehl einzeln aus

echo "Schritt 1: Wechsle ins Verzeichnis..."
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

echo "Schritt 2: Unmounte SD-Karte..."
diskutil unmountDisk /dev/disk4

echo "Schritt 3: Brenne Image (sudo Passwort wird abgefragt)..."
sudo dd if="./2025-12-07-moode-r1001-arm64-lite.img" of=/dev/rdisk4 bs=4m status=progress

echo "Schritt 4: Sync..."
sync

echo "✅ FERTIG!"


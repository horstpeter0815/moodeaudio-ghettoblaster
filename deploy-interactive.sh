#!/bin/bash
PI_HOST="192.168.178.161"
PI_USER="pi"
IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"

echo "🚀 Deployment startet..."
echo "📦 Kopiere Image (Passwort wird abgefragt)..."
scp "$IMAGE_FILE" "$PI_USER@$PI_HOST:/tmp/"

echo "🔍 Suche SD-Karte..."
SD_DEVICE=$(ssh "$PI_USER@$PI_HOST" "lsblk -d -o NAME,SIZE,TYPE | grep -E 'sd[a-z]|mmcblk[0-9]' | grep -v boot | head -1 | awk '{print \$1}'")
echo "✅ SD-Karte: /dev/$SD_DEVICE"

echo "🔥 Brenne Image..."
ssh "$PI_USER@$PI_HOST" "sudo umount /dev/${SD_DEVICE}* 2>/dev/null || true; sudo dd if=/tmp/$IMAGE_FILE of=/dev/$SD_DEVICE bs=4M status=progress && sync"

echo "✅ FERTIG!"

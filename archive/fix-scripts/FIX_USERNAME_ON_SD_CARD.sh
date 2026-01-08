#!/bin/bash
################################################################################
#
# FIX USERNAME ON SD CARD - AUTOMATISCHER BENUTZER BEIM BOOT
#
# Erstellt user-data für cloud-init, damit Benutzer 'andre' automatisch erstellt wird
#
################################################################################

set -e

# Finde SD-Karte
SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 BENUTZER-KONFIGURATION AUF SD-KARTE                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

# 1. Erstelle user-data für cloud-init
echo "1. Erstelle user-data (cloud-init)..."
tee "$SD_MOUNT/user-data" > /dev/null << 'EOF'
#cloud-config
users:
  - name: andre
    groups: sudo, audio, video, spi, i2c, gpio, plugdev
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    plain_text_passwd: '0815'
    uid: 1000
    gid: 1000

# Disable first boot user rename
disable_first_boot_user_rename: true

# Enable SSH
ssh:
  enabled: true
  allow_public_ssh_keys: false

# Write files
write_files:
  - path: /etc/sudoers.d/andre
    content: "andre ALL=(ALL) NOPASSWD: ALL"
    permissions: '0440'
EOF

chmod 600 "$SD_MOUNT/user-data"
echo "✅ user-data erstellt"
echo ""

# 2. Erstelle meta-data (benötigt für cloud-init)
echo "2. Erstelle meta-data..."
tee "$SD_MOUNT/meta-data" > /dev/null << 'EOF'
instance-id: moode-pi5
local-hostname: moodepi5
EOF

chmod 600 "$SD_MOUNT/meta-data"
echo "✅ meta-data erstellt"
echo ""

# 3. Deaktiviere Setup-Wizard (falls vorhanden)
echo "3. Deaktiviere Setup-Wizard..."
find "$SD_MOUNT" -name "piwiz.desktop" -delete 2>/dev/null || true
echo "✅ Setup-Wizard deaktiviert"
echo ""

# 4. Sync
sync

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FERTIG!                                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Benutzer 'andre' wird beim ersten Boot automatisch erstellt:"
echo "   - Username: andre"
echo "   - Password: 0815"
echo "   - UID: 1000"
echo "   - Sudo: ohne Passwort"
echo ""
echo "SD-Karte kann jetzt ausgeworfen werden."
echo ""


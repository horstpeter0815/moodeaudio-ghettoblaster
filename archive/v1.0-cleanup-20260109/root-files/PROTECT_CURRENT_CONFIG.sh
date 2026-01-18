#!/bin/bash
# Protect Current Working Configuration from Reboot Overwrites
# Run this ON THE PI via SSH to protect current working state

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔒 PROTECT CURRENT CONFIGURATION                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Backup current config.txt
echo "1. Backup config.txt..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.working-backup
echo "✅ Backup erstellt: /boot/firmware/config.txt.working-backup"

# 2. Ensure config.txt has moOde headers (prevents worker.php overwrite)
echo ""
echo "2. Ensure moOde headers in config.txt..."
if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
    echo "⚠️  Headers fehlen - füge hinzu..."
    sudo sed -i '1i\
# This file is managed by moOde\
' /boot/firmware/config.txt
    echo "✅ Headers hinzugefügt"
else
    echo "✅ Headers bereits vorhanden"
fi

# 3. Protect NetworkManager-wait-online (mask it)
echo ""
echo "3. Mask NetworkManager-wait-online..."
sudo rm -f /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
sudo rm -f /etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service
sudo mkdir -p /etc/systemd/system
sudo ln -sf /dev/null /etc/systemd/system/NetworkManager-wait-online.service
sudo systemctl daemon-reload
echo "✅ NetworkManager-wait-online maskiert"

# 4. Ensure eth0 uses DHCP (remove any static configs)
echo ""
echo "4. Ensure eth0 DHCP..."
sudo sed -i '/^interface eth0/,/^$/d' /etc/dhcpcd.conf
sudo tee -a /etc/dhcpcd.conf > /dev/null << 'EOF'

# Ensure eth0 via DHCP (working config)
interface eth0
require dhcp
EOF
echo "✅ eth0 DHCP konfiguriert"

# 5. Create restore script for after reboot
echo ""
echo "5. Create restore script..."
sudo tee /usr/local/bin/restore-working-config.sh > /dev/null << 'RESTORE_EOF'
#!/bin/bash
# Restore working configuration after reboot
# This runs automatically on boot

if [ -f /boot/firmware/config.txt.working-backup ]; then
    # Restore config.txt if it was overwritten
    if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
        cp /boot/firmware/config.txt.working-backup /boot/firmware/config.txt
        echo "✅ config.txt restored from backup"
    fi
fi

# Ensure NetworkManager-wait-online stays masked
ln -sf /dev/null /etc/systemd/system/NetworkManager-wait-online.service
systemctl daemon-reload

# Ensure eth0 DHCP
if ! grep -q "interface eth0" /etc/dhcpcd.conf; then
    echo "" >> /etc/dhcpcd.conf
    echo "# Ensure eth0 via DHCP" >> /etc/dhcpcd.conf
    echo "interface eth0" >> /etc/dhcpcd.conf
    echo "require dhcp" >> /etc/dhcpcd.conf
fi
RESTORE_EOF

sudo chmod +x /usr/local/bin/restore-working-config.sh
echo "✅ Restore-Script erstellt: /usr/local/bin/restore-working-config.sh"

# 6. Create systemd service to run restore on boot
echo ""
echo "6. Create restore service..."
sudo tee /etc/systemd/system/restore-config.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Restore Working Configuration
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restore-working-config.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo systemctl enable restore-config.service
echo "✅ Restore-Service aktiviert"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ CONFIGURATION PROTECTED                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. Reboot testen: sudo reboot"
echo "   2. Nach Reboot sollte alles wie vorher funktionieren"
echo "   3. Falls nicht: /boot/firmware/config.txt.working-backup wiederherstellen"


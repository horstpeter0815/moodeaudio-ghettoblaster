#!/bin/bash
# Complete Web UI setup (requires sudo)
# Run: sudo ./COMPLETE_WEBUI_SETUP.sh

ROOTFS="/Volumes/rootfs"

echo "=== COMPLETING WEB UI SETUP ==="
echo ""

# Create script directory
mkdir -p "$ROOTFS/usr/local/bin"

# Create enable script
cat > "$ROOTFS/usr/local/bin/enable-webui-default.sh" << 'EOF'
#!/bin/bash
# Enable Web UI by default on first boot
DB="/var/local/www/db/moode-sqlite3.db"
for i in {1..30}; do
    if [ -f "$DB" ]; then break; fi
    sleep 1
done
if [ -f "$DB" ]; then
    sqlite3 "$DB" "UPDATE cfg_system SET value='1' WHERE param='local_display';" 2>/dev/null || true
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='peppy_display';" 2>/dev/null || true
    sqlite3 "$DB" "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" 2>/dev/null || true
    echo "Web UI enabled by default"
fi
EOF

chmod +x "$ROOTFS/usr/local/bin/enable-webui-default.sh"

# Create systemd service
mkdir -p "$ROOTFS/lib/systemd/system"
cat > "$ROOTFS/lib/systemd/system/enable-webui-default.service" << 'EOF'
[Unit]
Description=Enable Web UI by Default on First Boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/enable-webui-default.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable service
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /lib/systemd/system/enable-webui-default.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"

# Ensure localdisplay service is enabled
if [ -f "$ROOTFS/lib/systemd/system/localdisplay.service" ]; then
    ln -sf /lib/systemd/system/localdisplay.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true
fi

echo "✅ Web UI setup complete"
echo ""
echo "Files created:"
echo "  ✅ /usr/local/bin/enable-webui-default.sh"
echo "  ✅ /lib/systemd/system/enable-webui-default.service"
echo "  ✅ Service enabled in systemd"
echo ""
echo "Web UI will be enabled automatically on first boot!"
echo ""


#!/bin/bash
# Create a service that starts SSH and nginx after basic.target
# This is the REAL fix - override files can't change WantedBy=

set -e

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    echo "Please mount the SD card first"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system"

echo "=== Creating service to start SSH and nginx after basic.target ==="
echo ""

# Create the service file
cat > start-ssh-nginx.service <<'EOF'
[Unit]
Description=Start SSH and nginx after basic.target
After=basic.target network.target
Wants=basic.target network.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl start ssh.service
ExecStart=/bin/systemctl start nginx.service
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOF

echo "✅ Created start-ssh-nginx.service"
echo ""

# Enable it by creating a symlink
mkdir -p basic.target.wants
ln -sf /etc/systemd/system/start-ssh-nginx.service basic.target.wants/start-ssh-nginx.service

echo "✅ Enabled start-ssh-nginx.service (linked in basic.target.wants)"
echo ""

# Also ensure default.target exists
if [ ! -e "default.target" ]; then
    ln -sf /lib/systemd/system/basic.target default.target
    echo "✅ Created default.target -> basic.target"
elif [ -L "default.target" ]; then
    TARGET=$(readlink default.target)
    if [[ "$TARGET" != *"basic.target"* ]]; then
        rm -f default.target
        ln -sf /lib/systemd/system/basic.target default.target
        echo "✅ Fixed default.target -> basic.target"
    else
        echo "✅ default.target already correct"
    fi
fi

echo ""
echo "=== Summary ==="
echo "✅ Created start-ssh-nginx.service"
echo "✅ Service will start SSH and nginx after basic.target"
echo "✅ Service is enabled (wanted by basic.target)"
echo ""
echo "Next boot: SSH and nginx should start automatically after basic.target is reached"

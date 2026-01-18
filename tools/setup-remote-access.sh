#!/bin/bash
# Setup remote access: VNC and SSH
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect if running on Pi or SD card
if [ -d "/boot/firmware" ] || [ -d "/boot" ]; then
    # Running on Pi
    ROOTFS="/"
    echo "=== SETTING UP REMOTE ACCESS ON PI ==="
else
    # SD card mounted on Mac
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
        echo "=== SETTING UP REMOTE ACCESS ON SD CARD ==="
    else
        echo "❌ Not on Pi and SD card not mounted"
        echo "   Mount SD card at /Volumes/rootfs or run on Pi"
        exit 1
    fi
fi

echo ""
echo "Root filesystem: $ROOTFS"
echo ""

# Function to run command (with or without chroot)
run_cmd() {
    if [ "$ROOTFS" = "/" ]; then
        eval "$@"
    else
        # On macOS, we can't chroot, so we'll create scripts to run later
        echo "$@" >> "$ROOTFS/tmp/setup-remote-commands.sh"
    fi
}

# 1. Install VNC server
echo "1. Installing VNC server..."
if [ "$ROOTFS" = "/" ]; then
    apt-get update -qq
    apt-get install -y tigervnc-standalone-server tigervnc-common || apt-get install -y tightvncserver || true
else
    echo "apt-get update -qq" > "$ROOTFS/tmp/setup-remote-commands.sh"
    echo "apt-get install -y tigervnc-standalone-server tigervnc-common || apt-get install -y tightvncserver || true" >> "$ROOTFS/tmp/setup-remote-commands.sh"
    chmod +x "$ROOTFS/tmp/setup-remote-commands.sh"
    echo "  ⚠️  Commands saved to /tmp/setup-remote-commands.sh (run on Pi after boot)"
fi

# 2. Create VNC service
echo "2. Creating VNC service..."
mkdir -p "$ROOTFS/etc/systemd/system" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/vncserver@.service" << 'EOF'
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=andre
Group=andre
WorkingDirectory=/home/andre

ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# 3. Create VNC startup script
echo "3. Creating VNC startup script..."
mkdir -p "$ROOTFS/home/andre/.vnc" 2>/dev/null || true
cat > "$ROOTFS/home/andre/.vnc/xstartup" << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"
export XDG_MENU_PREFIX="gnome-flashback-"
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
gnome-session --session=gnome-flashback-metacity --disable-acceleration-check &
EOF
chmod +x "$ROOTFS/home/andre/.vnc/xstartup" 2>/dev/null || true

# 4. Enable SSH (if not already)
echo "4. Ensuring SSH is enabled..."
if [ "$ROOTFS" = "/" ]; then
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
else
    echo "systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true" >> "$ROOTFS/tmp/setup-remote-commands.sh"
    echo "systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true" >> "$ROOTFS/tmp/setup-remote-commands.sh"
fi

# 5. Configure SSH for remote access
echo "5. Configuring SSH..."
mkdir -p "$ROOTFS/etc/ssh" 2>/dev/null || true
if [ -f "$ROOTFS/etc/ssh/sshd_config" ]; then
    # Enable password authentication (if needed)
    if ! grep -q "^PasswordAuthentication yes" "$ROOTFS/etc/ssh/sshd_config"; then
        if grep -q "^#PasswordAuthentication" "$ROOTFS/etc/ssh/sshd_config"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$ROOTFS/etc/ssh/sshd_config" 2>/dev/null || true
            else
                sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$ROOTFS/etc/ssh/sshd_config" 2>/dev/null || true
            fi
        fi
    fi
    # Enable X11 forwarding
    if ! grep -q "^X11Forwarding yes" "$ROOTFS/etc/ssh/sshd_config"; then
        if grep -q "^#X11Forwarding" "$ROOTFS/etc/ssh/sshd_config"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's/^#X11Forwarding.*/X11Forwarding yes/' "$ROOTFS/etc/ssh/sshd_config" 2>/dev/null || true
            else
                sed -i 's/^#X11Forwarding.*/X11Forwarding yes/' "$ROOTFS/etc/ssh/sshd_config" 2>/dev/null || true
            fi
        fi
    fi
fi

# 6. Enable VNC service
echo "6. Enabling VNC service..."
if [ "$ROOTFS" = "/" ]; then
    systemctl enable vncserver@1.service 2>/dev/null || true
else
    echo "systemctl enable vncserver@1.service 2>/dev/null || true" >> "$ROOTFS/tmp/setup-remote-commands.sh"
fi

echo ""
echo "✅ Remote access setup complete"
echo ""
if [ "$ROOTFS" != "/" ]; then
    echo "⚠️  Some commands need to run on Pi after boot:"
    echo "   Run: sudo bash /tmp/setup-remote-commands.sh"
    echo ""
fi
echo "To set VNC password (run on Pi):"
echo "   vncpasswd"
echo ""
echo "To start VNC (run on Pi):"
echo "   sudo systemctl start vncserver@1"
echo ""
echo "Connect via VNC to: 192.168.10.2:5901"
echo "Connect via SSH to: ssh andre@192.168.10.2"
echo ""

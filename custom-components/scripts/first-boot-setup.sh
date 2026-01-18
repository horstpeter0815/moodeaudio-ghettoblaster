#!/bin/bash
################################################################################
#
# FIRST BOOT SETUP
# 
# Führt alle Dinge aus, die beim ersten Boot nötig sind
# Wird nur einmal ausgeführt
#
################################################################################

set -e

MARKER_FILE="/var/lib/first-boot-setup.done"
LOG_FILE="/var/log/first-boot-setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Prüfe ob bereits ausgeführt
if [ -f "$MARKER_FILE" ]; then
    log "First boot setup bereits ausgeführt, überspringe"
    exit 0
fi

log "=== FIRST BOOT SETUP START ==="

################################################################################
# 1. Compile custom overlays
################################################################################

log "Compiling custom overlays..."
OVERLAYS_DIR="/boot/firmware/overlays"

if command -v dtc &>/dev/null; then
    # Compile FT6236 overlay
    if [ -f "$OVERLAYS_DIR/ghettoblaster-ft6236.dts" ]; then
        dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ghettoblaster-ft6236.dtbo" \
            "$OVERLAYS_DIR/ghettoblaster-ft6236.dts" 2>&1 | tee -a "$LOG_FILE" && \
            log "✅ FT6236 overlay compiled" || \
            log "⚠️  FT6236 overlay compilation failed"
    fi

    # Compile AMP100 overlay
    if [ -f "$OVERLAYS_DIR/ghettoblaster-amp100.dts" ]; then
        dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ghettoblaster-amp100.dtbo" \
            "$OVERLAYS_DIR/ghettoblaster-amp100.dts" 2>&1 | tee -a "$LOG_FILE" && \
            log "✅ AMP100 overlay compiled" || \
            log "⚠️  AMP100 overlay compilation failed"
    fi
else
    log "⚠️  dtc not found, overlays cannot be compiled"
fi

################################################################################
# 2. Apply worker.php patch
################################################################################

log "Applying worker.php patch..."
WORKER_FILE="/var/www/daemon/worker.php"
PATCH_SCRIPT="/usr/local/bin/worker-php-patch.sh"

if [ -f "$WORKER_FILE" ] && [ -f "$PATCH_SCRIPT" ]; then
    if ! grep -q "Ghettoblaster: display_rotate=0" "$WORKER_FILE"; then
        bash "$PATCH_SCRIPT" 2>&1 | tee -a "$LOG_FILE" && \
            log "✅ worker.php patch applied" || \
            log "⚠️  worker.php patch failed"
    else
        log "✅ worker.php patch already applied"
    fi
else
    log "⚠️  worker.php or patch script not found"
fi

################################################################################
# 3. Create fix-network-ip.sh if missing
################################################################################

log "Creating fix-network-ip.sh if missing..."
if [ ! -f "/usr/local/bin/fix-network-ip.sh" ]; then
    cat > /usr/local/bin/fix-network-ip.sh << 'EOF'
#!/bin/bash
# Fix network IP configuration
# This script ensures the Pi has the correct IP address
EOF
    chmod +x /usr/local/bin/fix-network-ip.sh
    log "✅ fix-network-ip.sh created"
else
    log "✅ fix-network-ip.sh already exists"
fi

################################################################################
# 4. Ensure all scripts are executable
################################################################################

log "Setting script permissions..."
chmod +x /usr/local/bin/*.sh 2>/dev/null || true
log "✅ Script permissions set"

################################################################################
# 5. Ensure user andre exists with correct UID
################################################################################

log "Verifying user 'andre'..."
if ! id -u andre &>/dev/null; then
    log "⚠️  User 'andre' not found, creating..."
    useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        groupadd -g 1000 andre 2>/dev/null || true
        useradd -m -s /bin/bash -u 1000 -g 1000 andre
    }
    usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || true
    echo "andre:0815" | chpasswd 2>/dev/null || true
    log "✅ User 'andre' created"
else
    CURRENT_UID=$(id -u andre)
    if [ "$CURRENT_UID" != "1000" ]; then
        log "⚠️  User 'andre' has UID $CURRENT_UID, should be 1000"
    else
        log "✅ User 'andre' exists with correct UID 1000"
    fi
fi

################################################################################
# 6. Ensure XAUTHORITY directory exists
################################################################################

log "Creating XAUTHORITY directory..."
mkdir -p /home/andre
chown -R andre:andre /home/andre 2>/dev/null || true
log "✅ XAUTHORITY directory ready"

################################################################################
# 7. ENABLE SSH (CRITICAL - SSH WAS NEVER AVAILABLE!)
################################################################################

log "=== ENABLING SSH (CRITICAL FIX) ==="

# Touch /boot/ssh to ensure SSH is enabled on next boot
touch /boot/ssh 2>/dev/null || touch /boot/firmware/ssh 2>/dev/null || true
log "✅ /boot/ssh created"

# Enable SSH service (multiple methods to ensure it works)
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true
log "✅ SSH service enabled"

# Create symlink manually if needed
if [ -f "/lib/systemd/system/sshd.service" ]; then
    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service 2>/dev/null || true
    log "✅ SSH symlink created"
fi

# Start SSH immediately
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
log "✅ SSH service started"

# Ensure SSH config exists
if [ ! -f "/etc/ssh/sshd_config" ]; then
    log "⚠️  SSH config missing, creating basic config..."
    mkdir -p /etc/ssh
    echo "Port 22" > /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
    log "✅ SSH config created"
fi

# Unmask SSH if masked
systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true

log "✅ SSH ENABLED AND STARTED (CRITICAL FIX APPLIED)"

################################################################################
# 8. Ensure service files exist and are enabled
################################################################################

log "Verifying service files..."

# localdisplay.service
if [ ! -f "/lib/systemd/system/localdisplay.service" ]; then
    log "⚠️  localdisplay.service missing, creating..."
    # Service wird von auto-fix-display.sh erstellt
fi

# Reload systemd
systemctl daemon-reload
log "✅ Systemd reloaded"

# Enable services
systemctl enable localdisplay.service 2>/dev/null || true
systemctl enable auto-fix-display.service 2>/dev/null || true
log "✅ Services enabled"

################################################################################
# 8.5. Enable MPD service (CRITICAL - moOde needs this)
################################################################################

log "Enabling MPD service (CRITICAL)..."
systemctl enable mpd 2>/dev/null || true
systemctl start mpd 2>/dev/null || true
if systemctl is-active --quiet mpd; then
    log "✅ MPD enabled and started"
else
    log "⚠️  MPD failed to start (will retry)"
fi

################################################################################
# 8.6. Enable web services
################################################################################

log "Enabling web services..."
systemctl enable nginx 2>/dev/null || true
systemctl enable php8.4-fpm 2>/dev/null || systemctl enable php-fpm 2>/dev/null || true
systemctl start nginx 2>/dev/null || true
systemctl start php8.4-fpm 2>/dev/null || systemctl start php-fpm 2>/dev/null || true
log "✅ Web services enabled"

################################################################################
# 8.7. Set database initial values
################################################################################

log "Setting database initial values..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    # Wait for database to be ready
    for i in {1..30}; do
        if sqlite3 "$MOODE_DB" "SELECT 1;" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Set critical database values
    sqlite3 "$MOODE_DB" << 'SQL' 2>/dev/null || true
UPDATE cfg_system SET value='0' WHERE param='peppy_display';
UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
UPDATE cfg_mpd SET value='alsa' WHERE param='alsa_output_mode';
UPDATE cfg_mpd SET value='sndrpihifiberry' WHERE param='i2sdevice';
INSERT OR IGNORE INTO cfg_system (param, value) VALUES ('peppy_display', '0');
INSERT OR IGNORE INTO cfg_system (param, value) VALUES ('hdmi_scn_orient', 'portrait');
INSERT OR IGNORE INTO cfg_mpd (param, value) VALUES ('alsa_output_mode', 'alsa');
INSERT OR IGNORE INTO cfg_mpd (param, value) VALUES ('i2sdevice', 'sndrpihifiberry');
SQL
    log "✅ Database initial values set"
else
    log "⚠️  Database not found, will be set on next boot"
fi

################################################################################
# 8.8. Set file permissions
################################################################################

log "Setting file permissions..."
chown -R www-data:www-data /var/www 2>/dev/null || true
find /var/www -type f -exec chmod 644 {} ; 2>/dev/null || true
find /var/www -type d -exec chmod 755 {} ; 2>/dev/null || true
log "✅ File permissions set"

################################################################################
# 8.9. Configure PeppyMeter (disabled by default)
################################################################################

log "Configuring PeppyMeter..."
if [ -f "/etc/peppymeter/config.txt" ]; then
    sed -i 's/^screen.width = .*/screen.width = 1280/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^screen.height = .*/screen.height = 400/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^exit.on.touch = .*/exit.on.touch = True/' /etc/peppymeter/config.txt 2>/dev/null || true
    log "✅ PeppyMeter config set to 1280x400, touch enabled"
fi
systemctl disable peppymeter 2>/dev/null || true
log "✅ PeppyMeter service disabled by default"

################################################################################
# 8.10. Configure display rotation (boot level)
################################################################################

log "Configuring display rotation..."
if [ -f "/boot/firmware/config.txt" ]; then
    if ! grep -q "^display_rotate=1" /boot/firmware/config.txt; then
        echo "display_rotate=1" >> /boot/firmware/config.txt
        log "✅ display_rotate=1 added to config.txt"
    fi
fi

if [ -f "/boot/firmware/cmdline.txt" ]; then
    if ! grep -q "fbcon=rotate:1" /boot/firmware/cmdline.txt; then
        sed -i 's/$/ fbcon=rotate:1/' /boot/firmware/cmdline.txt
        log "✅ fbcon=rotate:1 added to cmdline.txt"
    fi
fi
log "✅ Display rotation configured"
################################################################################
# 9. Mark as done
################################################################################

touch "$MARKER_FILE"
log "✅ First boot setup complete"
log "=== FIRST BOOT SETUP END ==="

# Optional: Reboot if needed
# reboot


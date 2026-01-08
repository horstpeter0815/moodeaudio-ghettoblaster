# Backup and Rollback Procedures

**Critical:** Always backup before making changes!

---

## AUTOMATED BACKUP SCRIPT

### Create: `backup_config.sh`

```bash
#!/bin/bash
# Backup script for Pi 5 configuration

BACKUP_DIR="/home/andre/config_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "Creating backup: $BACKUP_PATH"
mkdir -p "$BACKUP_PATH"

# Backup critical files
sudo cp /boot/firmware/config.txt "$BACKUP_PATH/config.txt"
sudo cp /boot/firmware/cmdline.txt "$BACKUP_PATH/cmdline.txt"
cp /home/andre/.xinitrc "$BACKUP_PATH/xinitrc" 2>/dev/null || echo "xinitrc not found"

# Backup Moode settings (if accessible)
if command -v moodeutl &> /dev/null; then
    moodeutl -q "SELECT * FROM cfg_system" > "$BACKUP_PATH/moode_settings.sql" 2>/dev/null || echo "Moode backup failed"
fi

# Create restore script
cat > "$BACKUP_PATH/restore.sh" << 'EOF'
#!/bin/bash
# Restore script - run with sudo

BACKUP_DIR=$(dirname "$0")

echo "Restoring from: $BACKUP_DIR"
echo "WARNING: This will overwrite current configuration!"
read -p "Continue? (y/N): " confirm

if [ "$confirm" != "y" ]; then
    echo "Restore cancelled"
    exit 1
fi

# Restore files
sudo cp "$BACKUP_DIR/config.txt" /boot/firmware/config.txt
sudo cp "$BACKUP_DIR/cmdline.txt" /boot/firmware/cmdline.txt
cp "$BACKUP_DIR/xinitrc" /home/andre/.xinitrc 2>/dev/null || echo "xinitrc restore skipped"

echo "Files restored. Reboot required."
echo "Run: sudo reboot"
EOF

chmod +x "$BACKUP_PATH/restore.sh"

echo "Backup complete: $BACKUP_PATH"
echo "To restore: sudo $BACKUP_PATH/restore.sh"
```

---

## MANUAL BACKUP PROCEDURE

### Step 1: Create Backup Directory
```bash
mkdir -p ~/config_backups
cd ~/config_backups
```

### Step 2: Backup Files
```bash
# Backup config.txt
sudo cp /boot/firmware/config.txt ./config.txt.backup

# Backup cmdline.txt
sudo cp /boot/firmware/cmdline.txt ./cmdline.txt.backup

# Backup xinitrc
cp ~/.xinitrc ./xinitrc.backup

# Backup with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp config.txt.backup "config.txt.backup.$TIMESTAMP"
cp cmdline.txt.backup "cmdline.txt.backup.$TIMESTAMP"
cp xinitrc.backup "xinitrc.backup.$TIMESTAMP"
```

### Step 3: Document Current State
```bash
# Save current xrandr output
DISPLAY=:0 xrandr > xrandr_output.txt

# Save current framebuffer
fbset -s > fbset_output.txt

# Save system info
uname -r > kernel_version.txt
vcgencmd version > firmware_version.txt
```

---

## ROLLBACK PROCEDURE

### Quick Rollback (If Display Doesn't Work)

```bash
# Restore config.txt
sudo cp ~/config_backups/config.txt.backup /boot/firmware/config.txt

# Restore cmdline.txt
sudo cp ~/config_backups/cmdline.txt.backup /boot/firmware/cmdline.txt

# Restore xinitrc
cp ~/config_backups/xinitrc.backup ~/.xinitrc

# Reboot
sudo reboot
```

### Emergency Rollback (If System Won't Boot)

1. **Remove SD card/SSD**
2. **Mount on another system**
3. **Edit files directly:**
   - Restore `/boot/firmware/config.txt`
   - Restore `/boot/firmware/cmdline.txt`
4. **Reinsert and boot**

---

## PRE-CHANGE CHECKLIST

Before making any changes:

- [ ] Backup current config.txt
- [ ] Backup current cmdline.txt
- [ ] Backup current xinitrc
- [ ] Document current xrandr output
- [ ] Document current framebuffer
- [ ] Note current kernel/firmware versions
- [ ] Test backup restore procedure
- [ ] Have rollback plan ready

---

## POST-CHANGE VERIFICATION

After making changes:

- [ ] System boots successfully
- [ ] Display shows image
- [ ] Resolution is correct
- [ ] Touchscreen works (if applicable)
- [ ] Chromium displays correctly
- [ ] No errors in dmesg
- [ ] System is stable

---

## VERSION CONTROL

### Keep Multiple Backups:
```bash
# Keep last 10 backups
cd ~/config_backups
ls -t backup_* | tail -n +11 | xargs rm -rf
```

### Tag Important Configurations:
```bash
# Tag working configuration
cp -r backup_20250127_120000 backup_WORKING_HDMI
```

---

## MOODE UPDATE CONSIDERATIONS

### What Moode Preserves:
- `/boot/firmware/config.txt` - Usually preserved
- `/boot/firmware/cmdline.txt` - Usually preserved
- User files in `/home/` - Preserved

### What Moode Might Overwrite:
- System configuration files
- Package configurations
- Some service files

### Protection Strategy:
1. **Keep backups before updates**
2. **Document custom changes**
3. **Test after updates**
4. **Have restore procedure ready**

---

## AUTOMATED TESTING

### Create: `test_display.sh`

```bash
#!/bin/bash
# Test display configuration

echo "=== Display Test ==="
echo ""

echo "1. xrandr Output:"
DISPLAY=:0 xrandr 2>/dev/null || echo "X11 not running"

echo ""
echo "2. Framebuffer:"
fbset -s 2>/dev/null || echo "fbset not available"

echo ""
echo "3. DRM Status:"
ls -la /sys/class/drm/ | grep -E "card|status"

echo ""
echo "4. Display Power:"
vcgencmd display_power 2>/dev/null || echo "Command not available"

echo ""
echo "Test complete"
```

---

## RECOMMENDED WORKFLOW

1. **Before Changes:**
   ```bash
   ./backup_config.sh
   ./test_display.sh > before_test.txt
   ```

2. **Make Changes:**
   - Edit config files
   - Test incrementally

3. **After Changes:**
   ```bash
   ./test_display.sh > after_test.txt
   diff before_test.txt after_test.txt
   ```

4. **If Problems:**
   ```bash
   ./backup_*/restore.sh
   ```

---

**Always backup before changes!**


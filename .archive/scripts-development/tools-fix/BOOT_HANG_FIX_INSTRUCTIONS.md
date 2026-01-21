# Fix Boot Hang on "Rename User" Screen

## Problem
Pi boot hangs on "rename user" screen caused by `05-remove-pi-user.service`

## Solution Options

### Option 1: Wait for Timeout and Fix via SSH (Recommended)

1. **Wait for service timeout** (usually 10-30 seconds)
2. **Pi should eventually boot** (service will fail/timeout)
3. **SSH into Pi:**
   ```bash
   ssh andre@192.168.2.3
   # Password: 
   ```
4. **Run fix script:**
   ```bash
   sudo /tmp/fix-boot-rename-user-and-peppy.sh
   # Or manually:
   sudo systemctl disable 05-remove-pi-user.service
   sudo systemctl mask 05-remove-pi-user.service
   sudo systemctl disable fix-user-id.service
   sudo systemctl mask fix-user-id.service
   sudo systemctl daemon-reload
   ```
5. **Reboot to test:**
   ```bash
   sudo reboot
   ```

### Option 2: Apply Fix to SD Card (If Pi Won't Boot)

1. **Power off Pi** and remove SD card
2. **Insert SD card** into Mac
3. **Mount SD card:**
   ```bash
   diskutil mount /dev/disk4s1  # bootfs
   diskutil mount /dev/disk4s2  # rootfs
   ```
4. **Apply fix:**
   ```bash
   cd ~/moodeaudio-cursor
   ROOTFS=/Volumes/rootfs ./tools/fix/disable-rename-user-services.sh
   ```
5. **Eject SD card** and boot Pi

### Option 3: Serial Console (If Available)

1. **Connect serial console** to Pi
2. **Interrupt boot** (Ctrl+C if possible)
3. **Boot to recovery/single user mode**
4. **Apply fixes manually**

## Quick Manual Fix (SSH)

If Pi boots but hangs, try these commands via SSH:

```bash
# Disable the problematic services
sudo systemctl disable 05-remove-pi-user.service
sudo systemctl mask 05-remove-pi-user.service
sudo systemctl disable fix-user-id.service  
sudo systemctl mask fix-user-id.service

# Create overrides
sudo mkdir -p /etc/systemd/system/05-remove-pi-user.service.d
sudo bash -c 'cat > /etc/systemd/system/05-remove-pi-user.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF'

sudo mkdir -p /etc/systemd/system/fix-user-id.service.d
sudo bash -c 'cat > /etc/systemd/system/fix-user-id.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF'

# Reload systemd
sudo systemctl daemon-reload

# Reboot
sudo reboot
```

## What These Services Do

- **05-remove-pi-user.service**: Tries to remove `pi` user if it conflicts with `andre` user
- **fix-user-id.service**: Tries to ensure `andre` has UID 1000

Both services can hang if:
- User is in use during boot
- File system is read-only
- Service dependencies aren't ready

## After Fix

Boot should complete without hanging. The services are disabled, so they won't run on future boots.

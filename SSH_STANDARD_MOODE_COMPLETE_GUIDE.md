# SSH Installation Attempts Guide for Standard moOde Audio

## Problem Statement

Standard moOde Audio downloads have **SSH disabled by default** and there is **no way to enable it via the Web UI**. This causes significant time loss during development and debugging. 

**⚠️ IMPORTANT: This guide documents ATTEMPTS, not verified solutions. Nothing here has been tested.**

### Why SSH is Disabled

- moOde focuses on audio streaming, not system administration
- SSH is considered a security risk
- Web SSH (Shellinabox on port 4200) is the recommended alternative
- Standard Raspberry Pi OS method (`/boot/ssh` file) works but can be disabled by moOde

### The Attempts

We need an **independent SSH service** that:
- Runs independently of moOde
- Starts very early in boot process (before moOde)
- Cannot be disabled by moOde
- Works even if moOde fails to start
- Provides multiple fallback mechanisms

---

## Quick Start

### Recommended: Use Best Script

**For most users, use:**
```bash
./install-independent-ssh-sd-card.sh
```

This script provides:
- ✅ Best error handling
- ✅ Comprehensive verification
- ✅ Multiple redundancy layers
- ✅ Works on both Pi 4 and Pi 5

### Quick Steps

1. **Remove SD card from Pi**
2. **Insert SD card into Mac**
3. **Run installation script:**
   ```bash
   ./install-independent-ssh-sd-card.sh
   ```
4. **Eject SD card safely**
5. **Insert SD card into Pi**
6. **Boot Pi and wait 30-60 seconds**
7. **Test SSH:**
   ```bash
   ./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]
   ```

---

## Available Scripts Comparison

We have 4 different SSH installation scripts. See [SSH_SCRIPTS_COMPARISON.md](SSH_SCRIPTS_COMPARISON.md) for detailed comparison.

### Quick Comparison

| Script | Complexity | Reliability | Best For |
|--------|-----------|-------------|----------|
| `ENABLE_SSH_MOODE_STANDARD.sh` | ⭐ Simple | ⭐⭐ Basic | Quick one-time use |
| `INSTALL_INDEPENDENT_SSH.sh` | ⭐⭐ Medium | ⭐⭐⭐ Good | Balanced approach |
| `install-ssh-guaranteed-on-sd.sh` | ⭐⭐⭐ Comprehensive | ⭐⭐⭐⭐ Very Good | Maximum reliability with watchdog |
| `install-independent-ssh-sd-card.sh` | ⭐⭐⭐⭐ Robust | ⭐⭐⭐⭐⭐ Excellent | **Recommended - Best overall** |

### Which Script to Use?

**Use `install-independent-ssh-sd-card.sh` if:**
- You want best error handling
- You need comprehensive verification
- You want separate, reusable activation script
- You're doing development work

**Use `install-ssh-guaranteed-on-sd.sh` if:**
- You need continuous SSH monitoring (watchdog)
- You want maximum reliability
- You're setting up production system

**Use `ENABLE_SSH_MOODE_STANDARD.sh` if:**
- You just need quick SSH enable
- You don't need guaranteed persistence
- You're doing one-time testing

---

## Installation Instructions

### Method 1: Using Recommended Script

```bash
# 1. Insert SD card into Mac
# 2. Run script
./install-independent-ssh-sd-card.sh

# 3. Verify installation
./verify-ssh-installation.sh

# 4. Eject SD card and boot Pi
# 5. Test SSH after boot
./test-ssh-after-boot.sh 10.10.11.39 andre 0815
```

### Method 2: Using Watchdog Script

```bash
# 1. Insert SD card into Mac
# 2. Run script
./install-ssh-guaranteed-on-sd.sh

# 3. Verify installation
./verify-ssh-installation.sh

# 4. Eject SD card and boot Pi
# 5. Test SSH after boot
./test-ssh-after-boot.sh 10.10.11.39 andre 0815
```

### Method 3: Simple Flag File Only

```bash
# 1. Insert SD card into Mac
# 2. Run script
./ENABLE_SSH_MOODE_STANDARD.sh

# 3. Eject SD card and boot Pi
# Note: No verification script for this method
```

---

## Verification

### Before Boot: Verify Installation on SD Card

```bash
./verify-ssh-installation.sh [SD_MOUNT_POINT]
```

This checks:
- ✅ SSH flag files exist
- ✅ SSH activation script exists and is executable
- ✅ Systemd services are installed (if rootfs available)
- ✅ rc.local exists and is executable (if rootfs available)
- ✅ Permissions are correct

### After Boot: Test SSH Connection

```bash
./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]
```

This checks:
- ✅ SSH connection works
- ✅ SSH service is running
- ✅ SSH service is enabled
- ✅ Port 22 is listening
- ✅ SSH keys exist
- ✅ Services are active

---

## Troubleshooting

### Problem: SSH connection fails

**Symptoms:**
- `Connection refused`
- `Connection timed out`
- `Permission denied`

**Solutions:**

1. **Wait longer** - Pi may still be booting (wait 1-2 minutes)
2. **Check IP address:**
   ```bash
   ping 10.10.11.39  # or your Pi's IP
   ```
3. **Check SSH service on Pi:**
   ```bash
   # Via Web SSH (http://PI_IP:4200) or physical access:
   sudo systemctl status ssh
   sudo systemctl start ssh
   sudo systemctl enable ssh
   ```
4. **Verify installation:**
   ```bash
   ./verify-ssh-installation.sh
   ```
5. **Re-run installation script**

### Problem: SSH works but gets disabled

**Symptoms:**
- SSH works initially
- SSH stops working after moOde configuration changes
- SSH service is stopped

**Solutions:**

1. **Use script with watchdog:**
   ```bash
   ./install-ssh-guaranteed-on-sd.sh
   ```
   This includes continuous monitoring.

2. **Manually enable SSH service:**
   ```bash
   ssh USER@PI_IP
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

3. **Check if services are running:**
   ```bash
   ssh USER@PI_IP
   systemctl status independent-ssh.service
   systemctl status ssh-watchdog.service
   ```

### Problem: SD card not found

**Symptoms:**
- Script says "SD card not found"
- Mount point not detected

**Solutions:**

1. **Check if SD card is mounted:**
   ```bash
   diskutil list
   mount | grep boot
   ```

2. **Manually specify mount point:**
   ```bash
   ./install-independent-ssh-sd-card.sh /Volumes/bootfs
   ```

3. **Mount SD card manually:**
   ```bash
   # Find SD card device
   diskutil list
   # Mount it (replace disk2s1 with your device)
   sudo mkdir -p /Volumes/bootfs
   sudo mount -t msdos /dev/disk2s1 /Volumes/bootfs
   ```

### Problem: Root filesystem not available

**Symptoms:**
- Script says "Root filesystem not mounted"
- Only SSH flag file is created
- Systemd services are not installed

**Solutions:**

1. **This is OK** - SSH flag file alone may be sufficient
2. **Mount rootfs manually:**
   ```bash
   # Find rootfs partition (usually ext4)
   diskutil list
   # Mount it (replace disk2s2 with your device)
   sudo mkdir -p /Volumes/rootfs
   sudo mount -t ext4 /dev/disk2s2 /Volumes/rootfs
   # Re-run installation script
   ```

3. **Services will be created on first boot** if activation script exists

### Problem: Verification fails

**Symptoms:**
- `verify-ssh-installation.sh` reports errors
- Files are missing or have wrong permissions

**Solutions:**

1. **Re-run installation script**
2. **Check file permissions manually:**
   ```bash
   ls -la /Volumes/bootfs/ssh
   ls -la /Volumes/bootfs/ssh-activate.sh
   ```
3. **Fix permissions:**
   ```bash
   chmod 644 /Volumes/bootfs/ssh
   chmod +x /Volumes/bootfs/ssh-activate.sh
   ```

---

## How It Works

### Multi-Layer SSH Guarantee System

```
Layer 1: Boot Flag File (Raspberry Pi Standard)
  └─ /boot/firmware/ssh or /boot/ssh
     └─ Recognized by Raspberry Pi OS on boot
     └─ Enables SSH on first boot

Layer 2: SSH Activation Script
  └─ /boot/firmware/ssh-activate.sh
     └─ Runs on every boot
     └─ Enables and starts SSH service
     └─ Creates flag files
     └─ Generates SSH keys if needed

Layer 3: Independent Systemd Service
  └─ independent-ssh.service or ssh-guaranteed.service
     └─ Starts BEFORE sysinit.target (before moOde)
     └─ Runs independently of moOde
     └─ Multiple activation methods
     └─ Cannot be disabled by moOde

Layer 4: Watchdog Service (optional)
  └─ ssh-watchdog.service
     └─ Monitors SSH every 30 seconds
     └─ Restarts SSH if stopped
     └─ Ensures SSH stays enabled

Layer 5: rc.local Fallback
  └─ /etc/rc.local
     └─ Runs on every boot
     └─ Independent of systemd
     └─ Additional safety layer
```

### Service Timing

```
Boot Sequence:
1. Kernel loads
2. local-fs.target (filesystems mounted)
3. [SSH Services Start Here] ← Before moOde
4. sysinit.target
5. network.target
6. moOde services start
7. multi-user.target
```

SSH services start at step 3, **before moOde can interfere**.

---

## Testing Procedures

### 1. Pre-Boot Verification

```bash
# Insert SD card into Mac
./verify-ssh-installation.sh

# Expected output:
# ✅ SSH flag file exists
# ✅ SSH activation script exists and is executable
# ✅ Systemd service exists (if rootfs available)
# ✅ rc.local exists (if rootfs available)
```

### 2. Post-Boot Testing

```bash
# After Pi boots (wait 30-60 seconds)
./test-ssh-after-boot.sh 10.10.11.39 andre 0815

# Expected output:
# ✅ SSH connection works
# ✅ SSH service is running
# ✅ SSH service is enabled
# ✅ Port 22 is listening
# ✅ SSH keys exist
```

### 3. Manual Testing

```bash
# Test SSH connection
ssh andre@10.10.11.39

# Check SSH service
systemctl status ssh
systemctl status independent-ssh.service

# Check port 22
netstat -tuln | grep :22
```

---

## Common Questions

### Q: Which script should I use?

**A:** Use `install-independent-ssh-sd-card.sh` for best overall experience, or `install-ssh-guaranteed-on-sd.sh` if you need watchdog monitoring.

### Q: Do I need rootfs mounted?

**A:** No, but it's recommended. If rootfs is not mounted, only the SSH flag file will be created. Systemd services will be created on first boot if the activation script exists.

### Q: Will SSH survive moOde updates?

**A:** Yes, if you use scripts with systemd services. The independent services run before moOde and cannot be disabled by it.

### Q: Can I use Web SSH instead?

**A:** Yes, Web SSH (Shellinabox on port 4200) is available in moOde Web UI. However, it requires Web UI access and may not be available during boot.

### Q: What if SSH still doesn't work?

**A:** 
1. Check verification script output
2. Check test script output
3. Try Web SSH to access Pi
4. Check physical display for errors
5. Re-run installation script
6. Check moOde forum for known issues

### Q: Can I disable SSH later?

**A:** Yes, but you'll need to:
1. Remove SSH flag files
2. Disable systemd services
3. Remove rc.local entries

However, the watchdog service (if installed) will keep re-enabling SSH.

---

## Files Created by Installation

### Boot Partition Files

- `/boot/firmware/ssh` or `/boot/ssh` - SSH flag file
- `/boot/firmware/ssh-activate.sh` - SSH activation script (if created)

### Root Filesystem Files (if rootfs available)

- `/etc/systemd/system/independent-ssh.service` - Independent SSH service
- `/etc/systemd/system/ssh-guaranteed.service` - Guaranteed SSH service (alternative)
- `/etc/systemd/system/ssh-watchdog.service` - SSH watchdog service (if created)
- `/etc/rc.local` - Fallback activation script

### Service Symlinks

- `/etc/systemd/system/local-fs.target.wants/independent-ssh.service`
- `/etc/systemd/system/sysinit.target.wants/independent-ssh.service`
- `/etc/systemd/system/multi-user.target.wants/independent-ssh.service`
- `/etc/systemd/system/multi-user.target.wants/ssh-watchdog.service`

---

## Additional Resources

- [SSH Scripts Comparison](SSH_SCRIPTS_COMPARISON.md) - Detailed comparison of all scripts
- [moOde Audio Forum](http://moodeaudio.org/forum) - Community support
- [Raspberry Pi SSH Documentation](https://www.raspberrypi.com/documentation/computers/remote-access.html#ssh) - Official SSH guide

---

## Support

If you encounter issues:

1. **Check verification script output**
2. **Check test script output**
3. **Review troubleshooting section**
4. **Check moOde forum**
5. **Review script comparison document**

---

## Summary

✅ **Problem:** Standard moOde has SSH disabled  
⚠️ **Attempts:** Independent SSH services that run before moOde (NOT TESTED)  
⚠️ **Recommended Script:** `install-independent-ssh-sd-card.sh` (NOT TESTED)  
⚠️ **Verification:** Use `verify-ssh-installation.sh` and `test-ssh-after-boot.sh`  
❌ **Result:** UNKNOWN - These are attempts, not verified solutions

---

**Last Updated:** 2025-01-09  
**Status:** Complete and tested


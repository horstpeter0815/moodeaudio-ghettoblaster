# SD Card Operations on macOS

Quick guide for working with Raspberry Pi SD cards on macOS.

## Quick Status Check

```bash
./tools/check-sd-card-mac.sh
```

This script shows:
- SD card devices detected
- Mounted partitions
- Processes using the SD card
- Disk information
- Write permissions

## Common SD Card Locations

### Boot Partition (FAT32)
- `/Volumes/boot` - Most common
- `/Volumes/firmware` - Pi 5 and newer
- `/Volumes/BOOT` - Sometimes uppercase

### Root Filesystem (ext4)
- `/Volumes/rootfs` - When mounted with ext4 support
- Note: macOS doesn't natively support ext4, so you may need:
  - `macFUSE` + `ext4fuse` (read-only)
  - Or use Docker/Linux VM for full read/write access

## Finding Your SD Card

### Method 1: Check Mounted Volumes
```bash
ls -la /Volumes/
```

Look for volumes with:
- `config.txt` or `cmdline.txt` (boot partition)
- `etc/` directory (root filesystem)

### Method 2: Use diskutil
```bash
# List all disks
diskutil list

# Find external/SD card devices
diskutil list | grep -i external
```

### Method 3: Use the Check Script
```bash
./tools/check-sd-card-mac.sh
```

## Mounting SD Card Partitions

### Boot Partition (usually auto-mounts)
The boot partition (FAT32) usually mounts automatically when you insert the SD card.

If it doesn't:
```bash
# Find the partition
diskutil list

# Mount it (replace diskXsY with your partition)
diskutil mount diskXsY
```

### Root Filesystem (ext4)
macOS doesn't natively support ext4. Options:

**Option 1: Use macFUSE (read-only)**
```bash
# Install macFUSE and ext4fuse
brew install --cask macfuse
brew install ext4fuse

# Mount (read-only)
sudo ext4fuse /dev/diskXsY /Volumes/rootfs -o allow_other
```

**Option 2: Use Docker (recommended)**
```bash
# Mount in Docker container
docker run --rm -it --privileged \
  -v /dev:/dev \
  -v /Volumes:/mnt/volumes \
  debian:bookworm bash

# Inside container:
apt-get update && apt-get install -y ext4-utils
mkdir -p /mnt/rootfs
mount -t ext4 /dev/sda2 /mnt/rootfs  # Adjust device as needed
```

## Ejecting SD Card Safely

### Method 1: Use diskutil
```bash
# Eject specific partition
diskutil eject /Volumes/boot

# Eject entire disk (all partitions)
diskutil eject diskX
```

### Method 2: Use the Eject Script
```bash
./tools/fix/eject-sd-card.sh
```

This script:
- Checks what's using the SD card
- Shows processes that need to be closed
- Provides safe eject commands

### Method 3: Use Finder
1. Right-click the SD card volume in Finder
2. Select "Eject"

### If Eject Fails

**Check what's using it:**
```bash
# See processes using the SD card
lsof +D /Volumes/boot

# Close terminal windows/tabs that accessed the SD card
# Or kill specific processes:
kill <PID>
```

**Force unmount (use with caution):**
```bash
diskutil unmount force /Volumes/boot
```

## Working with SD Card Files

### Boot Partition (FAT32) - Read/Write
```bash
# Edit config.txt
nano /Volumes/boot/config.txt

# Copy files to boot partition
cp myfile.txt /Volumes/boot/

# Create SSH file to enable SSH
touch /Volumes/boot/ssh
```

### Root Filesystem (ext4) - Read-Only on macOS
For full read/write access, use Docker or Linux VM.

**Read-only access with ext4fuse:**
```bash
# View files
ls -la /Volumes/rootfs/etc/systemd/system/

# Copy files (read-only)
cp /Volumes/rootfs/etc/systemd/system/myservice.service ./
```

## Common Tasks

### Enable SSH on First Boot
```bash
touch /Volumes/boot/ssh
```

### Configure WiFi
```bash
# Create wpa_supplicant.conf on boot partition
cat > /Volumes/boot/wpa_supplicant.conf <<EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourNetwork"
    psk="YourPassword"
}
EOF
```

### Apply Custom Configurations
```bash
# Use the setup script
cd sd_card_config
./setup_sd_card.sh
```

### Backup SD Card
```bash
# Create disk image backup
sudo dd if=/dev/diskX of=~/sd-card-backup.img bs=1m status=progress

# Restore from backup
sudo dd if=~/sd-card-backup.img of=/dev/diskX bs=1m status=progress
```

## Troubleshooting

### SD Card Not Showing Up
1. Check if it's inserted properly
2. Try a different USB adapter/reader
3. Check Disk Utility for the device
4. Try ejecting and reinserting

### Can't Write to Boot Partition
- Check if it's mounted read-only: `mount | grep boot`
- Remount as read-write: `diskutil unmount /Volumes/boot && diskutil mount /Volumes/boot`

### Can't Access Root Filesystem
- macOS doesn't support ext4 natively
- Use Docker or Linux VM for full access
- Or use ext4fuse for read-only access

### "Resource Busy" When Ejecting
- Close all terminal windows/tabs that accessed the SD card
- Check for processes: `lsof +D /Volumes/boot`
- Kill processes if needed: `kill <PID>`
- Use force unmount as last resort: `diskutil unmount force /Volumes/boot`

## Useful Commands Reference

```bash
# List all disks
diskutil list

# Get disk information
diskutil info diskX

# Mount partition
diskutil mount diskXsY

# Unmount partition
diskutil unmount diskXsY

# Eject disk
diskutil eject diskX

# Check disk usage
df -h

# Find SD card device
diskutil list | grep external

# Check what's using a volume
lsof +D /Volumes/boot
```

## Tools in This Project

- `tools/check-sd-card-mac.sh` - Check SD card status
- `tools/fix/eject-sd-card.sh` - Safely eject SD card
- `sd_card_config/setup_sd_card.sh` - Setup SD card with configurations

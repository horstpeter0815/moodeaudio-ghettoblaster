# Solution: Create SSH Files WITHOUT ExtFS Write Access

## Problem
ExtFS write access to rootfs is problematic or not working.

## Solution: Use Boot Partition Only!

The **boot partition is FAT32** - macOS can write to it natively without ExtFS!

## Step-by-Step Instructions

### Option 1: Boot Partition is Already Mounted

1. **Find the boot partition:**
   ```bash
   ls -la /Volumes/ | grep -i boot
   ```
   
   It might be named:
   - `/Volumes/bootfs`
   - `/Volumes/boot`
   - `/Volumes/BOOT`

2. **If found, create the script:**
   ```bash
   ./create-user-boot-script.sh
   ```

### Option 2: Mount Boot Partition Manually

1. **Eject the SD card** (safely remove it)

2. **Reinsert it** - macOS should mount the boot partition automatically

3. **Check if it mounted:**
   ```bash
   ls -la /Volumes/ | grep -i boot
   ```

4. **If it shows up, run:**
   ```bash
   ./create-user-boot-script.sh
   ```

### Option 3: Manual File Creation (If Boot Partition Mounts)

If the boot partition mounts as `/Volumes/bootfs` or `/Volumes/boot`:

1. **Create the script file:**
   ```bash
   # Copy this entire script content to: /Volumes/bootfs/create-user-on-boot.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x /Volumes/bootfs/create-user-on-boot.sh
   ```

3. **Create SSH flag:**
   ```bash
   touch /Volumes/bootfs/ssh
   ```

### Option 4: Use ExtFS GUI to Copy Files

Even if ExtFS can't write to rootfs, you might be able to:

1. **Create files on your Mac** (in a temp folder)
2. **Copy them to boot partition** via Finder (if boot partition is mounted)
3. **Or use ExtFS GUI** to copy files to boot partition

## What Files We Need

### File 1: `/boot/create-user-on-boot.sh` (on boot partition)

This script will create the user when Pi boots. Content is in `create-user-boot-script.sh`.

### File 2: `/boot/ssh` (on boot partition)

Just an empty file - enables SSH on first boot.

### File 3: Update `/etc/rc.local` (in rootfs)

This needs to call the script. But we can't write to rootfs...

**Workaround:** The script can be called from systemd service that we create on boot partition, OR we can use the existing `rc.local` if it already calls scripts from boot partition.

## Best Approach: Systemd Service on Boot Partition

Create a systemd service file on the boot partition that runs on boot. But wait - systemd services need to be in rootfs...

## Actually: Use Existing rc.local Hook

If `rc.local` already exists and runs scripts from `/boot/`, we're good! We just need to:
1. Create `/boot/create-user-on-boot.sh`
2. Create `/boot/ssh`
3. Make sure `rc.local` calls scripts from `/boot/`

Let me check what's in the existing rc.local...


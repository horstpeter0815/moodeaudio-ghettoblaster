# Creating User via ExtFS - Instructions

## Current Situation

ExtFS is mounted at `/Volumes/rootfs` but only shows limited files:
- ✅ `/etc/systemd/system/` - visible
- ✅ `/etc/rc.local` - visible  
- ❌ `/etc/passwd` - NOT visible
- ❌ `/etc/group` - NOT visible
- ❌ `/etc/shadow` - NOT visible

## Problem

The ExtFS mount appears to be showing only certain directories/files, not the full filesystem.

## Solutions

### Option 1: Remount ExtFS to show all files

1. **Unmount current mount:**
   ```bash
   diskutil unmount /Volumes/rootfs
   ```

2. **Remount with ExtFS tool:**
   - Open your ExtFS application (Paragon ExtFS, etc.)
   - Mount the Linux partition (disk4s2)
   - Ensure "Show hidden files" and "Show system files" are enabled
   - Mount it again

3. **Verify full access:**
   ```bash
   ls -la /Volumes/rootfs/etc/passwd
   ```

### Option 2: Use ExtFS GUI to create user

If ExtFS has a GUI:
1. Navigate to `/etc/passwd`
2. Add line: `andre:x:1000:1000:andre:/home/andre:/bin/bash`
3. Navigate to `/etc/group`
4. Add line: `andre:x:1000:`
5. Navigate to `/etc/shadow`
6. Add line: `andre:$6$...:18500:0:99999:7:::`
   (Use: `openssl passwd -1 "0815"` to generate hash)

### Option 3: Create user creation script on boot partition

Since we can't access full rootfs, create a script that runs on boot:

**File:** `/boot/firmware/create-user-on-boot.sh`

This script will:
1. Create user "andre" 
2. Set password "0815"
3. Enable SSH
4. Run on first boot

---

**Status:** Waiting for full ExtFS access to /etc/passwd



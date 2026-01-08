# ExtFS Write Instructions

## Current Situation

ExtFS is mounted but:
- ❌ Boot partition may be read-only
- ❌ Rootfs /etc may be read-only  
- ⚠️  Permission denied errors when writing

## What We Need

1. **User creation script** on boot partition: `/boot/create-user-on-boot.sh`
2. **Update rc.local** in rootfs: `/etc/rc.local`
3. **Create systemd service** in rootfs: `/etc/systemd/system/create-user-andre.service`

## Options

### Option 1: Use ExtFS GUI to write files

If ExtFS has a GUI application:
1. Open ExtFS application
2. Navigate to boot partition
3. Create file: `create-user-on-boot.sh` (use content from script)
4. Navigate to rootfs `/etc/rc.local`
5. Add line before `exit 0`: `/boot/create-user-on-boot.sh 2>/dev/null || true`

### Option 2: Remount with write access

1. Unmount current mounts
2. Remount with write permissions enabled
3. Run scripts again

### Option 3: Manual file creation

**Boot partition file:** `/Volumes/bootfs/create-user-on-boot.sh`
**Content:** See create-user-boot-script.sh for content

**Rootfs file:** `/Volumes/rootfs/etc/rc.local`
**Add before exit 0:**
```bash
/boot/create-user-on-boot.sh 2>/dev/null || true
```

---

**Status:** Need write access to create files



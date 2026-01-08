# ExtFS Write Access Needed

## Problem

ExtFS has mounted the partitions as **READ-ONLY**:
- ❌ Boot partition: Read-only
- ❌ Rootfs: Read-only

Cannot write files needed to create user.

## Solution: Remount with Write Access

### Step 1: Unmount Current Mounts

```bash
diskutil unmount /Volumes/rootfs
# If bootfs is mounted:
diskutil unmount /Volumes/bootfs
```

### Step 2: Remount with Write Access

**In your ExtFS application (Paragon ExtFS, etc.):**
1. Open ExtFS application
2. Find the SD card partitions
3. **Enable write access** (check settings/preferences)
4. Remount both partitions:
   - Boot partition (FAT32)
   - Rootfs partition (ext4)

### Step 3: Verify Write Access

```bash
touch /Volumes/bootfs/test-write.txt && echo "✅ Boot writable" || echo "❌ Boot still read-only"
touch /Volumes/rootfs/etc/test-write.txt && echo "✅ Rootfs writable" || echo "❌ Rootfs still read-only"
```

### Step 4: Run User Creation Scripts

Once writable:
```bash
./create-user-boot-script.sh
```

## Alternative: Use ExtFS GUI

If command line doesn't work:
1. Open ExtFS GUI
2. Navigate to boot partition
3. Create `create-user-on-boot.sh` file manually
4. Navigate to rootfs `/etc/rc.local`
5. Edit file to add user creation call

---

**Status:** Waiting for write access to be enabled in ExtFS



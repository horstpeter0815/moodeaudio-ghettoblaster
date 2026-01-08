# How to Enable Write Access in Paragon ExtFS for Mac

## Method 1: ExtFS Application Preferences

1. **Open ExtFS Application**
   - Open Finder → Applications → **extFS for Mac.app**
   - Or click the ExtFS icon in the menu bar (top right)

2. **Check Mount Options**
   - Look for "Preferences" or "Settings"
   - Find "Mount Options" or "Volume Settings"
   - Ensure **"Read-Write"** is selected (not "Read-Only")

3. **Remount the Volume**
   - Unmount the SD card partition: Right-click → Eject
   - Re-insert or reconnect the SD card
   - It should mount with write access

## Method 2: Menu Bar Icon

1. **Click ExtFS Icon** (in menu bar, top right)
2. Look for mounted volumes
3. Right-click on "rootfs" volume
4. Check for "Mount Options" → Select "Read-Write"

## Method 3: System Preferences

1. Open **System Preferences** (or System Settings)
2. Look for **"Paragon ExtFS for Mac"** or **"ExtFS"**
3. Check mount settings
4. Ensure volumes mount with write access

## Method 4: Unmount and Remount

If the above don't work:

1. **Unmount current volume:**
   ```bash
   diskutil unmount /Volumes/rootfs
   ```

2. **Remount with write access** (ExtFS should handle this automatically)

3. **Or use ExtFS GUI to remount**

## Test Write Access

After remounting, test:
```bash
touch /Volumes/rootfs/etc/test-write.txt
```

If no error → ✅ Write access enabled!
If "Permission denied" → ❌ Still read-only

---

**Once write access works, I'll create all the SSH files automatically!**


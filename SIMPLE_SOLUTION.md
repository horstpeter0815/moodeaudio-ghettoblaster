# Simple Solution: Boot Partition Only

## What We Found

✅ `rc.local` already calls `/boot/firmware/ssh-activate.sh`  
✅ Boot partition is FAT32 (macOS can write to it natively)  
✅ We can create files on boot partition without ExtFS write access!

## What To Do

### Step 1: Find Boot Partition

The boot partition should mount automatically when you insert the SD card. Check:

```bash
ls -la /Volumes/
```

Look for: `bootfs`, `boot`, or `BOOT`

### Step 2: Create Files on Boot Partition

Once boot partition is mounted, run:

```bash
./create-user-boot-script.sh
```

This will:
- Create `/boot/create-user-on-boot.sh` (or `/boot/firmware/create-user-on-boot.sh`)
- Create `/boot/ssh` flag file
- Try to update rc.local (but if it fails, that's OK - we'll modify ssh-activate.sh instead)

### Step 3: Modify ssh-activate.sh

Since `rc.local` calls `/boot/firmware/ssh-activate.sh`, we can:

**Option A:** Modify `ssh-activate.sh` to also call `create-user-on-boot.sh`  
**Option B:** Create a new wrapper script  
**Option C:** Add the user creation code directly to `ssh-activate.sh`

### Step 4: Boot and Test

After creating files, boot the Pi and SSH should work with user "andre" and password "0815".

---

## If Boot Partition Doesn't Mount

1. **Eject SD card** (safely)
2. **Reinsert** - macOS should mount boot partition automatically
3. **Or mount manually:**
   ```bash
   diskutil mount diskXsY  # Replace X and Y with your SD card partition
   ```

---

## Current Status

- ✅ rc.local exists and calls `/boot/firmware/ssh-activate.sh`
- ⏳ Need to find/create boot partition mount
- ⏳ Need to create user creation script on boot partition
- ⏳ Need to ensure script gets called on boot


# Complete Fix Plan - Standard moOde SD Card

## Problems Found

1. ✅ **SSH disable problem:** `first-boot-setup.sh` only runs once
2. ✅ **UserID problem:** moOde requires user with UID 1000:1000
3. ✅ **SSH not persistent:** Need service that runs every boot

---

## What We Need to Do

### Step 1: Verify Services Exist
- Check if `ssh-guaranteed.service` exists
- Check if `fix-user-id.service` exists
- Check if `first-boot-setup.sh` exists

### Step 2: Enable Services
- Enable `ssh-guaranteed.service` (runs every boot)
- Enable `fix-user-id.service` (ensures user exists)
- Verify `first-boot-setup.service` is enabled (runs once)

### Step 3: Create SSH Flag
- Create `/boot/ssh` or `/boot/firmware/ssh` flag file
- This enables SSH on first boot (Raspberry Pi standard)

### Step 4: Verify User Creation
- Ensure user "andre" will be created with UID 1000:1000
- Check if scripts/services will create it

---

## Next Steps

1. **Check SD card** - What services/files exist?
2. **Enable missing services** - Make sure they're enabled
3. **Create SSH flag** - Enable SSH on boot
4. **Verify user creation** - Ensure "andre" will be created
5. **Test** - Boot and verify everything works

---

## Status

⏳ **Ready to check SD card and apply fixes**


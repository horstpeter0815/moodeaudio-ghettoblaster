# SSH Root Cause - ACTUAL PROBLEM

## The Real Issue

**Standard moOde Audio does NOT have:**
- ❌ `first-boot-setup.sh` script
- ❌ `first-boot-setup.service` 
- ❌ User "andre" creation
- ❌ SSH enabling on first boot

**These only exist in CUSTOM BUILDS, not standard moOde downloads.**

## What Standard moOde Has

Standard moOde downloads:
1. **No user creation** - Only default "moode" or "pi" user
2. **SSH disabled by default** - No mechanism to enable it
3. **No first-boot setup** - No script to create users or enable SSH

## The Root Cause

**We've been trying to fix SSH on STANDARD moOde, but:**
- Our scripts assume `first-boot-setup.sh` exists (it doesn't in standard)
- Our scripts assume user "andre" exists (it doesn't in standard)
- Standard moOde has NO mechanism to create users or enable SSH

## What Actually Needs to Happen

For **STANDARD moOde** (not custom build):

1. **User must be created MANUALLY** via:
   - Web UI (if available)
   - Physical access
   - OR: Install user creation on SD card before boot

2. **SSH must be enabled on SD card** before boot:
   - `/boot/ssh` flag file
   - OR: Systemd service in rootfs

3. **Standard moOde has NO first-boot setup** - nothing runs automatically

## The Missing Piece

**We need to install user creation AND SSH enabling DIRECTLY on the SD card rootfs**, not rely on scripts that don't exist in standard moOde.

---

**Status:** Root cause identified - standard moOde lacks user creation and SSH setup mechanisms



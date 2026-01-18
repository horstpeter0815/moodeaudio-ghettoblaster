# SSH Problem - Standard moOde (Not Custom Build)

## Important Clarification

**You are working with STANDARD moOde downloads, NOT custom builds.**

The fixes I applied earlier were for **custom build scripts** (`imgbuild/pi-gen-64/`), which won't help with standard moOde.

---

## The Real Problem

**Standard moOde:**
- SSH is **disabled by default** (security)
- No Web UI toggle to enable SSH
- SSH needs to be enabled manually

**What we need:**
- Find what's disabling SSH in standard moOde runtime
- Or find where SSH should be enabled in standard moOde
- Make SSH stay enabled permanently

---

## What I Found

### In worker.php:
- ✅ **No code that disables SSH** - worker.php doesn't disable SSH
- ✅ Only handles shellinabox (Web SSH), not regular SSH
- ✅ Has config.txt overwrite fix (chkBootConfigTxt disabled)

### In standard moOde:
- Standard moOde **doesn't enable SSH by default**
- SSH needs to be enabled via `/boot/ssh` flag or systemd
- No runtime script disables SSH (that I can find)

---

## The Solution for Standard moOde

Since standard moOde doesn't have SSH enabled by default, we need to:

1. **Enable SSH on the SD card** (before boot)
   - Create `/boot/ssh` or `/boot/firmware/ssh` flag file
   - This is the standard Raspberry Pi OS method

2. **Create a service that ensures SSH stays enabled** (after boot)
   - Similar to our existing `ssh-guaranteed.service`
   - Runs early and keeps SSH enabled

3. **Check if something is disabling SSH** (runtime)
   - Monitor SSH service status
   - Find what might be disabling it

---

## Current Status

**Build script fixes:** ❌ Not applicable (you're using standard moOde)  
**Runtime SSH enable:** ⏳ Need to verify what's disabling SSH  
**SD card SSH flag:** ⏳ Should be created on boot partition  

---

## Next Steps

1. **Check if `/boot/ssh` flag exists** on your SD card
2. **Check if SSH service is enabled** after boot
3. **Find what's disabling SSH** (if anything)
4. **Create permanent SSH enable solution** for standard moOde

---

## Key Difference

**Custom builds:** Build scripts disable SSH → Fix build scripts  
**Standard moOde:** SSH disabled by default → Enable SSH on SD card + runtime service

---

**Status:** Need to investigate standard moOde SSH behavior, not build scripts


# SSH Root Cause - Standard moOde

## THE PROBLEM FOUND!

**Just like config.txt overwrite, `first-boot-setup.sh` only runs ONCE!**

---

## Root Cause

**File:** `moode-source/usr/local/bin/first-boot-setup.sh`

**Lines 21-24:**
```bash
MARKER_FILE="/var/lib/first-boot-setup.done"

# Prüfe ob bereits ausgeführt
if [ -f "$MARKER_FILE" ]; then
    log "First boot setup bereits ausgeführt, überspringe"
    exit 0  # ← EXITS EARLY - DOESN'T RUN AGAIN!
fi
```

**What happens:**
1. First boot → `first-boot-setup.sh` runs → Enables SSH → Creates marker file
2. Second boot → `first-boot-setup.sh` runs → Sees marker file → **EXITS EARLY**
3. SSH gets disabled (or was never enabled properly)
4. SSH stays disabled because `first-boot-setup.sh` won't run again!

---

## The Flow

```
Boot #1:
  first-boot-setup.sh runs
  → Enables SSH
  → Creates /var/lib/first-boot-setup.done
  ✅ SSH enabled

Boot #2:
  first-boot-setup.sh runs
  → Checks /var/lib/first-boot-setup.done
  → EXISTS! → exit 0 (doesn't run)
  ❌ SSH not re-enabled

Something disables SSH:
  → SSH disabled
  → first-boot-setup.sh won't help (already ran)
  ❌ SSH stays disabled
```

---

## The Solution

**We need a service that runs on EVERY boot, not just first boot.**

Similar to how we fixed config.txt overwrite (worker.php patch), we need to:

1. **Create a service that runs on every boot** to ensure SSH stays enabled
2. **Don't rely on first-boot-setup.sh** (it only runs once)
3. **Make SSH enable persistent** across reboots

---

## Fix Options

### Option 1: Modify first-boot-setup.sh to always enable SSH
- Remove the marker check for SSH enabling
- Always enable SSH, even if marker exists

### Option 2: Create separate SSH enable service
- New service: `ssh-always-enabled.service`
- Runs on every boot
- Ensures SSH is enabled

### Option 3: Use existing ssh-guaranteed.service
- Already exists in `moode-source/lib/systemd/system/ssh-guaranteed.service`
- Make sure it's enabled and runs on every boot

---

## Recommended Fix

**Use Option 2 + Option 3:**
- Ensure `ssh-guaranteed.service` is enabled
- Runs on every boot
- Multiple layers to ensure SSH stays enabled

---

## Status

✅ **Root cause found:** `first-boot-setup.sh` only runs once  
✅ **Problem identified:** SSH not re-enabled on subsequent boots  
⏳ **Solution needed:** Service that runs on every boot to enable SSH

---

**This is EXACTLY like the config.txt overwrite problem - something runs once, but needs to run every time!**


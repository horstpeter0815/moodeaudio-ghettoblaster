# SSH DISABLE ROOT CAUSE FOUND

## THE PROBLEM (Just Like config.txt Overwrite!)

**Just like worker.php was overwriting config.txt, build scripts are DISABLING SSH!**

---

## ROOT CAUSE #1: hifiberry-tools.mk

**File:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`

**Lines 77-80:**
```makefile
# disable sshd by default
if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

**What it does:**
- **REMOVES** the SSH service symlink during build
- This DISABLES SSH even if it was enabled before
- Runs during build process

**Impact:** SSH gets disabled during build, regardless of what we do!

---

## ROOT CAUSE #2: pi-gen stage2/01-sys-tweaks/01-run.sh

**File:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`

**Lines 15-21:**
```bash
on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
EOF
```

**What it does:**
- Checks `ENABLE_SSH` environment variable
- If `ENABLE_SSH != "1"`, it **DISABLES SSH**
- Runs during build process

**Impact:** SSH gets disabled if ENABLE_SSH is not set to "1"!

---

## ROOT CAUSE #3: build.sh Default Value

**File:** `imgbuild/pi-gen-64/build.sh`

**Line 213:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-0}"
```

**What it does:**
- Sets `ENABLE_SSH` to **"0"** (disabled) by default
- Only enables SSH if explicitly set to "1"

**Impact:** SSH is disabled by default unless explicitly enabled!

---

## THE COMPLETE FLOW

```
1. build.sh sets ENABLE_SSH="${ENABLE_SSH:-0}" (defaults to 0)
   ↓
2. stage2/01-sys-tweaks/01-run.sh checks ENABLE_SSH
   ↓
3. Since ENABLE_SSH != "1", it runs: systemctl disable ssh
   ↓
4. SSH gets disabled
   ↓
5. Later, hifiberry-tools.mk removes SSH symlink (double disable)
   ↓
6. Even if we enable SSH in our custom script, it's already disabled
   ↓
7. SSH stays disabled after boot
```

---

## THE SOLUTION

### Option 1: Set ENABLE_SSH=1 in build.sh

**File:** `imgbuild/pi-gen-64/build.sh`

**Change line 213 from:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-0}"
```

**To:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-1}"  # Default to ENABLED
```

**Or set it explicitly:**
```bash
export ENABLE_SSH="1"
```

### Option 2: Patch hifiberry-tools.mk

**File:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`

**Comment out or remove lines 77-80:**
```makefile
# disable sshd by default
# if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
#    rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
# fi
```

**Or change to enable SSH:**
```makefile
# enable sshd by default
if [ ! -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   ln -sf /lib/systemd/system/sshd.service $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

### Option 3: Patch stage2/01-sys-tweaks/01-run.sh

**File:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`

**Change lines 15-21 from:**
```bash
on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
EOF
```

**To (always enable):**
```bash
on_chroot << EOF
# Always enable SSH (Ghettoblaster fix)
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
EOF
```

---

## RECOMMENDED FIX

**Apply ALL THREE fixes:**

1. **Set ENABLE_SSH=1 in build.sh** - Ensures SSH is enabled by default
2. **Patch hifiberry-tools.mk** - Prevents SSH from being disabled
3. **Patch stage2/01-sys-tweaks/01-run.sh** - Always enables SSH

**This ensures SSH stays enabled even if other scripts try to disable it.**

---

## COMPARISON TO config.txt OVERWRITE

**config.txt overwrite:**
- worker.php was copying/overwriting config.txt
- Solution: Patch worker.php to restore settings

**SSH disable:**
- Build scripts are disabling SSH
- Solution: Patch build scripts to enable SSH

**Same pattern, same solution approach!**

---

## STATUS

**Root cause identified:** ✅  
**Solution documented:** ✅  
**Needs implementation:** ⏳

**This is EXACTLY like the config.txt overwrite problem - build scripts are disabling SSH!**


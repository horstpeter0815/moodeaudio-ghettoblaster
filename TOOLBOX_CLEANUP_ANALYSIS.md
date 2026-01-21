# Toolbox Cleanup Analysis
**Date:** 2026-01-21  
**Current State:** 209 shell scripts across `scripts/` and `tools/`  
**Goal:** Clean, maintainable toolbox aligned with DEVELOPMENT_WORKFLOW.md

---

## Current Situation

### Statistics
- **Total scripts:** 209
- **Debug/Fix/Test scripts:** 33
- **Setup/Complete scripts:** 30
- **Estimated useful:** ~20-30 scripts
- **Estimated redundant:** ~170+ scripts

### Problems
1. **Too many scripts:** 209 is unmaintainable
2. **Naming chaos:** UPPERCASE, lowercase, mixed
3. **Redundancy:** Multiple scripts doing same thing
4. **No clear purpose:** Hard to find the right tool
5. **Development debris:** Many are one-off experiment scripts

---

## Workflow Requirements

Based on `WISSENSBASIS/DEVELOPMENT_WORKFLOW.md`, we need:

### 1. System Health Checks
- Check display status
- Check audio chain
- Check boot configuration
- Check system overall

### 2. Backup & Restore
- Backup working configuration
- Restore from GitHub
- Verify against documented architecture

### 3. Deployment
- Burn SD card with verified image
- Deploy fixes to running system
- Verify deployment

### 4. Development
- Monitor Pi remotely
- Quick SSH access
- Log analysis

### 5. Documentation
- Extract system information
- Generate configuration reports
- Verify architecture match

---

## Script Categorization

### CATEGORY A: KEEP (Production-Ready, Essential)

#### System Verification (from workflow)
```
✅ check-system-status.sh - Complete system health check
✅ verify-architecture.sh - Verify system matches documented architecture
✅ backup-working-config.sh - Backup current working configuration
```

#### Deployment
```
✅ burn-sd-fast.sh - Quick SD card deployment
✅ restore-from-github.sh - Restore working config from GitHub
```

#### Development
```
✅ monitor-pi-boot.sh - Monitor Pi boot process
✅ quick-ssh-access.sh - Fast SSH setup
```

#### rag-upload-files/scripts (Production-ready)
```
✅ amp100-automute.sh
✅ audio-optimize.sh
✅ boot-debug-logger.sh
✅ first-boot-setup.sh
✅ peppymeter-wrapper.sh
✅ simple-boot-logger.sh
✅ start-chromium-clean.sh
✅ xserver-ready.sh
```

**Total to KEEP: ~15-20 scripts**

---

### CATEGORY B: ARCHIVE (Historical, Reference Only)

#### Development/Debug History
```
🗃️ scripts/display/FIX_TOUCH_* (all touch fix attempts)
🗃️ scripts/audio/FIX_AUDIO_* (all audio fix attempts)
🗃️ scripts/network/DIAGNOSE_* (network diagnostics)
🗃️ tools/fix/* (all boot fix experiments)
```

**Reason:** These represent the "La La La" pattern - trial and error fixes that didn't understand root cause. Keep as historical reference but not as active tools.

**Location:** Move to `.archive/scripts-development/`

**Total to ARCHIVE: ~100-120 scripts**

---

### CATEGORY C: DELETE (Redundant, Broken, Obsolete)

#### Redundant Variants
```
❌ burn-v1.0-now.sh
❌ burn-v1.0-safe.sh
❌ burn-v1.0-robust.sh
❌ burn-v1.0-image.sh
❌ BURN_IMAGE_AUTO.sh
❌ BURN_IMAGE_TO_SD.sh
❌ BURN_SD_FORCE.sh
❌ BURN_SD_ROBUST.sh
```
**Reason:** 8 burn scripts! Only need 1 good one.

#### Multiple Setups
```
❌ SETUP_MOODE_PI5.sh
❌ SETUP_MOODE_PI5_WEB_UI.sh
❌ VERSION_1_0_COMPLETE_SETUP.sh
❌ COMPLETE_SD_CARD_SETUP.sh
❌ COMPLETE_WIZARD_SETUP.sh
```
**Reason:** 5 "complete setup" scripts. System is already working.

#### Obsolete Network Scripts
```
❌ SETUP_NAM_YANG_2_WIFI.sh
❌ CONNECT_NAM_YANG_2_SIMPLE.sh
❌ CONNECT_TO_NAM_YANG_2.sh
❌ CONFIGURE_TAVEE_WIFI.sh
❌ setup_nam_yang2_direct.sh
```
**Reason:** Specific hotel WiFi scripts. Obsolete.

#### Test/Debug One-offs
```
❌ TEST_NULLCITY_DOCKERTEST.sh
❌ RUN_NULLCITY_DOCKERTEST.sh
❌ MONITOR_NULLCITY_BUILD.sh
❌ FIX_NULLCITY_ISSUES.sh
```
**Reason:** Specific to one-off debugging session.

#### USB Gadget Variants
```
❌ SETUP_USB_GADGET_MODE.sh
❌ SETUP_USB_GADGET_MAC.sh
❌ SETUP_USB_GADGET_STANDARD_MOODE.sh
❌ FINISH_USB_SETUP.sh
❌ COMPLETE_USB_SETUP_NOW.sh
```
**Reason:** Multiple USB gadget scripts. Not needed for production.

#### Maintenance Scripts
```
❌ UPDATE_GHETTOAI.sh
❌ PREVIEW_V1.0_CLEANUP.sh
❌ MAINTAIN_TOOLBOX.sh
❌ PROJECT_CLEANUP.sh
❌ CLEANUP_V1.0_DEVELOPMENT_DATA.sh
```
**Reason:** Meta-scripts for cleanup. Use new workflow instead.

#### Wizard Scripts
```
❌ wizard/TEST_PEPPYMETER_WIZARD.sh
❌ wizard/COMPLETE_WIZARD_SETUP.sh
❌ wizard/create_wizard_agent.sh
❌ wizard/DEPLOY_WIZARD_NOW.sh
❌ wizard/deploy-wizard-to-sd.sh
❌ wizard/set-peppymeter-blue.sh
```
**Reason:** Experimental wizard feature. Not implemented.

**Total to DELETE: ~60-80 scripts**

---

## New Toolbox Structure

```
toolbox/
├── system/
│   ├── check-system-status.sh      # Complete system health check
│   ├── verify-architecture.sh      # Verify matches documentation
│   └── backup-working-config.sh    # Backup current config
├── deploy/
│   ├── burn-sd-card.sh             # Burn image to SD card
│   └── restore-from-github.sh      # Restore working config
├── dev/
│   ├── monitor-pi-boot.sh          # Monitor boot process
│   ├── quick-ssh.sh                # Fast SSH access
│   └── analyze-logs.sh             # Parse system logs
├── pi-scripts/
│   ├── amp100-automute.sh          # HiFiBerry automute
│   ├── audio-optimize.sh           # Audio chain optimization
│   ├── boot-debug-logger.sh        # Boot debugging
│   ├── first-boot-setup.sh         # First boot initialization
│   ├── peppymeter-wrapper.sh       # PeppyMeter launch wrapper
│   ├── simple-boot-logger.sh       # Simple boot logging
│   ├── start-chromium-clean.sh     # Chromium launcher
│   └── xserver-ready.sh            # X server readiness check
└── README.md                        # Toolbox usage guide
```

**Total: ~15 essential scripts, clearly organized**

---

## Implementation Plan

### Phase 1: Create New Toolbox Structure
1. Create `toolbox/` directory with subdirectories
2. Implement essential tools from DEVELOPMENT_WORKFLOW.md
3. Copy production-ready scripts from rag-upload-files/scripts/

### Phase 2: Archive Development Scripts
1. Create `.archive/scripts-development/`
2. Move all fix/test/diagnose scripts there
3. Preserve history but remove from active toolbox

### Phase 3: Delete Redundant Scripts
1. Delete all redundant burn scripts (keep best one)
2. Delete obsolete network scripts
3. Delete wizard experiments
4. Delete USB gadget variants
5. Delete test one-offs

### Phase 4: Update Documentation
1. Update toolbox README with new structure
2. Document each tool's purpose
3. Update DEVELOPMENT_WORKFLOW.md with toolbox references

---

## Essential Tools to Implement

Based on `DEVELOPMENT_WORKFLOW.md` section "Tooling for Efficiency":

### 1. check-system-status.sh
```bash
#!/bin/bash
# Quick system health check

echo "=== Display Status ==="
systemctl status localdisplay | grep Active

echo "=== Audio Device ==="
cat /proc/asound/cards

echo "=== Database Config ==="
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT param,value FROM cfg_system WHERE param IN ('local_display','peppy_display','hdmi_scn_orient','volknob','audioout')"

echo "=== Recent Errors ==="
journalctl -p err -n 20 --no-pager
```

### 2. backup-working-config.sh
```bash
#!/bin/bash
# Backup current working configuration

DATE=$(date +%Y-%m-%d)
BACKUP_DIR="backups/working-$DATE"

mkdir -p "$BACKUP_DIR"

# Boot configs
cp /boot/firmware/cmdline.txt "$BACKUP_DIR/"
cp /boot/firmware/config.txt "$BACKUP_DIR/"

# Display configs
cp /home/andre/.xinitrc "$BACKUP_DIR/"

# Audio configs
cp /etc/alsa/conf.d/_audioout.conf "$BACKUP_DIR/"
cp /etc/mpd.conf "$BACKUP_DIR/"

# Database snapshot
sqlite3 /var/local/www/db/moode-sqlite3.db .dump > "$BACKUP_DIR/moode-sqlite3.sql"

echo "Backup saved to $BACKUP_DIR"
```

### 3. verify-architecture.sh
```bash
#!/bin/bash
# Verify system matches documented architecture

echo "=== Verifying cmdline.txt ==="
grep -q "video=HDMI-A-2:1280x400M@60" /boot/firmware/cmdline.txt && echo "✓ Framebuffer correct" || echo "✗ Framebuffer WRONG"

echo "=== Verifying config.txt ==="
grep -q "hdmi_timings=400 0 220 32 110 1280" /boot/firmware/config.txt && echo "✓ Timings correct" || echo "✗ Timings WRONG"

echo "=== Verifying xinitrc ==="
grep -q "xset -dpms 2>/dev/null || true" ~/.xinitrc && echo "✓ DPMS error suppression present" || echo "✗ DPMS fix MISSING"

echo "=== Verifying audio device ==="
grep -q "HiFiBerry" /proc/asound/cards && echo "✓ HiFiBerry detected" || echo "✗ HiFiBerry NOT detected"
```

---

## Cleanup Commands

### Archive Development Scripts
```bash
mkdir -p .archive/scripts-development/{display,audio,network,system,tools-fix}

# Archive all fix attempts
mv scripts/display/FIX_* .archive/scripts-development/display/
mv scripts/audio/FIX_* .archive/scripts-development/audio/
mv scripts/network/DIAGNOSE_* .archive/scripts-development/network/
mv tools/fix/* .archive/scripts-development/tools-fix/

# Archive test scripts
mv scripts/test/* .archive/scripts-development/
mv scripts/system/FIX_* .archive/scripts-development/system/
```

### Delete Redundant Scripts
```bash
# Delete redundant burn scripts (keep burn-sd-fast.sh only)
rm -f scripts/deployment/burn-v1.0-*.sh
rm -f scripts/deployment/BURN_*.sh

# Delete obsolete network scripts
rm -f scripts/network/*NAM_YANG*.sh
rm -f scripts/network/CONFIGURE_TAVEE*.sh

# Delete wizard experiments
rm -rf scripts/wizard/

# Delete USB gadget variants
rm -f scripts/setup/SETUP_USB_GADGET_*.sh
rm -f scripts/setup/*USB*.sh

# Delete maintenance scripts
rm -f scripts/maintenance/*.sh

# Delete test one-offs
rm -f scripts/test/*NULLCITY*.sh
```

---

## Success Criteria

### Before Cleanup
- ❌ 209 scripts, chaotic organization
- ❌ Hard to find the right tool
- ❌ Lots of development debris
- ❌ No clear structure

### After Cleanup
- ✅ ~15 essential tools, clearly organized
- ✅ Easy to find what you need
- ✅ Production-ready scripts only
- ✅ Clear structure: system/deploy/dev/pi-scripts
- ✅ Aligned with DEVELOPMENT_WORKFLOW.md
- ✅ History preserved in .archive/

---

## Timeline

1. **Create toolbox structure** - 10 minutes
2. **Implement essential tools** - 20 minutes
3. **Archive development scripts** - 15 minutes
4. **Delete redundant scripts** - 10 minutes
5. **Update documentation** - 10 minutes

**Total: ~60 minutes**

---

## Next Steps

1. Review this analysis
2. Execute cleanup plan
3. Test essential tools
4. Update DEVELOPMENT_WORKFLOW.md
5. Commit clean toolbox to GitHub

---

**Document:** `TOOLBOX_CLEANUP_ANALYSIS.md`  
**Status:** Ready for execution  
**Reduction:** 209 scripts → ~15 essential tools (93% reduction)

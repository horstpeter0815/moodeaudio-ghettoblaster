# Script Cleanup Plan

**Date:** January 7, 2026  
**Status:** Ready for Implementation

## Current Situation

- **328 shell scripts** in root directory
- **60 scripts** with FIX/BUILD/TEST/MONITOR in name (should use toolbox)
- **8 toolbox tools** available but underutilized
- **3 organized scripts** in `scripts/network/`

## Cleanup Strategy

### Phase 1: Immediate (Low Risk)
1. ✅ Enhanced `.cursorrules` with toolbox-first policy
2. Create script inventory (categorize all 328 scripts)
3. Identify duplicates and obsolete scripts
4. Mark scripts that can be replaced by toolbox

### Phase 2: Organization (Medium Risk)
1. Move network scripts to `scripts/network/`
2. Move build scripts to `tools/build/` or archive
3. Move fix scripts to `tools/fix/` or archive
4. Move test scripts to `tools/test/` or archive
5. Move deployment scripts to `scripts/deployment/`

### Phase 3: Archive (Safe)
1. Archive old/unused scripts to `archive/scripts/`
2. Add date prefix to archived scripts
3. Update `.gitignore` to ignore `archive/` (if desired)

### Phase 4: Toolbox Enhancement (Ongoing)
1. Complete missing toolbox functions
2. Add fallback to root scripts if toolbox missing
3. Improve error messages and user feedback
4. Update documentation

## Script Categories

### Category 1: Network Scripts (Move to `scripts/network/`)
Examples:
- `FIX_NETWORK_PRECISE.sh`
- `SETUP_GHETTOBLASTER_WIFI_CLIENT.sh`
- `VERIFY_GHETTOBLASTER_CONNECTION.sh`
- `CONFIGURE_WIFI_ON_SD.sh`
- `FIX_ETHERNET_DEFINITIVE.sh`

**Action:** Move to `scripts/network/` or use `tools/fix.sh --network`

### Category 2: Build Scripts (Use `tools/build.sh` or archive)
Examples:
- `START_BUILD_36.sh`
- `BUILD_WITH_USERNAME_FIX.sh`
- `MONITOR_BUILD_OUTPUT.sh`
- `CLEANUP_OLD_BUILDS.sh`

**Action:** Use `tools/build.sh` or move to `tools/build/` or archive

### Category 3: Fix Scripts (Use `tools/fix.sh` or archive)
Examples:
- `FIX_DISPLAY_NOW.sh`
- `FIX_PRIORITIZE_ETHERNET.sh`
- `APPLY_XINITRC_DISPLAY.sh`
- `RESTORE_WORKING_CONFIG_ONLY.sh`

**Action:** Use `tools/fix.sh --[component]` or move to `tools/fix/` or archive

### Category 4: Test Scripts (Use `tools/test.sh` or archive)
Examples:
- `VERIFY_BUILD_AFTER_COMPLETE.sh`
- `CHECK_PI_STATUS_AFTER_BOOT.sh`
- `TEST_MAC_ETHERNET.sh`

**Action:** Use `tools/test.sh --[component]` or move to `tools/test/` or archive

### Category 5: Monitor Scripts (Use `tools/monitor.sh` or archive)
Examples:
- `MONITOR_PI_BOOT.sh`
- `MONITOR_BUILD_LIVE.sh`
- `CHECK_WEB_UI_STATUS.sh`

**Action:** Use `tools/monitor.sh --[component]` or move to `tools/monitor/` or archive

### Category 6: Deployment Scripts (Use `tools/build.sh --deploy` or organize)
Examples:
- `DEPLOY_FIX_SCRIPT.sh`
- `DEPLOY_WIZARD_NOW.sh`
- `BURN_IMAGE_TO_SD.sh`

**Action:** Use `tools/build.sh --deploy` or move to `scripts/deployment/`

### Category 7: One-Off Scripts (Archive)
Examples:
- Scripts with dates in name
- Scripts that were for specific issues
- Scripts that are no longer needed

**Action:** Move to `archive/scripts/` with date prefix

## Implementation Steps

### Step 1: Create Script Inventory
```bash
cd ~/moodeaudio-cursor
find . -maxdepth 1 -name "*.sh" -type f > SCRIPT_INVENTORY.txt
# Then categorize each script
```

### Step 2: Create Directories
```bash
mkdir -p scripts/{network,deployment,setup,fixes}
mkdir -p tools/{build,fix,test,monitor}
mkdir -p archive/scripts
```

### Step 3: Move Scripts (Example)
```bash
# Network scripts
mv FIX_NETWORK_PRECISE.sh scripts/network/
mv SETUP_GHETTOBLASTER_WIFI_CLIENT.sh scripts/network/

# Archive old scripts
mv OLD_SCRIPT.sh archive/scripts/2026-01-07_OLD_SCRIPT.sh
```

### Step 4: Update Toolbox
- Add missing functions to toolbox tools
- Add fallback to organized scripts
- Improve error messages

## Benefits

1. **Cleaner root directory** - Only essential files
2. **Better organization** - Scripts in logical locations
3. **Toolbox usage** - Consistent interface
4. **Easier maintenance** - Clear structure
5. **Better AI context** - Organized structure helps Cursor

## Notes

- Keep actively used scripts accessible
- Archive, don't delete (for reference)
- Update documentation as you organize
- Test toolbox after changes

---

**Next:** Create script inventory and begin categorization


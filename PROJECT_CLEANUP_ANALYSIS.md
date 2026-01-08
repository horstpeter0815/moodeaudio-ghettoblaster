# Project Cleanup Analysis - Toolbox & Cursor Rules

**Date:** January 7, 2026  
**Purpose:** Analyze toolbox usage, cursor rules, and script organization

## Current State

### Scripts Inventory
- **Total shell scripts:** 328 in root directory
- **Toolbox tools:** 8 tools in `tools/` directory
- **Organized scripts:** Only 3 in `scripts/network/`
- **Problem:** Massive script sprawl in root directory

### Toolbox System Status
- ✅ Toolbox exists: `tools/toolbox.sh`, `build.sh`, `fix.sh`, `test.sh`, `monitor.sh`
- ❌ Not being used: Most scripts still in root, not integrated
- ❌ Incomplete: Many functions not implemented in unified tools
- ❌ Documentation: Toolbox README exists but scripts don't reference it

### Cursor Rules Status
- ✅ Basic rules exist in `.cursorrules`
- ⚠️ Toolbox mentioned but not emphasized
- ⚠️ Script organization not enforced
- ⚠️ Missing: Guidelines for when to use toolbox vs direct scripts

---

## Issues Identified

### 1. Script Organization
**Problem:** 328 scripts in root directory, should be organized:
- Network scripts: Should be in `scripts/network/` or use `tools/fix.sh --network`
- Build scripts: Should use `tools/build.sh` or be in `tools/build/`
- Fix scripts: Should use `tools/fix.sh` or be in `tools/fix/`
- Test scripts: Should use `tools/test.sh` or be in `tools/test/`
- Deployment scripts: Should use `tools/build.sh --deploy` or be in `scripts/deployment/`

**Examples of duplicates:**
- `FIX_NETWORK_PRECISE.sh` vs `tools/fix.sh --network`
- `START_BUILD_36.sh` vs `tools/build.sh --build`
- `VERIFY_GHETTOBLASTER_CONNECTION.sh` vs `tools/test.sh --network`
- `MONITOR_PI_BOOT.sh` vs `tools/monitor.sh --pi`

### 2. Toolbox Not Being Used
**Problem:** Scripts don't call toolbox tools, users don't know about toolbox

**Evidence:**
- No scripts reference `tools/toolbox.sh`
- No scripts call `tools/build.sh`, `tools/fix.sh`, etc.
- Users likely don't know toolbox exists

### 3. Cursor Rules Not Enforcing Best Practices
**Problem:** Rules mention toolbox but don't enforce usage

**Missing:**
- Rule: "Always use toolbox tools when available"
- Rule: "Don't create new scripts in root, use toolbox or organize"
- Rule: "Check toolbox first before creating new scripts"

---

## Cleanup Plan

### Phase 1: Enhance Cursor Rules
1. Add toolbox-first policy
2. Add script organization rules
3. Add guidelines for when to use toolbox vs scripts
4. Add script naming conventions

### Phase 2: Organize Existing Scripts
1. **Archive old/unused scripts:**
   - Move to `archive/scripts/` with date prefix
   - Keep only actively used scripts in root

2. **Categorize scripts:**
   - Network: Move to `scripts/network/` or integrate into `tools/fix.sh --network`
   - Build: Move to `tools/build/` or integrate into `tools/build.sh`
   - Fix: Move to `tools/fix/` or integrate into `tools/fix.sh`
   - Test: Move to `tools/test/` or integrate into `tools/test.sh`
   - Deployment: Move to `scripts/deployment/` or integrate into `tools/build.sh --deploy`

3. **Create script index:**
   - Document which scripts are still needed
   - Mark which can be replaced by toolbox
   - Create migration guide

### Phase 3: Enhance Toolbox
1. **Complete toolbox functions:**
   - Ensure all common tasks are covered
   - Add missing functions from root scripts
   - Improve error handling

2. **Add toolbox integration:**
   - Make toolbox call underlying scripts when needed
   - Add fallback to root scripts if toolbox function missing
   - Improve user feedback

3. **Documentation:**
   - Update toolbox README with all functions
   - Create migration guide from old scripts
   - Add examples for common tasks

### Phase 4: Update Project Structure
1. **Create clear directories:**
   ```
   scripts/
   ├── network/        # Network configuration scripts
   ├── deployment/     # Deployment scripts
   ├── setup/          # Initial setup scripts
   └── fixes/          # One-off fix scripts
   
   tools/
   ├── build.sh        # Unified build tool
   ├── fix.sh          # Unified fix tool
   ├── test.sh         # Unified test tool
   ├── monitor.sh      # Unified monitor tool
   └── toolbox.sh      # Interactive launcher
   
   archive/
   └── scripts/        # Old/unused scripts
   ```

2. **Update .gitignore:**
   - Ignore `archive/` directory
   - Keep scripts organized

---

## Recommendations

### Immediate Actions

1. **Update `.cursorrules`:**
   - Add toolbox-first policy
   - Add script organization rules
   - Add guidelines for script creation

2. **Create script inventory:**
   - List all 328 scripts
   - Categorize them
   - Mark which can be archived

3. **Enhance toolbox:**
   - Complete missing functions
   - Add better error messages
   - Improve integration

### Long-term Actions

1. **Migrate to toolbox:**
   - Gradually move scripts to toolbox
   - Update documentation
   - Train users (and AI) to use toolbox

2. **Maintain organization:**
   - Enforce script organization in cursor rules
   - Review periodically
   - Archive old scripts

---

## Benefits

### For Users
- ✅ Easier to find scripts (organized structure)
- ✅ Consistent interface (toolbox)
- ✅ Less confusion (clear organization)

### For AI (Cursor)
- ✅ Better context (organized structure)
- ✅ Clearer rules (enhanced .cursorrules)
- ✅ Toolbox-first approach (consistent usage)

### For Project
- ✅ Cleaner structure
- ✅ Better maintainability
- ✅ Easier onboarding

---

**Next Steps:**
1. Review and approve this plan
2. Start with Phase 1 (enhance cursor rules)
3. Create script inventory
4. Begin organization


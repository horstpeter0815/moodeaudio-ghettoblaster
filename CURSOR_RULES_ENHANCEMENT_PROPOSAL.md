# Cursor Rules Enhancement Proposal

## Current State
- Basic rules exist
- Toolbox mentioned but not emphasized
- Script organization not enforced

## Proposed Enhancements

### 1. Toolbox-First Policy
Add to `.cursorrules`:

```markdown
## Toolbox-First Policy - CRITICAL

**ALWAYS use toolbox tools when available. DO NOT create new scripts in root directory.**

### Toolbox Tools (Use These First):
- **Build/Deploy:** `tools/build.sh` (not root scripts)
- **Fixes:** `tools/fix.sh` (not root scripts)
- **Testing:** `tools/test.sh` (not root scripts)
- **Monitoring:** `tools/monitor.sh` (not root scripts)
- **Interactive:** `tools/toolbox.sh` (menu launcher)

### When to Use Toolbox:
- ✅ Building images → `tools/build.sh --build`
- ✅ Fixing issues → `tools/fix.sh --[component]`
- ✅ Testing systems → `tools/test.sh --[component]`
- ✅ Monitoring status → `tools/monitor.sh --[component]`
- ✅ Deploying → `tools/build.sh --deploy`

### When Toolbox Not Available:
- ⚠️ If toolbox function missing, add it to toolbox first
- ⚠️ Only create root script if absolutely necessary
- ⚠️ Then immediately move to appropriate directory:
  - Network scripts → `scripts/network/`
  - Build scripts → `tools/build/`
  - Fix scripts → `tools/fix/`
  - Test scripts → `tools/test/`
  - Deployment → `scripts/deployment/`

### Script Organization Rules:
1. **NEVER create scripts in root** (except toolbox launchers)
2. **ALWAYS check toolbox first** before creating new script
3. **ORGANIZE scripts** into appropriate directories
4. **ARCHIVE old scripts** to `archive/scripts/` with date prefix
```

### 2. Enhanced Script Guidelines
Add to `.cursorrules`:

```markdown
## Script Creation Guidelines

### Before Creating a Script:
1. **Check toolbox:** Does `tools/[category].sh` have this function?
2. **Check existing:** Is there already a script for this?
3. **Check organization:** Where should this script live?

### Script Naming:
- Toolbox scripts: `tools/[category].sh` (e.g., `tools/fix.sh`)
- Organized scripts: `scripts/[category]/ACTION_DESCRIPTION.sh`
- Archive scripts: `archive/scripts/YYYY-MM-DD_SCRIPT_NAME.sh`

### Script Categories:
- **Network:** `scripts/network/` or `tools/fix.sh --network`
- **Build:** `tools/build/` or `tools/build.sh`
- **Fix:** `tools/fix/` or `tools/fix.sh`
- **Test:** `tools/test/` or `tools/test.sh`
- **Deployment:** `scripts/deployment/` or `tools/build.sh --deploy`
- **Setup:** `scripts/setup/` or `tools/fix.sh --setup`
```

### 3. AI Assistant Guidelines
Add to `.cursorrules`:

```markdown
## AI Assistant Guidelines

### When User Asks for Script:
1. **First:** Check if toolbox has this function
2. **Second:** Check if script exists in organized directories
3. **Third:** Suggest using toolbox or organizing existing script
4. **Last:** Only create new script if absolutely necessary

### When Creating Scripts:
- **Always:** Use toolbox if function exists
- **Always:** Organize into appropriate directory
- **Always:** Follow naming conventions
- **Never:** Create in root unless it's a toolbox launcher
- **Never:** Duplicate toolbox functionality

### When Suggesting Commands:
- **Prefer:** `cd ~/moodeaudio-cursor && ./tools/toolbox.sh`
- **Prefer:** `cd ~/moodeaudio-cursor && ./tools/[category].sh --[function]`
- **Avoid:** Direct root script execution (unless no toolbox alternative)
```

---

## Implementation

These enhancements should be added to `.cursorrules` to:
1. Enforce toolbox-first approach
2. Guide script organization
3. Help AI make better decisions
4. Improve project maintainability


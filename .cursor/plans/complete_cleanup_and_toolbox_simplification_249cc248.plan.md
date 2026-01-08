---
name: Complete Cleanup and Toolbox Simplification
overview: Delete old build images (keep only Build 35), clean up project files (logs, old docs), and simplify/organize the 334+ scripts into a proper toolbox structure.
todos:
  - id: delete-old-images
    content: Delete Build 33 and Build 34 images, keep only Build 35
    status: completed
  - id: clean-intermediate-files
    content: Clean up old .info files (keep last 5), old .log files (keep last 5), old ZIP files
    status: completed
    dependencies:
      - delete-old-images
  - id: create-tools-structure
    content: "Create tools/ directory with subdirectories: build/, fix/, test/, monitor/, setup/, utils/"
    status: completed
  - id: consolidate-build-tools
    content: Consolidate 10+ build scripts into tools/build.sh unified tool
    status: completed
    dependencies:
      - create-tools-structure
  - id: consolidate-fix-tools
    content: Consolidate 40+ fix scripts into tools/fix.sh unified tool
    status: completed
    dependencies:
      - create-tools-structure
  - id: consolidate-test-tools
    content: Consolidate 25+ test scripts into tools/test.sh unified tool
    status: completed
    dependencies:
      - create-tools-structure
  - id: consolidate-monitor-tools
    content: Consolidate 30+ monitor scripts into tools/monitor.sh unified tool
    status: completed
    dependencies:
      - create-tools-structure
  - id: create-toolbox-launcher
    content: Create tools/toolbox.sh interactive menu launcher for all tools
    status: completed
    dependencies:
      - consolidate-build-tools
      - consolidate-fix-tools
      - consolidate-test-tools
      - consolidate-monitor-tools
  - id: archive-old-scripts
    content: Move old/duplicate scripts to archive/scripts/ directory
    status: completed
    dependencies:
      - create-toolbox-launcher
  - id: clean-root-directory
    content: Move old status files, logs, and docs to archive/ or appropriate subdirectories
    status: completed
    dependencies:
      - archive-old-scripts
  - id: create-toolbox-docs
    content: Create tools/README.md documenting the simplified toolbox structure
    status: completed
    dependencies:
      - create-toolbox-launcher
---

# Complete Clea

nup and Toolbox Simplification

## Phase 1: Image Cleanup

### Delete Old Build Images

- **Keep:** `moode-r1001-arm64-build-35-20251209_234258.img` (4.9 GB) - Latest build
- **Delete:** `moode-r1001-arm64-build-33-20251209_010729.img` (5.0 GB)
- **Delete:** `moode-r1001-arm64-build-34-20251209_181813.img` (4.9 GB)
- **Result:** Reduce `imgbuild/deploy/` from 16 GB to ~5 GB

### Clean Intermediate Files

- Keep last 5: `.info` files (build metadata)
- Keep last 5: `.log` files (build logs)
- Delete: All old `.info` files (many from Dec 7-8)
- Delete: All old `.log` files (builds 30-32)
- Delete: Old ZIP files if any

## Phase 2: Project Cleanup

### Root Directory Cleanup

- **Current:** 1,523 files in root (938 markdown, 334 scripts, 165 logs)
- **Organize:**
- Move old status files to `archive/status/`
- Move old logs to `archive/logs/`
- Move duplicate/obsolete scripts to `archive/scripts/`
- Keep only essential files in root

### Documentation Cleanup

- Consolidate duplicate status files
- Archive old planning documents
- Keep only current/essential documentation in root
- Move detailed docs to `documentation/` structure

## Phase 3: Toolbox Simplification

### Current Situation

- **334 shell scripts** in root directory
- Many duplicates (e.g., 40+ display fix scripts)
- No clear organization
- Hard to find the right tool

### Toolbox Structure

Create organized toolbox structure:

```javascript
tools/
├── build/           # Build management tools
│   ├── start-build.sh
│   ├── monitor-build.sh
│   └── burn-image.sh
├── fix/             # Fix tools (consolidated)
│   ├── fix-display.sh
│   ├── fix-audio.sh
│   └── fix-network.sh
├── test/            # Testing tools
│   ├── test-display.sh
│   ├── test-touchscreen.sh
│   └── test-system.sh
├── monitor/         # Monitoring tools
│   ├── check-pi-status.sh
│   └── monitor-boot.sh
├── setup/           # Setup tools
│   ├── setup-pi.sh
│   └── setup-debugger.sh
└── utils/           # Utility tools
    ├── cleanup.sh
    └── archive.sh
```



### Consolidation Strategy

1. **Identify duplicates:** Group similar scripts
2. **Choose best version:** Keep the most complete/working version
3. **Create unified tools:** Combine related functionality
4. **Archive old versions:** Move to `archive/scripts/`
5. **Create toolbox launcher:** `tools/toolbox.sh` - Interactive menu

### Key Tools to Create/Consolidate

- `tools/build.sh` - Unified build tool (replaces 10+ build scripts)
- `tools/fix.sh` - Unified fix tool (replaces 40+ fix scripts)
- `tools/test.sh` - Unified test tool (replaces 25+ test scripts)
- `tools/monitor.sh` - Unified monitor tool (replaces 30+ monitor scripts)
- `tools/toolbox.sh` - Main toolbox launcher with menu

## Implementation Steps

1. **Delete old images** (Builds 33, 34)
2. **Clean intermediate files** (.info, .log files)
3. **Create tools/ directory structure**
4. **Consolidate scripts** into unified tools
5. **Archive old/duplicate scripts**
6. **Create toolbox launcher** with interactive menu
7. **Update documentation** with new toolbox structure
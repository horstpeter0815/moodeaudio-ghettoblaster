# 🛠️ Toolbox - Unified Tools

**Date:** 2025-12-19  
**Purpose:** Simplified, unified interface for all build, fix, test, and monitor operations

---

## 📋 Overview

This toolbox consolidates **334+ shell scripts** into **4 unified tools** plus a launcher:

1. **`build.sh`** - Build and deployment management
2. **`fix.sh`** - System fixes and configuration
3. **`test.sh`** - Testing and validation
4. **`monitor.sh`** - Monitoring and status checking
5. **`toolbox.sh`** - Interactive menu launcher

---

## 🤖 AI / RAG Tool (`ai.sh`)

**Purpose:** Manage "GhettoAI" Knowledge Base via **RAG** (Open WebUI)

**Functions:**
- Check if KB needs refresh (`--status`)
- Upload files to KB (`--upload`)
- Generate RAG upload manifest (`--manifest`)
- Verify AI stack (`--verify`)

**Usage:**
```bash
# Check if refresh is needed
./tools/ai.sh --status

# Upload all files to KB (requires token)
OPENWEBUI_TOKEN='<jwt>' ./tools/ai.sh --upload

# Regenerate manifest
./tools/ai.sh --manifest

# Verify Ollama + Open WebUI setup
./tools/ai.sh --verify

# Check Open WebUI availability
./tools/ai.sh --openwebui
```

**Getting the Token:**
1. Open http://localhost:3000 in browser
2. DevTools → Console → `localStorage.token`
3. Copy the JWT (starts with `eyJ...`)

---

## 🚀 Quick Start

### **Interactive Mode (Recommended):**
```bash
./tools/toolbox.sh
```

### **Command Line Mode:**
```bash
# Build
./tools/build.sh --build
./tools/build.sh --monitor
./tools/build.sh --validate
./tools/build.sh --deploy
./tools/build.sh --cleanup
./tools/build.sh --status

# Fix
./tools/fix.sh --display
./tools/fix.sh --touchscreen
./tools/fix.sh --audio
./tools/fix.sh --network
./tools/fix.sh --ssh
./tools/fix.sh --amp100
./tools/fix.sh --all

# Test
./tools/test.sh --display
./tools/test.sh --touchscreen
./tools/test.sh --audio
./tools/test.sh --peppy
./tools/test.sh --all
./tools/test.sh --verify

# Monitor
./tools/monitor.sh --build
./tools/monitor.sh --pi
./tools/monitor.sh --serial
./tools/monitor.sh --all
./tools/monitor.sh --status
```

---

## 🔨 Build Tool (`build.sh`)

**Purpose:** Manage image builds and deployment

**Functions:**
- Build new images
- Monitor build progress
- Validate build images
- Deploy images to SD cards
- Cleanup old images
- Show build status

**Usage:**
```bash
./tools/build.sh [--build|--monitor|--validate|--deploy|--cleanup|--status]
```

**Examples:**
```bash
# Start a new build
./tools/build.sh --build

# Monitor current build
./tools/build.sh --monitor

# Validate latest image
./tools/build.sh --validate

# Deploy to SD card
./tools/build.sh --deploy

# Cleanup old images (keep only latest)
./tools/build.sh --cleanup

# Show build status
./tools/build.sh --status
```

---

## 🔧 Fix Tool (`fix.sh`)

**Purpose:** Fix system issues and configuration

**Functions:**
- Fix display issues
- Fix touchscreen
- Fix audio hardware
- Fix network configuration
- Fix SSH configuration
- Fix AMP100 hardware
- Fix all systems

**WISSENSBASIS Integration:**
- Automatically shows relevant solutions from `WISSENSBASIS/03_PROBLEME_LOESUNGEN.md` before applying fixes
- Helps identify known problems and tested solutions

**Usage:**
```bash
./tools/fix.sh [--display|--touchscreen|--audio|--network|--ssh|--amp100|--all]
```

**Examples:**
```bash
# Fix display rotation
./tools/fix.sh --display

# Fix touchscreen coordinates
./tools/fix.sh --touchscreen

# Fix audio hardware
./tools/fix.sh --audio

# Fix all systems
./tools/fix.sh --all
```

---

## 🧪 Test Tool (`test.sh`)

**Purpose:** Test and validate system components

**Functions:**
- Test display
- Test touchscreen
- Test audio system
- Test PeppyMeter
- Run complete test suite
- Verify all systems

**WISSENSBASIS Integration:**
- Automatically documents test results in `WISSENSBASIS/04_TESTS_ERGEBNISSE.md`
- Captures test output and results for future reference

**Usage:**
```bash
./tools/test.sh [--display|--touchscreen|--audio|--peppy|--all|--verify]
```

**Examples:**
```bash
# Test display resolution
./tools/test.sh --display

# Test touchscreen
./tools/test.sh --touchscreen

# Run complete test suite
./tools/test.sh --all

# Verify all systems
./tools/test.sh --verify
```

---

## 📡 Monitor Tool (`monitor.sh`)

**Purpose:** Monitor system status and processes

**Functions:**
- Monitor build progress
- Monitor Pi systems
- Monitor serial console
- Monitor all systems
- Check system status

**WISSENSBASIS Integration:**
- Shows hardware configuration from `WISSENSBASIS/02_HARDWARE.md` in status checks
- Displays known system configurations and IP addresses

**Usage:**
```bash
./tools/monitor.sh [--build|--pi|--serial|--all|--status]
```

**Examples:**
```bash
# Monitor build progress
./tools/monitor.sh --build

# Monitor Pi systems
./tools/monitor.sh --pi

# Check system status
./tools/monitor.sh --status
```

---

## 🎯 Toolbox Launcher (`toolbox.sh`)

**Purpose:** Interactive menu for all tools

**Features:**
- Main menu with all tool categories
- Sub-menus for each tool category
- System status display
- Cleanup tools
- Documentation access

**Usage:**
```bash
./tools/toolbox.sh
```

**Menu Structure:**
```
Main Menu
├── Build Tools
│   ├── Build new image
│   ├── Monitor build progress
│   ├── Validate build image
│   ├── Deploy image to SD card
│   ├── Cleanup old images
│   └── Show build status
├── Fix Tools
│   ├── Fix display issues
│   ├── Fix touchscreen
│   ├── Fix audio hardware
│   ├── Fix network configuration
│   ├── Fix SSH configuration
│   ├── Fix AMP100 hardware
│   └── Fix all systems
├── Test Tools
│   ├── Test display
│   ├── Test touchscreen
│   ├── Test audio system
│   ├── Test PeppyMeter
│   ├── Run complete test suite
│   └── Verify all systems
├── Monitor Tools
│   ├── Monitor build progress
│   ├── Monitor Pi systems
│   ├── Monitor serial console
│   ├── Monitor all systems
│   └── Check system status
├── System Status
├── Cleanup Tools
└── Documentation
```

---

## 📁 Directory Structure

```
tools/
├── build.sh          # Build and deployment tool
├── fix.sh            # Fix and configuration tool
├── test.sh           # Test and validation tool
├── monitor.sh        # Monitor and status tool
├── toolbox.sh        # Interactive launcher
├── README.md         # This file
├── build/            # Build-related scripts (future)
├── fix/              # Fix-related scripts (future)
├── test/             # Test-related scripts (future)
├── monitor/          # Monitor-related scripts (future)
├── setup/            # Setup-related scripts (future)
└── utils/            # Utility scripts
    └── wissensbasis.sh  # WISSENSBASIS helper (search, update, document)
```

---

## 🔄 Migration from Old Scripts

**Old way:**
```bash
./START_BUILD_NOW.sh
./BUILD_MONITOR_REAL.sh
./fix_everything.sh
./verify_everything.sh
./CHECK_PI_STATUS.sh
```

**New way:**
```bash
./tools/build.sh --build
./tools/build.sh --monitor
./tools/fix.sh --all
./tools/test.sh --verify
./tools/monitor.sh --status
```

**Or use the toolbox:**
```bash
./tools/toolbox.sh
# Then select from menu
```

---

## 📝 Notes

- All tools support both **interactive mode** (no arguments) and **command line mode** (with arguments)
- Old scripts are still available in the root directory
- Tools automatically find and use the best available underlying script
- All tools include error handling and user-friendly output
- Tools are color-coded for better readability

---

## 🆘 Troubleshooting

**Tool not found:**
```bash
chmod +x tools/*.sh
```

**Underlying script not found:**
- Tools will show an error message
- Check that the required scripts exist in the project root
- Some tools have fallback methods

**Permission denied:**
```bash
chmod +x tools/*.sh
```

---

## 📚 WISSENSBASIS Integration

The toolbox is fully integrated with the project's knowledge base (`WISSENSBASIS/`):

### **WISSENSBASIS Helper (`utils/wissensbasis.sh`)**

**Purpose:** Search, update, and document in the knowledge base

**Usage:**
```bash
# Search for problems/solutions
./tools/utils/wissensbasis.sh search <keyword>

# Show relevant solutions by type
./tools/utils/wissensbasis.sh solution <display|touchscreen|audio|network|boot>

# Add test result
./tools/utils/wissensbasis.sh add-test "Test Name" "SUCCESS|FAILED" "details"

# Add problem/solution
./tools/utils/wissensbasis.sh add-problem "Problem" "Solution" "Status"
```

**Examples:**
```bash
# Find solutions for display issues
./tools/utils/wissensbasis.sh solution display

# Document a test result
./tools/utils/wissensbasis.sh add-test "Display Rotation Test" "SUCCESS" "display_rotate=3 works"

# Add a new problem/solution
./tools/utils/wissensbasis.sh add-problem "New Issue" "Solution steps" "Gelöst"
```

### **Automatic Integration:**

- **`fix.sh`**: Shows relevant solutions before applying fixes
- **`test.sh`**: Automatically documents test results
- **`monitor.sh`**: Displays hardware info from WISSENSBASIS

### **WISSENSBASIS Structure:**

```
WISSENSBASIS/
├── 00_INDEX.md                    # Index and navigation
├── 01_PROJEKT_UEBERSICHT.md       # Project overview
├── 02_HARDWARE.md                 # Hardware documentation
├── 03_PROBLEME_LOESUNGEN.md       # Problems & solutions (auto-updated)
├── 04_TESTS_ERGEBNISSE.md         # Test results (auto-updated)
├── 05_ANSATZE_VERGLEICH.md        # Approach comparison
├── 06_BEST_PRACTICES.md           # Best practices
├── 07_IMPLEMENTIERUNGEN.md        # Implementation guides
└── 08_TROUBLESHOOTING.md          # Troubleshooting guide
```

---

## 📚 Related Documentation

- `TOOLS_INVENTORY.md` - Complete inventory of all 334+ scripts
- `WISSENSBASIS/00_INDEX.md` - Knowledge base index
- `COMPLETE_BOOT_PROCESS_ANALYSIS.md` - Boot process analysis
- `CUSTOM_BUILD_NEXT_STEPS.md` - Build next steps

---

**Last Updated:** 2025-12-19  
**WISSENSBASIS Integration:** ✅ Complete


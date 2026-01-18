# Cursor Project Setup Guide

## Current Project Issues

Your project has:
- ✅ `.cursorignore` file (good!)
- ❌ No `.cursorrules` file
- ❌ No clear project structure
- ❌ Too many files in root directory (800+ files)
- ❌ No clear documentation structure

## Cursor Best Practices

### 1. Create `.cursorrules` File

This file tells Cursor how to work with your project:

```markdown
# moOde Audio Custom Build Project

## Project Structure
- `moode-source/` - Source files for moOde modifications
- `scripts/` - All shell scripts
- `docs/` - Documentation
- `config/` - Configuration files
- `archive/` - Old/archived files

## Coding Standards
- Use bash for shell scripts
- Use Python 3 for automation
- Follow moOde coding conventions
- Document all changes

## Key Directories
- `/moode-source/lib/systemd/system/` - Systemd services
- `/moode-source/boot/firmware/` - Boot configuration
- `/moode-source/www/` - Web interface files

## Important Notes
- Always test on SD card before deploying
- Backup working configurations
- Use sudo for system file modifications
- SSH user: andre (UID 1000)
- Default password: 0815
```

### 2. Improve `.cursorignore`

Add more patterns to ignore:

```
# Cursor ignore patterns
*.log
*.tmp
*.bak
archive/
temp/
build-outputs/
*.img
*.zip
.DS_Store
node_modules/
.git/
```

### 3. Project Structure

**Recommended structure:**
```
moodeaudio-cursor/
├── .cursorrules          # Cursor project rules
├── .cursorignore         # Files to ignore
├── README.md             # Main project documentation
├── docs/                 # All documentation
│   ├── setup/
│   ├── troubleshooting/
│   └── guides/
├── scripts/              # All scripts organized
│   ├── setup/
│   ├── deployment/
│   └── maintenance/
├── config/               # Configuration files
│   ├── boot/
│   ├── systemd/
│   └── network/
├── moode-source/         # moOde source modifications
├── test/                 # Test files
└── archive/              # Old files (ignored)
```

### 4. Create `README.md`

Main project documentation:

```markdown
# moOde Audio Custom Build

## Overview
Custom moOde Audio build for Raspberry Pi with:
- Custom display configuration
- SSH access
- Network fixes
- Room Correction Wizard

## Quick Start
1. Flash moOde image to SD card
2. Run setup scripts
3. Boot Pi

## Documentation
See `docs/` directory

## Scripts
See `scripts/` directory
```

## Action Plan

1. **Create `.cursorrules`** - Define project rules
2. **Reorganize files** - Move to proper directories
3. **Create README.md** - Main documentation
4. **Update `.cursorignore`** - Better ignore patterns
5. **Document structure** - Clear organization

---

**Should I create these files and reorganize the project?**


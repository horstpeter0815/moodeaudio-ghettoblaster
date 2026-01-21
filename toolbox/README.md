# moOde Ghettoblaster Toolbox
**Clean, maintainable toolbox aligned with DEVELOPMENT_WORKFLOW.md**

---

## Overview

This toolbox contains **15 essential tools** for system management, deployment, and development.

All redundant and experimental scripts have been cleaned up:
- **209 scripts** → **15 essential tools** (93% reduction)
- Clear organization by purpose
- Production-ready scripts only
- Aligned with sustainable development workflow

---

## Directory Structure

```
toolbox/
├── system/          # System verification and maintenance
├── deploy/          # Deployment and restoration
├── dev/             # Development and debugging
└── pi-scripts/      # Scripts that run on the Pi
```

---

## System Tools (`system/`)

### check-system-status.sh
**Purpose:** Quick system health check  
**Usage:** `./toolbox/system/check-system-status.sh [pi-ip] [user]`  
**What it does:**
- Display status (localdisplay service)
- Audio device detection
- Database configuration
- Recent errors
- System uptime and disk usage

**Example:**
```bash
./toolbox/system/check-system-status.sh 192.168.2.3 andre
```

### backup-working-config.sh
**Purpose:** Backup current working configuration from Pi  
**Usage:** `./toolbox/system/backup-working-config.sh [pi-ip] [user]`  
**What it does:**
- Backs up cmdline.txt, config.txt
- Backs up .xinitrc and xinitrc.default
- Backs up ALSA and MPD configs
- Dumps moOde database
- Creates restore manifest

**Saves to:** `backups/working-YYYY-MM-DD-HHMM/`

**After backup, commit to GitHub:**
```bash
git add backups/
git commit -m "Working configuration backup $(date +%Y-%m-%d)"
git tag v1.0-working-$(date +%Y%m%d)
git push --tags
```

### verify-architecture.sh
**Purpose:** Verify system matches documented architecture  
**Usage:** `./toolbox/system/verify-architecture.sh [pi-ip] [user]`  
**What it does:**
- Verifies cmdline.txt (framebuffer config)
- Verifies config.txt (HDMI timings, arm_boost, etc.)
- Verifies .xinitrc (xset -dpms fix)
- Verifies audio chain (HiFiBerry detection)
- Verifies database config
- Verifies system services

**Reference:** `WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md`

**Exit code:** 0 if all checks pass, 1 if any fail

---

## Deployment Tools (`deploy/`)

### burn-sd-card.sh
**Purpose:** Burn moOde image to SD card (macOS)  
**Usage:** `./toolbox/deploy/burn-sd-card.sh <image> <device>`  
**What it does:**
- Unmounts device
- Burns image (supports .img and .img.xz)
- Ejects when complete

**Example:**
```bash
# List disks
diskutil list

# Burn image
./toolbox/deploy/burn-sd-card.sh moode-r900.img.xz /dev/disk4
```

### restore-from-github.sh
**Purpose:** Restore working configuration from GitHub backup  
**Usage:** `./toolbox/deploy/restore-from-github.sh <commit> <backup-dir> [pi-ip] [user]`  
**What it does:**
- Extracts configs from GitHub commit
- Deploys to running Pi
- Preserves permissions

**Example:**
```bash
# Find working configs
git log --grep="working" --oneline
git tag -l "*working*"

# Restore
./toolbox/deploy/restore-from-github.sh 84aa8c2 backups/v1.0-2026-01-08
```

---

## Development Tools (`dev/`)

### monitor-pi-boot.sh
**Purpose:** Monitor Raspberry Pi boot process in real-time  
**Usage:** `./toolbox/dev/monitor-pi-boot.sh [pi-ip] [user]`  
**What it does:**
- Waits for Pi to become reachable
- Shows boot messages
- Shows failed services
- Shows X server status

**Use when:**
- After flashing SD card
- After reboot
- Debugging boot issues

### quick-ssh.sh
**Purpose:** Fast SSH access with common commands  
**Usage:** `./toolbox/dev/quick-ssh.sh [pi-ip] [user] [command]`  
**What it does:**
- Opens SSH session (no command)
- Executes quick commands

**Commands:**
- `reboot` - Reboot and wait
- `logs` - Show recent logs
- `display` - Display service status
- `audio` - Audio device status
- `db` - Database query
- Custom command

**Examples:**
```bash
# Interactive SSH
./toolbox/dev/quick-ssh.sh 192.168.2.3 andre

# Quick reboot
./toolbox/dev/quick-ssh.sh 192.168.2.3 andre reboot

# Check logs
./toolbox/dev/quick-ssh.sh 192.168.2.3 andre logs
```

### analyze-logs.sh
**Purpose:** Parse and analyze system logs for common issues  
**Usage:** `./toolbox/dev/analyze-logs.sh [pi-ip] [user]`  
**What it does:**
- Shows recent errors
- Analyzes display issues
- Checks X server errors
- Checks audio issues
- Lists failed services
- Shows boot time analysis

---

## Pi Scripts (`pi-scripts/`)

These scripts run **on the Pi** (not on your Mac). They are production-ready scripts from the working v1.0 system.

### amp100-automute.sh
**Purpose:** HiFiBerry AMP100 automute control  
**Deployed to:** `/usr/local/bin/` on Pi

### audio-optimize.sh
**Purpose:** Audio chain optimization  
**Deployed to:** `/usr/local/bin/` on Pi

### boot-debug-logger.sh
**Purpose:** Boot process debug logging  
**Deployed to:** `/usr/local/bin/` on Pi

### first-boot-setup.sh
**Purpose:** First boot initialization  
**Deployed to:** `/usr/local/bin/` on Pi

### peppymeter-wrapper.sh
**Purpose:** PeppyMeter launch wrapper  
**Deployed to:** `/usr/local/bin/` on Pi

### simple-boot-logger.sh
**Purpose:** Simple boot logging  
**Deployed to:** `/usr/local/bin/` on Pi

### start-chromium-clean.sh
**Purpose:** Chromium launcher (clean start)  
**Deployed to:** `/usr/local/bin/` on Pi

### xserver-ready.sh
**Purpose:** X server readiness check  
**Deployed to:** `/usr/local/bin/` on Pi

---

## Typical Workflows

### 1. Check System Health
```bash
./toolbox/system/check-system-status.sh
```

### 2. Verify Architecture
```bash
./toolbox/system/verify-architecture.sh
```

### 3. Backup Before Changes
```bash
# Backup
./toolbox/system/backup-working-config.sh

# Commit to GitHub
git add backups/
git commit -m "Backup before making changes"
git push
```

### 4. Deploy New Image
```bash
# Burn SD card
./toolbox/deploy/burn-sd-card.sh moode-r900.img.xz /dev/disk4

# Monitor boot
./toolbox/dev/monitor-pi-boot.sh

# Check status
./toolbox/system/check-system-status.sh

# Verify
./toolbox/system/verify-architecture.sh
```

### 5. Restore from GitHub
```bash
# Find working config
git log --grep="working" --oneline

# Restore
./toolbox/deploy/restore-from-github.sh 84aa8c2 backups/v1.0-2026-01-08

# Reboot
./toolbox/dev/quick-ssh.sh 192.168.2.3 andre reboot

# Verify
./toolbox/system/verify-architecture.sh
```

### 6. Debug Issues
```bash
# Analyze logs
./toolbox/dev/analyze-logs.sh

# Monitor boot
./toolbox/dev/monitor-pi-boot.sh

# Check specific service
./toolbox/dev/quick-ssh.sh 192.168.2.3 andre display
```

---

## Integration with Development Workflow

This toolbox implements the "Custom Scripts for Common Tasks" section from:  
**`WISSENSBASIS/DEVELOPMENT_WORKFLOW.md`**

### Quality Gates Integration

**Before Committing Code:**
- ✅ Run: `./toolbox/system/verify-architecture.sh`
- ✅ Run: `./toolbox/system/check-system-status.sh`

**Before Claiming "Fixed":**
- ✅ Run: `./toolbox/system/verify-architecture.sh`
- ✅ Backup: `./toolbox/system/backup-working-config.sh`
- ✅ Commit backup to GitHub

**Before Session Complete:**
- ✅ Backup working config
- ✅ Commit to GitHub
- ✅ Tag: `git tag v1.0-working-$(date +%Y%m%d)`

---

## Maintenance

### Adding New Tools
1. Create script in appropriate directory (`system/`, `deploy/`, `dev/`)
2. Add header comment explaining purpose
3. Make executable: `chmod +x toolbox/<dir>/<script>.sh`
4. Document in this README
5. Test thoroughly before committing

### Tool Naming Convention
- Use lowercase with hyphens: `check-system-status.sh`
- Be descriptive: what the tool does
- Avoid version numbers in names

### What NOT to Add
- ❌ One-off debug scripts
- ❌ Experimental "fix" attempts
- ❌ Duplicate functionality
- ❌ Scripts without clear purpose

### Cleanup Policy
- Keep toolbox lean (<20 scripts)
- Archive development scripts to `.archive/`
- Delete redundant/obsolete scripts
- Review toolbox quarterly

---

## Cleanup Results

### Before
- **209 scripts** across `scripts/` and `tools/`
- Chaotic organization
- Many redundant "fix" attempts
- Hard to find the right tool

### After
- **15 essential tools** in `toolbox/`
- Clear organization by purpose
- Production-ready scripts only
- Easy to find what you need

### Archived
- ~100-120 development/debug scripts → `.archive/scripts-development/`
- Preserved for historical reference
- Not in active toolbox

### Deleted
- ~60-80 redundant/obsolete scripts
- Multiple burn script variants
- Hotel-specific network scripts
- One-off test scripts
- Experimental wizard features

---

## Documentation References

- **Workflow:** `WISSENSBASIS/DEVELOPMENT_WORKFLOW.md`
- **Architecture:** `WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md`
- **Cleanup Analysis:** `TOOLBOX_CLEANUP_ANALYSIS.md`

---

**Total Tools:** 15 essential scripts  
**Organization:** 4 categories (system/deploy/dev/pi-scripts)  
**Status:** Production-ready, aligned with workflow  
**Maintenance:** Quarterly review

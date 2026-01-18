---
name: Proper moOde Boot Fix with Wizard Integration
overview: Fix D-Bus circular dependency properly, keep moOde architecture intact, and integrate Room Correction Wizard into build process
todos: []
---

# Proper moOde Boot Fix with Wizard Integration

## Part 1: Boot Fixes (Proper Systemd Method)

### Research Findings

From moOde forum and GitHub research:
- moOde 10.0.3 uses `multi-user.target` as default (standard for headless systems)
- Services like `mpd.service`, `nginx`, `localui.service` are configured with `WantedBy=multi-user.target`
- `worker.php` runs from `/etc/rc.local` which depends on `network.target`
- Changing to `basic.target` breaks moOde's architecture

### The Real Problem

The D-Bus circular dependency is a real systemd issue:
- `dbus.service` implicitly waits for `basic.target`
- `basic.target` depends on `sockets.target`
- `sockets.target` activates `dbus.socket`
- `dbus.socket` activates `dbus.service`
- Cycle: dbus.service → basic.target → sockets.target → dbus.socket → dbus.service

### Proper Solution

1. **Fix D-Bus Circular Dependency**
   - Create `/etc/systemd/system/dbus.service.d/override.conf`
   - Use `DefaultDependencies=no` to prevent implicit dependencies
   - Set explicit `Before=basic.target` to break cycle
   - Keep `After=dbus.socket sysinit.target` (explicit dependencies only)

2. **Keep moOde's Architecture Intact**
   - DO NOT change `default.target` to `basic.target`
   - Keep `multi-user.target` as default
   - DO NOT create workaround services
   - Let moOde's services start normally

3. **Optimize Boot**
   - Disable services we don't need (audio, avahi) via `systemctl disable`
   - Mask services: `systemctl mask sound.target alsa-*.service`
   - Keep SSH/nginx enabled normally

### Implementation

**Files to Create:**
- `custom-components/services/dbus.service.d/override.conf`
- `custom-components/services/basic.target.d/override.conf`

**Files to Modify:**
- `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh` - Apply fixes, mask services

---

## Part 1.5: Fix Dependency and Path Issues

### Problems Identified

**Massive "No such file or directory" errors caused by:**

1. **Missing Environment Variable Checks**
   - `MOODE_SOURCE` used but never validated
   - `CUSTOM_COMPONENTS` used but never validated
   - `ROOTFS_DIR` checked, but others are not
   - Scripts fail silently or with cryptic errors

2. **Missing File/Directory Existence Checks**
   - Scripts use `${MOODE_SOURCE}/...` without checking if file exists
   - Scripts use `${CUSTOM_COMPONENTS}/...` without checking
   - Operations assume paths exist, causing cascading failures

3. **Relative Path Issues**
   - Some operations use relative paths without context
   - Working directory assumptions cause failures
   - Paths not verified before use

### Solution: Comprehensive Path and Dependency Validation

**Modify:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-deploy.sh`

Add at the beginning (after line 6):

```bash
# ========================================================================
# ENVIRONMENT VARIABLE VALIDATION
# ========================================================================
echo "=== VALIDATING ENVIRONMENT VARIABLES ==="

# Check ROOTFS_DIR (already checked, but make it explicit)
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ ERROR: ROOTFS_DIR not set"
    echo "   This script requires ROOTFS_DIR to be set by pi-gen"
    exit 1
fi
ROOTFS="${ROOTFS_DIR}"
echo "✅ ROOTFS_DIR: $ROOTFS"

# Check MOODE_SOURCE
if [ -z "${MOODE_SOURCE}" ]; then
    echo "❌ ERROR: MOODE_SOURCE not set"
    echo "   Expected: /workspace/moode-source (from Docker volume mount)"
    echo "   Please check docker-compose.build.yml volume mounts"
    exit 1
fi
if [ ! -d "${MOODE_SOURCE}" ]; then
    echo "❌ ERROR: MOODE_SOURCE directory does not exist: ${MOODE_SOURCE}"
    exit 1
fi
echo "✅ MOODE_SOURCE: ${MOODE_SOURCE}"

# Check CUSTOM_COMPONENTS (optional, but validate if used)
if [ -z "${CUSTOM_COMPONENTS}" ]; then
    # Try to infer from workspace structure
    if [ -d "/workspace/custom-components" ]; then
        CUSTOM_COMPONENTS="/workspace/custom-components"
        echo "⚠️  CUSTOM_COMPONENTS not set, using inferred: $CUSTOM_COMPONENTS"
    else
        echo "⚠️  WARNING: CUSTOM_COMPONENTS not set and not found at /workspace/custom-components"
        echo "   Some wizard files may not be copied"
        CUSTOM_COMPONENTS=""
    fi
else
    if [ ! -d "${CUSTOM_COMPONENTS}" ]; then
        echo "⚠️  WARNING: CUSTOM_COMPONENTS directory does not exist: ${CUSTOM_COMPONENTS}"
        CUSTOM_COMPONENTS=""
    else
        echo "✅ CUSTOM_COMPONENTS: ${CUSTOM_COMPONENTS}"
    fi
fi

# Verify ROOTFS is writable
if [ ! -w "${ROOTFS}" ]; then
    echo "❌ ERROR: ROOTFS is not writable: ${ROOTFS}"
    exit 1
fi
echo "✅ ROOTFS is writable"

echo ""
```

**Update all file operations to check existence first:**

Replace lines 19-39 with:

```bash
# ========================================================================
# COPY FILES WITH VALIDATION
# ========================================================================

# Copy config.txt.overwrite
CONFIG_SOURCE="${MOODE_SOURCE}/boot/firmware/config.txt.overwrite"
if [ -f "${CONFIG_SOURCE}" ]; then
    CONFIG_DEST="${ROOTFS}/boot/firmware"
    mkdir -p "${CONFIG_DEST}" || {
        echo "❌ ERROR: Cannot create directory: ${CONFIG_DEST}"
        exit 1
    }
    cp "${CONFIG_SOURCE}" "${CONFIG_DEST}/config.txt" || {
        echo "❌ ERROR: Failed to copy config.txt"
        exit 1
    }
    echo "✅ config.txt.overwrite copied and REPLACED config.txt"
else
    echo "⚠️  WARNING: ${CONFIG_SOURCE} not found, skipping config.txt copy"
fi

# Copy services with validation
SERVICES_SOURCE="${MOODE_SOURCE}/lib/systemd/system"
if [ -d "${SERVICES_SOURCE}" ]; then
    SERVICES_DEST="${ROOTFS}/lib/systemd/system"
    mkdir -p "${SERVICES_DEST}" || {
        echo "❌ ERROR: Cannot create directory: ${SERVICES_DEST}"
        exit 1
    }
    if [ "$(ls -A ${SERVICES_SOURCE} 2>/dev/null)" ]; then
        cp -r "${SERVICES_SOURCE}/"* "${SERVICES_DEST}/" 2>/dev/null || {
            echo "⚠️  WARNING: Some services failed to copy (non-critical)"
        }
        echo "✅ Services copied from ${SERVICES_SOURCE}"
    else
        echo "⚠️  WARNING: ${SERVICES_SOURCE} is empty"
    fi
else
    echo "⚠️  WARNING: ${SERVICES_SOURCE} not found, skipping services copy"
fi

# Copy scripts with validation
SCRIPTS_SOURCE="${MOODE_SOURCE}/usr/local/bin"
if [ -d "${SCRIPTS_SOURCE}" ]; then
    SCRIPTS_DEST="${ROOTFS}/usr/local/bin"
    mkdir -p "${SCRIPTS_DEST}" || {
        echo "❌ ERROR: Cannot create directory: ${SCRIPTS_DEST}"
        exit 1
    }
    if [ "$(ls -A ${SCRIPTS_SOURCE} 2>/dev/null)" ]; then
        cp -r "${SCRIPTS_SOURCE}/"* "${SCRIPTS_DEST}/" 2>/dev/null || {
            echo "⚠️  WARNING: Some scripts failed to copy (non-critical)"
        }
        chmod +x "${SCRIPTS_DEST}/"*.sh 2>/dev/null || true
        echo "✅ Scripts copied from ${SCRIPTS_SOURCE}"
    else
        echo "⚠️  WARNING: ${SCRIPTS_SOURCE} is empty"
    fi
else
    echo "⚠️  WARNING: ${SCRIPTS_SOURCE} not found, skipping scripts copy"
fi
```

**For Wizard Integration, add validation:**

```bash
# ========================================================================
# ROOM CORRECTION WIZARD INTEGRATION (WITH VALIDATION)
# ========================================================================
echo ""
echo "=== COPYING ROOM CORRECTION WIZARD FILES ==="

# PHP backend
WIZARD_PHP_SOURCE="${MOODE_SOURCE}/www/command/room-correction-wizard.php"
if [ -f "${WIZARD_PHP_SOURCE}" ]; then
    WIZARD_PHP_DEST="${ROOTFS}/var/www/html/command"
    mkdir -p "${WIZARD_PHP_DEST}" || {
        echo "❌ ERROR: Cannot create directory: ${WIZARD_PHP_DEST}"
        exit 1
    }
    cp "${WIZARD_PHP_SOURCE}" "${WIZARD_PHP_DEST}/" || {
        echo "❌ ERROR: Failed to copy room-correction-wizard.php"
        exit 1
    }
    chmod 644 "${WIZARD_PHP_DEST}/room-correction-wizard.php"
    echo "✅ room-correction-wizard.php copied"
else
    echo "⚠️  WARNING: ${WIZARD_PHP_SOURCE} not found, skipping PHP backend"
fi

# Python scripts from moode-source
CAMILLADSP_EQ_SOURCE="${MOODE_SOURCE}/usr/local/bin/generate-camilladsp-eq.py"
if [ -f "${CAMILLADSP_EQ_SOURCE}" ]; then
    PYTHON_DEST="${ROOTFS}/usr/local/bin"
    mkdir -p "${PYTHON_DEST}" || {
        echo "❌ ERROR: Cannot create directory: ${PYTHON_DEST}"
        exit 1
    }
    cp "${CAMILLADSP_EQ_SOURCE}" "${PYTHON_DEST}/" || {
        echo "❌ ERROR: Failed to copy generate-camilladsp-eq.py"
        exit 1
    }
    chmod +x "${PYTHON_DEST}/generate-camilladsp-eq.py"
    echo "✅ generate-camilladsp-eq.py copied"
else
    echo "⚠️  WARNING: ${CAMILLADSP_EQ_SOURCE} not found, skipping generate-camilladsp-eq.py"
fi

# Python scripts from custom-components (if available)
if [ -n "${CUSTOM_COMPONENTS}" ] && [ -d "${CUSTOM_COMPONENTS}/scripts" ]; then
    ANALYZE_SOURCE="${CUSTOM_COMPONENTS}/scripts/analyze-measurement.py"
    if [ -f "${ANALYZE_SOURCE}" ]; then
        PYTHON_DEST="${ROOTFS}/usr/local/bin"
        mkdir -p "${PYTHON_DEST}" || {
            echo "❌ ERROR: Cannot create directory: ${PYTHON_DEST}"
            exit 1
        }
        cp "${ANALYZE_SOURCE}" "${PYTHON_DEST}/" || {
            echo "❌ ERROR: Failed to copy analyze-measurement.py"
            exit 1
        }
        chmod +x "${PYTHON_DEST}/analyze-measurement.py"
        echo "✅ analyze-measurement.py copied"
    else
        echo "⚠️  WARNING: ${ANALYZE_SOURCE} not found"
    fi
    
    FIR_FILTER_SOURCE="${CUSTOM_COMPONENTS}/scripts/generate-fir-filter.py"
    if [ -f "${FIR_FILTER_SOURCE}" ]; then
        PYTHON_DEST="${ROOTFS}/usr/local/bin"
        mkdir -p "${PYTHON_DEST}" || {
            echo "❌ ERROR: Cannot create directory: ${PYTHON_DEST}"
            exit 1
        }
        cp "${FIR_FILTER_SOURCE}" "${PYTHON_DEST}/" || {
            echo "❌ ERROR: Failed to copy generate-fir-filter.py"
            exit 1
        }
        chmod +x "${PYTHON_DEST}/generate-fir-filter.py"
        echo "✅ generate-fir-filter.py copied"
    else
        echo "⚠️  WARNING: ${FIR_FILTER_SOURCE} not found"
    fi
else
    echo "⚠️  WARNING: CUSTOM_COMPONENTS not available, skipping custom Python scripts"
fi

# HTML template
if [ -n "${CUSTOM_COMPONENTS}" ]; then
    WIZARD_HTML_SOURCE="${CUSTOM_COMPONENTS}/templates/room-correction-wizard-modal.html"
    if [ -f "${WIZARD_HTML_SOURCE}" ]; then
        WIZARD_HTML_DEST="${ROOTFS}/var/www/html/templates"
        mkdir -p "${WIZARD_HTML_DEST}" || {
            echo "❌ ERROR: Cannot create directory: ${WIZARD_HTML_DEST}"
            exit 1
        }
        cp "${WIZARD_HTML_SOURCE}" "${WIZARD_HTML_DEST}/" || {
            echo "❌ ERROR: Failed to copy room-correction-wizard-modal.html"
            exit 1
        }
        chmod 644 "${WIZARD_HTML_DEST}/room-correction-wizard-modal.html"
        echo "✅ room-correction-wizard-modal.html copied"
    else
        echo "⚠️  WARNING: ${WIZARD_HTML_SOURCE} not found"
    fi
fi
```

**Also update run-chroot.sh to validate paths:**

Add at the beginning (after line 18):

```bash
# ========================================================================
# PATH VALIDATION
# ========================================================================
echo "=== VALIDATING PATHS ==="

# Verify workspace is mounted
if [ ! -d "/workspace" ]; then
    echo "❌ ERROR: /workspace directory not found"
    echo "   This script runs in chroot, /workspace should be mounted from host"
    exit 1
fi
echo "✅ /workspace directory exists"

# Verify critical directories exist
for dir in "/workspace/moode-source" "/workspace/custom-components" "/workspace/v1.0-config-export"; do
    if [ -d "$dir" ]; then
        echo "✅ Found: $dir"
    else
        echo "⚠️  WARNING: $dir not found (may be optional)"
    fi
done

echo ""
```

**Update all file operations in run-chroot.sh to check existence:**

Example pattern to follow:
```bash
# OLD (causes errors):
if [ -f "/usr/local/bin/script.sh" ]; then
    chmod +x /usr/local/bin/script.sh
fi

# NEW (validates first):
SCRIPT_PATH="/usr/local/bin/script.sh"
if [ -f "${SCRIPT_PATH}" ]; then
    if [ -r "${SCRIPT_PATH}" ]; then
        chmod +x "${SCRIPT_PATH}" || {
            echo "⚠️  WARNING: Failed to chmod ${SCRIPT_PATH}"
        }
        echo "✅ ${SCRIPT_PATH} made executable"
    else
        echo "⚠️  WARNING: ${SCRIPT_PATH} exists but is not readable"
    fi
else
    echo "⚠️  WARNING: ${SCRIPT_PATH} not found (may be optional)"
fi
```

### Key Principles

1. **Always validate environment variables** before use
2. **Always check file/directory existence** before operations
3. **Use absolute paths** or validate relative paths
4. **Handle missing files gracefully** (warn, don't fail unless critical)
5. **Verify write permissions** before creating directories
6. **Check operation success** after each critical step

## Part 2: Room Correction Wizard Integration

### Wizard Components

**Frontend:**
- `custom-components/templates/room-correction-wizard-modal.html` - UI modal
- JavaScript functions for wizard workflow

**Backend:**
- `moode-source/www/command/room-correction-wizard.php` - PHP API handler
- Commands: upload_measurement, analyze_measurement, generate_filter, apply_filter, generate_peq, apply_peq

**Python Scripts:**
- `custom-components/scripts/analyze-measurement.py` - Analyzes WAV files, extracts frequency response
- `custom-components/scripts/generate-fir-filter.py` - Generates FIR convolution filters
- `moode-source/usr/local/bin/generate-camilladsp-eq.py` - Generates CamillaDSP PEQ/Biquad configs

### Integration Method: Bake into Build

**Modify:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-deploy.sh`

Add wizard file copying section after line 40:

```bash
# Copy Room Correction Wizard files
echo "Copying Room Correction Wizard files..."

# PHP backend
if [ -f "${MOODE_SOURCE}/www/command/room-correction-wizard.php" ]; then
    mkdir -p "${ROOTFS}/var/www/html/command"
    cp "${MOODE_SOURCE}/www/command/room-correction-wizard.php" "${ROOTFS}/var/www/html/command/"
    chmod 644 "${ROOTFS}/var/www/html/command/room-correction-wizard.php"
    echo "✅ room-correction-wizard.php copied"
fi

# Python scripts
if [ -f "${MOODE_SOURCE}/usr/local/bin/generate-camilladsp-eq.py" ]; then
    mkdir -p "${ROOTFS}/usr/local/bin"
    cp "${MOODE_SOURCE}/usr/local/bin/generate-camilladsp-eq.py" "${ROOTFS}/usr/local/bin/"
    chmod +x "${ROOTFS}/usr/local/bin/generate-camilladsp-eq.py"
    echo "✅ generate-camilladsp-eq.py copied"
fi

if [ -d "${CUSTOM_COMPONENTS}/scripts" ]; then
    if [ -f "${CUSTOM_COMPONENTS}/scripts/analyze-measurement.py" ]; then
        cp "${CUSTOM_COMPONENTS}/scripts/analyze-measurement.py" "${ROOTFS}/usr/local/bin/"
        chmod +x "${ROOTFS}/usr/local/bin/analyze-measurement.py"
        echo "✅ analyze-measurement.py copied"
    fi
    
    if [ -f "${CUSTOM_COMPONENTS}/scripts/generate-fir-filter.py" ]; then
        cp "${CUSTOM_COMPONENTS}/scripts/generate-fir-filter.py" "${ROOTFS}/usr/local/bin/"
        chmod +x "${ROOTFS}/usr/local/bin/generate-fir-filter.py"
        echo "✅ generate-fir-filter.py copied"
    fi
fi

# HTML template
if [ -f "${CUSTOM_COMPONENTS}/templates/room-correction-wizard-modal.html" ]; then
    mkdir -p "${ROOTFS}/var/www/html/templates"
    cp "${CUSTOM_COMPONENTS}/templates/room-correction-wizard-modal.html" "${ROOTFS}/var/www/html/templates/"
    chmod 644 "${ROOTFS}/var/www/html/templates/room-correction-wizard-modal.html"
    echo "✅ room-correction-wizard-modal.html copied"
fi
```

**Dependencies (Already in Build):**
- Python packages installed in run-chroot.sh line 361: `python3-scipy python3-soundfile python3-numpy`
- Directories created in run-chroot.sh lines 368-371: `/var/lib/camilladsp/convolution`, `/var/lib/camilladsp/measurements`

### Files to Integrate

1. `moode-source/www/command/room-correction-wizard.php` → `/var/www/html/command/room-correction-wizard.php`
2. `custom-components/templates/room-correction-wizard-modal.html` → `/var/www/html/templates/room-correction-wizard-modal.html`
3. `custom-components/scripts/analyze-measurement.py` → `/usr/local/bin/analyze-measurement.py`
4. `custom-components/scripts/generate-fir-filter.py` → `/usr/local/bin/generate-fir-filter.py`
5. `moode-source/usr/local/bin/generate-camilladsp-eq.py` → `/usr/local/bin/generate-camilladsp-eq.py`

### Verification After Build

```bash
# Check files exist
ls -la /var/www/html/command/room-correction-wizard.php
ls -la /usr/local/bin/analyze-measurement.py
ls -la /usr/local/bin/generate-camilladsp-eq.py

# Check Python dependencies
python3 -c "import scipy, soundfile, numpy; print('OK')"

# Check directories
ls -ld /var/lib/camilladsp/convolution
ls -ld /var/lib/camilladsp/measurements
```

---

## Summary

**Boot Fixes:**
- Fix D-Bus circular dependency properly
- Keep multi-user.target (moOde standard)
- Mask unwanted services only

**Dependency and Path Fixes:**
- Validate all environment variables (MOODE_SOURCE, CUSTOM_COMPONENTS, ROOTFS_DIR)
- Check file/directory existence before all operations
- Use absolute paths or validate relative paths
- Handle missing files gracefully (warn, don't fail unless critical)
- Verify write permissions before creating directories
- Check operation success after each critical step
- Eliminates "No such file or directory" errors

**Wizard Integration:**
- Copy all wizard files during build with validation
- Python dependencies already installed
- Directories already created
- No post-build steps needed

**Result:**
- Boot works properly (no circular dependency)
- No more "No such file or directory" errors
- Wizard fully integrated in image
- Ready to use after first boot

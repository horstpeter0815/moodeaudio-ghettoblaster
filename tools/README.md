# Professional Debugging Tools

These tools follow professional debugging approaches to fix build issues systematically.

## Quick Start

### 1. Compare Working vs New Build

**When to use:** You have a working moOde SD card and want to see what's different in the new build.

```bash
# Mount both SD cards
# Then run:
./tools/compare-working-vs-new.sh
```

**What it does:**
- Detects both SD cards
- Compares systemd configurations
- Shows exact differences
- Saves comparison report

**Output:** `comparison-YYYYMMDD-HHMMSS/` directory with diff files

---

### 2. Validate SD Card Fixes

**When to use:** After applying fixes, verify they're actually applied correctly.

```bash
./tools/validate-sd-card-fixes.sh /Volumes/rootfs
```

**What it checks:**
- ✅ Services are masked correctly
- ✅ Override files exist and are correct
- ✅ Source service files are deleted
- ✅ network-online.target.wants is removed
- ✅ All required overrides exist

**Output:** Pass/Fail with detailed report

---

### 3. Analyze Systemd Dependencies

**When to use:** To understand WHY a service starts and what triggers it.

```bash
./tools/analyze-systemd-dependencies.sh /Volumes/rootfs
```

**What it shows:**
- Dependency chains
- What triggers what
- Override files
- Service relationships

**Output:** `dependency-analysis-YYYYMMDD-HHMMSS/` directory with analysis

---

### 4. Apply Working Configuration

**When to use:** You have a working SD card and want to copy its config to new build.

```bash
./tools/apply-working-config.sh /Volumes/working-rootfs /Volumes/rootfs
```

**What it does:**
- Copies all systemd overrides from working to new
- Copies service masks
- Removes unwanted directories
- Applies fixes automatically

**Output:** New build configured like working system

---

## Workflow

### Recommended Workflow

1. **Compare first:**
   ```bash
   ./tools/compare-working-vs-new.sh
   ```
   See what's different

2. **Apply working config:**
   ```bash
   ./tools/apply-working-config.sh /Volumes/working-rootfs /Volumes/rootfs
   ```
   Copy working configuration

3. **Validate:**
   ```bash
   ./tools/validate-sd-card-fixes.sh /Volumes/rootfs
   ```
   Verify fixes are applied

4. **Test:**
   - Boot on Raspberry Pi
   - If it works, document what was applied
   - If it fails, analyze dependencies

5. **Analyze if needed:**
   ```bash
   ./tools/analyze-systemd-dependencies.sh /Volumes/rootfs
   ```
   Understand dependency chain

---

## Examples

### Example 1: First Time Setup

```bash
# 1. Mount working SD card and new build SD card
# 2. Compare
./tools/compare-working-vs-new.sh

# 3. Review differences in comparison-*/ directory
# 4. Apply working config
./tools/apply-working-config.sh /Volumes/working-rootfs /Volumes/rootfs

# 5. Validate
./tools/validate-sd-card-fixes.sh /Volumes/rootfs

# 6. Test boot
```

### Example 2: After Manual Fixes

```bash
# After manually applying fixes, validate:
./tools/validate-sd-card-fixes.sh /Volumes/rootfs

# If validation fails, see what's wrong
# Fix issues
# Validate again
```

### Example 3: Understanding a Problem

```bash
# Analyze dependencies to understand why something starts:
./tools/analyze-systemd-dependencies.sh /Volumes/rootfs

# Review output in dependency-analysis-*/ directory
# Understand the chain
# Apply appropriate fix
```

---

## Integration with Build Process

### Add to Build Script

```bash
# In build script, after image is created:
# 1. Mount image
# 2. Validate fixes
./tools/validate-sd-card-fixes.sh /mnt/rootfs

# If validation fails, build fails
if [ $? -ne 0 ]; then
    echo "❌ Validation failed - build aborted"
    exit 1
fi
```

### Add to CI/CD

```bash
# In CI pipeline:
# 1. Build image
# 2. Mount and validate
# 3. Report results
```

---

## Troubleshooting

### Tool not found
```bash
# Make sure you're in the project root
cd /Users/andrevollmer/moodeaudio-cursor

# Make tools executable
chmod +x tools/*.sh
```

### SD card not detected
```bash
# Check if SD card is mounted
diskutil list

# Mount manually if needed
diskutil mountDisk /dev/disk4
```

### Permission denied
```bash
# Tools use sudo for some operations
# You'll be prompted for password ( for Mac)
```

---

## Best Practices

1. **Always compare first** - Don't guess, compare working vs broken
2. **Validate after fixes** - Ensure fixes are actually applied
3. **Document what works** - Save working configurations
4. **Test incrementally** - Test after each fix
5. **Use version control** - Tag working builds

---

## Next Steps

1. Use these tools for your next build
2. Document what works
3. Create automated validation in build process
4. Build knowledge base of working configurations

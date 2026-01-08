# Display Rotation Root Cause Analysis

## The Problem
Portrait and landscape settings are "twisted" - setting portrait gives landscape and vice versa.

## Root Cause: TWO SEPARATE ROTATION MECHANISMS

### 1. Web UI Setting: `hdmi_scn_orient`
**Location:** `www/per-config.php` → `www/daemon/worker.php` (case 'hdmi_scn_orient')

**What it does:**
- Updates X11 touchscreen calibration matrix ONLY
- Does NOT modify `config.txt` or `cmdline.txt`
- Does NOT affect framebuffer rotation
- Used by `.xinitrc` script for X11 display rotation

**Implementation:**
```php
// worker.php lines 3535-3546
case 'hdmi_scn_orient':
    if ($_SESSION['w_queueargs'] == 'portrait') {
        // Add touchscreen calibration matrix
        sysCmd("sed -i 's/touchscreen catchall\"/touchscreen catchall\""
            . '\n\tOption "CalibrationMatrix" '
            . "\"0 -1 1 1 0 0 0 0 1\"/' /usr/share/X11/xorg.conf.d/40-libinput.conf");
    } else if ($_SESSION['w_queueargs'] == 'landscape') {
        // Remove calibration matrix
        sysCmd('sed -i /CalibrationMatrix/d /usr/share/X11/xorg.conf.d/40-libinput.conf');
    }
    stopLocalDisplay();
    startLocalDisplay();
    break;
```

**Used in `.xinitrc`:**
```bash
# Get screen resolution from hardware
SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
# Hardware reports: 400x1280 (portrait)

# If Web UI says "portrait"
if [ $HDMI_SCN_ORIENT = "portrait" ]; then
    # SWAP dimensions: 400x1280 → 1280x400
    SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
    # Then rotate X11 display left
    DISPLAY=:0 xrandr --output HDMI-1 --rotate left
fi
```

**Result:** Setting "portrait" in Web UI → swaps dimensions → rotates → gives LANDSCAPE display!

### 2. Boot-Level Rotation: `display_rotate` and `fbcon rotate`

**`display_rotate` (config.txt):**
- Raspberry Pi boot parameter
- Rotates framebuffer at boot time
- Values: 0, 90, 180, 270
- NOT managed by moOde Web UI
- We removed this earlier, but it's separate from Web UI

**`fbcon rotate` (cmdline.txt):**
- Framebuffer console rotation
- ONLY used for DSI touchscreen (touch1)!
- Managed by `updBootConfigTxt('upd_dsi_scn_rotate')` in `common.php`
- NOT used for HDMI displays
- Code: `common.php` lines 617-628

```php
case 'upd_dsi_scn_rotate': // touch1 only
    if ($value == '0') {
        sysCmd('sed -i "s/ ' . CFG_PITOUCH_ROTATE_180 . '//"' . ' ' . BOOT_CMDLINE_TXT);
    } else {
        sysCmd('sed -i "s/$/ ' . CFG_PITOUCH_ROTATE_180 . '/"' . ' ' . BOOT_CMDLINE_TXT);
    }
```

## Why It's Twisted

1. **Hardware reports:** 400x1280 (portrait orientation)
2. **We want:** 1280x400 (landscape)
3. **Web UI logic:** If setting is "portrait", it assumes hardware is landscape and needs rotation
4. **Actual result:** Hardware IS portrait, so "portrait" setting swaps and rotates → landscape!

## The Two Different Pages

### Page 1: Web UI (`per-config.php`)
- Controls: `hdmi_scn_orient` database setting
- Affects: X11 display rotation via `.xinitrc`
- Does NOT affect: Boot-level rotation

### Page 2: Boot Configuration (`config.txt`, `cmdline.txt`)
- Controls: `display_rotate`, `fbcon rotate`
- Affects: Framebuffer rotation at boot
- NOT controlled by: Web UI `hdmi_scn_orient`

## Solution

For HDMI displays with custom resolution (1280x400):
1. Hardware reports: 400x1280 (portrait)
2. Set Web UI to: **"portrait"** (this swaps and rotates to landscape)
3. Do NOT use: `display_rotate` in config.txt (conflicts with custom resolution)
4. Do NOT use: `fbcon rotate` (only for DSI touchscreen)

The "twist" is INTENTIONAL - it compensates for hardware reporting portrait when we want landscape.


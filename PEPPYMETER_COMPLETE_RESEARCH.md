# PeppyMeter Complete Research - Theory, Skins, Moode Integration

**Date:** 2025-12-25  
**Purpose:** Comprehensive documentation of PeppyMeter theory, skin system, Moode integration, and troubleshooting

---

## 1. PeppyMeter Theory & Architecture

### What is PeppyMeter?
- **Software VU-Meter** written in Python using Pygame
- Originally developed as screensaver for **Peppy Player**
- Standalone application that receives audio data via **FIFO pipes**
- Displays real-time volume levels as graphical VU-meters

### Data Flow Architecture:
```
MPD (Music Player Daemon)
    ↓ (writes audio data)
FIFO Pipe (/tmp/mpd.fifo)
    ↓ (reads audio data)
PeppyMeter (datasource.py)
    ↓ (processes audio)
Pygame (renders graphics)
    ↓ (displays on screen)
VU-Meter Indicators (move based on audio levels)
```

### Key Components:
1. **`datasource.py`**: 
   - Opens FIFO pipe (`os.open(pipe_name, os.O_RDONLY | os.O_NONBLOCK)`)
   - Reads audio data in separate thread
   - Processes audio (mono/stereo algorithms)
   - Provides volume levels to meter renderer

2. **`configfileparser.py`**:
   - Parses `/etc/peppymeter/config.txt` (main config)
   - Parses `/opt/peppymeter/{SKIN}/meters.txt` (skin config)
   - Determines screen size from folder name (e.g., `1280x400`)

3. **`circular.py` / `linear.py`**:
   - Renders meter graphics (circular or linear meters)
   - Uses Pygame for drawing

4. **`meters.txt`** (per-skin):
   - Defines meter type (circular/linear)
   - Positions (left.x, left.y, right.x, right.y)
   - Image files (background, indicators, needles)

---

## 2. PeppyMeter Skins/Styles System

### Skin Location:
**Base Directory:** `/opt/peppymeter/`

### Available Skins (on your system):
```
/opt/peppymeter/
├── 320x240/          # 320x240 resolution skin
├── 480x320/          # 480x320 resolution skin
├── 800x480/          # 800x480 resolution skin
├── 800x480-moode/    # Moode-specific 800x480 skin
├── 1024x600-moode/   # Moode-specific 1024x600 skin
├── 1280x400/         # 1280x400 resolution skin
├── 1280x400-moode/   # Moode-specific 1280x400 skin (CURRENT)
└── __pycache__/      # Python cache (ignored)
```

### How Skins Work:
1. **Folder name = Screen resolution** (e.g., `1280x400` means 1280x400 pixels)
2. PeppyMeter uses folder name to determine screen size (parsed by `get_meter_size()`)
3. Each folder contains:
   - `meters.txt`: Configuration file with meter definitions
   - Image files: PNG files for backgrounds, indicators, needles
   - Multiple meter styles: Each `[section]` in `meters.txt` is a different style

### Skin Configuration:
**Main Config:** `/etc/peppymeter/config.txt`
```ini
[current]
meter = random                    # or specific meter name
meter.folder = 1280x400-moode     # Which skin folder to use
screen.width = 1280
screen.height = 400
```

**Skin Config:** `/opt/peppymeter/{SKIN}/meters.txt`
```ini
[linear-left-right]              # Meter style name
meter.type = linear              # or circular
channels = 2                     # Stereo
left.x = 50                      # Left meter position
left.y = 150
right.x = 680                    # Right meter position
right.y = 150
bgr.filename = bar-bgr.png      # Background image
indicator.filename = bar-indicator.png  # Indicator image
```

### Available Meter Styles in Each Skin:
Each skin folder can contain multiple meter styles. To see available styles:
```bash
cat /opt/peppymeter/1280x400-moode/meters.txt | grep "^\["
```

Example output:
```
[black-white]
[blue]
[emerald]
[gold]
[orange]
[red]
[tube]
[white-red]
```

---

## 3. Moode Audio Integration

### Web UI Configuration Page:
**URL:** `http://{PI_IP}/peppy-config.php`  
**File:** `/var/www/peppy-config.php`

### How Moode Displays Skins:

#### 1. Folder Dropdown (Skins):
```php
// In peppy-config.php (lines 82-88)
$folders = getPeppyFolderList('meter');
foreach($folders as $folderPath) {
    $folder = rtrim(ltrim($folderPath, PEPPY_METER_OPT_DIR . '/'), '/');
    if (!str_contains($folder, 'pycache')) {
        $_select['meter_folder'] .= "<option value=\"" . $folder . "\">" . $folder . "</option>\n";
    }
}
```

**Function:** `getPeppyFolderList('meter')` in `/var/www/inc/peripheral.php`
```php
function getPeppyFolderList($type) {
    $peppyBaseDir = $type == 'meter' ? PEPPY_METER_OPT_DIR : PEPPY_SPECTRUM_OPT_DIR;
    $array = glob($peppyBaseDir . '/*/', GLOB_ONLYDIR);
    sort($array);
    return $array;
}
```

This function:
- Scans `/opt/peppymeter/*/` for directories
- Returns list of all skin folders
- Excludes `__pycache__`

#### 2. Meter Style Dropdown (Within Selected Skin):
```php
// In peppy-config.php (line 89)
$_meter_list = getPeppyFolderContents('meter', $configMeter['meter.folder']);
```

**Function:** `getPeppyFolderContents('meter', '1280x400-moode')` in `/var/www/inc/peripheral.php`
```php
function getPeppyFolderContents($type, $contentDir) {
    $peppyBaseDir = $type == 'meter' ? PEPPY_METER_OPT_DIR : PEPPY_SPECTRUM_OPT_DIR;
    $configFile = $type == 'meter' ? 'meters.txt' : 'spectrum.txt';
    // Get all [name] items from meters.txt
    $items = sysCmd('cat ' . $peppyBaseDir . '/' . $contentDir . '/' . $configFile . ' | grep "]"');
    // Strip brackets and return comma-separated list
    foreach ($items as $item) {
        $item = rtrim(ltrim($item, '['), ']');
        $itemList .= $item . ', ';
    }
    return rtrim($itemList, ', ');
}
```

This function:
- Reads `meters.txt` from selected skin folder
- Extracts all `[section]` names (meter styles)
- Returns comma-separated list: `"black-white, blue, emerald, gold, ..."`

### Database Settings:
```sql
SELECT param, value FROM cfg_system WHERE param LIKE '%peppy%';
```
- `peppy_display`: Enable/disable (0/1)
- `peppy_display_type`: Type (`meter` or `spectrum`)

### Service Management:
- **Service:** `localdisplay.service` (starts X11 and PeppyMeter)
- **Launch:** Via `.xinitrc` when `peppy_display=1`
- **Process:** `python3 /opt/peppymeter/peppymeter.py`

---

## 4. Why Skins Might Not Show in Web UI

### Possible Issues:

#### Issue 1: Page Not Accessible
**Check:** Can you access `http://{PI_IP}/peppy-config.php`?
- If 404: Page doesn't exist (wrong Moode version?)
- If blank: PHP error (check `/var/log/apache2/error.log`)

#### Issue 2: Permissions
**Check:** Can Moode read `/opt/peppymeter/`?
```bash
ls -la /opt/peppymeter/
# Should be readable by www-data user
```

#### Issue 3: glob() Function Failing
**Check:** PHP `glob()` function might not work
```bash
# Test on Pi:
php -r "print_r(glob('/opt/peppymeter/*/', GLOB_ONLYDIR));"
```

#### Issue 4: Template Not Loading
**Check:** Template file exists?
```bash
ls -la /var/www/templates/peppy-config.html
```

### Debug Steps:
1. **Check if page loads:**
   ```bash
   curl http://localhost/peppy-config.php
   ```

2. **Check PHP errors:**
   ```bash
   tail -50 /var/log/apache2/error.log
   ```

3. **Test folder list function:**
   ```bash
   php -r "require '/var/www/inc/peripheral.php'; print_r(getPeppyFolderList('meter'));"
   ```

4. **Check template:**
   ```bash
   cat /var/www/templates/peppy-config.html | grep -A 10 "meter_folder"
   ```

---

## 5. Common Problems & Solutions

### Problem 1: Indicators Not Moving
**Root Cause:** MPD FIFO output not enabled or wrong pipe path

**Solution:**
```bash
# Enable FIFO output
mpc enable 4

# Verify pipe path in config
grep pipe.name /etc/peppymeter/config.txt
# Should be: pipe.name = /tmp/mpd.fifo

# Check data flow
timeout 3 cat /tmp/mpd.fifo | wc -c
# Should be > 0 if data is flowing
```

### Problem 2: Skins Not Showing in Dropdown
**Root Cause:** 
- Page not accessible
- Permissions issue
- glob() function failing
- Template not loading correctly

**Solution:**
1. Access page: `http://{PI_IP}/peppy-config.php`
2. Check browser console for JavaScript errors
3. Check Apache error log
4. Verify folders exist: `ls -d /opt/peppymeter/*/`

### Problem 3: Wrong Skin Selected
**Root Cause:** `meter.folder` doesn't match display resolution

**Solution:**
```bash
# Check actual display resolution
DISPLAY=:0 xdpyinfo | grep dimensions

# Update config
sudo sed -i 's/^meter.folder.*/meter.folder = 1280x400-moode/' /etc/peppymeter/config.txt

# Restart PeppyMeter
sudo systemctl restart localdisplay.service
```

### Problem 4: Display Orientation Issues
**Root Cause:** X11 rotation changes coordinate system

**Solution:**
- Fix rotation at boot level (`config.txt`: `display_rotate=1`)
- Or adjust coordinates in `meters.txt` to account for rotation

---

## 6. PeppyMeter Configuration Reference

### Main Config (`/etc/peppymeter/config.txt`):
```ini
[current]
meter = random                    # or specific meter name
meter.folder = 1280x400-moode    # Skin folder
screen.width = 1280
screen.height = 400
random.meter.interval = 20        # Seconds between random meter changes

[data.source]
type = pipe                        # Data source: pipe, noise, constant, etc.
pipe.name = /tmp/mpd.fifo         # FIFO pipe path
polling.interval = 0.04           # How often to read data (seconds)
volume.constant = 80.0
volume.min = 0.0
volume.max = 100.0
volume.max.in.pipe = 100.0        # Normalization level
mono.algorithm = average          # Algorithm for mono audio
stereo.algorithm = new            # Algorithm for stereo audio
smooth.buffer.size = 4            # Smoothing buffer size
```

### Skin Config (`/opt/peppymeter/{SKIN}/meters.txt`):
```ini
[linear-left-right]              # Meter style name
meter.type = linear              # or circular
channels = 2                     # Stereo (2 channels)
ui.refresh.period = 0.033        # Refresh rate (seconds)
bgr.filename = bar-bgr.png       # Background image
indicator.filename = bar-indicator.png  # Indicator image
left.x = 50                      # Left meter X position
left.y = 150                     # Left meter Y position
right.x = 680                    # Right meter X position
right.y = 150                    # Right meter Y position
position.regular = 10           # Number of regular volume steps
position.overload = 3            # Number of overload (peak) steps
step.width.regular = 45         # Width of regular steps (pixels)
step.width.overload = 50         # Width of overload steps (pixels)
meter.x = 0                      # Meter offset X
meter.y = 0                      # Meter offset Y
screen.bgr =                     # Screen background (optional)
```

---

## 7. Accessing PeppyMeter Settings in Moode Web UI

### How to Access:
1. **Open Moode Web UI:** `http://{PI_IP}/`
2. **Navigate to:** System Configuration → Peripherals → Peppy Display
3. **Or direct URL:** `http://{PI_IP}/peppy-config.php`

### What You Should See:
1. **General Settings:**
   - Screen width/height
   - Random meter interval

2. **Meter Folder Dropdown:**
   - Lists all available skins (e.g., `1280x400-moode`, `1024x600-moode`)
   - Current selection highlighted

3. **Meter Name Dropdown:**
   - Lists all meter styles in selected folder
   - Shows: `black-white, blue, emerald, gold, orange, red, tube, white-red`
   - Or `random` to cycle through all

4. **Normalization:**
   - Volume normalization level (100, 90, 80, ... 10)

---

## 8. Troubleshooting Checklist

### If Skins Don't Show in Dropdown:
- [ ] Can you access `http://{PI_IP}/peppy-config.php`?
- [ ] Check browser console for errors (F12)
- [ ] Check Apache error log: `tail -50 /var/log/apache2/error.log`
- [ ] Verify folders exist: `ls -d /opt/peppymeter/*/`
- [ ] Test PHP glob function: `php -r "print_r(glob('/opt/peppymeter/*/', GLOB_ONLYDIR));"`
- [ ] Check permissions: `ls -la /opt/peppymeter/`

### If Indicators Don't Move:
- [ ] MPD FIFO output enabled? (`mpc outputs` → Output 4 enabled)
- [ ] FIFO pipe exists? (`ls -la /tmp/mpd.fifo`)
- [ ] Data flowing? (`timeout 3 cat /tmp/mpd.fifo | wc -c` > 0)
- [ ] Config correct? (`grep pipe.name /etc/peppymeter/config.txt`)
- [ ] MPD playing? (`mpc status`)

### If Wrong Skin/Resolution:
- [ ] Check actual resolution: `DISPLAY=:0 xdpyinfo | grep dimensions`
- [ ] Verify skin folder matches: `grep meter.folder /etc/peppymeter/config.txt`
- [ ] Ensure skin folder exists: `ls -d /opt/peppymeter/{RESOLUTION}*`

---

## 9. Additional Resources

### GitHub Repositories:
- **PeppyMeter:** `github.com/project-owner/PeppyMeter`
- **Peppy Player:** `github.com/project-owner/PeppyPlayer`
- **Peppy Documentation:** `github.com/project-owner/Peppy.doc/wiki`
- **Moode Integration:** `github.com/FdeAlexa/PeppyMeter_and_moOde`

### Moode Forum:
- Search for: "PeppyMeter skins", "PeppyMeter dropdown", "PeppyMeter configuration"
- Common topics: Indicators not moving, skins not showing, display issues

### Skin Collections:
- **Grzegorz Pietrzak (Gelo5)**: Extensive skin collection for various resolutions
- Available for: 800x480, 1024x600, 1280x400, 1280x800, 1920x480, 1920x1080, etc.

---

**Status:** Research complete - Ready for troubleshooting and implementation











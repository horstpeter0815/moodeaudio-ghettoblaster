# PeppyMeter Toggle Solution - Working Configuration

## Date: 2026-01-21
## Status: ✅ WORKING

## Overview
Bidirectional toggle between moOde WebUI and PeppyMeter visualization using:
- Button in moOde UI (playback panel)
- Touch gesture when PeppyMeter is showing

## Architecture

### 1. Database Configuration (cfg_system table)
Two parameters control the display:
- `local_display`: 1 = moOde UI, 0 = OFF
- `peppy_display`: 1 = PeppyMeter, 0 = OFF

**Critical**: These must be OPPOSITE at all times:
- moOde UI: local_display=1, peppy_display=0
- PeppyMeter: local_display=0, peppy_display=1

### 2. Display Control (.xinitrc)
File: `/home/andre/.xinitrc`

Reads database and launches appropriate display:
```bash
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")

if [ $WEBUI_SHOW = "1" ]; then
    # Launch Chromium with moOde UI
    /usr/lib/chromium-browser/chromium-browser --app=http://localhost/ ...
elif [ $PEPPY_SHOW = "1" ]; then
    # Launch PeppyMeter + touch exit script
    cd /opt/peppymeter && python3 peppymeter.py & /usr/local/bin/peppy-exit.sh
fi
```

### 3. Toggle Script
File: `/usr/local/bin/toggle-peppy-simple.sh`

Direct database update + service restart:
```bash
#!/bin/bash
CURRENT_PEPPY=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='peppy_display'")

if [ "$CURRENT_PEPPY" = "1" ]; then
    NEW_PEPPY="0"
    NEW_LOCAL="1"
else
    NEW_PEPPY="1"
    NEW_LOCAL="0"
fi

sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='${NEW_PEPPY}' WHERE param='peppy_display'; UPDATE cfg_system SET value='${NEW_LOCAL}' WHERE param='local_display'"
sudo systemctl restart localdisplay
```

### 4. Touch Exit Script
File: `/usr/local/bin/peppy-exit.sh`

Monitors touchscreen (/dev/input/event3) for tap events:
```bash
#!/bin/bash
TOUCH_DEV="/dev/input/event3"

timeout 600 evtest "$TOUCH_DEV" 2>/dev/null | while read line; do
    if echo "$line" | grep -q "BTN_TOUCH.*value 1"; then
        /usr/local/bin/toggle-peppy-simple.sh
        exit 0
    fi
done
```

### 5. moOde UI Button
File: `/var/www/templates/indextpl.min.html`

Button with inline onclick handler:
```html
<button class="btn btn-cmd toggle-peppymeter" id="toggle-peppymeter" 
        aria-label="PeppyMeter" 
        onclick="fetch('/command/index.php?cmd=toggle_peppymeter').then(()=>setTimeout(()=>location.href='/',1000))">
    <i class="fa-regular fa-sharp fa-wave-pulse"></i>
</button>
```

### 6. Backend Handler
File: `/var/www/command/index.php`

Case for toggle_peppymeter:
```php
case 'toggle_peppymeter':
    _openSession($dbh);
    $peppy = $_SESSION['peppy_display'] == '1' ? '0' : '1';
    $local = $peppy == '1' ? '0' : '1';
    $_SESSION['peppy_display'] = $peppy;
    $_SESSION['local_display'] = $local;
    session_write_close();
    sqlUpdate('cfg_system', $dbh, 'peppy_display', $peppy);
    sqlUpdate('cfg_system', $dbh, 'local_display', $local);
    sysCmd('systemctl restart localdisplay');
    echo json_encode($peppy == '1' ? 'PeppyMeter ON' : 'PeppyMeter OFF');
    break;
```

### 7. Permissions (sudoers)
File: `/etc/sudoers.d/localdisplay-toggle`

Allows andre user to restart display without password:
```
andre ALL=(ALL) NOPASSWD: /bin/systemctl restart localdisplay
```

### 8. Dependencies
- `evtest` package (for touch detection)
- andre user in `input` group (for /dev/input/event3 access)

## Critical Files Inventory

```
/home/andre/.xinitrc                           # Display launcher
/usr/local/bin/toggle-peppy-simple.sh          # Toggle script
/usr/local/bin/peppy-exit.sh                   # Touch exit monitor
/etc/sudoers.d/localdisplay-toggle             # Permission rule
/var/www/templates/indextpl.min.html           # UI button HTML
/var/www/command/index.php                     # Backend handler
/var/www/css/fix-peppymeter-button.css         # Button styling
/var/www/js/scripts-panels.js                  # jQuery handler (optional)
```

## User Flow

### moOde UI → PeppyMeter
1. User clicks PeppyMeter button in moOde UI
2. Inline onclick: fetch('/command/index.php?cmd=toggle_peppymeter')
3. Backend: Updates database (peppy=1, local=0), restarts localdisplay
4. .xinitrc: Reads database, launches PeppyMeter + touch-exit script
5. Display shows PeppyMeter visualization

### PeppyMeter → moOde UI
1. User touches screen anywhere
2. Touch-exit script: Detects touch via evtest
3. Calls toggle-peppy-simple.sh
4. Updates database (peppy=0, local=1), restarts localdisplay
5. .xinitrc: Reads database, launches Chromium
6. Display shows moOde UI

## Key Learnings

1. **Avoid worker queue**: Direct database update + restart is faster and more reliable than submitJob()
2. **Coordinate both settings**: local_display and peppy_display must be opposite
3. **Permissions critical**: Toggle script needs sudo rights to restart service
4. **Touch device**: /dev/input/event3 is the WaveShare touchscreen
5. **Simple is better**: Direct evtest monitoring works better than complex Pygame overlay

## Testing Commands

```bash
# Check current state
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT param, value FROM cfg_system WHERE param IN ('local_display', 'peppy_display')"

# Manual toggle
sudo /usr/local/bin/toggle-peppy-simple.sh

# Check what's running
ps aux | grep -E 'chromium|peppymeter' | grep -v grep

# Check touch device
ls -la /dev/input/event3
evtest /dev/input/event3

# View logs
journalctl -u localdisplay -f
```

## Maintenance

### Backup these files regularly
```bash
sudo tar -czf /home/andre/peppymeter-toggle-backup-$(date +%Y%m%d).tar.gz \
    /home/andre/.xinitrc \
    /usr/local/bin/toggle-peppy-simple.sh \
    /usr/local/bin/peppy-exit.sh \
    /etc/sudoers.d/localdisplay-toggle \
    /var/www/templates/indextpl.min.html \
    /var/www/command/index.php \
    /var/www/css/fix-peppymeter-button.css
```

### If display gets stuck
```bash
# Reset to moOde UI
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display'; UPDATE cfg_system SET value='0' WHERE param='peppy_display'"
sudo systemctl restart localdisplay
```

## Version History
- 2026-01-21: Initial working version
  - Touch detection with evtest
  - Direct database toggle (no worker queue)
  - Sudoers rule for permissions
  - Bidirectional toggle verified working

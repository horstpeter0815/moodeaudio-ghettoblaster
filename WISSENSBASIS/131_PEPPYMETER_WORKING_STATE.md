# PeppyMeter Working State - v1.0 Complete

**Date**: 2026-01-19 03:50  
**Status**: FULLY WORKING  
**System**: moOde Audio Player 10.0.3 on Raspberry Pi 5

## Working Functionality

✅ **PeppyMeter button activates PeppyMeter display**  
✅ **Touch screen exits PeppyMeter and returns to moOde UI**  
✅ **Complete bidirectional toggle working**

## Critical Fixes Applied

### 1. Database Parameters
```sql
-- Required database entries
enable_peppyalsa = 1  -- CRITICAL: Without this, moodeutl rejects toggle
local_display = 1     -- Start in webui mode
peppy_display = 0     -- PeppyMeter off initially
```

### 2. JavaScript Handler (`/var/www/js/main.min.js`)
```javascript
// PeppyMeter button handler - extracts message from JSON response
jQuery(document).ready(function($){
  $("#toggle-peppymeter").click(function(e){
    e.preventDefault();
    e.stopPropagation();
    $.post("command/index.php?cmd=set_display toggle", function(data){
      // CRITICAL: Extract message from response object
      notify("PeppyMeter", data.info||data.alert||"Unknown message. Check the source code.", 3000);
    });
  });
});
```

**Key Fix**: Changed from `notify("PeppyMeter", data, 3000)` to extract the actual message string.

### 3. Stop PeppyMeter Script (`/usr/local/bin/stop-peppymeter.sh`)
```bash
#!/bin/bash
# Stop PeppyMeter and restore moOde UI

# Stop PeppyMeter service
sudo systemctl stop peppymeter 2>/dev/null

# Update database to webui mode (BOTH parameters!)
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display'; UPDATE cfg_system SET value='0' WHERE param='peppy_display'"

# Restart localdisplay service to show moOde UI
sudo systemctl restart localdisplay 2>/dev/null
```

**Key Fix**: Original script only set `peppy_display=0`, didn't set `local_display=1`, and didn't restart localdisplay.

### 4. PeppyMeter Exit Watcher (`/usr/local/bin/peppymeter-exit-watcher.sh`)
```bash
#!/bin/bash
# Watch for PeppyMeter exit and restore UI

while true; do
    # Check if PeppyMeter should be running but isn't
    DB_STATE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='peppy_display'")
    PROCESS_RUNNING=$(ps aux | grep -E 'peppymeter.py|spectrum.py' | grep -v grep | wc -l)
    
    if [ "$DB_STATE" = "1" ] && [ "$PROCESS_RUNNING" = "0" ]; then
        # PeppyMeter exited unexpectedly (touch-exit), restore UI
        /usr/local/bin/stop-peppymeter.sh
    fi
    
    sleep 2
done
```

**Key Fix**: Original checked `systemctl is-active peppymeter` but PeppyMeter runs directly from xinitrc, NOT as a service!

### 5. Display Control Flow

**System uses `localdisplay.service`, not manual xinit:**
```bash
# Service definition
[Unit]
Description=Start Local Display
After=nginx.service php8.4-fpm.service mpd.service

[Service]
Type=simple
User=andre
ExecStart=/usr/bin/xinit -- -nocursor
```

**xinitrc checks database and launches appropriate display:**
```bash
# Get display type config
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")

# Launch WebUI or Peppy
if [ $WEBUI_SHOW = "1" ]; then
    # Launch chromium browser
    chromium --app="http://localhost/" --window-size="$SCREEN_RES" ... --kiosk
elif [ $PEPPY_SHOW = "1" ]; then
    cd /opt/peppymeter && python3 peppymeter.py
fi
```

## Complete Toggle Flow

### Activation (Button Click → PeppyMeter)
1. User clicks PeppyMeter button in moOde UI
2. JavaScript sends: `POST /command/index.php?cmd=set_display toggle`
3. PHP backend: `moodeutl --setdisplay toggle`
4. moodeutl:
   - Checks `enable_peppyalsa=1` (REQUIRED)
   - Checks `local_display=1` (at least one display must be on)
   - Sets `local_display=0, peppy_display=1` in database
   - Runs `systemctl restart localdisplay`
5. localdisplay service restarts → xinitrc runs
6. xinitrc reads database → sees `peppy_display=1`
7. xinitrc launches: `python3 /opt/peppymeter/peppymeter.py`
8. PeppyMeter displays on screen

### Deactivation (Touch Screen → moOde UI)
1. User touches screen while PeppyMeter is running
2. PeppyMeter detects touch and exits (process terminates)
3. Watcher loop (every 2 seconds) checks:
   - Database: `peppy_display=1` (should be running)
   - Process: `peppymeter.py` not in process list (NOT running)
   - Mismatch detected!
4. Watcher calls: `/usr/local/bin/stop-peppymeter.sh`
5. stop-peppymeter.sh:
   - Sets `local_display=1, peppy_display=0` in database
   - Runs `systemctl restart localdisplay`
6. localdisplay service restarts → xinitrc runs
7. xinitrc reads database → sees `local_display=1`
8. xinitrc launches: `chromium --kiosk http://localhost/`
9. moOde UI displays on screen

## Critical Architecture Insights

### Why the Original Implementation Failed

1. **Missing database parameter**: `enable_peppyalsa` was not in the database, causing moodeutl validation to fail silently

2. **Display control conflict**: Manual `xinit` commands conflicted with `systemctl restart localdisplay` - the system MUST use the service, not manual processes

3. **Watcher checking wrong thing**: Watcher checked `systemctl is-active peppymeter.service` but PeppyMeter runs directly from xinitrc, not as a systemd service

4. **Incomplete restoration**: stop-peppymeter.sh only set `peppy_display=0` but didn't set `local_display=1` or restart the display service

5. **JavaScript passing entire object**: notify() received the JSON object instead of extracting the message string

### Key Design Patterns

**Database as Single Source of Truth**: All display decisions read from `cfg_system` table:
- `local_display`: Should Chromium (moOde UI) be shown?
- `peppy_display`: Should PeppyMeter be shown?
- `enable_peppyalsa`: Is PeppyALSA driver enabled? (validation flag)

**Service-Based Display Management**: `localdisplay.service` always controls the display:
- Restarting the service re-reads database and launches correct display
- Never run manual `xinit` - always use the service

**Watcher Pattern for Touch Exit**: Since touch-to-exit is handled by PeppyMeter itself (not moOde), a watcher detects when the process unexpectedly terminates and restores the UI

**Toggle Command Reuses Existing Infrastructure**: Instead of creating a new `toggle_peppymeter` command, reused moOde's existing `set_display toggle` command

## Files Modified

1. `/var/www/js/main.min.js` - Added PeppyMeter button handler with message extraction
2. `/var/www/templates/indextpl.min.html` - Added PeppyMeter button to UI
3. `/usr/local/bin/stop-peppymeter.sh` - Fixed to update both DB params and restart service
4. `/usr/local/bin/peppymeter-exit-watcher.sh` - Fixed to check process instead of service
5. `/var/local/www/db/moode-sqlite3.db` - Added `enable_peppyalsa=1` parameter

## Verification Commands

```bash
# Check database state
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT param, value FROM cfg_system WHERE param IN ('local_display', 'peppy_display', 'enable_peppyalsa')"

# Check services
systemctl status localdisplay.service peppymeter-watcher.service

# Check what's running
ps aux | grep -E 'chromium|peppymeter' | grep -v grep

# Test toggle manually
curl 'http://localhost/command/index.php?cmd=set_display%20toggle'
```

## Next Steps

- Test audio routing when PeppyMeter is active vs inactive
- Check if PeppyMeter indicators are working
- Document audio chain differences between modes

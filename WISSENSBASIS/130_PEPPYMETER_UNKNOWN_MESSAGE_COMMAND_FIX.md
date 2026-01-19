# PeppyMeter "Unknown message" Error - Wrong Command Name

**Date**: 2026-01-19  
**Status**: RESOLVED  
**System**: moOde Audio Player 10.0.3 on Raspberry Pi 5

## Problem

When clicking the PeppyMeter button in the moOde UI, the user received:
```
Unknown message. Check the source code.
```

The button appeared correctly, JavaScript fired, but the backend command failed.

## Root Cause

The JavaScript handler was calling a **non-existent command** `toggle_peppymeter`:

```javascript
$.post("command/index.php?cmd=toggle_peppymeter", function(data){
    notify("PeppyMeter", data, 3000);
});
```

However, moOde's command handler (`/var/www/command/index.php`) does **not** have a `toggle_peppymeter` case. Instead, it has:

```php
case 'set_display': // webui | peppy | toggle
    $result = sysCmd('moodeutl --setdisplay' . getArgs($cmd));
    echo empty($result) ?
        json_encode(array('info' => 'Set display to ' . getArgs($cmd) . ' submitted')) :
        json_encode(array('alert' => 'Missing or invalid argument'));
    break;
```

The correct command is **`set_display`** with argument **`toggle`**.

## Evidence

**Backend command check**:
```bash
$ ssh andre@192.168.2.3 "grep -E 'case.*toggle' /var/www/command/index.php"
case 'toggle_play_pause':
case 'set_display': // webui | peppy | toggle
# No 'toggle_peppymeter' case exists!
```

**PeppyMeter service exists**:
```bash
$ systemctl list-units | grep peppy
peppymeter-watcher.service    loaded active running   PeppyMeter Exit Watcher
peppymeter.service            loaded failed failed    Peppy Meter
```

**Command implementation**:
- Correct: `moodeutl --setdisplay toggle`
- Calls existing `set_display` command
- Argument: `toggle` switches between webui and peppy display

## Solution

Fix the JavaScript to use the correct command:

```javascript
// WRONG (causes "Unknown message"):
$.post("command/index.php?cmd=toggle_peppymeter", function(data){
    notify("PeppyMeter", data, 3000);
});

// CORRECT:
$.post("command/index.php?cmd=set_display toggle", function(data){
    notify("PeppyMeter", data, 3000);
});
```

**Implementation**:
```bash
ssh andre@192.168.2.3 "sudo python3 << 'PYEOF'
with open('/var/www/js/main.min.js', 'r') as f:
    js = f.read()

# Replace incorrect command with correct one
js = js.replace(
    '$.post(\"command/index.php?cmd=toggle_peppymeter\"',
    '$.post(\"command/index.php?cmd=set_display toggle\"'
)

with open('/var/www/js/main.min.js', 'w') as f:
    f.write(js)
PYEOF
"

# Clear Chromium cache and restart
sudo rm -rf /home/andre/.config/chromium/Default/Cache
sudo pkill xinit
sudo -u andre DISPLAY=:0 xinit -- -nocursor &
```

## Verification

**Before fix**:
```bash
$ tail -2 /var/www/js/main.min.js
jQuery(document).ready(function($){$("#toggle-peppymeter").click(function(e){e.preventDefault();e.stopPropagation();$.post("command/index.php?cmd=toggle_peppymeter",function(data){notify("PeppyMeter",data,3000);});});});
# Wrong command ^^^^^^^^^^^^^^^^^^^
```

**After fix**:
```bash
$ tail -2 /var/www/js/main.min.js
jQuery(document).ready(function($){$("#toggle-peppymeter").click(function(e){e.preventDefault();e.stopPropagation();$.post("command/index.php?cmd=set_display toggle",function(data){notify("PeppyMeter",data,3000);});});});
# Correct command ^^^^^^^^^^^^^^^^^^^^^
```

**User experience**:
- Before: Click button → "Unknown message. Check the source code."
- After: Click button → PeppyMeter toggles correctly

## How set_display Works

The `set_display` command in moOde:

1. **Webui mode**: Shows moOde web interface (default)
2. **Peppy mode**: Shows PeppyMeter visualization fullscreen
3. **Toggle**: Switches between webui and peppy

**Backend flow**:
```
JavaScript: $.post("cmd=set_display toggle")
    ↓
PHP: /var/www/command/index.php
    ↓
Shell: moodeutl --setdisplay toggle
    ↓
systemd: Start/stop peppymeter.service
    ↓
Display: Switch between Chromium (webui) and PeppyMeter (peppy)
```

## Related Commands

Other display-related commands in moOde:

```bash
# Set to webui explicitly
moodeutl --setdisplay webui

# Set to peppy explicitly
moodeutl --setdisplay peppy

# Toggle between them
moodeutl --setdisplay toggle
```

## Prevention Rules

When adding custom UI commands:

1. **Always check existing commands first**:
   ```bash
   grep "case '" /var/www/command/index.php | less
   ```

2. **Read the backend implementation**:
   ```bash
   grep -A 10 "case 'commandname'" /var/www/command/index.php
   ```

3. **Test the command manually first**:
   ```bash
   curl "http://localhost/command/index.php?cmd=set_display%20toggle"
   ```

4. **Use existing patterns**: Don't invent new commands if existing ones work

5. **Verify the command exists**: Check PHP backend before writing JavaScript

## Learning

This demonstrates:
1. **JavaScript alone isn't enough** - backend must implement the command
2. **Read existing code first** - moOde already had the right command (`set_display`)
3. **"Unknown message"** = command not found in PHP switch statement
4. **Test backend separately** - curl can verify commands before UI integration

The fix was simple: change 5 words in the JavaScript. But finding it required understanding the full stack: JavaScript → PHP → moodeutl → systemd.

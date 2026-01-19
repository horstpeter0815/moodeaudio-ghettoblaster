# PeppyMeter UI Loading Issue - JavaScript Corruption

**Date**: 2026-01-19  
**Status**: RESOLVED  
**System**: moOde Audio Player 10.0.3 on Raspberry Pi 5

## Problem

After adding PeppyMeter button functionality, the moOde UI display would not load properly:
- Icons not displaying
- UI elements not rendering
- Display appeared broken or incomplete
- System very slow to load

## Root Cause

The `/var/www/js/main.min.js` file was corrupted by adding the PeppyMeter click handler **TWICE**:

1. **First addition** (formatted, 13 lines):
```javascript
jQuery(document).ready(function($){
	$("#toggle-peppymeter").click(function(e){
		e.preventDefault();
		e.stopPropagation();
		
		$.post('command/index.php?cmd=toggle_peppymeter', function(data){
			notify('PeppyMeter', data, 3000);
		});
	});
});
```

2. **Second addition** (minified, 1 line):
```javascript
jQuery(document).ready(function($){$("#toggle-peppymeter").click(function(e){e.preventDefault();e.stopPropagation();$.post("command/index.php?cmd=toggle_peppymeter",function(data){notify("PeppyMeter",data,3000);});});});
```

This caused:
- File size: 49 lines → 62 lines (incorrect)
- JavaScript parse/execution errors in browser
- UI rendering blocked/broken
- Performance degradation

## Evidence

**Before fix** (corrupted):
```bash
$ wc -l /var/www/js/main.min.js
62 /var/www/js/main.min.js

$ tail -10 /var/www/js/main.min.js
# Shows BOTH formatted AND minified handler
```

**After fix** (correct):
```bash
$ wc -l /var/www/js/main.min.js
50 /var/www/js/main.min.js  # 49 original + 1 handler

$ tail -2 /var/www/js/main.min.js
//# sourceMappingURL=../maps/js/main.min.js.map
jQuery(document).ready(function($){$("#toggle-peppymeter").click(function(e){e.preventDefault();e.stopPropagation();$.post("command/index.php?cmd=toggle_peppymeter",function(data){notify("PeppyMeter",data,3000);});});});
```

## Solution

1. **Extract clean original from package**:
```bash
cd /home/andre
sudo apt-get download moode-player
dpkg-deb -x moode-player_10.0.3-1moode1_all.deb extracted
```

2. **Restore clean main.min.js** (49 lines):
```bash
sudo cp extracted/var/www/js/main.min.js /var/www/js/main.min.js
```

3. **Add PeppyMeter handler ONCE** (properly):
```python
# Read clean original
with open('/var/www/js/main.min.js', 'r') as f:
    js = f.read()

# Add handler ONCE at end (minified, single line)
handler = 'jQuery(document).ready(function($){$("#toggle-peppymeter").click(function(e){e.preventDefault();e.stopPropagation();$.post("command/index.php?cmd=toggle_peppymeter",function(data){notify("PeppyMeter",data,3000);});});});'

# Write with handler
with open('/var/www/js/main.min.js', 'w') as f:
    f.write(js.rstrip() + '\n' + handler + '\n')
```

4. **Clear Chromium cache and restart**:
```bash
sudo rm -rf /home/andre/.config/chromium/Default/Cache
sudo rm -rf /home/andre/.config/chromium/Default/'Code Cache'
sudo pkill xinit
sudo -u andre DISPLAY=:0 xinit -- -nocursor &
```

## Prevention

**CRITICAL RULES when modifying JavaScript files:**

1. **Always check line count before and after**:
   - Original moOde `main.min.js`: **49 lines**
   - After adding ONE handler: **50 lines**
   - If more than 50 lines → corrupted/duplicated

2. **Never add both formatted AND minified code**:
   - ❌ Add formatted version, then also add minified version
   - ✅ Add ONLY minified version once

3. **Always verify with tail**:
```bash
tail -3 /var/www/js/main.min.js
# Should show sourcemap line, then handler, that's it
```

4. **Test incrementally**:
   - Restore clean original first
   - Verify UI loads correctly
   - Then add handler
   - Verify UI still loads correctly

5. **Keep backups**:
```bash
sudo cp /var/www/js/main.min.js /var/www/js/main.min.js.backup-$(date +%Y%m%d-%H%M%S)
```

## Related Files

- `/var/www/js/main.min.js` - Main UI JavaScript (MUST be 50 lines after PeppyMeter handler)
- `/var/www/templates/indextpl.min.html` - HTML template (must have ONE `toggle-peppymeter` button)
- `/home/andre/.config/chromium/` - Browser cache (clear after JS changes)

## Verification Commands

```bash
# Check file integrity
wc -l /var/www/js/main.min.js  # Should be 50
grep -c 'toggle-peppymeter' /var/www/js/main.min.js  # Should be 1

# Check UI loads correctly
curl -s http://localhost/ | grep -c 'fa-solid'  # Should be > 0
curl -s http://localhost/ | grep -c 'toggle-peppymeter'  # Should be 1

# Check Chromium is running
ps aux | grep chromium-browser | grep -v grep | wc -l  # Should be ~12
```

## Learning

This issue demonstrates the importance of:
1. **Precision in code modifications** - adding code twice breaks everything
2. **Verification after changes** - always check line counts and content
3. **Understanding browser caching** - must clear cache after JS changes
4. **Clean restoration process** - extract from package, don't guess at original

The fix required understanding the entire chain:
- JavaScript file corruption → browser parse errors → UI not rendering
- Solution: Clean restore + single correct addition + cache clear

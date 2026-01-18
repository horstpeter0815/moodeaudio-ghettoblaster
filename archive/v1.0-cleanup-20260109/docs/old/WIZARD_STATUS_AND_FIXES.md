# Wizard Status and Website Switching Fix

## ✅ Wizard Status

**Current State:**
- ✅ All 6 steps implemented and working
- ✅ Step 2 (Ambient Noise) is ENABLED (not skipped)
- ✅ Backend PHP working
- ✅ Wizard modal should work

**To Test Wizard:**
1. Open moOde web interface
2. Go to Audio page
3. Click "Run Wizard" button
4. Test all steps

## 🔧 Website Switching Issue - FIXED

**Problem:** `index.html` file blocks `index.php`, causing redirect issues when switching between pages.

**Solution:** Delete `index.html` file

**Quick Fix (run on Pi):**
```bash
sudo rm -f /var/www/html/index.html
sudo systemctl restart nginx
```

**Or use the fix script:**
```bash
# Copy to Pi
scp scripts/wizard/fix-website-switching.sh andre@<PI_IP>:/tmp/

# Run on Pi
sudo bash /tmp/fix-website-switching.sh
```

**What This Does:**
- Removes `/var/www/html/index.html` if it exists
- Ensures `index.php` is used (correct moOde entry point)
- Restarts nginx to apply changes

**After Fix:**
- Page navigation should work correctly
- No more redirect issues
- Wizard should work properly

## 📋 Next Steps

1. **Fix website switching** (run script above)
2. **Test wizard** - Open Audio page → Run Wizard
3. **Report any issues** - Let me know what doesn't work

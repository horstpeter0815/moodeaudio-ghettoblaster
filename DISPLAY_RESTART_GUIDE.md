# Restart moOde Display - Quick Guide

## If Display is Not Showing

### Quick Restart (Run on Pi)

**SSH into Pi:**
```bash
ssh andre@moode.local
# Password: 0815
```

**Restart Display Service:**
```bash
sudo systemctl restart localdisplay
```

Wait 5-10 seconds for Chromium to start.

### Check Display Status

**Check if service is running:**
```bash
sudo systemctl status localdisplay
```

**Check if Chromium is running:**
```bash
ps aux | grep chromium | grep -v grep
```

**Check recent logs:**
```bash
sudo journalctl -u localdisplay -n 50
```

### If Display Still Not Working

**1. Check if display is enabled in database:**
```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='local_display';"
```
Should return: `1` (enabled)

**2. Check X Server:**
```bash
ps aux | grep Xorg
```

**3. Check display configuration:**
```bash
cat /home/andre/.xinitrc
```

**4. Check HDMI connection:**
```bash
tvservice -s
```

**5. Restart X Server:**
```bash
sudo systemctl restart localdisplay
sudo systemctl restart lightdm  # If using lightdm
```

### Enable Display (if disabled)

**Enable in database:**
```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
sudo systemctl restart localdisplay
```

### Common Issues

**Black screen:**
- Check HDMI cable
- Check display power
- Check: `tvservice -s` shows connected

**Chromium not starting:**
- Check logs: `sudo journalctl -u localdisplay -n 50`
- Check if X Server is running: `ps aux | grep Xorg`
- Restart: `sudo systemctl restart localdisplay`

**Wrong resolution/orientation:**
- Check: `cat /home/andre/.xinitrc`
- Check database: `sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';"`

---

**Quick Command:**
```bash
ssh andre@moode.local
sudo systemctl restart localdisplay
```

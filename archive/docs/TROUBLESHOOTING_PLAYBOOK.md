# TROUBLESHOOTING PLAYBOOK

**Purpose:** Structured methodology for diagnosing and fixing issues

---

## 🔍 TROUBLESHOOTING METHODOLOGY

### **Step 1: Understand the Problem**
1. **What is the expected behavior?**
2. **What is the actual behavior?**
3. **When did it start?**
4. **What changed recently?**

### **Step 2: Gather Information**
1. **Check system status:**
   ```bash
   systemctl status <service>
   journalctl -u <service> -n 50
   ```

2. **Check configuration:**
   ```bash
   # Find all relevant config files
   find /etc /boot -name "*config*" -type f
   # Check specific parameters
   grep -r "parameter" /etc /boot
   ```

3. **Check system-specific differences:**
   - Is this Pi 4 or Pi 5?
   - What OS/distribution?
   - What display server (X11/Wayland)?

### **Step 3: Research**
1. **Search codebase for similar issues**
2. **Check documentation**
3. **Look for system-specific requirements**
4. **Check service dependencies**

### **Step 4: Hypothesis & Test**
1. **Form hypothesis about root cause**
2. **Test hypothesis incrementally**
3. **Verify each step**
4. **Document findings**

### **Step 5: Implement Fix**
1. **Make minimal changes**
2. **Verify fix immediately**
3. **Test related functionality**
4. **Document solution**

---

## 🛠️ COMMON ISSUES & SOLUTIONS

### **Issue: Service Won't Start**

**Diagnosis:**
```bash
systemctl status <service>
journalctl -u <service> -n 50
systemctl cat <service>
```

**Common Causes:**
- Missing dependencies
- Configuration errors
- Permission issues
- Resource conflicts

**Solutions:**
- Check dependencies: `systemctl list-dependencies <service>`
- Check logs: `journalctl -u <service>`
- Test manually: Run command directly
- Check permissions: `ls -la /path/to/config`

---

### **Issue: Display Not Working**

**Diagnosis:**
```bash
xrandr --query
cat /sys/class/graphics/fb0/virtual_size
systemctl status localdisplay
```

**Common Causes:**
- Wrong resolution
- Incorrect rotation
- X server not running
- Chromium not starting

**Solutions:**
- Check framebuffer: `cat /sys/class/graphics/fb0/virtual_size`
- Check X11: `xrandr --query`
- Check rotation: `grep display_rotate /boot/config.txt /boot/firmware/config.txt`
- Restart service: `systemctl restart localdisplay`

---

### **Issue: Touchscreen Not Working**

**Diagnosis:**
```bash
xinput list
xinput list-props <device_id>
xinput test <device_id>
```

**Common Causes:**
- Device not detected
- Events disabled
- Wrong calibration matrix
- Touch events not converted to pointer events

**Solutions:**
- Check device: `xinput list | grep -i touch`
- Enable events: `xinput enable <device_id>`
- Set calibration: `xinput set-prop <device_id> "Coordinate Transformation Matrix" ...`
- Check Xorg config: `/etc/X11/xorg.conf.d/`

---

### **Issue: Configuration Not Applied**

**Diagnosis:**
```bash
# Check all possible locations
grep -r "parameter" /boot /etc
# Verify file was edited
ls -la /path/to/config
# Check if service reloaded
systemctl daemon-reload
```

**Common Causes:**
- Wrong file location
- Multiple config files
- Service not reloaded
- Changes overwritten

**Solutions:**
- Check all locations (Pi 5: both `/boot/` and `/boot/firmware/`)
- Reload systemd: `systemctl daemon-reload`
- Restart service: `systemctl restart <service>`
- Verify changes: `grep parameter /path/to/config`

---

### **Issue: Network Connection Failed**

**Diagnosis:**
```bash
ping <ip>
ssh -v <host>
nmap -sn <network>
```

**Common Causes:**
- IP address changed
- Network down
- SSH not running
- Firewall blocking

**Solutions:**
- Check IP: `ping <hostname>.local`
- Check SSH: `systemctl status ssh`
- Try different IP detection methods
- Update scripts with new IP

---

## 📋 VERIFICATION CHECKLIST

### **After Any Configuration Change:**
- [ ] Verify change in all relevant files
- [ ] Check if service needs reload: `systemctl daemon-reload`
- [ ] Restart affected service: `systemctl restart <service>`
- [ ] Check service status: `systemctl status <service>`
- [ ] Check logs: `journalctl -u <service> -n 20`
- [ ] Test functionality
- [ ] Document change

### **Before Making Changes:**
- [ ] Understand the problem completely
- [ ] Research similar issues
- [ ] Check system-specific requirements
- [ ] Backup current configuration
- [ ] Test in non-production if possible

---

## 🎯 BEST PRACTICES

1. **Always verify immediately after changes**
2. **Check all relevant configuration files**
3. **Test incrementally, not all at once**
4. **Document findings as you discover them**
5. **Complete diagnosis before attempting fixes**
6. **Research system-specific differences first**
7. **Check service dependencies before configuration**
8. **Keep troubleshooting notes for future reference**

---

**Last Updated:** 2025-12-04  
**Status:** Active reference document


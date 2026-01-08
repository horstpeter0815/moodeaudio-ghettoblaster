# Implementation Checklist

**Step-by-step checklist for implementing stable HDMI solution**

---

## PRE-IMPLEMENTATION

### Information Gathering
- [ ] Run `diagnose_pi5.sh` on Pi 5
- [ ] Review diagnostic output
- [ ] Note current kernel version
- [ ] Note current firmware version
- [ ] Note current Moode version
- [ ] Document current xrandr output
- [ ] Document current framebuffer

### Backup
- [ ] Create backup directory: `~/config_backups`
- [ ] Backup `/boot/firmware/config.txt`
- [ ] Backup `/boot/firmware/cmdline.txt`
- [ ] Backup `~/.xinitrc`
- [ ] Save current xrandr output
- [ ] Save current framebuffer output
- [ ] Test backup restore procedure
- [ ] Document backup location

### Preparation
- [ ] Read `STABLE_HDMI_SOLUTION_PLAN.md`
- [ ] Understand the approach
- [ ] Review `ALTERNATIVE_HDMI_CONFIGS.md`
- [ ] Have rollback plan ready
- [ ] Prepare test procedures

---

## PHASE 1: Remove Video Parameter

### Test Direct Landscape Start

- [ ] **Edit cmdline.txt:**
  ```bash
  sudo nano /boot/firmware/cmdline.txt
  # Remove: video=HDMI-A-2:400x1280M@60,rotate=90
  # Keep everything else
  ```

- [ ] **Save and reboot:**
  ```bash
  sudo reboot
  ```

- [ ] **After reboot, check:**
  ```bash
  xrandr
  fbset -s
  cat /sys/class/drm/card*/status
  ```

- [ ] **Document results:**
  - Does display start in Landscape?
  - What resolution does xrandr show?
  - What does framebuffer show?
  - Any errors in dmesg?

- [ ] **If successful:** Continue to Phase 2
- [ ] **If failed:** Try Approach 3 from ALTERNATIVE_HDMI_CONFIGS.md

---

## PHASE 2: Clean config.txt

### Optimize Configuration

- [ ] **Review current config.txt:**
  ```bash
  cat /boot/firmware/config.txt
  ```

- [ ] **Edit config.txt:**
  ```bash
  sudo nano /boot/firmware/config.txt
  ```

- [ ] **Ensure these settings:**
  ```ini
  [pi5]
  dtoverlay=vc4-kms-v3d-pi5,noaudio
  hdmi_enable_4kp60=0

  [all]
  dtoverlay=vc4-kms-v3d
  hdmi_group=2
  hdmi_mode=87
  hdmi_cvt 1280 400 60 6 0 0 0
  hdmi_force_hotplug=1
  hdmi_drive=2
  display_rotate=0
  ```

- [ ] **Remove DSI settings** (if not using DSI)
- [ ] **Save and reboot**

- [ ] **Test:**
  - Display works?
  - Correct resolution?
  - No errors?

---

## PHASE 3: Clean xinitrc

### Remove Forced Rotation

- [ ] **Backup xinitrc:**
  ```bash
  cp ~/.xinitrc ~/.xinitrc.backup
  ```

- [ ] **Edit xinitrc:**
  ```bash
  nano ~/.xinitrc
  ```

- [ ] **Remove forced rotation:**
  - Remove: `DISPLAY=:0 xrandr --output HDMI-2 --rotate left`
  - Let Moode handle rotation based on `hdmi_scn_orient`

- [ ] **Update Chromium:**
  - Use `$SCREEN_RES` instead of hardcoded `--window-size="1280,400"`
  - Or keep explicit if needed

- [ ] **Save and test:**
  ```bash
  # Restart X11 or reboot
  sudo reboot
  ```

- [ ] **Test:**
  - Chromium displays correctly?
  - No cut-off issues?
  - Moode UI works?

---

## PHASE 4: Touchscreen Configuration

### Configure Touchscreen

- [ ] **Identify touchscreen type:**
  ```bash
  lsusb | grep -i touch
  i2cdetect -y 1
  xinput list
  ```

- [ ] **Get device ID:**
  ```bash
  xinput list | grep -i touch
  ```

- [ ] **Test current behavior:**
  ```bash
  xinput test "Device Name"
  ```

- [ ] **Configure transformation matrix:**
  ```bash
  DEVICE_ID=$(xinput list | grep -i touch | grep -oP 'id=\K[0-9]+')
  xinput set-prop $DEVICE_ID "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
  ```

- [ ] **Test coordinates:**
  - Touch corners
  - Verify coordinates match display

- [ ] **Make permanent:**
  - Add to xinitrc or
  - Create xorg.conf.d file

- [ ] **Test:**
  - Touchscreen works correctly?
  - Coordinates match display?

---

## PHASE 5: Application Testing

### Test All Applications

- [ ] **Chromium:**
  - Moode UI displays correctly?
  - No cut-off?
  - Touch works?

- [ ] **Peppy Meter:**
  - Works correctly?
  - Correct resolution?
  - No orientation issues?

- [ ] **Other apps:**
  - Test any other applications
  - Verify they work

---

## PHASE 6: Finalization

### Documentation & Testing

- [ ] **Document final configuration:**
  - Final config.txt
  - Final cmdline.txt
  - Final xinitrc
  - Touchscreen configuration

- [ ] **Test update survival:**
  - Simulate Moode update (if possible)
  - Verify config preserved
  - Document results

- [ ] **Create restore procedure:**
  - Document how to restore
  - Test restore procedure
  - Keep backups

- [ ] **Final testing:**
  - Reboot multiple times
  - Verify stability
  - Test all features

---

## ROLLBACK PROCEDURE

### If Something Goes Wrong

- [ ] **Stop immediately**
- [ ] **Restore backups:**
  ```bash
  sudo cp ~/config_backups/config.txt.backup /boot/firmware/config.txt
  sudo cp ~/config_backups/cmdline.txt.backup /boot/firmware/cmdline.txt
  cp ~/config_backups/xinitrc.backup ~/.xinitrc
  ```

- [ ] **Reboot:**
  ```bash
  sudo reboot
  ```

- [ ] **Verify restore:**
  - System works?
  - Display works?
  - Back to working state?

- [ ] **Document what went wrong:**
  - What was tried?
  - What failed?
  - Why did it fail?

---

## SUCCESS VERIFICATION

### Final Checklist

- [ ] Display starts in Landscape (1280x400)
- [ ] No rotation workarounds needed
- [ ] Framebuffer reports correct resolution
- [ ] Chromium works correctly
- [ ] Touchscreen coordinates correct
- [ ] Peppy Meter works
- [ ] Configuration is clean
- [ ] All applications work
- [ ] System is stable
- [ ] Documentation complete

---

## NOTES

- Test each phase before moving to next
- Document everything
- Keep backups
- Have rollback plan ready

---

**Follow this checklist step by step!**


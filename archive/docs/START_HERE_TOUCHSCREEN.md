# START HERE - Touchscreen Fix

**Run these scripts in order. They will fix everything.**

---

## STEP 1: Fix Everything

```bash
# On Pi 5, run:
./fix_everything.sh
```

**This will:**
- Remove video parameter workaround
- Fix config.txt
- Fix xinitrc (remove forced rotation)
- Configure touchscreen
- Create backups

---

## STEP 2: Reboot

```bash
sudo reboot
```

**After reboot, the display should start in Landscape directly!**

---

## STEP 3: Verify Everything

```bash
./verify_everything.sh
```

**Should show:**
- ✅ All checks passed
- ✅ No errors
- ✅ Display is 1280x400 (normal, not rotated)
- ✅ Touchscreen configured

---

## STEP 4: Test Touchscreen

```bash
./test_touchscreen.sh
```

**Touch corners and verify coordinates:**
- Top-left: (0, 0)
- Top-right: (1280, 0)
- Bottom-left: (0, 400)
- Bottom-right: (1280, 400)

---

## STEP 5: Test Applications

- **Chromium:** Should work correctly, no cut-off
- **Peppy Meter:** Should work now!
- **Touch:** Should work everywhere

---

## IF COORDINATES ARE WRONG

```bash
./fix_touchscreen_coordinates.sh
```

**Follow interactive prompts to fix coordinates**

---

## SUCCESS CHECKLIST

Before considering it "done":

- [ ] Display starts Landscape (1280x400) - NO rotation
- [ ] xrandr shows "normal" not "left"
- [ ] Framebuffer shows 1280 400
- [ ] Touchscreen coordinates correct
- [ ] Chromium works
- [ ] Peppy Meter works
- [ ] verify_everything.sh shows all ✅
- [ ] Works after reboot

---

## ROLLBACK (If Needed)

```bash
# Restore from backup
sudo cp ~/config_backups_*/config.txt /boot/firmware/config.txt
sudo cp ~/config_backups_*/cmdline.txt /boot/firmware/cmdline.txt
cp ~/config_backups_*/xinitrc ~/.xinitrc
sudo reboot
```

---

**Run the scripts. Verify. Make it work. No excuses.**


# PEPPYMETER CONFIGURATION

**Date:** 2025-12-04  
**Issue:** One meter showing top-left, should be two meters centered

---

## CONFIGURATION FILES

### **Main Config: `/etc/peppymeter/config.txt`**
- width = 1280
- height = 400
- base.folder = /opt/peppymeter/1280x400
- current = gold

### **Meter Config: `/opt/peppymeter/1280x400/meters.txt`**
- channels = 2
- left.origin.x = 320
- left.origin.y = 200
- right.origin.x = 960
- right.origin.y = 200
- meter.x = 0
- meter.y = 0

---

## CURRENT STATUS

- **Config Location:** ✅ /etc/peppymeter/config.txt (primary location)
- **Meter Positions:** ✅ Configured for two meters at (320,200) and (960,200)
- **Window:** ✅ 1280x400 at 0,0
- **Service:** ✅ Active

---

## ISSUE

User reports:
- Only ONE meter displayed
- Position: Top-left (not centered)
- Bottom cut off
- Right side empty

This suggests:
1. Only left meter rendering (or both at same position)
2. Meter positioned at (0,0) instead of configured positions
3. Config might not be applied correctly

---

## NEXT STEPS

1. Verify config is being read (check logs)
2. Test if both meters are created
3. Check coordinate system
4. Verify background image layout

---

**Status:** Configuration is correct, but rendering issue persists.


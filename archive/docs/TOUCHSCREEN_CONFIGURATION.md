# Touchscreen Konfiguration - Waveshare 7.9" HDMI Display

**Datum:** $(date)  
**Hardware:** Raspberry Pi 5, Waveshare 7.9" HDMI LCD

---

## ✅ Touchscreen Status:

- ✅ **USB Device:** `ID 0712:000a WaveShare WaveShare`
- ✅ **Input Device:** `/dev/input/event7`
- ✅ **X11 Device:** `WaveShare WaveShare` (id=12)

---

## 📐 Transformation Matrix:

### Touchscreen Native:
- **X:** 0-4096
- **Y:** 0-4096

### Display:
- **Auflösung:** 1280x400
- **Rotation:** left (90° CCW)

### Transformation:
- **Rotation:** 90° CCW (X und Y vertauschen)
- **Skalierung X:** 1280/4096 = 0.3125
- **Skalierung Y:** 400/4096 = 0.09765625

### Matrix:
```
0          -0.09765625  1
0.3125      0           0
0           0           1
```

---

## 🔧 Konfiguration:

```bash
DISPLAY=:0 xinput set-prop 12 'Coordinate Transformation Matrix' \
  0 -0.09765625 1 0.3125 0 0 0 0 1
```

---

**Status:** ✅ **Touchscreen konfiguriert!**


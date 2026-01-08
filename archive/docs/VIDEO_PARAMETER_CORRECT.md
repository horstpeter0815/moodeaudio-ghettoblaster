# Video Parameter Korrektur

**Problem:** Display wird mit 1280 Höhe initialisiert, aber es ist nur 400 Pixel hoch!

---

## ✅ Korrekte Parameter

**Display physisch:** 1280x400 (Breite x Höhe)

**Nach Rotation 90°:** 400x1280 (Breite x Höhe)

**cmdline.txt Parameter:**
```
video=DSI-1:400x1280M@60,rotate=90
```

**Erklärung:**
- `400x1280` = Ziel-Auflösung NACH Rotation (Breite x Höhe)
- `rotate=90` = 90° Rotation
- Nach Rotation: 400 Breite, 1280 Höhe ✅

---

## ❌ Falscher Parameter

**FALSCH:**
```
video=DSI-1:1280x400M@60,rotate=90
```

**Warum falsch:**
- `1280x400` würde bedeuten: 1280 Höhe, 400 Breite
- Aber Display ist nur 400 Pixel hoch!
- Initialisiert mit 1280 Höhe → FALSCH!

---

## Forum-Referenz

**Im Forum (HDMI):**
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Bedeutung:**
- Display ist 400x1280 (rotated)
- `400x1280` = Ziel-Auflösung
- `rotate=90` = Rotation

**Für unser DSI Display (1280x400 physisch):**
- Ziel nach Rotation: 400x1280
- Parameter: `video=DSI-1:400x1280M@60,rotate=90` ✅

---

## Implementierung

**cmdline.txt:**
```
console=serial0,115200 console=tty1 root=PARTUUID=... rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE fbcon=map=1 video=DSI-1:400x1280M@60,rotate=90
```

**Wichtig:** `400x1280` (Höhe x Breite für rotiertes Display)!


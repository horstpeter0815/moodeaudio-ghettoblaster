# DISPLAY ROTATION - WEITERE ANALYSE

**Datum:** 02.12.2025  
**Status:** ❌ transform=rotate-270 funktioniert nicht  
**Weston läuft:** ✅ Ja

---

## 🔍 NEUE ERKENNTNISSE

### **1. Weston läuft:**
- ✅ Weston Service ist active
- ✅ Weston Process läuft (PID 1067)
- ✅ Cog läuft (PID 1077)
- ✅ Wayland Socket existiert

### **2. Weston.ini ist gesetzt:**
```ini
[output]
name=HDMI-A-1
transform=rotate-270
mode=1280x400@60
```

### **3. PROBLEM GEFUNDEN: Zwei video Parameter!**
```
video=HDMI-A-1:1280x720M@100
video=HDMI-A-1:1280x400@60
```

**Das ist ein Problem!** Zwei video Parameter können sich überschreiben oder konfliktieren.

---

## ⚠️ MÖGLICHE URSACHEN

1. **Zwei video Parameter im cmdline:**
   - Erster: `video=HDMI-A-1:1280x720M@100` (aus Kernel defaults?)
   - Zweiter: `video=HDMI-A-1:1280x400@60` (aus cmdline.txt)
   - Können sich überschreiben

2. **Weston transform wird ignoriert:**
   - Möglicherweise wird transform von video Parameter überschrieben
   - vc4-fkms-v3d könnte transform nicht unterstützen

3. **Display Hardware:**
   - Display im Sleep-Mode
   - Nur Backlight an
   - Kein Signal

---

## 📝 NÄCHSTE SCHRITTE

1. ✅ Prüfe weston-info Output
2. ✅ Entferne doppelten video Parameter
3. ✅ Prüfe ob transform wirklich angewendet wird
4. ✅ Alternative: vc4-kms-v3d statt vc4-fkms-v3d

---

**Status:** ⏳ Analyse läuft...


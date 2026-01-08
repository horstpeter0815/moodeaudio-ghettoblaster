# DISPLAY ROTATION - FINALE ROOT CAUSE ANALYSE

**Datum:** 02.12.2025  
**Status:** ❌ transform=rotate-270 funktioniert nicht  
**Weston läuft:** ✅ Ja

---

## 🔍 ROOT CAUSE IDENTIFIZIERT

### **Das Problem:**

1. **DRM Output zeigt beide Modi:**
   - `400x1280` (Portrait) ← Weston wählt diesen!
   - `1280x400` (Landscape)

2. **Weston sieht Display als Portrait:**
   ```
   logical_width: 400, logical_height: 1280  ← PORTRAIT!
   width: 400 px, height: 1280 px
   output_transform: 270°
   ```

3. **Weston.ini mode wird ignoriert:**
   - `mode=1280x400@60` in weston.ini wird nicht verwendet
   - Weston wählt automatisch `400x1280` (Portrait)

4. **transform=rotate-270 wird angewendet:**
   - Aber die Basis-Dimensionen sind falsch (400x1280 statt 1280x400)

---

## ⚠️ WARUM FUNKTIONIERT ES NICHT?

### **display_rotate=3 rotiert Hardware:**
- `display_rotate=3` rotiert das Framebuffer
- Aber DRM sieht das Display immer noch als 400x1280 (Portrait)
- Weston wählt automatisch den Portrait-Modus

### **Weston transform funktioniert nicht richtig:**
- `transform=rotate-270` wird angewendet
- Aber Weston denkt das Display ist 400x1280
- Rotation führt nicht zum gewünschten Ergebnis

---

## 💡 MÖGLICHE LÖSUNGEN

### **Lösung 1: mode=400x1280, transform=rotate-270**
```ini
[output]
name=HDMI-A-1
mode=400x1280@60
transform=rotate-270
```
**Idea:** Weston verwendet Portrait-Mode, rotiert zu Landscape

### **Lösung 2: display_rotate entfernen, nur Weston transform**
- Entferne `display_rotate=3` aus config.txt
- Nur `transform=rotate-270` in weston.ini
- **Problem:** Framebuffer wäre dann Portrait

### **Lösung 3: vc4-kms-v3d statt vc4-fkms-v3d**
- `vc4-kms-v3d` könnte transform besser unterstützen
- **Problem:** Erfordert Reboot und möglicherweise andere Probleme

### **Lösung 4: video Parameter mit rotate**
- `video=HDMI-A-1:1280x400@60,rotate=270` in cmdline.txt
- **Problem:** Könnte mit display_rotate=3 kollidieren

---

## 📝 NÄCHSTER SCHRITT

**Teste Lösung 1:** mode=400x1280@60, transform=rotate-270

**Wahrscheinlichkeit:** Unbekannt - muss getestet werden

---

**Status:** ⏳ Bereit für Test


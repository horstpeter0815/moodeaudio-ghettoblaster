# 480 Pixel Minimum Height Issue - DSI Display

**User-Hinweis:** "480" oder "480p" - möglicherweise gibt es eine Minimum-Anforderung von 480 Pixel Höhe!

---

## 🔍 Kern-Erkenntnis: Kernel behandelt 480 Pixel speziell!

### 1. Default LCD-Mode ist 800x480

**In `vc4_firmware_kms.c` (Zeile 1504-1510):**
```c
/* This is the DSI panel resolution. Use this as a default should the firmware
 * not respond to our request for the timings.
 */
static const struct drm_display_mode lcd_mode = {
	DRM_MODE("800x480", DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
		25979400 / 1000,
		800, 800 + 1, 800 + 1 + 2, 800 + 1 + 2 + 46, 0,
		480, 480 + 7, 480 + 7 + 2, 480 + 7 + 2 + 21, 0,
		0)
};
```

**Erkenntnis:** Der **Default LCD-Mode** ist **800x480** (480 Pixel hoch)!

---

### 2. Spezielle Behandlung für 480 Pixel in vc4_dsi.c

**In `vc4_dsi.c` (Zeile 894-906):**
```c
if (dsi->variant->port == 0 && mode->clock == 30000 &&
    mode->hdisplay == 800 && mode->htotal == (800 + 59 + 2 + 45) &&
    mode->vdisplay == 480 && mode->vtotal == (480 + 7 + 2 + 22)) {
    /*
     * Raspberry Pi 7" panel via TC358762 seems to have an issue on
     * DSI0 that it doesn't actually follow the vertical timing that
     * is otherwise identical to that produced on DSI1.
     * Fixup the mode.
     */
    htotal = 800 + 59 + 2 + 47;
    adjusted_mode->vtotal = 480 + 7 + 2 + 45;
    adjusted_mode->crtc_vtotal = 480 + 7 + 2 + 45;
}
```

**Erkenntnis:** Der Kernel hat **spezielle Behandlung für 480 Pixel Höhe** für das Raspberry Pi 7" Panel!

---

## ❗ Problem: Unser Display ist 1280x400, nicht 480!

**Unser Display:**
- **Auflösung:** 1280x400 (400 Pixel hoch)
- **Fehlend:** 80 Pixel Höhe gegenüber 480!

**Mögliche Probleme:**
1. **Kernel erwartet 480 Pixel** als Standard/Minimum
2. **Keine spezielle Behandlung für 400 Pixel** im Kernel
3. **FKMS Default-Mode ist 800x480**, nicht 1280x400
4. **Firmware meldet möglicherweise 480 als Minimum**

---

## 💡 Mögliche Lösungen

### Option 1: Display-Mode auf 480 Pixel ändern

**Idea:** Das Display als 1280x480 melden, auch wenn es physisch 1280x400 ist.

**Problem:** Das würde das Bild verzerren oder schneiden.

---

### Option 2: Driver-Patch für 400 Pixel Höhe

**Idea:** Ähnliche spezielle Behandlung für 400 Pixel wie für 480 Pixel hinzufügen.

**Code-Änderung:**
```c
// In panel-waveshare-dsi.c oder vc4_dsi.c
if (mode->vdisplay == 400 && ...) {
    // Spezielle Behandlung für 400 Pixel Höhe
    adjusted_mode->vtotal = 400 + 7 + 2 + 45;
    adjusted_mode->crtc_vtotal = 400 + 7 + 2 + 45;
}
```

---

### Option 3: xinitrc Hack für "480p minimum"

**Idea:** xinitrc-Hack der das Display als 480 hoch meldet oder einen 480p-Modus erzwingt.

**Möglicher Hack:**
```bash
# In /home/andre/.xinitrc
# Force 480p mode for DSI displays with 400 pixel height
if [ $DSI_SCN_TYPE = 'other' ] && [ $(echo $SCREEN_RES | cut -d',' -f2) -lt 480 ]; then
    # Add padding or force 480p mode
    SCREEN_RES="1280,480"
    DISPLAY=:0 xrandr --output DSI-1 --mode 1280x480
fi
```

---

### Option 4: FKMS Default-Mode ändern

**Idea:** Den Default-Mode in `vc4_firmware_kms.c` auf 1280x400 ändern.

**Problem:** Erfordert Kernel-Patch.

---

## 🔬 Was zu prüfen ist

1. **Prüfe Firmware-Meldung:**
   ```bash
   vcgencmd get_display_mode
   vcgencmd display_power
   ```

2. **Prüfe ob 480 als Minimum erwartet wird:**
   ```bash
   cat /sys/class/drm/card1-DSI-1/modes
   modetest -c
   ```

3. **Prüfe FKMS LCD-Mode:**
   ```bash
   dmesg | grep -i "lcd_mode\|800x480\|400"
   ```

4. **Prüfe ob Firmware 480 meldet:**
   ```bash
   vcgencmd display_power 0
   vcgencmd display_power 1
   dmesg | tail -20
   ```

---

## 📝 Nächste Schritte

1. **Prüfe ob FKMS 480 als Default verwendet:**
   - Wenn Firmware nicht antwortet, verwendet FKMS 800x480
   - Unser Display ist 1280x400 → Mismatch!

2. **Prüfe ob 480 Minimum-Requirement ist:**
   - Kernel-Code zeigt spezielle Behandlung für 480
   - Vielleicht gibt es eine Minimum-Anforderung

3. **Suche nach xinitrc-Hack für 480:**
   - User sagt "480" war sein Beitrag
   - Möglicherweise ein Hack um 400 als 480 zu melden

4. **Prüfe Waveshare Driver:**
   - Panel-Mode für 7.9" ist 1280x400
   - Vielleicht muss der Driver-Mode angepasst werden

---

**Quelle:** Kernel-Code Analyse  
**User-Hinweis:** "480" oder "480p" - möglicherweise Minimum-Requirement!


# CRTC Problem - Root Cause Analysis

**Problem:** `possible_crtcs=0x0` für DSI-32 Encoder

---

## 🔍 Root Cause gefunden!

### Code-Analyse: `vc4_fkms_create_screen()` (Zeile 1900)

```c
vc4_encoder->base.possible_crtcs |= drm_crtc_mask(crtc);
```

**Bedeutung:**
- Encoder `possible_crtcs` wird **NUR** gesetzt, wenn `vc4_fkms_create_screen()` aufgerufen wird
- `possible_crtcs` wird mit `drm_crtc_mask(crtc)` gesetzt
- **ABER:** Wenn kein CRTC erstellt wird → `possible_crtcs` bleibt `0x0`!

---

## ❌ Warum wird kein CRTC für DSI erstellt?

### Schritt 1: Firmware fragt nach Displays (Zeile 1961-1973)

```c
ret = rpi_firmware_property(vc4->firmware,
            RPI_FIRMWARE_FRAMEBUFFER_GET_NUM_DISPLAYS,
            &num_displays, sizeof(u32));

if (ret) {
    num_displays = 1;  // Fallback zu 1 Display
}
```

**Problem:** 
- Wenn Firmware **DSI nicht meldet** → `num_displays` enthält DSI nicht
- `num_displays` könnte nur HDMI enthalten (z.B. `num_displays = 1` für HDMI)

---

### Schritt 2: Für jedes Display CRTC erstellen (Zeile 1993-2010)

```c
for (display_num = 0; display_num < num_displays; display_num++) {
    display_id = display_num;
    ret = rpi_firmware_property(vc4->firmware,
                    RPI_FIRMWARE_FRAMEBUFFER_GET_DISPLAY_ID,
                    &display_id, sizeof(display_id));
    
    if (ret)
        continue;  // Überspringen wenn Fehler
    
    ret = vc4_fkms_create_screen(dev, drm, display_num, display_id,
                     &crtc_list[display_num]);
    if (ret)
        continue;  // Überspringen wenn Fehler
}
```

**Problem:**
- **NUR** für Displays in `num_displays` wird `vc4_fkms_create_screen()` aufgerufen
- Wenn DSI **nicht in `num_displays`** ist → wird übersprungen!
- **Ergebnis:** Kein CRTC für DSI!

---

### Schritt 3: DSI-Encoder existiert, aber ohne CRTC

**Was passiert:**
- DSI-Encoder wird vom **Waveshare Panel Driver** erstellt (separat!)
- DSI-Connector wird vom **Waveshare Panel Driver** erstellt
- **ABER:** CRTC wird **nur** von FKMS erstellt (wenn Firmware DSI meldet)
- Wenn Firmware DSI **nicht meldet** → kein CRTC!
- DSI-Encoder hat `possible_crtcs=0x0` → **Fehler!**

---

## 🎯 Das Problem im Detail

**Sequenz:**
1. **Firmware** wird gefragt: "Wie viele Displays?"
2. **Firmware antwortet:** "1 Display" (nur HDMI, DSI wird nicht gemeldet)
3. **FKMS erstellt CRTC** nur für HDMI
4. **Waveshare Driver** erstellt DSI-Encoder und Connector (separat!)
5. **DSI-Encoder** hat `possible_crtcs=0x0` → **Fehler!**

**Warum meldet Firmware DSI nicht?**
- Firmware kennt DSI möglicherweise nicht
- Oder DSI ist nicht in Firmware-Konfiguration
- Oder FKMS fragt Firmware zu früh (bevor DSI initialisiert ist)

---

## 💡 Mögliche Lösungen

### Lösung 1: Firmware zwingen DSI zu melden
- Prüfe ob DSI in Firmware-Konfiguration ist
- Prüfe Timing (wird Firmware zu früh gefragt?)
- Prüfe Device Tree (wird DSI richtig konfiguriert?)

### Lösung 2: CRTC manuell für DSI erstellen
- Falls Firmware DSI nicht meldet
- Manuell `vc4_fkms_create_screen()` für DSI aufrufen
- Oder CRTC-Binding manuell setzen

### Lösung 3: True KMS verwenden
- True KMS erstellt CRTCs **direkt**, nicht über Firmware
- Vielleicht funktioniert DSI besser mit True KMS

### Lösung 4: Double Rotation Hack
- Vielleicht hilft `video=DSI-1:400x1280M@60,rotate=90`
- Display startet im Portrait-Mode
- Vielleicht meldet Firmware DSI dann?

---

## 🔬 Prüfung

**Zu prüfen:**
```bash
# Prüfe was Firmware meldet
vcgencmd get_display_mode
vcgencmd display_power

# Prüfe dmesg nach Firmware-Meldungen
dmesg | grep -i "num_displays\|display_id\|create_screen"

# Prüfe ob DSI in Firmware-Liste ist
# (schwierig, aber dmesg könnte Hinweise geben)
```

---

**Status:** Root Cause identifiziert - Firmware meldet DSI nicht, daher wird kein CRTC erstellt!


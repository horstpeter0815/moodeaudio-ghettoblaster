# Action Plan für Morgen - Waveshare 7.9" DSI LCD

**Datum:** 2025-11-26  
**Status:** Bereit für systematische Lösung

---

## 🎯 Hauptziel

Waveshare 7.9" DSI LCD zum Laufen bringen - Display zeigt Bild

---

## 🔍 Kritische Erkenntnis von Heute

**Es gibt ZWEI verschiedene Waveshare-Overlays:**
- `vc4-kms-dsi-waveshare-panel` → für **echtes KMS** (`vc4-kms-v3d`)
- `vc4-fkms-dsi-waveshare-panel` → für **FKMS** (`vc4-fkms-v3d`)

**Wir haben bisher IMMER das falsche Overlay verwendet:**
- Mit FKMS haben wir `vc4-kms-dsi-waveshare-panel` verwendet ❌
- Das passt nicht zusammen!

---

## 📋 Schritt-für-Schritt Plan

### **Phase 1: FKMS-Overlay prüfen (15-30 Min)**

#### Schritt 1.1: Prüfe ob FKMS-Overlay existiert
```bash
ls -la /boot/firmware/overlays/vc4-fkms-dsi-waveshare-panel.dtbo
ls -la /boot/overlays/vc4-fkms-dsi-waveshare-panel.dtbo
```

**Erwartetes Ergebnis:**
- ✅ Datei existiert → Weiter zu Schritt 1.2
- ❌ Datei existiert nicht → Weiter zu Phase 2

#### Schritt 1.2: Teste FKMS + FKMS-Overlay
**Config ändern:**
```
dtoverlay=vc4-fkms-v3d
dtoverlay=vc4-fkms-dsi-waveshare-panel,7_9_inch,i2c1,dsi1
```

**System rebooten und prüfen:**
```bash
# DSI-1 Status
cat /sys/class/drm/card1-DSI-1/status
cat /sys/class/drm/card1-DSI-1/enabled

# CRTC-Info
dmesg | grep -iE 'crtc|Bogus|possible_crtc'

# Framebuffer
ls -la /dev/fb*
```

**Erfolg-Kriterien:**
- ✅ DSI-1 ist `enabled` (nicht nur `connected`)
- ✅ `/dev/fb0` existiert
- ✅ Keine "Bogus possible_crtcs" Fehler
- ✅ Display zeigt Bild

**Wenn erfolgreich:** ✅ **FERTIG!**

**Wenn fehlgeschlagen:** Weiter zu Phase 2

---

### **Phase 2: FKMS-Overlay von Waveshare holen (30-60 Min)**

#### Schritt 2.1: Waveshare Repository prüfen
```bash
# Prüfe ob wir das Repository haben
ls -la kernel-build/ | grep waveshare

# Oder: Suche nach Waveshare-Overlays im System
find /boot -name "*waveshare*" -o -name "*fkms*"
```

#### Schritt 2.2: Waveshare GitHub Repository durchsuchen
**URL:** https://github.com/waveshare/7.9inch-DSI-LCD

**Was suchen:**
- `vc4-fkms-dsi-waveshare-panel.dts` oder `.dtbo`
- Offizielle Config-Beispiele
- Installation-Skripte
- Bekannte Issues

#### Schritt 2.3: Overlay kompilieren (falls .dts vorhanden)
```bash
# Falls .dts gefunden:
dtc -@ -I dts -O dtb -o vc4-fkms-dsi-waveshare-panel.dtbo vc4-fkms-dsi-waveshare-panel.dts

# Kopiere nach /boot/firmware/overlays/
sudo cp vc4-fkms-dsi-waveshare-panel.dtbo /boot/firmware/overlays/
```

**Dann:** Zurück zu Phase 1, Schritt 1.2

---

### **Phase 3: Echtes KMS debuggen (60-90 Min)**

**Nur wenn Phase 1 & 2 fehlschlagen**

#### Schritt 3.1: Warum wird DSI-1 nicht erkannt?
**Config:**
```
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1,dsi1
```

**Debug-Commands:**
```bash
# Prüfe ob DSI-1 existiert
ls -la /sys/class/drm/ | grep DSI

# Prüfe DSI-Host
dmesg | grep -iE 'dsi.*host|dsi.*bound|dsi.*attach'

# Prüfe Panel-Driver
dmesg | grep -iE 'panel.*waveshare|ws_panel'

# Prüfe Device Tree
find /proc/device-tree -name "*dsi*" -o -name "*panel*"
```

#### Schritt 3.2: Overlay-Parameter anpassen
**Mögliche Parameter:**
- `dsi0` statt `dsi1`
- `i2c0` statt `i2c1`
- Weitere Parameter prüfen

#### Schritt 3.3: Kernel-Parameter testen
**cmdline.txt anpassen:**
```
video=DSI-1:1280x400@60
# oder
video=DSI-0:1280x400@60
```

---

### **Phase 4: Alternative Lösungen (Last Resort)**

**Nur wenn Phase 1-3 alle fehlschlagen**

#### Option 4.1: Direkter Framebuffer
- Ohne DRM/KMS arbeiten
- Direkt auf `/dev/fb0` schreiben
- Für einfache Anzeigen

#### Option 4.2: Display-Manager installieren
- X11 mit fbdev
- Wayland (Weston)
- DirectFB

#### Option 4.3: Custom Overlay erstellen
- Device Tree Overlay anpassen
- CRTC explizit definieren
- Sehr komplex

---

## 📊 Aktueller System-Status

### Was funktioniert:
- ✅ Panel-Driver lädt: `panel-waveshare-dsi`
- ✅ I2C funktioniert: `1-0045` (Panel), `1-0014` (Touchscreen)
- ✅ Backlight existiert: `/sys/class/backlight/1-0045`
- ✅ DSI-1 erkannt (mit FKMS): `connected`, `1280x400`

### Was nicht funktioniert:
- ❌ DSI-1 bleibt `disabled` (kein CRTC)
- ❌ Kein Framebuffer (`/dev/fb0` existiert nicht)
- ❌ Display zeigt kein Bild

### Aktuelle Config:
```
dtoverlay=vc4-fkms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1,dsi1
```

**Problem:** FKMS mit KMS-Overlay - passt nicht!

---

## 🎯 Erwartetes Ergebnis

**Nach erfolgreicher Phase 1:**
```
dtoverlay=vc4-fkms-v3d
dtoverlay=vc4-fkms-dsi-waveshare-panel,7_9_inch,i2c1,dsi1
```

**System zeigt:**
- DSI-1: `enabled` (nicht nur `connected`)
- `/dev/fb0` existiert mit `1280x400`
- Display zeigt Bild
- Keine CRTC-Fehler

---

## 📝 Notizen für Morgen

1. **Wichtig:** Wir haben das falsche Overlay verwendet!
2. **Erste Aktion:** Prüfe ob `vc4-fkms-dsi-waveshare-panel.dtbo` existiert
3. **Falls nicht:** Waveshare Repository durchsuchen
4. **Systematisch vorgehen:** Eine Phase nach der anderen

---

## 🔗 Wichtige Links

- Waveshare Repository: https://github.com/waveshare/7.9inch-DSI-LCD
- Raspberry Pi DSI Docs: https://www.raspberrypi.com/documentation/computers/display.html
- VC4 DRM Driver: https://github.com/raspberrypi/linux/tree/rpi-6.12.y/drivers/gpu/drm/vc4

---

**Viel Erfolg morgen! 🚀**


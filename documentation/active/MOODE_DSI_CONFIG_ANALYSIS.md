# Moode DSI Konfiguration - Analyse

**User-Frage:** Muss DSI in Moode Web-UI konfiguriert werden?

---

## ✅ DSI ist in Moode konfiguriert

**Datenbank-Werte:**
```
dsi_scn_type=other ✅
dsi_port=1 ✅
dsi_scn_rotate=90 ✅
local_display=1 ✅
```

---

## 🔍 Was Moode mit DSI macht

### Für `dsi_scn_type='1'` (Touch1):
- Moode ändert **config.txt** mit `updBootConfigTxt('upd_dsi_scn_rotate')`
- Rotation wird in **cmdline.txt** gesetzt

### Für `dsi_scn_type='2' || 'other'` (Touch2/Other):
- Moode ändert **NICHT config.txt**!
- Rotation wird **nur in xinitrc** behandelt
- Code: `// Only update the touch angle here, xinitrc handles rotation value`

---

## ⚠️ WICHTIGE ERKENNTNIS!

**Bei `dsi_scn_type=other`:**
- Moode konfiguriert **nur xinitrc** (für X11)
- Moode konfiguriert **NICHT config.txt** oder Device Tree!
- **config.txt muss manuell** konfiguriert werden!

**Das bedeutet:**
- Wir müssen **manuell** das Waveshare Overlay in `config.txt` setzen
- Moode hilft **nicht** bei Device Tree Konfiguration
- **ABER:** Moode konfiguriert xinitrc für X11 (falls X11 läuft)

---

## 🎯 Warum das CRTC-Problem bleibt

**Auch wenn DSI in Moode konfiguriert ist:**
- Moode konfiguriert **nur xinitrc** (für X11)
- Moode konfiguriert **nicht** die Firmware!
- **Firmware** wird separat initialisiert (durch Device Tree)
- **FKMS** fragt Firmware nach Displays
- **Firmware** meldet möglicherweise DSI nicht → kein CRTC!

**Moode-Konfiguration hilft NICHT bei CRTC-Problem!**

---

## 💡 Mögliche Lösung

**Vielleicht gibt es eine andere Moode-Einstellung?**

**Zu prüfen:**
1. Gibt es eine "Display Enable" Option in Web-UI?
2. Gibt es eine "DSI Enable" Option?
3. Muss `local_display=1` sein, damit Firmware DSI erkennt?

---

**Status:** DSI ist in Moode konfiguriert, aber das hilft nicht bei CRTC-Problem (Firmware-Problem)!


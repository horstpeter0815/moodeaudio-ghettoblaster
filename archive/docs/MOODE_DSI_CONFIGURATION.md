# Moode Audio DSI Konfiguration

**User-Frage:** Muss DSI in der Moode Web-Interface konfiguriert werden?

---

## 🔍 Prüfung: Moode DSI-Konfiguration

### Datenbank-Parameter

**DSI-bezogene Parameter:**
- `dsi_port` = Port-Nummer (1, 2, etc.)
- `dsi_scn_type` = Screen Type ('none', '2', 'other')
- `dsi_scn_rotate` = Rotation (0, 90, 180, 270)
- `local_display` = Web-UI Display aktiviert? (0/1)

---

## ⚠️ WICHTIGE ERKENNTNIS!

**Vielleicht muss DSI in Moode Web-UI aktiviert werden!**

**Mögliche Probleme:**
1. **DSI nicht in Web-UI aktiviert** → Firmware erkennt es nicht
2. **DSI falsch konfiguriert** → Firmware meldet es falsch
3. **Display-Type falsch** → FKMS erstellt keinen CRTC

---

## 🔧 Moode Web-Interface Konfiguration

**Zu prüfen:**
1. **System → Local Display** aktiviert?
2. **DSI Port** richtig konfiguriert?
3. **DSI Screen Type** richtig gesetzt?
4. **DSI Rotation** richtig?

**Möglicherweise:**
- Wenn DSI nicht in Web-UI aktiviert ist
- Wird es möglicherweise nicht richtig initialisiert
- Firmware erkennt es dann nicht
- FKMS erstellt keinen CRTC

---

**Status:** Prüfe jetzt Moode-Konfiguration!


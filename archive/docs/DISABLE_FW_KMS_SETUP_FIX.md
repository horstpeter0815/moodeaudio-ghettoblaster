# disable_fw_kms_setup Fix

**Gefunden:** `disable_fw_kms_setup=1` in config.txt!

**Änderung:** Auf `disable_fw_kms_setup=0` gesetzt!

---

## Was macht dieser Parameter?

**`disable_fw_kms_setup=1`:**
- Verhindert möglicherweise Firmware KMS Setup
- Kann CRTC-Erstellung blockieren
- Kann Firmware-Display-Abfrage blockieren

**`disable_fw_kms_setup=0`:**
- Erlaubt Firmware KMS Setup
- FKMS kann Firmware nach Displays fragen
- FKMS kann CRTCs erstellen

---

## Nächster Schritt

**Reboot erforderlich!**

Nach Reboot prüfen:
1. Wird CRTC für DSI erstellt?
2. Ist Display "enabled" statt "disabled"?
3. Gibt es noch `possible_crtcs=0x0` Fehler?

---

**Status:** `disable_fw_kms_setup=0` gesetzt - Reboot erforderlich!


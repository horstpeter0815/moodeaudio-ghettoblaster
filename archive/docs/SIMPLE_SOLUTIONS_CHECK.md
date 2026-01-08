# Einfache Lösungen prüfen

## Mögliche einfache Lösungen:

### 1. FKMS statt True KMS?
- ⏳ Aktuell: `vc4-kms-v3d` (True KMS)
- ⏳ Prüfe: `vc4-fkms-v3d` (Fake KMS)
- **Warum:** FKMS hat andere CRTC-Erstellung (vielleicht besser für DSI?)

### 2. Config-Parameter die wir noch nicht probiert haben?
- ⏳ `display_auto_detect=1` statt `0`?
- ⏳ `dsi1_init=1` oder `dsi0_init=1`?
- ⏳ `ignore_lcd=0` oder `1`?
- ⏳ `video=` Parameter in cmdline.txt?

### 3. Overlay-Reihenfolge?
- ⏳ Muss Waveshare Overlay wirklich am Ende sein?
- ⏳ Muss vc4-kms-v3d vor Waveshare sein?

### 4. Firmware-KMS Setup?
- ⏳ `disable_fw_kms_setup=0` ist gesetzt
- ⏳ Aber vielleicht braucht es andere Parameter?

## Prüfe jetzt:

1. Welcher KMS Driver wird verwendet?
2. Welche Config-Parameter sind gesetzt?
3. Was meldet die Firmware?

---

**Status:** Prüfe alle einfachen Lösungen zuerst...


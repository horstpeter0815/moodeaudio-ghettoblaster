# True KMS Test

**Änderung:** `vc4-fkms-v3d` → `vc4-kms-v3d-pi4,noaudio`

**Grund:**
- FKMS hat CRTC-Problem (Firmware meldet DSI nicht)
- True KMS erstellt CRTCs direkt, nicht über Firmware
- True KMS könnte DSI besser unterstützen

---

## Änderungen in config.txt

**Vorher:**
```
dtoverlay=vc4-fkms-v3d
```

**Nachher:**
```
dtoverlay=vc4-kms-v3d-pi4,noaudio
```

---

## Nächster Schritt

**Reboot erforderlich!**

Nach Reboot prüfen:
1. Wird DSI-1 erkannt?
2. Wird CRTC erstellt?
3. Ist Display enabled?

---

**Status:** True KMS aktiviert - Reboot erforderlich!


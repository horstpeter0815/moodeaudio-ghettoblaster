# Tonight's Research Findings - CRTC Problem

**Date:** 2025-11-25  
**Status:** In Progress

## Research Questions

1. Warum erstellt fkms keinen CRTC für DSI?
2. Wie sollte Waveshare Overlay konfiguriert sein?
3. Warum funktioniert echtes KMS nicht (DSI-1 fehlt)?
4. Gibt es bekannte Lösungen?

---

## Finding 1: HiFiBerry verwendet fkms

**Source:** `hifiberry-os/buildroot/package/enable-vc4kms/enable-vc4kms.mk`

```makefile
echo "dtoverlay=vc4-fkms-v3d,audio=off" >> $(BINARIES_DIR)/rpi-firmware/config.txt
```

**Erkenntnis:** HiFiBerry OS verwendet fkms standardmäßig, aber wahrscheinlich nur für HDMI, nicht für DSI.

---

## Finding 2: Waveshare empfiehlt vc4-kms-v3d (NICHT fkms!)

**Source:** Web Search Results

Waveshare Dokumentation empfiehlt:
```
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

**KRITISCH:** Waveshare verwendet **echtes KMS** (`vc4-kms-v3d`), **NICHT** `vc4-fkms-v3d`!

**Das könnte das Problem sein!** fkms unterstützt möglicherweise DSI nicht richtig.

---

## Finding 3: Waveshare Installation Script

**Source:** Web Search Results

Waveshare bietet Installation Script:
```bash
sudo bash ./WS_xinchDSI_MAIN.sh 79 I2C1
```

**Frage:** Was macht dieses Script genau? Installiert es einen Custom Driver oder konfiguriert es nur das Overlay?

---

## Next Steps

1. **Waveshare Overlay Source analysieren** - Wie ist es strukturiert?
2. **fkms Source Code prüfen** - Unterstützt es DSI?
3. **Echtes KMS Problem analysieren** - Warum wird DSI-1 nicht erkannt?

---

## Hypothesis

**Hypothese:** fkms unterstützt DSI nicht richtig oder braucht spezielle Konfiguration. Waveshare empfiehlt echtes KMS, aber bei uns funktioniert echtes KMS nicht (DSI-1 fehlt).

**Mögliche Lösung:** 
- Echtes KMS verwenden, aber Overlay-Konfiguration anpassen
- Oder: fkms patchen/konfigurieren für DSI-Support

---

## Finding 4: Waveshare Overlay Structure

**Source:** `vc4-kms-dsi-waveshare-panel-overlay.dts`

**Key Points:**
1. **Standard I2C:** `i2c_csi_dsi` (DSI I2C Bus 10)
2. **Alternative:** `i2c1` Parameter wechselt zu GPIO I2C (Bus 1)
3. **Panel Definition:** `panel_disp1@45` mit `compatible = "waveshare,7.9inch-panel"`
4. **DSI Connection:** `dsi_out` → `panel_in` endpoint connection
5. **KEIN explizites CRTC** im Overlay!

**7.9" Panel Override:**
```dts
7_9_inch = <&panel>, "compatible=waveshare,7.9inch-panel",
           <&touch>, "touchscreen-size-x:0=1280",
           <&touch>, "touchscreen-size-y:0=400",
```

**I2C1 Parameter:**
```dts
i2c1 = <&i2c_frag>, "target:0=",<&i2c1>,
       <0>, "-3-4+5";
```

**Erkenntnis:** Overlay ist korrekt strukturiert, aber CRTC wird nicht explizit definiert - wird von KMS erwartet.

---

## Finding 5: Waveshare empfiehlt echtes KMS

**Source:** Web Search + Waveshare Dokumentation

**Empfohlene Config:**
```
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

**NICHT:**
```
dtoverlay=vc4-fkms-v3d  # ← Das verwenden wir!
```

**KRITISCH:** fkms wird von Waveshare NICHT empfohlen!

---

## Root Cause Hypothesis

**Problem:** fkms erstellt keinen CRTC für DSI, weil:
1. fkms ist primär für HDMI designed
2. DSI-Support in fkms ist limitiert oder fehlt
3. Waveshare Overlay erwartet echtes KMS

**Warum echtes KMS nicht funktioniert:**
- Mit `vc4-kms-v3d-pi4` wird DSI-1 nicht erkannt
- Möglicherweise Overlay-Konflikt oder falsche Reihenfolge

---

## Action Plan

### Option 1: Echtes KMS verwenden (Waveshare Empfehlung)

**Versuch:**
1. `vc4-fkms-v3d` → `vc4-kms-v3d` ändern
2. Overlay-Reihenfolge prüfen
3. Möglicherweise `vc4-kms-v3d-pi4` statt generischem `vc4-kms-v3d`

**Problem:** Bei uns funktioniert echtes KMS nicht (DSI-1 fehlt)

### Option 2: fkms für DSI patchen

**Versuch:**
1. fkms Source Code analysieren
2. DSI CRTC-Support hinzufügen
3. Oder: Workaround finden

**Problem:** Komplex, braucht Kernel-Patch

### Option 3: Overlay anpassen

**Versuch:**
1. CRTC explizit im Overlay definieren
2. Oder: Overlay-Parameter anpassen

**Problem:** Unklar ob fkms das unterstützt

---

## Next Steps

1. **Test:** `vc4-kms-v3d` (nicht pi4-spezifisch) verwenden
2. **Analysieren:** Warum wird DSI-1 nicht erkannt mit echtem KMS?
3. **Recherchieren:** fkms Source Code für DSI-Support

---

**Status:** Research continues... Key finding: Waveshare empfiehlt echtes KMS, nicht fkms!


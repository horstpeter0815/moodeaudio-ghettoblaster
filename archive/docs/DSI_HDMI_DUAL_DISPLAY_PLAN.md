# DSI + HDMI DUAL DISPLAY - PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**System:** Ghettoblaster (Pi 5)  
**Zweck:** DSI und HDMI gleichzeitig aktivieren

---

## 🎯 ANFORDERUNGEN

**Display-Ausgänge:**
- ✅ **DSI Display:** WaveShare 1280x400 (aktuell aktiv)
- ✅ **HDMI Display:** Zusätzlicher HDMI-Monitor
- ✅ **Beide gleichzeitig:** Dual-Display Setup

---

## 📋 RASPBERRY PI 5 DISPLAY-SYSTEM

**Raspberry Pi 5 unterstützt:**
- ✅ DSI (Display Serial Interface) - Touchscreen
- ✅ HDMI (High-Definition Multimedia Interface)
- ✅ Beide gleichzeitig (Multi-Display)

**Aktuelle Konfiguration:**
- DSI: WaveShare 1280x400 Touchscreen
- HDMI: Nicht konfiguriert

---

## 🔧 IMPLEMENTIERUNGS-OPTIONEN

### **Option 1: X11 Multi-Display (Empfohlen)**

**Konfiguration:**
- DSI als primäres Display
- HDMI als sekundäres Display
- X11 erkennt beide automatisch

**Vorteile:**
- ✅ Standard X11 Multi-Display
- ✅ Einfach zu konfigurieren
- ✅ Beide Displays unabhängig steuerbar

---

### **Option 2: Mirrored Display**

**Konfiguration:**
- Gleicher Inhalt auf beiden Displays
- DSI und HDMI zeigen dasselbe

**Vorteile:**
- ✅ Einfache Konfiguration
- ✅ Gleiche Anzeige

**Nachteile:**
- ⚠️ Unterschiedliche Auflösungen problematisch

---

### **Option 3: Extended Desktop**

**Konfiguration:**
- DSI: Haupt-Display (Web-UI)
- HDMI: Erweitertes Display (PeppyMeter oder andere Anzeige)

**Vorteile:**
- ✅ Maximale Flexibilität
- ✅ Verschiedene Inhalte pro Display

---

## 📋 KONFIGURATION

### **1. Boot-Konfiguration (`/boot/firmware/config.txt`)**

**Aktuell:**
```
display_rotate=3
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
```

**Neu (DSI + HDMI):**
```
# DSI Display (WaveShare 1280x400)
display_rotate=3
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-7inch

# HDMI Display
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1920 1080 60 6 0 0 0  # Beispiel: Full HD
# Oder automatisch:
# hdmi_group=0  # Auto-detect
```

---

### **2. X11 Konfiguration**

**Multi-Display Setup:**
```bash
# Prüfe verfügbare Displays
xrandr --query

# DSI Display konfigurieren
xrandr --output DSI-1 --mode 1280x400 --rotate left

# HDMI Display konfigurieren
xrandr --output HDMI-1 --mode 1920x1080 --right-of DSI-1
```

---

### **3. Chromium Multi-Display**

**Option A: Chromium auf DSI, PeppyMeter auf HDMI**
```bash
# Chromium auf DSI
DISPLAY=:0.0 chromium-browser --kiosk --display=:0.0 http://localhost

# PeppyMeter auf HDMI
DISPLAY=:0.1 python3 /opt/peppymeter/peppymeter.py
```

**Option B: Extended Desktop**
```bash
# Chromium auf beiden Displays (Fullscreen auf primärem)
DISPLAY=:0 chromium-browser --kiosk http://localhost
```

---

## 🔧 IMPLEMENTIERUNGS-SCHRITTE

### **PHASE 1: Boot-Konfiguration**

**Script: `enable-dual-display.sh`**
```bash
#!/bin/bash
# Aktiviert DSI und HDMI gleichzeitig

CONFIG_FILE="/boot/firmware/config.txt"

# DSI Overlay hinzufügen (falls nicht vorhanden)
if ! grep -q "dtoverlay=vc4-kms-dsi-7inch" "$CONFIG_FILE"; then
    echo "dtoverlay=vc4-kms-dsi-7inch" >> "$CONFIG_FILE"
fi

# HDMI Konfiguration
if ! grep -q "hdmi_group=0" "$CONFIG_FILE"; then
    echo "hdmi_group=0" >> "$CONFIG_FILE"  # Auto-detect
fi

# KMS aktivieren (für Multi-Display)
if ! grep -q "dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
    echo "dtoverlay=vc4-kms-v3d" >> "$CONFIG_FILE"
fi
```

---

### **PHASE 2: X11 Multi-Display Setup**

**Script: `setup-multi-display.sh`**
```bash
#!/bin/bash
# Konfiguriert X11 für Multi-Display

export DISPLAY=:0

# Warte auf X Server
for i in {1..30}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 1
done

# Prüfe verfügbare Displays
DSI_DISPLAY=$(xrandr --query | grep -i "DSI" | awk '{print $1}' | head -1)
HDMI_DISPLAY=$(xrandr --query | grep -i "HDMI" | awk '{print $1}' | head -1)

if [ -n "$DSI_DISPLAY" ] && [ -n "$HDMI_DISPLAY" ]; then
    # DSI konfigurieren
    xrandr --output "$DSI_DISPLAY" --mode 1280x400 --rotate left
    
    # HDMI konfigurieren (rechts von DSI)
    xrandr --output "$HDMI_DISPLAY" --mode 1920x1080 --right-of "$DSI_DISPLAY"
    
    echo "✅ Multi-Display konfiguriert:"
    echo "   DSI: $DSI_DISPLAY (1280x400)"
    echo "   HDMI: $HDMI_DISPLAY (1920x1080)"
else
    echo "⚠️  Nicht alle Displays erkannt"
    echo "   DSI: $DSI_DISPLAY"
    echo "   HDMI: $HDMI_DISPLAY"
fi
```

---

### **PHASE 3: Chromium Multi-Display**

**Option A: Chromium auf DSI**
```bash
# Chromium nur auf DSI Display
DISPLAY=:0 chromium-browser \
    --kiosk \
    --display=:0 \
    --window-position=0,0 \
    --window-size=1280,400 \
    http://localhost
```

**Option B: Chromium auf beiden Displays**
```bash
# Chromium auf primärem Display (DSI)
DISPLAY=:0 chromium-browser \
    --kiosk \
    http://localhost
```

---

## 📊 DISPLAY-KONFIGURATION

### **DSI Display (WaveShare 1280x400):**
- **Auflösung:** 1280x400
- **Rotation:** 270° (Landscape)
- **Touchscreen:** Aktiv
- **Verwendung:** Web-UI (Chromium)

### **HDMI Display:**
- **Auflösung:** Auto-detect oder manuell
- **Rotation:** Normal
- **Verwendung:** PeppyMeter oder erweitertes Display

---

## ✅ VORTEILE

**Dual-Display:**
- ✅ Mehr Bildschirmfläche
- ✅ Verschiedene Inhalte pro Display
- ✅ Flexibilität

**DSI + HDMI:**
- ✅ DSI für Touchscreen-Interaktion
- ✅ HDMI für größere Anzeige
- ✅ Beide gleichzeitig nutzbar

---

## 📝 NÄCHSTE SCHRITTE

1. **Boot-Konfiguration anpassen**
   - DSI Overlay aktivieren
   - HDMI konfigurieren
   - KMS aktivieren

2. **X11 Multi-Display Setup**
   - Displays erkennen
   - Konfiguration anwenden

3. **Chromium/PeppyMeter anpassen**
   - Display-Zuweisung
   - Window-Position

4. **Testing**
   - Beide Displays testen
   - Funktionalität prüfen

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Boot-Konfiguration anpassen


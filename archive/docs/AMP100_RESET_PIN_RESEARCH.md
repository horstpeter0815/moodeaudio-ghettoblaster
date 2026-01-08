# AMP100 RESET-PIN FORSCHUNG - ZUSAMMENFASSUNG

## GEFUNDENE INFORMATIONEN:

### 1. ORIGINAL HIFIBERRY AMP100 OVERLAY:
```dts
reset-gpio = <&gpio 17 0x11>;  // GPIO 17 mit Flag 0x11
mute-gpio = <&gpio 4 0>;       // GPIO 4 mit Flag 0
```

**Quelle**: `/kernel-build/linux/arch/arm/boot/dts/overlays/hifiberry-amp100-overlay.dts`

### 2. HIFIBERRYOS RESET-SCRIPT:
```bash
# Reset Amp100
echo 17 >/sys/class/gpio/export
echo 4  >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio17/direction
echo out >/sys/class/gpio/gpio4/direction
# Mute
echo 1 >/sys/class/gpio/gpio4/value
# Reset
echo 0 >/sys/class/gpio/gpio17/value  # LOW = Reset
echo 1 >/sys/class/gpio/gpio17/value  # HIGH = Normal
# Unmute
echo 0 >/sys/class/gpio/gpio4/value
```

**Quelle**: HiFiBerryOS `reset-amp100` Script

### 3. WICHTIGE ERKENNTNISSE:

#### GPIO 17 = Reset-Pin (ORIGINAL)
- ✅ Wird im originalen Overlay verwendet
- ✅ Wird in HiFiBerryOS verwendet
- ❌ Wird VOM DSP ADD-ON verwendet (Konflikt!)

#### GPIO 4 = Mute-Pin (ORIGINAL)
- ✅ Wird im originalen Overlay verwendet
- ✅ Wird in HiFiBerryOS verwendet
- ❌ Wird VOM DSP ADD-ON verwendet (Konflikt!)

#### GPIO 14 = Alternative Reset-Pin
- ✅ Nicht vom DSP Add-on verwendet
- ✅ UART wurde deaktiviert (`dtoverlay=disable-uart`)
- ❌ Keine Testpads führen zu PCM5122 Pin 8

---

## PROBLEM:

### KEINES DER 3 GOLDENEN PADS FÜHRT ZUM RESET-PIN:
- ❌ K1 (Quadratisches Pad) → Kein Durchgang zu Pin 8
- ❌ Oberes runde Pad → Kein Durchgang zu Pin 8
- ❌ Unteres runde Pad → Kein Durchgang zu Pin 8

**Bedeutung**: Die externen Lötpunkte sind NICHT mit PCM5122 Pin 8 verbunden!

---

## LÖSUNGSOPTIONEN:

### OPTION 1: DIREKT ZUM CHIP-PIN 8 LÖTEN ⭐ EMPFOHLEN
**Vorteile:**
- ✅ Sicherste Methode
- ✅ Direkte Verbindung
- ✅ Keine Zwischenstufen

**Nachteile:**
- ⚠️ Sehr präzises Löten erforderlich
- ⚠️ Pin 8 ist sehr klein
- ⚠️ Andere Pins nicht berühren

**Schritte:**
1. PCM5122 Pin 8 identifizieren (linke Seite, 8. Pin von unten)
2. Sehr dünnes Kabel (30 AWG) vorbereiten
3. Pin 8 vorsichtig anlöten (1-2 Sekunden)
4. Kabel zu Raspberry Pi Pin 8 (GPIO 14) führen
5. Mit Multimeter prüfen (Durchgang)

### OPTION 2: ANDEREN GPIO-PIN VERWENDEN
**Alternative GPIO-Pins:**
- GPIO 18 (Pin 12)
- GPIO 23 (Pin 16)
- GPIO 24 (Pin 18)
- GPIO 25 (Pin 22)

**Vorteile:**
- ✅ Vielleicht gibt es Testpunkte für diese Pins
- ✅ Kein Löten am Chip erforderlich

**Nachteile:**
- ❌ Unbekannt, ob Testpunkte existieren
- ❌ Neues Overlay erforderlich

### OPTION 3: DSP ADD-ON KONFIGURIEREN
**Frage:** Kann das DSP Add-on so konfiguriert werden, dass es GPIO 17/4 nicht verwendet?

**Vorteile:**
- ✅ Kein Löten erforderlich
- ✅ Original GPIO 17/4 verwenden

**Nachteile:**
- ❌ DSP Add-on Konfiguration unbekannt
- ❌ Vielleicht nicht möglich

---

## NÄCHSTE SCHRITTE:

1. **Entscheidung treffen**: Welche Option?
2. **Falls Option 1**: Direktes Löten zum Chip-Pin 8
3. **Falls Option 2**: Andere GPIO-Pins prüfen
4. **Falls Option 3**: DSP Add-on Dokumentation suchen

---

## WICHTIGE HINWEISE:

- **PCM5122 Pin 8** = Reset-Pin (RST)
- **Reset ist ACTIVE LOW**: LOW = Reset, HIGH = Normal
- **GPIO 14 Flag**: `1` = Active Low (korrekt!)
- **Original GPIO 17 Flag**: `0x11` = Spezielle Konfiguration?

---

## QUELLEN:

1. HiFiBerryOS Source Code: `hifiberry-amp100-overlay.dts`
2. HiFiBerryOS Reset Script: `reset-amp100`
3. Eigene Messungen: Kein Durchgang zu Pin 8 über Testpads


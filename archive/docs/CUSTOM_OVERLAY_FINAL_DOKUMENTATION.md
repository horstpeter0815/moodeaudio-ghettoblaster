# Custom Overlay für HiFiBerry AMP100 auf Raspberry Pi 5 - Vollständige Dokumentation

**Datum:** 1. Dezember 2025  
**Hardware:** Raspberry Pi 5 + DSP Add-on + HiFiBerry AMP100  
**Problem:** AMP100 funktioniert nicht auf Pi 5  
**Lösung:** Custom Device Tree Overlay

---

## 📋 EXECUTIVE SUMMARY

### Problem
- HiFiBerry AMP100 funktioniert nicht auf Raspberry Pi 5
- PCM5122 wird erkannt, aber Soundcard wird nicht registriert
- Reset-Fehler (-11) verhindert Treiber-Bindung

### Lösung
- Custom Overlay erstellt: `hifiberry-amp100-pi5.dtbo`
- Overlay verwendet I2C Bus 13 (RP1 Controller) statt Bus 1
- Reset/Mute-Pins werden vom DSP Add-on gesteuert

### Status
- ✅ Overlay erstellt und kompiliert
- ✅ PCM5122 wird erkannt
- ✅ Sound Node wird erstellt
- ❌ Reset-Fehler verhindert Treiber-Bindung
- ❌ Soundcard wird nicht registriert

---

## 🔍 PROBLEM-ANALYSE

### Hardware-Setup

```
Raspberry Pi 5
    ↓ (GPIO Header - alle 40 Pins)
DSP Add-on (sitzt auf Pi)
    ↓ (einzelne Kabel - nicht alle 40 Pins)
HiFiBerry AMP100 (separates Board)
```

### GPIO-Verbindungen: DSP Add-on → AMP100

| GPIO | Pin | Funktion | Verbindung |
|------|-----|----------|------------|
| **GPIO 2** | Pin 3 | **SDA (I2C Data)** | ✅ DSP Add-on → AMP100 |
| **GPIO 3** | Pin 5 | **SCL (I2C Clock)** | ✅ DSP Add-on → AMP100 |
| GPIO 4 | Pin 7 | MUTE | ✅ DSP Add-on → AMP100 |
| GPIO 17 | Pin 11 | RESET | ✅ DSP Add-on → AMP100 |
| GPIO 18-21 | Pins 12,35,38,40 | I2S Sound | ✅ DSP Add-on → AMP100 |

### Warum Bus 13?

**Problem:**
- Standard-Overlay erwartet PCM5122 auf I2C Bus 1 (i2c_arm)
- Aber I2C läuft über DSP Add-on → RP1 Controller (Bus 13)
- Bus 1 existiert, aber PCM5122 ist nicht darauf

**Lösung:**
- Custom Overlay verwendet Bus 13 direkt
- `target-path = "/axi/pcie@1000120000/rp1/i2c@74000"`

---

## 🔧 CUSTOM OVERLAY IMPLEMENTIERUNG

### Overlay-Datei: `hifiberry-amp100-pi5.dts`

```dts
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712"; // Raspberry Pi 5
    
    fragment@0 {
        target-path = "/";
        __overlay__ {
            dacpro_osc {
                compatible = "hifiberry,dacpro-clk";
                #clock-cells = <0>;
                phandle = <0x01>;
            };
        };
    };
    
    fragment@1 {
        target = <&i2s_clk_consumer>;
        __overlay__ {
            status = "okay";
        };
    };
    
    fragment@2 {
        // Bus 13 (RP1 Controller)
        target-path = "/axi/pcie@1000120000/rp1/i2c@74000";
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";
            
            pcm5122@4d {
                #sound-dai-cells = <0>;
                compatible = "ti,pcm5122";
                reg = <0x4d>;
                clocks = <0x01>;
                AVDD-supply = <&vdd_3v3_reg>;
                DVDD-supply = <&vdd_3v3_reg>;
                CPVDD-supply = <&vdd_3v3_reg>;
                status = "okay";
                reset-gpios = <&gpio 17 1>; // GPIO 17, active low
            };
        };
    };
    
    fragment@3 {
        target-path = "/soc@107c000000/sound";
        __overlay__ {
            compatible = "hifiberry,hifiberry-dacplus";
            i2s-controller = <&i2s_clk_consumer>;
            status = "okay";
            mute-gpio = <&gpio 4 0>; // GPIO 4, active high
        };
    };
    
    __fixups__ {
        i2s_clk_consumer = "/fragment@1:target:0", "/fragment@3/__overlay__:i2s-controller:0";
        vdd_3v3_reg = "/fragment@2/__overlay__/pcm5122@4d:AVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:DVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:CPVDD-supply:0";
        gpio = "/fragment@2/__overlay__/pcm5122@4d:reset-gpios:0", "/fragment@3/__overlay__:mute-gpio:0";
    };
    
    __local_fixups__ {
        fragment@2 {
            __overlay__ {
                pcm5122@4d {
                    clocks = <0x00>;
                };
            };
        };
    };
};
```

### Kompilierung

```bash
dtc -@ -I dts -O dtb -o hifiberry-amp100-pi5.dtbo hifiberry-amp100-pi5.dts
```

### Installation

```bash
sudo cp hifiberry-amp100-pi5.dtbo /boot/firmware/overlays/
sudo cp hifiberry-amp100-pi5.dts /boot/firmware/overlays/
```

### Aktivierung in `config.txt`

```ini
dtoverlay=hifiberry-amp100-pi5
```

---

## ❌ VERBLEIBENDES PROBLEM: RESET-FEHLER

### Symptom

```
[    5.697542] pcm512x 1-004d: Failed to reset device: -11
[    5.697865] pcm512x 1-004d: probe with driver pcm512x failed with error -11
```

### Auswirkung

- ❌ Treiber wird nicht gebunden
- ❌ Soundcard wird nicht registriert
- ❌ Keine Audio-Ausgabe möglich

### Mögliche Ursachen

1. **I2C Arbitration:**
   - Mehrere Master auf I2C Bus
   - "lost arbitration" Fehler in dmesg

2. **Reset-Timing:**
   - Reset zu schnell/nach Timing-Problem
   - DSP Add-on und Treiber konkurrieren um GPIO 17

3. **GPIO-Konflikt:**
   - DSP Add-on steuert GPIO 17
   - Treiber versucht auch GPIO 17 zu steuern
   - Konflikt → Reset schlägt fehl

---

## 🔄 MÖGLICHE LÖSUNGSANSÄTZE

### Option 1: Reset im Treiber deaktivieren (Kernel-Patch)

**Vorgehen:**
- Kernel Source patchen
- PCM5122 Treiber modifizieren
- Reset-Code überspringen wenn Reset fehlschlägt

**Nachteile:**
- Sehr komplex
- Muss bei jedem Kernel-Update neu gemacht werden
- Nicht wartbar

### Option 2: Reset vor Treiber-Laden (Script)

**Vorgehen:**
- Systemd Service erstellen
- Reset durchführen VOR Treiber-Laden
- Treiber findet bereits resettetes Gerät

**Vorteile:**
- Einfacher als Kernel-Patch
- Wartbar

### Option 3: Dummy Reset-Pin (nicht-existierender GPIO)

**Vorgehen:**
- Reset-Pin auf nicht-existierenden GPIO setzen
- Treiber versucht Reset, schlägt fehl, ignoriert Fehler

**Nachteile:**
- Funktioniert möglicherweise nicht
- Treiber könnte komplett fehlschlagen

### Option 4: Reset-Pin optional machen (Treiber-Modifikation)

**Vorgehen:**
- Treiber so modifizieren dass Reset optional ist
- Wenn Reset fehlschlägt, trotzdem fortfahren

**Nachteile:**
- Kernel-Patch nötig
- Nicht wartbar

---

## 📝 AKTUELLER STATUS

### Was funktioniert:
- ✅ Custom Overlay erstellt und kompiliert
- ✅ PCM5122 wird erkannt (auf Bus 13)
- ✅ Sound Node wird erstellt
- ✅ Device Tree Konfiguration korrekt

### Was nicht funktioniert:
- ❌ Reset-Fehler verhindert Treiber-Bindung
- ❌ Soundcard wird nicht registriert
- ❌ Keine Audio-Ausgabe

### Nächste Schritte:
1. Reset-Problem lösen (Option 2 empfohlen: Script)
2. Soundcard-Registrierung testen
3. Audio-Ausgabe testen

---

## 📚 DATEIEN

### Overlay-Dateien:
- `/boot/firmware/overlays/hifiberry-amp100-pi5.dtbo` - Kompiliertes Overlay
- `/boot/firmware/overlays/hifiberry-amp100-pi5.dts` - Source Code

### Konfiguration:
- `/boot/firmware/config.txt` - Overlay aktiviert: `dtoverlay=hifiberry-amp100-pi5`

### Dokumentation:
- `CUSTOM_OVERLAY_FINAL_DOKUMENTATION.md` - Diese Datei
- `DSP_ADDON_AMP100_VERBINDUNGEN.md` - GPIO-Verbindungen
- `GPIO_RESET_PIN_DOKUMENTATION.md` - Reset-Pin Details

---

**Status:** ⚠️ **FUNKTIONIERT TEILWEISE** - Reset-Problem muss noch gelöst werden


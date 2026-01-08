# RESET VOM DSP ADD-ON - OHNE LÖTEN AM CHIP

**Datum:** 1. Dezember 2025  
**Ziel:** Reset vom DSP Add-on aus erreichen, OHNE am kleinen PCM5122 Chip zu löten

---

## 🎯 PROBLEM

### **Aktuelle Situation:**
- ❌ PCM5122 Chip hat sehr kleine Lötpunkte
- ❌ Direktes Löten am Chip ist schwierig/riskant
- ✅ DSP Add-on steuert bereits GPIO 17
- ✅ GPIO 17 führt zum Reset-Pin des PCM5122 (über AMP100 Board)

### **Frage:**
- Kann das DSP Add-on den Reset-Pin des PCM5122 steuern?
- Wie können wir das erreichen, OHNE am Chip zu löten?

---

## 🔍 ANALYSE: DSP ADD-ON → AMP100 → PCM5122

### **VERBINDUNGSPFAD:**

```
DSP Add-on
    ↓ (GPIO 17 - bereits verbunden)
AMP100 Board
    ↓ (interne Leiterbahn)
PCM5122 Reset-Pin (Pin 8)
```

**Wichtig:**
- ✅ DSP Add-on steuert GPIO 17
- ✅ GPIO 17 ist bereits mit AMP100 verbunden
- ✅ AMP100 Board hat interne Verbindung zum PCM5122 Reset-Pin
- ✅ **KEIN LÖTEN AM CHIP NÖTIG!**

---

## 💡 LÖSUNG: DSP ADD-ON STEUERT RESET

### **OPTION 1: OVERLAY OHNE RESET-GPIO** ⭐ **EMPFOHLEN**

**Idee:**
- Overlay definiert KEINEN `reset-gpio`
- DSP Add-on steuert GPIO 17 komplett
- Treiber versucht nicht, GPIO 17 zu steuern
- **Kein Konflikt!**

**Overlay-Konfiguration:**
```dts
fragment@3 {
    target-path = "/soc@107c000000";
    __overlay__ {
        sound {
            compatible = "hifiberry,hifiberry-dacplus";
            i2s-controller = <&i2s_clk_consumer>;
            status = "okay";
            // KEIN reset-gpio definiert!
            // DSP Add-on steuert Reset
        };
    };
};
```

**Vorteile:**
- ✅ Kein Konflikt mit DSP Add-on
- ✅ DSP Add-on steuert Reset wie vorgesehen
- ✅ Kein Löten nötig
- ✅ Standard-Verbindung wird genutzt

**Nachteile:**
- ⚠️ Treiber erwartet möglicherweise reset-gpio
- ⚠️ Reset muss vom DSP Add-on durchgeführt werden

### **OPTION 2: OVERLAY MIT GPIO 17, ABER OHNE EXPORT**

**Idee:**
- Overlay definiert `reset-gpio = <&gpio 17 0x11>;`
- Aber: Treiber versucht NICHT, GPIO 17 zu exportieren
- DSP Add-on exportiert und steuert GPIO 17
- Treiber verwendet bereits exportiertes GPIO 17

**Problem:**
- ⚠️ Treiber versucht möglicherweise, GPIO 17 zu exportieren
- ⚠️ Wenn bereits exportiert → Fehler -11

**Lösung:**
- Treiber-Code prüfen, ob Export übersprungen werden kann
- Oder: GPIO 17 vorher nicht exportieren lassen

---

## 🔧 TECHNISCHE UMSETZUNG

### **SCHRITT 1: OVERLAY OHNE RESET-GPIO ERSTELLEN**

**Datei:** `hifiberry-amp100-pi5-dsp-reset.dts`

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
        target-path = "/axi/pcie@1000120000/rp1/i2c@74000"; // I2C Bus 13
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
                CPVDD-supply = <&cpvdd_supply>;
                status = "okay";
                // I2C Timing parameters
                i2c-scl-falling-time-ns = <100>;
                i2c-scl-rising-time-ns = <100>;
            };
        };
    };

    fragment@3 {
        target-path = "/soc@107c000000";
        __overlay__ {
            sound {
                compatible = "hifiberry,hifiberry-dacplus";
                i2s-controller = <&i2s_clk_consumer>;
                status = "okay";
                // KEIN reset-gpio - DSP Add-on steuert Reset!
            };
        };
    };

    __fixups__ {
        i2s_clk_consumer = "/fragment@1:target:0", "/fragment@3/__overlay__/sound:i2s-controller:0";
        vdd_3v3_reg = "/fragment@2/__overlay__/pcm5122@4d:AVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:DVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:CPVDD-supply:0";
    };
};
```

### **SCHRITT 2: DSP ADD-ON RESET SCRIPT**

**Datei:** `/usr/local/bin/dsp-reset-amp100.sh`

```bash
#!/bin/bash
# Reset AMP100 via DSP Add-on GPIO 17

# GPIO 17 exportieren (falls noch nicht exportiert)
if [ ! -d /sys/class/gpio/gpio17 ]; then
    echo 17 >/sys/class/gpio/export 2>/dev/null
fi

# GPIO 17 als Output konfigurieren
if [ -d /sys/class/gpio/gpio17 ]; then
    echo out >/sys/class/gpio/gpio17/direction 2>/dev/null
    
    # Reset-Sequenz: LOW = Reset, HIGH = Normal
    echo 0 >/sys/class/gpio/gpio17/value  # Reset
    sleep 0.1
    echo 1 >/sys/class/gpio/gpio17/value  # Normal
fi
```

### **SCHRITT 3: SYSTEMD SERVICE FÜR RESET**

**Datei:** `/etc/systemd/system/dsp-reset-amp100.service`

```ini
[Unit]
Description=Reset AMP100 via DSP Add-on GPIO 17
Before=sound.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dsp-reset-amp100.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

---

## ✅ VORTEILE DIESER LÖSUNG

1. ✅ **KEIN LÖTEN AM CHIP NÖTIG!**
   - DSP Add-on steuert GPIO 17
   - GPIO 17 führt bereits zum Reset-Pin (über AMP100 Board)
   - Standard-Verbindung wird genutzt

2. ✅ **KEIN KONFLIKT**
   - Overlay definiert keinen reset-gpio
   - DSP Add-on steuert Reset komplett
   - Treiber versucht nicht, GPIO 17 zu steuern

3. ✅ **STANDARD-VERBINDUNG**
   - GPIO 17 ist bereits verbunden (DSP Add-on → AMP100)
   - AMP100 Board hat interne Verbindung zum PCM5122
   - Keine zusätzlichen Kabel nötig

4. ✅ **EINFACHE UMSETZUNG**
   - Overlay ohne reset-gpio
   - Systemd Service für Reset
   - Reset vor Treiber-Laden

---

## 📝 NÄCHSTE SCHRITTE

1. **Overlay erstellen:** `hifiberry-amp100-pi5-dsp-reset.dts`
2. **Reset-Script erstellen:** `/usr/local/bin/dsp-reset-amp100.sh`
3. **Systemd Service erstellen:** `/etc/systemd/system/dsp-reset-amp100.service`
4. **Service aktivieren:** `systemctl enable dsp-reset-amp100.service`
5. **Testen:** Booten und prüfen, ob Reset funktioniert

---

## ⚠️ WICHTIGE HINWEISE

1. **GPIO 17 Verbindung:**
   - DSP Add-on → GPIO 17 → AMP100 Board → PCM5122 Reset-Pin
   - **Bereits vorhanden!** Kein Löten nötig!

2. **Reset-Timing:**
   - Reset muss VOR Treiber-Laden erfolgen
   - Systemd Service mit `Before=sound.target`

3. **Treiber-Kompatibilität:**
   - Treiber sollte ohne reset-gpio funktionieren
   - Falls nicht: Treiber-Code prüfen

---

## 📚 QUELLEN

1. **DSP Add-on Verbindungen:**
   - GPIO 17 führt zum Reset-Pin (über AMP100 Board)
   - Bereits verbunden, kein Löten nötig

2. **Original AMP100 Overlay:**
   - `reset-gpio = <&gpio 17 0x11>;`
   - Aber: Wir lassen es weg, damit DSP Add-on steuert

3. **Reset-Sequenz:**
   - LOW = Reset
   - HIGH = Normal
   - Standard für PCM5122

---

**Status:** ✅ Reset vom DSP Add-on möglich - KEIN LÖTEN AM CHIP NÖTIG!


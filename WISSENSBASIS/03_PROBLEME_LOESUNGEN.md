# PROBLEME & LÖSUNGEN

**Datum:** 02.12.2025  
**Status:** Aktualisiert mit WaveShare Touchscreen Lösung

---

## PROBLEM: WAVESHARE TOUCHSCREEN I2C WRITE ERROR -5

### **Symptome:**
- `ws_touchscreen 10-0045: I2C write failed: -5`
- Kein Input Device wird erstellt
- Touchscreen nicht in xinput erkannt

### **Root Cause (Vermutung):**
- **WaveShare 7.9-inch Panel (GT911) hat möglicherweise KEINE Interrupt-Pins**
- `ws_touchscreen` Driver versucht Interrupt-Mode
- Goodix Controller benötigt möglicherweise Polling Mode

### **ANSATZ: GOODIX POLLING MODE (GETESTET - FUNKTIONIERT NICHT)**

**Problem:** `ws_touchscreen` Driver bindet Device, `goodix_ts` kann nicht binden

**Getestete Ansätze:**
1. ✅ Custom Device Tree Overlay erstellt
2. ✅ `no-touchscreen` Parameter hinzugefügt
3. ✅ `ws_touchscreen` Device manuell gelöscht
4. ✅ `goodix_ts` Device manuell erstellt
5. ❌ **Ergebnis:** I2C Write Error -5 bleibt bestehen

**Status:** ❌ Alle Ansätze getestet - Hardware-Problem vermutet

**1. Device Tree Overlay erstellen:**
```dts
/boot/firmware/overlays/goodix-polling.dts
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2835";

    fragment@0 {
        target = <&i2c1>;
        __overlay__ {
            goodix_ts@45 {
                compatible = "goodix,gt911", "goodix,gt9271";
                reg = <0x45>;
                touchscreen-size-x = <800>;
                touchscreen-size-y = <480>;
                touchscreen-inverted-x;
                touchscreen-inverted-y;
                goodix,driver-send-cfg;
                goodix,no-reset-during-probe;
            };
        };
    };
};
```

**2. Overlay kompilieren:**
```bash
sudo dtc -I dts -O dtb -o /boot/firmware/overlays/goodix-polling.dtbo \
  /boot/firmware/overlays/goodix-polling.dts
```

**3. Config.txt anpassen:**
```bash
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90,touchscreen=goodix
dtoverlay=goodix-polling
```

**4. Reboot**

### **Getestete Ansätze:**
1. ✅ **disable_touch Parameter** - ws_touchscreen erfolgreich deaktiviert
2. ❌ **Goodix Polling Mode Overlay** - I2C Read Error -5
3. ❌ **Goodix Device Tree Overlay für I2C Bus 10** - I2C Read Error -5
4. ❌ **Goodix Register direkt lesen (0x8140)** - "Data address invalid"
5. ❌ **Goodix Hardware Reset** - I2C Write schlägt fehl
6. ❌ **Goodix Alternative Register** - Alle Register schlagen fehl

### **Status:**
- ✅ **ws_touchscreen erfolgreich deaktiviert**
- ❌ **goodix_ts kann nicht mit Hardware kommunizieren**
- 🔍 **I2C Read/Write Error -5 konsistent - Hardware-Problem sehr wahrscheinlich**
- ⏳ **Physische Hardware-Prüfung nötig**

---

## PROBLEM: FT6236 TOUCHSCREEN TIMING (PI 4)

### **Symptome:**
- Touchscreen initialisiert vor Display
- X Server Crashes
- I2C Read/Write Error -5

### **ANSATZ: SYSTEMD SERVICE DELAY (GETESTET - FUNKTIONIERT NICHT)**

**1. ft6236-delay.service:**
```ini
[Unit]
Description=FT6236 Touchscreen Delay Service
After=multi-user.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 5 && echo "edt-ft5x06 0x38" > /sys/bus/i2c/devices/i2c-1/new_device'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**2. Config.txt:**
```bash
#dtoverlay=ft6236  # Deaktiviert
```

**Status:** ❌ Getestet - Device kann erstellt werden, aber Driver-Bindung schlägt fehl (I2C Error -5). Alle Software-Ansätze getestet, Hardware-Problem bestätigt.

---

## PROBLEM: AMP100 AUDIO (PI 5)

### **Symptome:**
- PCM5122 probe failed: -110
- Kein Soundcard gefunden

### **ANSATZ: DSP RESET SERVICE (IN TEST)**

**1. dsp-reset-amp100.service:**
```ini
[Unit]
Description=AMP100 DSP Reset Service
Before=sound.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'gpioset gpiochip0 4=1 && gpioset gpiochip0 17=0 && sleep 0.1 && gpioset gpiochip0 17=1 && gpioset gpiochip0 4=0'
RemainAfterExit=yes

[Install]
WantedBy=sound.target
```

**Status:** ⏳ Wird getestet

---

**Letzte Aktualisierung:** 02.12.2025

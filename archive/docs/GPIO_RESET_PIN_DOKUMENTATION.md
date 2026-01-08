# GPIO Reset-Pin Definitionen für HiFiBerry AMP100

**Datum:** 1. Dezember 2025  
**Quelle:** HiFiBerryOS Configs

---

## 📋 GPIO PIN DEFINITIONEN

### AMP100 GPIO Pins

| GPIO | Funktion | Beschreibung | Aktiv |
|------|----------|--------------|-------|
| **GPIO 17** | Reset-Pin | Reset des PCM5122 | High (0->1) |
| **GPIO 4** | Mute-Pin | Mute/Unmute | Low = unmuted, High = muted |

---

## 🔧 RESET-SEQUENZ (aus HiFiBerryOS)

### Script: `reset-amp100`

```bash
#!/bin/bash
# Reset Amp100
echo 17 >/sys/class/gpio/export
echo 4  >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio17/direction
echo out >/sys/class/gpio/gpio4/direction
# Mute
echo 1 >/sys/class/gpio/gpio4/value
# Reset
echo 0 >/sys/class/gpio/gpio17/value
echo 1 >/sys/class/gpio/gpio17/value
# Unmute
echo 0 >/sys/class/gpio/gpio4/value
```

### Sequenz:
1. **Mute aktivieren:** GPIO 4 = 1 (muted)
2. **Reset durchführen:** GPIO 17 = 0, dann 1
3. **Unmute:** GPIO 4 = 0 (unmuted)

---

## 📝 DEVICE TREE OVERLAY SYNTAX

### Original Overlay (hifiberry-amp100.dtbo)

```dts
fragment@3 {
    target = <&sound>;
    __overlay__ {
        compatible = "hifiberry,hifiberry-dacplus";
        i2s-controller = <&i2s_clk_consumer>;
        status = "okay";
        mute-gpio = <&gpio 4 0>;      // GPIO 4, active low
        reset-gpio = <&gpio 17 17>;   // GPIO 17, flags = 17
    };
};
```

### GPIO Syntax im Device Tree

```dts
gpio-pin = <&gpio pin flags>;
```

**Flags:**
- `0` = GPIO_ACTIVE_HIGH
- `1` = GPIO_ACTIVE_LOW
- `16` = GPIO_OPEN_DRAIN
- `17` = GPIO_ACTIVE_HIGH + GPIO_OPEN_DRAIN (0 + 16)

### Für AMP100:
- **mute-gpio:** `<&gpio 4 0>` - GPIO 4, active high (1 = muted)
- **reset-gpio:** `<&gpio 17 17>` - GPIO 17, active high + open drain

---

## 🔍 PROBLEM ANALYSE

### Error -11 (EAGAIN) beim Reset

**Mögliche Ursachen:**
1. GPIO nicht richtig exportiert
2. GPIO-Timing Problem
3. Reset-Sequenz zu schnell
4. GPIO-Controller nicht bereit

### Lösung im Overlay:

Das Overlay sollte die GPIOs korrekt definieren, aber der Treiber muss sie auch richtig verwenden. Der Fehler "-11" deutet darauf hin, dass der Reset-Versuch fehlschlägt, möglicherweise weil:

1. **GPIO 17 nicht richtig konfiguriert** - Prüfe ob GPIO im Overlay richtig referenziert wird
2. **Timing-Problem** - Reset muss möglicherweise mit Delay erfolgen
3. **GPIO-Controller** - Auf Pi 5 könnte der GPIO-Controller anders sein

---

## ✅ KORREKTUR IM CUSTOM OVERLAY

### Korrigierte GPIO-Definition:

```dts
fragment@3 {
    target-path = "/soc@107c000000/sound";
    __overlay__ {
        compatible = "hifiberry,hifiberry-dacplus";
        i2s-controller = <&i2s_clk_consumer>;
        status = "okay";
        mute-gpio = <&gpio 4 0>;      // GPIO 4, active high
        reset-gpio = <&gpio 17 0>;    // GPIO 17, active high (vereinfacht)
    };
};
```

**Hinweis:** Das Original verwendet `reset-gpio = <&gpio 17 17>`, was GPIO_ACTIVE_HIGH + GPIO_OPEN_DRAIN bedeutet. Für den Test verwenden wir erstmal `0` (nur active high).

---

## 📚 QUELLEN

1. **HiFiBerryOS:** `hifiberry-os/buildroot/package/hifiberry-tools/reset-amp100`
2. **HiFiBerryOS:** `hifiberry-os/buildroot/package/hifiberry-test/S99testamp100`
3. **Original Overlay:** `/boot/firmware/overlays/hifiberry-amp100.dtbo`

---

**Status:** ✅ GPIO-Definitionen identifiziert und dokumentiert


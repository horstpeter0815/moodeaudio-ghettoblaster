# HiFiBerry AMP100 auf Pi 5 - i2c1 Alias Problem

**Datum:** 1. Dezember 2025  
**Status:** ❌ Overlay kann nicht geladen werden  
**Problem:** Overlay sucht nach `i2c1` Alias, der auf Pi 5 nicht existiert

---

## 🔍 PROBLEM

### Fehler:
```
* Failed to apply overlay '0_hifiberry-amp100' (kernel)
```

### Root Cause:
- Das Overlay sucht nach `i2c1` im Device Tree (`i2c1 = "/fragment@2:target:0"`)
- Auf Pi 5 gibt es **keinen `i2c1` Alias** im Device Tree
- I2C Busse sind über RP1 Controller gemappt: `/axi/pcie@1000120000/rp1/i2c@...`
- `i2c_arm` ist auf `/soc@107c000000/i2c@7d005600` gemappt (entspricht `/dev/i2c-1`)

### Symptome:
- ✅ Overlay-Datei existiert
- ✅ Module werden geladen (`snd_soc_pcm512x`, `snd_soc_hifiberry_dacplus`)
- ❌ Overlay kann nicht angewendet werden (Fixup-Fehler)
- ❌ Keine ALSA Soundkarte
- ❌ `pcm512x 1-004d: Failed to reset device: -11`

---

## 💡 LÖSUNG

### Option 1: i2c1 Alias erstellen
Erstelle einen Device Tree Overlay, der einen `i2c1` Alias auf `i2c_arm` mappt:

```dts
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712";
    
    fragment@0 {
        target-path = "/aliases";
        __overlay__ {
            i2c1 = "/soc@107c000000/i2c@7d005600";
        };
    };
};
```

### Option 2: Custom AMP100 Overlay für Pi 5
Erstelle ein angepasstes Overlay, das direkt auf `/soc@107c000000/i2c@7d005600` verweist statt auf `i2c1`.

### Option 3: Prüfe ob neueres Overlay verfügbar ist
HiFiBerry könnte ein Pi 5-kompatibles Overlay bereitstellen.

---

## 🔧 NÄCHSTE SCHRITTE

1. Erstelle i2c1 Alias Overlay
2. Lade es VOR dem AMP100 Overlay
3. Teste ob AMP100 dann funktioniert

---

**Status:** ⚠️ **I2C1 ALIAS FEHLT AUF PI5**


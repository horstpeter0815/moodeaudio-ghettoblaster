# HiFiBerry AMP100 auf Raspberry Pi 5 - Fix Dokumentation

**Datum:** 30. November 2025  
**Problem:** AMP100 Overlay funktioniert nicht auf Pi 5  
**Status:** In Arbeit

---

## 🔍 PROBLEM-ANALYSE

### Root Cause
Das `hifiberry-amp100` Overlay sucht nach:
1. `<&sound>` - Sound-Node existiert nicht auf Pi 5
2. `<&i2s_clk_consumer>` - I2S Label existiert nicht auf Pi 5

### Warum funktioniert es nicht?
- **Pi 4:** Device Tree hat `/soc/sound` und `i2s_clk_consumer` Label
- **Pi 5:** Device Tree hat `/axi/...` (kein `/soc`) und keine I2S Labels

---

## 💡 LÖSUNGSANSÄTZE

### Ansatz 1: Sound-Node erstellen + Phandle-Referenz
**Status:** ❌ Getestet - Overlay kann nicht geladen werden
**Problem:** Hardcoded Phandle (0xbb000000) funktioniert nicht

### Ansatz 2: Sound-Node erstellen + Fixup
**Status:** ⏳ In Arbeit
**Idee:** Overlay erstellt Fixup, der I2S Controller zur Laufzeit findet

### Ansatz 3: Warten auf offizielles Update
**Status:** ⏳ Parallel
**Aktion:** HiFiBerry Support kontaktieren

---

## 🛠️ IMPLEMENTIERUNG

### Versuch 1: Phandle-Referenz (FEHLGESCHLAGEN)

**Overlay:**
```dts
fragment@3 {
    target-path = "/";
    __overlay__ {
        sound {
            compatible = "hifiberry,hifiberry-dacplus";
            i2s-controller = <0xbb000000>;  // Hardcoded Phandle
            status = "okay";
        };
    };
};
```

**Fehler:** `Failed to apply overlay '0_hifiberry-amp100' (kernel)`

**Grund:** Phandle-Referenz funktioniert nicht in Overlays

### Versuch 2: Fixup verwenden (IN ARBEIT)

**Idee:** Overlay erstellt einen Fixup, der zur Laufzeit den I2S Controller findet.

**Problem:** Device Tree Overlays können keine dynamischen Fixups erstellen.

### Versuch 3: Sound-Node ohne I2S-Referenz (ZU TESTEN)

**Idee:** Overlay erstellt Sound-Node ohne I2S-Referenz, Driver findet I2S selbst.

**Problem:** Driver benötigt I2S-Referenz im Device Tree.

---

## 📋 NÄCHSTE SCHRITTE

1. **Kernel-Source analysieren:** Wie finden andere Overlays I2S auf Pi 5?
2. **HiFiBerry Support kontaktieren:** Problem melden, Lösung anfragen
3. **Alternative Overlays prüfen:** Gibt es ein funktionierendes Beispiel?
4. **Kernel-Patch erstellen:** Falls nötig, Kernel anpassen

---

## 🔬 TECHNISCHE DETAILS

### I2S Controller auf Pi 5

**Pfad:** `/axi/pcie@1000120000/rp1/i2s@a4000`
**Phandle:** `0xbb000000`
**Compatible:** `snps,designware-i2s`
**Status:** `okay`

### Sound-Node Anforderungen

**Compatible:** `hifiberry,hifiberry-dacplus`
**I2S Controller:** Muss referenziert werden
**Status:** `okay`

---

**Letzte Aktualisierung:** 30. November 2025, 09:10 CET


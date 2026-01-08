# HiFiBerry AMP100: Pi 4 vs Pi 5 Vergleich

**Datum:** 30. November 2025  
**Status:** ✅ Pi 4 funktioniert | ❌ Pi 5 funktioniert nicht

---

## 🎯 ZUSAMMENFASSUNG

### ✅ Raspberry Pi 4 - FUNKTIONIERT
- **ALSA Soundcard:** `card 2: sndrpihifiberry [snd_rpi_hifiberry_dacplus]`
- **I2C Hardware:** PCM5122 erkannt auf Bus 1, Adresse 0x4d
- **Overlay:** `dtoverlay=hifiberry-amp100` lädt korrekt
- **Sound-Node:** Wird durch Overlay erstellt (über `/soc/sound`)
- **I2S Controller:** Wird korrekt referenziert (`i2s_clk_consumer` existiert)

### ❌ Raspberry Pi 5 - FUNKTIONIERT NICHT
- **ALSA Soundcard:** Keine Soundcard registriert
- **I2C Hardware:** PCM5122 erkannt, aber kein Sound-Node
- **Overlay:** Lädt, aber kann Sound-Node nicht erstellen
- **Sound-Node:** Existiert nicht (Overlay sucht `<&sound>`, existiert nicht auf Pi 5)
- **I2S Controller:** Overlay sucht `<&i2s_clk_consumer>`, existiert nicht auf Pi 5

---

## 🔍 TECHNISCHE UNTERSCHIEDE

### Device Tree Struktur

**Pi 4:**
```
/proc/device-tree/
├── soc/                    # VideoCore verwaltet
│   ├── sound/             # ✅ Sound-Node existiert
│   ├── i2s@.../           # ✅ I2S Controller mit Label
│   └── ...
```

**Pi 5:**
```
/proc/device-tree/
├── axi/                    # RP1 Controller verwaltet
│   ├── pcie@1000120000/
│   │   └── rp1/
│   │       ├── i2c@74000/  # I2C1
│   │       └── i2s@a4000/  # I2S Controller (kein Label!)
│   └── ...
└── ...                     # ❌ Kein /soc/sound
```

### Overlay-Anforderungen

**Was das `hifiberry-amp100` Overlay benötigt:**

1. **Sound-Node:** `<&sound>` - existiert auf Pi 4, nicht auf Pi 5
2. **I2S Label:** `<&i2s_clk_consumer>` - existiert auf Pi 4, nicht auf Pi 5
3. **Compatible:** `"brcm,bcm2835"` - Pi 4, sollte `"brcm,bcm2712"` für Pi 5 sein

**Warum funktioniert es auf Pi 4?**

- Pi 4 hat die alte Device Tree Struktur mit `/soc/sound`
- I2S Controller hat Labels (`i2s_clk_consumer`, `i2s_clk_producer`)
- Overlay kann direkt auf diese Nodes/Labels verweisen

**Warum funktioniert es nicht auf Pi 5?**

- Pi 5 hat neue Device Tree Struktur mit `/axi/...`
- Kein `/soc/sound` Node vorhanden
- I2S Controller hat keine Labels, nur Paths
- Overlay kann nicht auf nicht-existierende Nodes verweisen

---

## 📊 VERGLEICHS-TABELLE

| Feature | Pi 4 | Pi 5 |
|---------|------|------|
| **Device Tree Root** | `/soc` | `/axi` |
| **Sound-Node** | ✅ `/soc/sound` | ❌ Nicht vorhanden |
| **I2S Labels** | ✅ `i2s_clk_consumer` | ❌ Keine Labels |
| **I2S Path** | `/soc/i2s@...` | `/axi/.../rp1/i2s@a4000` |
| **Overlay Compatible** | `brcm,bcm2835` | Sollte `brcm,bcm2712` sein |
| **AMP100 Overlay** | ✅ Funktioniert | ❌ Funktioniert nicht |
| **ALSA Soundcard** | ✅ Registriert | ❌ Nicht registriert |
| **Hardware-Erkennung** | ✅ PCM5122 erkannt | ✅ PCM5122 erkannt |
| **Sound-Node Erstellung** | ✅ Durch Overlay | ❌ Overlay kann nicht erstellen |

---

## 🔬 DETAILANALYSE

### Pi 4 - Funktionsweise

**1. Overlay lädt:**
```ini
dtoverlay=hifiberry-amp100
```

**2. Overlay erstellt:**
- Clock Supplier: `dacpro_osc` ✅
- PCM5122 auf I2C Bus 1: `1-004d` ✅
- Sound-Node: Verwendet existierenden `<&sound>` ✅
- I2S Controller: Verwendet `<&i2s_clk_consumer>` ✅

**3. ALSA registriert Soundcard:**
```
card 2: sndrpihifiberry [snd_rpi_hifiberry_dacplus]
```

**4. dmesg zeigt:**
```
snd-rpi-hifiberry-dacplus soc:sound: GPIO4 for HW-MUTE selected
snd-rpi-hifiberry-dacplus soc:sound: GPIO17 for HW-RESET selected
```

### Pi 5 - Warum es nicht funktioniert

**1. Overlay lädt:**
```ini
dtoverlay=hifiberry-amp100
```

**2. Overlay erstellt:**
- Clock Supplier: `dacpro_osc` ✅
- PCM5122 auf I2C Bus 1: `1-004d` ✅
- Sound-Node: Sucht `<&sound>`, existiert nicht ❌
- I2S Controller: Sucht `<&i2s_clk_consumer>`, existiert nicht ❌

**3. ALSA registriert keine Soundcard:**
```
--- no soundcards ---
```

**4. dmesg zeigt:**
```
platform soc@107c000000:sound: deferred probe pending: (reason unknown)
pcm512x 1-004d: Failed to reset device: -11
```

---

## 💡 LÖSUNGSANSÄTZE FÜR PI 5

### Option 1: Angepasstes Overlay (Empfohlen)

**Idee:** Overlay erstellt Sound-Node unter `/` statt nach `<&sound>` zu suchen.

**Vorteile:**
- Funktioniert sofort
- Keine Kernel-Änderungen nötig

**Nachteile:**
- Phandle-Referenz könnte sich ändern
- Nicht die "saubere" Lösung

### Option 2: Offizielles Update abwarten

**Idee:** HiFiBerry Support kontaktieren, auf Update warten.

**Vorteile:**
- Offizielle Lösung
- Wird in zukünftigen Kernels enthalten sein

**Nachteile:**
- Kann Wochen/Monate dauern

### Option 3: Pi 4 verwenden (Aktuell)

**Idee:** Für AMP100 Pi 4 verwenden, Pi 5 für andere Aufgaben.

**Vorteile:**
- Funktioniert sofort ✅
- Keine Workarounds nötig

**Nachteile:**
- Pi 5 bleibt ungenutzt
- Zwei Systeme nötig

---

## 📝 FAZIT

**Aktueller Stand:**
- ✅ **Pi 4:** AMP100 funktioniert perfekt
- ❌ **Pi 5:** AMP100 funktioniert nicht (Device Tree Inkompatibilität)

**Empfehlung:**
- **Kurzfristig:** Pi 4 für AMP100 verwenden
- **Mittelfristig:** Angepasstes Overlay für Pi 5 erstellen/testen
- **Langfristig:** Auf offizielles HiFiBerry Update warten

**Nächste Schritte:**
1. ✅ Pi 4 Konfiguration dokumentieren
2. ⏳ Pi 5 Overlay-Fix weiterentwickeln
3. ⏳ HiFiBerry Support kontaktieren

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** Pi 4 funktioniert, Pi 5 Fix in Arbeit


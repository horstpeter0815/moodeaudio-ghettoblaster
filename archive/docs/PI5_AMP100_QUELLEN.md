# Pi5 + AMP100 Problem - Quellen und Referenzen

**Datum:** 1. Dezember 2025  
**Status:** Quellen-Sammlung

---

## 🔗 OFFIZIELLE HIER IST DAS PROBLEM

### HiFiBerry Blog: Pi5 Kompatibilität

**Quelle:** https://www.hifiberry.com/blog/pi5-compatibility-with-hifiberry-products/

**Wichtige Punkte:**

1. **Stromversorgung:**
   - Pi5 benötigt 5V/5A (nicht 5V/3A wie Pi4)
   - Schwache Stromversorgung kann zu Instabilitäten führen

2. **I2S Master/Slave-Modus:**
   - Pi5 kann nicht mehr zwischen I2S Master/Slave wechseln
   - Onboard-Audio MUSS deaktiviert sein: `dtparam=audio=off`
   - Wichtig: `dtoverlay=vc4-kms-v3d-pi5,noaudio` (HDMI Audio deaktivieren)

3. **Kompatibilität:**
   - HiFiBerry sagt: "AMP100 funktioniert mit Pi5"
   - ABER: Es gibt bekannte Probleme mit I2S-Konfiguration

---

## 🔍 UNSER PROBLEM vs. OFFIZIELLE AUSSAGE

### Was HiFiBerry sagt:
- ✅ AMP100 ist kompatibel mit Pi5
- ⚠️ Stromversorgung wichtig (5V/5A)
- ⚠️ Onboard-Audio deaktivieren

### Was wir sehen:
- ❌ `deferred probe pending`
- ❌ Keine ALSA Soundkarten
- ✅ Hardware erkannt (PCM5122 auf I2C Bus 13/14)
- ✅ ALSA Module geladen
- ❌ Sound-Node kann nicht erstellt werden

### Mögliche Ursachen:

1. **Device Tree Problem** (unser Hauptproblem)
   - Overlay sucht `<&sound>` und `<&i2s_clk_consumer>`
   - Diese existieren nicht auf Pi5

2. **I2S Master/Slave Problem** (HiFiBerry erwähnt)
   - Pi5 kann nicht mehr zwischen Modi wechseln
   - Möglicherweise falsche I2S-Konfiguration

3. **Stromversorgung** (HiFiBerry erwähnt)
   - Unterspannung könnte Probleme verursachen
   - Aber: Hardware wird erkannt, also wahrscheinlich nicht das Problem

---

## 📋 TECHNISCHE REFERENZEN

### Device Tree Struktur

**Pi4:**
- `/soc/sound` - existiert
- `i2s_clk_consumer` - Label existiert
- `compatible = "brcm,bcm2835"`

**Pi5:**
- `/axi/...` - neue Struktur
- Kein `/soc/sound`
- Keine I2S Labels
- `compatible = "brcm,bcm2712"`

### Overlay-Anforderungen

Das `hifiberry-amp100` Overlay benötigt:
1. `<&sound>` - Sound-Node (existiert nicht auf Pi5)
2. `<&i2s_clk_consumer>` - I2S Label (existiert nicht auf Pi5)
3. `compatible = "brcm,bcm2835"` - sollte `"brcm,bcm2712"` sein

---

## 💡 LÖSUNGSANSÄTZE (BASIEREND AUF QUELLEN)

### 1. Offizielle HiFiBerry Empfehlung

**Konfiguration:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtparam=audio=off
dtoverlay=hifiberry-amp100
force_eeprom_read=0
```

**Stromversorgung:**
- 5V/5A Netzteil verwenden
- Nicht 5V/3A (Pi4 Netzteil)

### 2. Device Tree Fix (Erfordert angepasstes Overlay)

**Problem:** Overlay muss für Pi5 angepasst werden
**Lösung:** Angepasstes Overlay erstellen oder auf Update warten

---

## 🔗 WEITERE QUELLEN

### Forum-Diskussionen

**Zu suchen:**
- Raspberry Pi Forums: "Pi5 AMP100"
- HiFiBerry Forums: "Pi5 compatibility"
- GitHub Issues: HiFiBerry Overlays

### Kernel-Dokumentation

**Device Tree:**
- Raspberry Pi Device Tree Dokumentation
- HiFiBerry Overlay Source Code

---

## 📝 FAZIT

**Offizielle Aussage:**
- HiFiBerry sagt: AMP100 funktioniert mit Pi5
- ABER: Es gibt bekannte Probleme (I2S, Stromversorgung)

**Unser Problem:**
- Device Tree Inkompatibilität
- Overlay kann Sound-Node nicht erstellen
- Möglicherweise zusätzlich I2S Master/Slave Problem

**Nächste Schritte:**
1. HiFiBerry Support kontaktieren mit unserem spezifischen Problem
2. Forum-Diskussionen prüfen
3. Angepasstes Overlay erstellen/testen

---

**Letzte Aktualisierung:** 1. Dezember 2025


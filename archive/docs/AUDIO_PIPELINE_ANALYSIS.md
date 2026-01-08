# Audio-Pipeline Analyse: ALSA → MPD → HiFiBerry AMP100

**Datum:** 30. November 2025  
**System:** Raspberry Pi 5 + Moode Audio + HiFiBerry AMP100

---

## 🔄 ERWARTETE AUDIO-PIPELINE

```
Audio Source (MPD/Streaming)
    ↓
MPD (Music Player Daemon)
    ↓
ALSA (Advanced Linux Sound Architecture)
    ↓
snd_soc_hifiberry_dacplus (Sound Card Driver)
    ↓
snd_soc_pcm512x (PCM5122 Codec Driver)
    ↓
I2S Bus (Digital Audio)
    ↓
PCM5122 DAC (Digital → Analog)
    ↓
TAS5756M Amplifier (Analog Verstärkung)
    ↓
Speakers (Bose Wave Radio)
```

---

## 📊 AKTUELLER STATUS

### ✅ Funktioniert
- **MPD:** Läuft, konfiguriert
- **ALSA Module:** Geladen (`snd_soc_hifiberry_dacplus`, `snd_soc_pcm512x`)
- **PCM5122:** Erkannt auf I2C Bus 1 (0x4d)
- **Clock Supplier:** `dacpro_osc` funktioniert

### ❌ Funktioniert nicht
- **ALSA Soundcard:** Keine Soundcard registriert
- **Sound-Node:** Nicht im Device Tree
- **I2S Binding:** Overlay kann I2S Controller nicht binden

---

## 🔍 DETAILANALYSE

### MPD Konfiguration

**Datei:** `/etc/mpd.conf`

**Aktuelle Einstellung:**
```ini
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "software"
}
```

**Erwartete Einstellung (nach Fix):**
```ini
audio_output {
    type "alsa"
    name "HiFiBerry AMP100"
    device "hw:0,0"  # oder "hw:sndrpihifiberry,0"
    mixer_type "software"
}
```

### ALSA Konfiguration

**Datei:** `/etc/asound.conf`

**Aktuell:** Basis-Konfiguration vorhanden
**Erwartet:** Nach Soundcard-Registrierung automatisch konfiguriert

### Device Tree Sound-Node

**Erwartete Struktur:**
```
/sound {
    compatible = "hifiberry,hifiberry-dacplus";
    i2s-controller = <&i2s_controller>;
    status = "okay";
}
```

**Problem:** Sound-Node wird nicht erstellt, weil:
1. Overlay sucht `<&sound>` (existiert nicht)
2. Overlay sucht `<&i2s_clk_consumer>` (existiert nicht)

---

## 🛠️ LÖSUNGSANSÄTZE

### Ansatz 1: Kernel-Patch
**Idee:** Kernel-Patch erstellen, der Fixups für Pi 5 hinzufügt
**Komplexität:** Hoch
**Zeitaufwand:** Mehrere Stunden

### Ansatz 2: Alternative Overlay-Struktur
**Idee:** Overlay so umstrukturieren, dass es ohne Fixups funktioniert
**Komplexität:** Mittel
**Zeitaufwand:** 1-2 Stunden

### Ansatz 3: Warten auf offizielles Update
**Idee:** HiFiBerry/Raspberry Pi Foundation kontaktieren
**Komplexität:** Niedrig
**Zeitaufwand:** Unbekannt (Wochen/Monate)

---

## 📝 NÄCHSTE SCHRITTE

1. **Kernel-Source analysieren:** Wie funktionieren Fixups auf Pi 5?
2. **Alternative Overlays prüfen:** Gibt es funktionierende Beispiele?
3. **HiFiBerry Support kontaktieren:** Problem melden
4. **Workaround entwickeln:** Falls nötig, temporäre Lösung

---

## 🔗 REFERENZEN

- [ALSA Documentation](https://www.alsa-project.org/wiki/Documentation)
- [MPD Configuration](https://mpd.readthedocs.io/en/stable/user.html#audio-outputs)
- [Device Tree Sound](https://www.kernel.org/doc/Documentation/devicetree/bindings/sound/)

---

**Status:** Analyse abgeschlossen - Lösung in Arbeit


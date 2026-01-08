# PeppyMeter Setup Plan

**Datum:** 30. November 2025  
**Ziel:** PeppyMeter für Moode Audio auf Raspberry Pi 5 einrichten

---

## 📋 ÜBERSICHT

PeppyMeter ist ein visueller Audio-Meter für Raspberry Pi, der auf einem Display angezeigt wird.

---

## 🎯 ANFORDERUNGEN

### Hardware
- ✅ Raspberry Pi 5 (vorhanden)
- ✅ Display: Waveshare 7.9" HDMI LCD (vorhanden, 1280x400)
- ⏳ Audio: HiFiBerry AMP100 (in Arbeit)

### Software
- ✅ Moode Audio 10.0.0 (vorhanden)
- ⏳ PeppyMeter Installation
- ⏳ Python Dependencies
- ⏳ ALSA/PulseAudio Integration

---

## 📦 INSTALLATION

### Schritt 1: PeppyMeter herunterladen

```bash
cd /opt
sudo git clone https://github.com/project-owner/peppymeter.git
# Oder: Moode's PeppyMeter verwenden (falls vorhanden)
```

### Schritt 2: Dependencies installieren

```bash
sudo apt update
sudo apt install -y python3-pip python3-dev python3-pygame
sudo pip3 install numpy
```

### Schritt 3: ALSA/PulseAudio Integration

PeppyMeter benötigt Zugriff auf Audio-Daten:
- **ALSA:** Direkter Zugriff auf Audio-Stream
- **PulseAudio:** Über PulseAudio-Monitor
- **MPD:** Über MPD-Status

---

## ⚙️ KONFIGURATION

### Display-Konfiguration

**Aktuelles Display:** 1280x400 Landscape
**PeppyMeter:** Muss für diese Auflösung angepasst werden

### Audio-Input

**Optionen:**
1. **ALSA Loopback:** Audio von MPD zu Loopback, PeppyMeter liest Loopback
2. **PulseAudio Monitor:** PeppyMeter liest PulseAudio-Monitor
3. **MPD Status:** PeppyMeter liest MPD-Status (weniger genau)

---

## 🔗 INTEGRATION MIT MOODE

### Moode Audio PeppyMeter Support

Moode Audio hat bereits PeppyMeter-Support:
- **Setting:** `peppy_display = '1'`
- **Type:** `peppy_display_type = 'meter'` oder `'spectrum'`

### Konfiguration in Moode

```sql
UPDATE cfg_system SET value='1' WHERE param='peppy_display';
UPDATE cfg_system SET value='meter' WHERE param='peppy_display_type';
```

---

## 📝 NÄCHSTE SCHRITTE

1. **Audio funktionieren lassen:** HiFiBerry AMP100 muss zuerst funktionieren
2. **PeppyMeter installieren:** Nach Audio-Fix
3. **Display-Integration:** PeppyMeter auf Waveshare Display anzeigen
4. **Testing:** Audio-Meter testen

---

## 🔗 REFERENZEN

- [PeppyMeter GitHub](https://github.com/project-owner/peppymeter)
- [Moode Audio PeppyMeter](https://moodeaudio.org/docs/peppy.html)
- [ALSA Loopback](https://www.alsa-project.org/wiki/Matrix:Module-aloop)

---

**Status:** Vorbereitung - Wartet auf Audio-Fix


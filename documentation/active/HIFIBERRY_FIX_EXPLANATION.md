# HIFIBERRY FIX EXPLANATION

**Date:** 2025-12-04  
**Problem:** HiFiBerry AMP100 I2C Timeout, keine Soundkarten erkannt  
**Lösung:** Pi 4 Konfiguration auf Pi 5 übertragen

---

## 🔍 PROBLEM ANALYSE

### **Pi 4 (funktioniert):**
- ✅ `dtoverlay=hifiberry-dacplus`
- ✅ `dtparam=i2c_arm=on`
- ✅ `dtparam=i2s=on`
- ✅ Card 2: sndrpihifiberry erkannt
- ✅ Keine I2C Timeouts

### **Pi 5 (funktioniert nicht):**
- ❌ `dtoverlay=hifiberry-amp100`
- ❌ I2C Timeouts: `i2c_designware 1f00074000.i2c: controller timed out`
- ❌ PCM512x Reset-Fehler: `Failed to reset device: -110`
- ❌ Keine Soundkarten erkannt

---

## 🛠️ LÖSUNG

### **Script:** `fix-hifiberry-pi5-auto.sh`

**Was es macht:**

1. **Bereinigt config.txt:**
   - Entfernt alle alten Audio/HiFiBerry Einstellungen
   - Entfernt Konflikte

2. **Fügt Pi 4 Konfiguration hinzu:**
   - `dtparam=i2c_arm=on`
   - `dtparam=i2s=on`
   - `dtoverlay=vc4-kms-v3d-pi5,noaudio` (HDMI Audio deaktiviert)
   - `dtoverlay=hifiberry-dacplus` (wie Pi 4)

3. **Behebt I2C-Probleme:**
   - Senkt I2C Baudrate auf 50000 (vermeidet Timeouts)
   - Entfernt hohe Baudrate-Einstellungen

4. **Aktualisiert ALSA:**
   - Konfiguriert für Card 2 (wie Pi 4)
   - `/etc/asound.conf` für HiFiBerry

5. **Aktualisiert MPD:**
   - Verwendet `hw:2,0` (Card 2, Device 0)
   - Mixer Control: "Digital" (wie Pi 4)

6. **Reboot:**
   - Startet Pi 5 neu
   - Änderungen werden aktiv

---

## ⚠️ WICHTIG

**Wenn du AMP100 hast (nicht DAC+):**
- Das Script verwendet `hifiberry-dacplus` (Standard)
- Falls AMP100, ändere nach Reboot zu `hifiberry-amp100`
- Aber zuerst testen, ob DAC+ Overlay funktioniert

**HDMI Audio:**
- Bleibt deaktiviert (`noaudio`)
- HiFiBerry hat Priorität

---

## 🚀 AUSFÜHRUNG

```bash
./fix-hifiberry-pi5-auto.sh
```

**Nach Reboot testen:**
```bash
ssh pi2 "aplay -l"
ssh pi2 "cat /proc/asound/cards"
ssh pi2 "mpc play"
```

---

**Status:** Script bereit - basiert auf funktionierender Pi 4 Konfiguration


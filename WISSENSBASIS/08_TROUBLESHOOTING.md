# TROUBLESHOOTING

**Datum:** 1. Dezember 2025  
**Status:** In Arbeit  
**Version:** 1.0

---

## 🔍 HÄUFIGE PROBLEME

### **PROBLEM: Display flackert / wird inaktiv**

#### **Symptome:**
- Display flackert beim Boot
- Display wird schwarz
- X Server startet nicht

#### **Diagnose:**
```bash
# Prüfe X Server Status
systemctl status localdisplay.service

# Prüfe Xorg Prozess
ps aux | grep Xorg

# Prüfe Display-Device
ls -la /dev/dri/card0

# Prüfe FT6236 Status
lsmod | grep ft6236
```

#### **Lösung:**
- FT6236 Overlay aus `config.txt` entfernen
- Ansatz A (Path-Unit) implementieren
- Siehe [Implementierungs-Guides](07_IMPLEMENTIERUNGEN.md)

---

### **PROBLEM: Touchscreen funktioniert nicht**

#### **Symptome:**
- Touchscreen reagiert nicht
- Touchscreen wird nicht erkannt

#### **Diagnose:**
```bash
# Prüfe FT6236 Modul
lsmod | grep ft6236

# Prüfe Input-Devices
xinput list

# Prüfe I2C-Bus
i2cdetect -y 13
```

#### **Lösung:**
- FT6236 Modul manuell laden: `sudo modprobe ft6236`
- Touchscreen-Kalibrierung prüfen
- I2C-Verbindung prüfen

---

### **PROBLEM: Audio funktioniert nicht**

#### **Symptome:**
- Kein Sound
- Soundcard wird nicht erkannt

#### **Diagnose:**
```bash
# Prüfe Soundcards
aplay -l

# Prüfe ALSA
cat /proc/asound/cards

# Prüfe MPD Status
systemctl status mpd

# Prüfe dmesg
dmesg | grep -i audio
dmesg | grep -i pcm5122
```

#### **Lösung:**
- Reset-Service prüfen: `systemctl status dsp-reset-amp100.service`
- I2C-Verbindung prüfen
- Overlay prüfen

---

## 🔗 VERWANDTE DOKUMENTE

- [Probleme & Lösungen](03_PROBLEME_LOESUNGEN.md)
- [Hardware-Dokumentation](02_HARDWARE.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025


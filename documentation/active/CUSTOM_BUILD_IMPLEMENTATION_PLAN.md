# CUSTOM BUILD IMPLEMENTATION PLAN

**Datum:** 2. Dezember 2025  
**Status:** IMPLEMENTATION PLAN  
**Projekt:** moOde Custom Build für Pi 5

---

## 🎯 ZIEL

Erstellen eines custom moOde Images mit:
- ✅ Integrierten Device Tree Overlays (FT6236, AMP100)
- ✅ Optimierten systemd Services
- ✅ Korrekter Boot-Sequenz
- ✅ Keine Workarounds
- ✅ Zukunftssicher und erweiterbar

---

## 📋 PHASE 1: VORBEREITUNG (Mac)

### **1.1 Build-Umgebung einrichten**

```bash
# Repository klonen
cd ~/Projects
git clone https://github.com/moode-player/imgbuild.git
cd imgbuild

# Dependencies prüfen
# Pi-gen benötigt: Docker oder native Linux-Umgebung
```

**Checkliste:**
- [ ] imgbuild Repository geklont
- [ ] Build-Umgebung funktioniert
- [ ] Dependencies installiert

---

### **1.2 moOde Source analysieren**

**Ziel:** Verstehen, wie moOde aufgebaut ist

**Zu analysieren:**
- [ ] moOde Source-Struktur
- [ ] Pi-gen Build-Prozess
- [ ] Service-Integration
- [ ] Overlay-Integration
- [ ] Config.txt Management

**Dateien zu prüfen:**
- `moode-source/etc/systemd/system/` - Services
- `moode-source/boot/firmware/config.txt.overwrite` - Config
- `moode-source/lib/systemd/system/` - System Services

---

### **1.3 Custom Overlays vorbereiten**

**FT6236 Overlay:**
- [ ] Overlay-Datei erstellen
- [ ] Timing-Optimierungen
- [ ] I2C-Konfiguration

**AMP100 Overlay:**
- [ ] Pi 5 kompatible Konfiguration
- [ ] Auto-Mute aktiviert
- [ ] I2C-Baudrate optimiert

---

### **1.4 Custom Services vorbereiten**

**Services zu integrieren:**
- [ ] `localdisplay.service` - Display-Initialisierung
- [ ] `ft6236-delay.service` - Touchscreen (nach Display)
- [ ] `peppymeter.service` - PeppyMeter
- [ ] `chromium-kiosk.service` - Chromium Kiosk
- [ ] Service-Abhängigkeiten definieren

---

### **1.5 Config-Templates erstellen**

**Templates:**
- [ ] `config.txt.template` - Boot-Konfiguration
- [ ] `cmdline.txt.template` - Kernel-Parameter
- [ ] Service-Templates

---

## 📋 PHASE 2: BUILD-KONFIGURATION (Mac)

### **2.1 Pi-gen Konfiguration anpassen**

**Zu konfigurieren:**
- [ ] Build-Stages anpassen
- [ ] Custom Packages hinzufügen
- [ ] Service-Integration
- [ ] Overlay-Integration

---

### **2.2 Custom Packages definieren**

**Packages:**
- [ ] `moode-custom-display` - Display-Services
- [ ] `moode-custom-touchscreen` - Touchscreen-Services
- [ ] `moode-custom-audio` - Audio-Optimierungen
- [ ] `moode-custom-peppymeter` - PeppyMeter Integration

---

### **2.3 Service-Integration planen**

**Boot-Sequenz:**
```
1. Hardware-Init (I2C, Display)
2. localdisplay.service
3. ft6236-delay.service (After=localdisplay)
4. MPD Service (After=localdisplay)
5. peppymeter.service (After=localdisplay)
6. chromium-kiosk.service (After=localdisplay)
```

---

## 📋 PHASE 3: BUILD (Mac)

### **3.1 Image bauen**

```bash
# Build starten
cd imgbuild
./build.sh

# Build-Zeit: 8-12 Stunden
```

**Checkliste:**
- [ ] Build startet ohne Fehler
- [ ] Build läuft durch
- [ ] Image wird erstellt

---

### **3.2 Test-Image erstellen**

**Zu testen:**
- [ ] Image-Größe
- [ ] Image-Format
- [ ] Boot-Fähigkeit

---

## 📋 PHASE 4: TESTING (Pi 5)

### **4.1 Image auf SD-Karte schreiben**

```bash
# Image schreiben
sudo dd if=moode-custom.img of=/dev/diskX bs=1m
```

**Checkliste:**
- [ ] Image geschrieben
- [ ] SD-Karte bootfähig

---

### **4.2 Boot-Test**

**Zu prüfen:**
- [ ] Pi 5 bootet
- [ ] Boot-Sequenz korrekt
- [ ] Services starten in richtiger Reihenfolge

---

### **4.3 Funktionalitätstest**

**Tests:**
- [ ] Display: 1280x400 Landscape
- [ ] Touchscreen: Funktioniert
- [ ] Audio: AMP100 funktioniert
- [ ] Chromium: Startet automatisch
- [ ] PeppyMeter: Funktioniert

---

### **4.4 Stabilitätstest**

**Tests:**
- [ ] Reboot 1: Alles funktioniert
- [ ] Reboot 2: Alles funktioniert
- [ ] Reboot 3: Alles funktioniert

---

## 📋 PHASE 5: PRODUKTION

### **5.1 Finales Image erstellen**

**Zu tun:**
- [ ] Finales Image bauen
- [ ] Dokumentation
- [ ] Backup

---

### **5.2 Deployment**

**Zu tun:**
- [ ] Image auf Pi 5 deployen
- [ ] Verifikation
- [ ] Dokumentation

---

## 🔧 TECHNISCHE DETAILS

### **Service-Abhängigkeiten:**

```ini
[Unit]
# localdisplay.service
After=graphical.target
Wants=graphical.target

# ft6236-delay.service
After=localdisplay.service
Wants=localdisplay.service

# mpd.service
After=localdisplay.service sound.target
Wants=localdisplay.service sound.target

# peppymeter.service
After=localdisplay.service mpd.service
Wants=localdisplay.service mpd.service

# chromium-kiosk.service
After=localdisplay.service
Requires=localdisplay.service
```

---

### **Config.txt Template:**

```
# Display
disable_overscan=1
display_rotate=3
dtoverlay=vc4-fkms-v3d,audio=off

# I2C
dtparam=i2c=on
dtparam=spi=on

# Audio
dtoverlay=hifiberry-amp100,automute

# Custom HDMI Mode
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
```

---

### **cmdline.txt Template:**

```
console=serial0,115200 console=tty1 root=PARTUUID=... rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE systemd.show_status=yes fbcon=rotate:3
```

---

## ✅ SUCCESS CRITERIA

**Projekt ist erfolgreich, wenn:**
- ✅ Image baut ohne Fehler
- ✅ Pi 5 bootet erfolgreich
- ✅ Display zeigt 1280x400 Landscape
- ✅ Touchscreen funktioniert
- ✅ Audio (AMP100) funktioniert
- ✅ Chromium startet automatisch
- ✅ PeppyMeter funktioniert
- ✅ 3x Reboot ohne Probleme
- ✅ Keine Workarounds nötig

---

## 📝 NÄCHSTE SCHRITTE

1. **JETZT:** Build-Umgebung einrichten
2. **HEUTE:** Custom Komponenten vorbereiten
3. **MORGEN:** Build starten
4. **ÜBERMORGEN:** Testing und Deployment

---

**Status:** BEREIT FÜR IMPLEMENTIERUNG  
**Projektmanager:** Auto  
**Datum:** 2. Dezember 2025


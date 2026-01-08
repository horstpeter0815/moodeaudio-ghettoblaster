# 📚 REPOSITORY WISSENSBASIS - SYSTEMATISCHES VERSTÄNDNIS

**Erstellt:** 2025-12-07  
**Zweck:** Proaktives Arbeiten statt reaktives - Verstehen des gesamten Systems

---

## 🏗️ BUILD-PROZESS

### **Haupt-Build-Script:**
- `imgbuild/build.sh` - Startet den Build
- `imgbuild/pi-gen-64/build.sh` - pi-gen Build-System
- Docker Container: `moode-builder`

### **Build-Stages:**
1. **stage0:** Basis-System (apt, locale, firmware)
2. **stage1:** Boot-Files, sys-tweaks, net-tweaks
3. **stage2:** moOde Installation (04-moode-install)
4. **stage3:** 
   - `00-moode-install-prereq` - Voraussetzungen
   - `01-moode-install` - moOde Installation
   - `02-moode-install-post` - Nach moOde Installation
   - `03-ghettoblaster-custom` - **UNSERE CUSTOM KOMPONENTEN** ⭐
5. **export-image:** Image-Erstellung

### **Wann läuft INTEGRATE_CUSTOM_COMPONENTS.sh?**
- **VOR dem Build** - bereitet `moode-source` vor
- Kopiert Services, Scripts, Configs in `moode-source/`
- Wird dann vom Build-System verwendet

### **Wie wird stage3_03 integriert?**
- `pi-gen-utils/setuppigen.sh` kopiert `moode-cfg/stage3_03-*` → `pi-gen-64/stage3/03-ghettoblaster-custom/`
- pi-gen führt dann automatisch alle `*-run-chroot.sh` Scripts in stage3 aus
- Reihenfolge: `00-*`, `01-*`, `02-*`, `03-*` (alphabetisch)

---

## 🔧 CUSTOM COMPONENTS

### **Services** (`custom-components/services/`):
1. `localdisplay.service` - Chromium Browser auf Display
2. `xserver-ready.service` - Wartet auf X Server
3. `disable-console.service` - Deaktiviert Console auf tty1
4. `peppymeter.service` - Audio Visualizer
5. `peppymeter-extended-displays.service` - Extended Displays
6. `ft6236-delay.service` - Touchscreen (FT6236)
7. `i2c-monitor.service` - I2C Monitoring
8. `i2c-stabilize.service` - I2C Stabilization
9. `audio-optimize.service` - Audio Optimierung
10. `fix-ssh-sudoers.service` - **PERMANENTE SSH/SUDOERS LÖSUNG** ⭐

### **Scripts** (`custom-components/scripts/`):
1. `start-chromium-clean.sh` - Chromium Startup (Landscape, Kiosk)
2. `xserver-ready.sh` - X Server Ready Check
3. `peppymeter-wrapper.sh` - PeppyMeter Wrapper
4. `peppymeter-extended-displays.py` - Extended Displays Python
5. `worker-php-patch.sh` - moOde worker.php Patch (display_rotate=0)
6. `i2c-stabilize.sh` - I2C Stabilization
7. `i2c-monitor.sh` - I2C Monitoring
8. `audio-optimize.sh` - Audio Optimierung
9. `pcm5122-oversampling.sh` - PCM5122 Oversampling

### **Overlays** (`custom-components/overlays/`):
1. `ghettoblaster-ft6236.dts` - FT6236 Touchscreen
2. `ghettoblaster-amp100.dts` - HiFiBerry AMP100

### **Configs** (`custom-components/configs/`):
1. `config.txt.template` - Raspberry Pi Config (display_rotate=0)
2. `cmdline.txt.template` - Boot Command Line

---

## 🔴 BEKANNTE PROBLEME + LÖSUNGEN

### **Problem 1: SSH wird nicht aktiviert**
- **Symptom:** SSH ist nach Boot nicht aktiv (Connection refused)
- **Ursache:** moOde überschreibt SSH-Einstellungen beim ersten Boot
- **Lösung:** `fix-ssh-sudoers.service` - läuft bei JEDEM Boot NACH moOde
- **Status:** ✅ GELÖST (permanente Lösung)

### **Problem 2: Andre ist nicht in sudoers**
- **Symptom:** `andre` kann kein `sudo` ohne Passwort nutzen
- **Ursache:** moOde überschreibt sudoers beim ersten Boot
- **Lösung:** `fix-ssh-sudoers.service` - setzt sudoers bei JEDEM Boot
- **Status:** ✅ GELÖST (permanente Lösung)

### **Problem 3: Display zeigt Console statt Browser**
- **Symptom:** Console auf Display, Chromium startet nicht
- **Ursache:** Console auf tty1, Chromium startet nicht richtig
- **Lösung:** 
  - `disable-console.service` - deaktiviert Console
  - `localdisplay.service` - startet Chromium
  - `start-chromium-clean.sh` - robuster Chromium-Start
- **Status:** ✅ GELÖST

### **Problem 4: Display Rotation falsch (Portrait statt Landscape)**
- **Symptom:** Display zeigt Portrait statt Landscape
- **Ursache:** `display_rotate=3` statt `display_rotate=0`
- **Lösung:** 
  - `config.txt.overwrite`: `display_rotate=0`
  - `worker-php-patch.sh`: verhindert Überschreibung durch moOde
  - `hdmi_force_mode=1`: erzwingt Landscape
- **Status:** ✅ GELÖST

### **Problem 5: Chromium startet nicht**
- **Symptom:** Browser öffnet sich nicht
- **Ursache:** X Server nicht ready, Console blockiert, Permissions
- **Lösung:**
  - `xserver-ready.service` - wartet auf X Server
  - `disable-console.service` - deaktiviert Console
  - `start-chromium-clean.sh` - robuster Start mit Checks
- **Status:** ✅ GELÖST

---

## 📋 SPEZIFIKATIONEN

### **Username:**
- Linux: `andre` (für "André")
- Password: `0815`
- Sudoers: `andre ALL=(ALL) NOPASSWD: ALL`

### **Hostname:**
- Linux: `GhettoBlaster` (CamelCase, für "Ghetto Blaster")
- Display Name: "Ghetto Blaster" (mit Leerzeichen, in `/etc/machine-info`)

### **Display:**
- Resolution: `1280x400`
- Rotation: `0` (Landscape)
- Mode: `hdmi_mode=87`, `hdmi_cvt=1280 400 60 6 0 0 0`
- Force: `hdmi_force_mode=1`

### **WLAN:**
- SSID: `Martin Router King`
- Password: `06082020`
- Config: `/etc/wpa_supplicant/wpa_supplicant.conf`

### **Hardware:**
- Raspberry Pi 5
- Display: Waveshare DSI LCD 1280x400
- Audio: HiFiBerry AMP100
- Touchscreen: FT6236

---

## 🔄 BUILD-WORKFLOW

### **1. Vorbereitung:**
```bash
bash INTEGRATE_CUSTOM_COMPONENTS.sh
```
- Kopiert alle Custom Components in `moode-source/`
- Erstellt `config.txt.overwrite`
- Bereitet alles für Build vor

### **2. Build starten:**
```bash
docker-compose -f docker-compose.build.yml exec moode-builder bash /build/build.sh
```

### **3. Build-Prozess:**
- Stage 0-2: Basis-System + moOde Installation
- **Stage 3.03:** `stage3_03-ghettoblaster-custom_00-run-chroot.sh`
  - Erstellt User `andre`
  - Setzt Password `0815`
  - Kopiert Services
  - Enabled Services
  - Setzt Sudoers
  - Aktiviert SSH
  - Konfiguriert WLAN
  - **AM ENDE:** `fix-ssh-sudoers.service` enabled (permanente Lösung)

### **4. Export:**
- Image wird erstellt in `imgbuild/deploy/*.img`

---

## ⚠️ KRITISCHE REGELN

1. **Script-Pfade:** Scripts die User ausführt → `~/` (Home-Verzeichnis)
2. **Username:** Immer `andre` (nicht `andreon0815`)
3. **Hostname:** Immer `GhettoBlaster` (CamelCase)
4. **Display Rotation:** Immer `display_rotate=0` (Landscape)
5. **SSH/Sudoers:** Immer am ENDE des Build-Scripts (nach moOde)
6. **Services:** Immer `User=andre`, `XAUTHORITY=/home/andre/.Xauthority`

---

## 🎯 PROAKTIVES ARBEITEN

### **Vor jedem Build prüfen:**
1. ✅ Alle Spezifikationen korrekt?
2. ✅ Alle Services vorhanden?
3. ✅ Alle Scripts vorhanden?
4. ✅ Build-Script hat alle Fixes?
5. ✅ `fix-ssh-sudoers.service` enabled?

### **Nach jedem Build prüfen:**
1. ✅ SSH aktiv?
2. ✅ Sudoers gesetzt?
3. ✅ Display Landscape?
4. ✅ Browser startet?
5. ✅ WLAN verbunden?

---

**Diese Wissensbasis wird kontinuierlich aktualisiert!**


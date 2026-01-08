# 🧪 Testing Ready - Hardware Test

**Status:** ✅ BEREIT FÜR HARDWARE-TEST

---

## 📦 Image Status

**Image:** `2025-12-07-moode-r1001-arm64-lite.img` (4.8 GB)

**Location:** Projekt-Root-Verzeichnis

---

## 🚀 Schnellstart - Image auf Pi 5 deployen

### **Option 1: Direkt auf Pi 5 brennen (Empfohlen)**

```bash
# 1. Image zu Pi 5 kopieren
scp 2025-12-07-moode-r1001-arm64-lite.img pi@192.168.178.161:/tmp/

# 2. Auf Pi 5 einloggen
ssh pi@192.168.178.161

# 3. SD-Karte finden
lsblk

# 4. Image brennen (z.B. /dev/sda)
sudo umount /dev/sda* 2>/dev/null
sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
sync
```

### **Option 2: Mit balenaEtcher (Mac)**

1. balenaEtcher öffnen
2. Image auswählen: `2025-12-07-moode-r1001-arm64-lite.img`
3. SD-Karte auswählen
4. Flash!

---

## ✅ Nach dem Brennen

1. **SD-Karte aus Pi 5 entfernen**
2. **SD-Karte in Raspberry Pi 5 (Ziel-System) stecken**
3. **Hardware verbinden:**
   - HiFiBerry AMP100 HAT
   - Display (1280x400)
   - Touchscreen (FT6236)
   - Netzwerk (Ethernet)
   - Stromversorgung
4. **System booten** (~1-2 Minuten)
5. **Web-UI öffnen:** `http://moode.local` oder IP-Adresse

---

## 🧪 Testing Checklist

### **1. Basis-System:**
- [ ] System bootet
- [ ] Web-UI erreichbar
- [ ] Login funktioniert
- [ ] Audio-Output erkannt (HiFiBerry AMP100)

### **2. Display & Touch:**
- [ ] Display zeigt korrekt (1280x400)
- [ ] Rotation korrekt (Portrait)
- [ ] Touchscreen funktioniert
- [ ] Chromium startet automatisch

### **3. Features:**
- [ ] **Flat EQ Preset:** Checkbox sichtbar, Toggle funktioniert
- [ ] **Room Correction Wizard:** Wizard öffnet, Test-Tone funktioniert
- [ ] **PeppyMeter:** Startet, Touch-Gesten funktionieren
- [ ] **Audio:** Sound funktioniert, Volume Control OK

### **4. Services:**
- [ ] MPD läuft
- [ ] CamillaDSP läuft (falls aktiv)
- [ ] PeppyMeter Extended Displays läuft
- [ ] I2C Monitor läuft

---

## 📊 Test-Ergebnisse dokumentieren

Nach dem Test:
- ✅ Welche Features funktionieren
- ⚠️ Welche Features Probleme haben
- 📝 Performance (CPU, RAM)
- 🔊 Audio-Qualität
- 🖥️ UI/UX Feedback

---

## 🔗 Weitere Ressourcen

- **Deployment:** `DEPLOY_TO_PI5_INSTRUCTIONS.md`
- **Quick Deploy:** `QUICK_DEPLOY.md`
- **Testing Checklist:** `TESTING_CHECKLIST.md`
- **Troubleshooting:** `docs/instructions/troubleshooting.md`

---

**Status:** ✅ READY FOR TESTING  
**Nächster Schritt:** Image brennen & System testen


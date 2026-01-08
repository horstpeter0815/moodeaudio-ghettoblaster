# 🌐 Web-UI Setup - Vollständige Anleitung

**Status:** SSH nicht verfügbar - Konfiguration über Web-UI

---

## 🔧 ALLE PROBLEME BEHEBEN

### **1. Display-Rotation: Portrait → Landscape**

**Schritte:**
1. Öffne: http://192.168.178.161
2. Login (falls nötig)
3. **Configure → System**
4. Suche: **"Display Rotation"** oder **"Screen Rotation"**
5. Ändere: **Portrait (270°)** → **Landscape (0°)**
6. **Speichern**

**Oder direkt in config.txt (falls SSH später funktioniert):**
```bash
sudo sed -i 's/display_rotate=3/display_rotate=0/' /boot/firmware/config.txt
sudo reboot
```

---

### **2. Browser starten (Local Display)**

**Schritte:**
1. **Configure → Peripherals**
2. **"Local Display"**: ✅ Aktivieren
3. **URL**: `http://localhost`
4. **Kiosk Mode**: ✅ Aktivieren
5. **Speichern**

**Service sollte automatisch starten**

---

### **3. Audio-Output: HiFiBerry AMP100**

**Schritte:**
1. **Configure → Audio**
2. **Output Device**: Wähle **"HiFiBerry AMP100"**
3. **Sample Rate**: `192000` (192kHz)
4. **Bit Depth**: `32-bit`
5. **Speichern**

---

### **4. SSH konfigurieren (für zukünftige Fixes)**

**Falls SSH später funktionieren soll:**
1. **Configure → System**
2. Suche: **SSH** oder **Remote Access**
3. **SSH aktivieren**
4. **Password Authentication**: Aktivieren
5. **Speichern**

---

### **5. Neustart**

**Nach allen Änderungen:**
1. **System → Restart**
2. Oder: `sudo reboot` (falls SSH funktioniert)

---

## ✅ NACH NEUSTART

**Erwartete Ergebnisse:**
- ✅ Display: Landscape (nicht mehr Portrait)
- ✅ Browser: Automatisch gestartet (moOde UI sichtbar)
- ✅ Audio: HiFiBerry AMP100 funktioniert
- ✅ SSH: Sollte funktionieren (falls konfiguriert)

---

## 🐛 BEKANNTE PROBLEME & LÖSUNGEN

### **Problem: SSH funktioniert nicht**
- **Lösung:** Über Web-UI konfigurieren
- **Oder:** SSH in Web-UI aktivieren

### **Problem: Chromium startet nicht**
- **Lösung:** Local Display in Web-UI aktivieren
- **Prüfen:** Configure → Peripherals → Local Display

### **Problem: Display ist Portrait**
- **Lösung:** Display Rotation auf 0° setzen
- **Prüfen:** Configure → System → Display Rotation

---

**Status:** ✅ ANLEITUNG ERSTELLT  
**Nächster Schritt:** Web-UI öffnen und konfigurieren


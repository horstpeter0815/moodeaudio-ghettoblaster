# GHETTO OS - RENAMING PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** Umbenennung zu "Ghetto Blaster" und "Ghetto OS"

---

## 🎯 RENAMING

**System-Name:**
- ✅ **Ghetto Blaster** - Hardware-System (Raspberry Pi 5)
- ✅ **Ghetto OS** - Software-System (moOde Audio Custom Build)

**Bereiche:**
- ✅ Boot-Screen-Nachricht
- ✅ Web-UI Titel
- ✅ Service-Namen
- ✅ Dokumentation
- ✅ Scripts

---

## 📋 UMBENENNUNGS-BEREICHE

### **1. Boot-Screen-Nachricht**

**Aktuell:**
```
moOde Audio Player - Custom Build
```

**Neu:**
```
Ghetto Blaster - Ghetto OS
```

**Datei:** `/etc/issue`, `/etc/motd`

---

### **2. Web-UI Titel**

**Aktuell:**
```
moOde Audio Player
```

**Neu:**
```
Ghetto Blaster - Ghetto OS
```

**Datei:** moOde Web-UI Konfiguration

---

### **3. Service-Namen**

**Aktuell:**
- `localdisplay.service`
- `peppymeter.service`
- `mpd.service`

**Neu (optional):**
- `ghetto-display.service`
- `ghetto-visualizer.service`
- `ghetto-player.service`

**Hinweis:** Service-Namen können bleiben, da sie intern sind.

---

### **4. Dokumentation**

**Dateien umbenennen/anpassen:**
- `COMPREHENSIVE_2_DAY_PLAN.md` → `GHETTO_OS_PROJECT_PLAN.md`
- `PI5_STATUS_REPORT.md` → `GHETTO_BLASTER_STATUS.md`
- `MOODE_AUDIO_REFERENCE.md` → `GHETTO_OS_REFERENCE.md`

---

### **5. Scripts**

**Scripts anpassen:**
- Kommentare aktualisieren
- Log-Nachrichten anpassen
- Ausgabe-Meldungen ändern

---

## 🔧 IMPLEMENTIERUNG

### **Boot-Screen-Nachricht:**

**Script: `update-ghetto-boot-message.sh`**
```bash
#!/bin/bash
# Aktualisiert Boot-Screen-Nachricht zu "Ghetto Blaster - Ghetto OS"

BOOT_MESSAGE="
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          Ghetto Blaster - Ghetto OS                         ║
║                                                              ║
║     Powered by Advanced AI Engineering                      ║
║     Developed with precision and care                       ║
║                                                              ║
║     \"Excellence is not a destination,                       ║
║      it's a continuous journey.\"                            ║
║                                                              ║
║     Built for audio enthusiasts who                        ║
║     demand perfection in every detail.                     ║
║                                                              ║
║     Welcome to your Ghetto Blaster!                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"

echo "$BOOT_MESSAGE" | sudo tee /etc/issue
echo "$BOOT_MESSAGE" | sudo tee /etc/motd
```

---

### **Web-UI Titel:**

**Option 1: moOde Konfiguration**
- moOde Web-UI Konfiguration anpassen
- Titel in PHP-Templates ändern

**Option 2: Custom CSS/JavaScript**
- Eigene CSS/JavaScript-Datei
- Titel überschreiben

---

## 📝 UMBENENNUNGS-CHECKLISTE

- [ ] Boot-Screen-Nachricht aktualisieren
- [ ] Web-UI Titel anpassen
- [ ] Dokumentation umbenennen
- [ ] Scripts aktualisieren
- [ ] Log-Nachrichten anpassen
- [ ] README aktualisieren

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Boot-Screen-Nachricht aktualisieren


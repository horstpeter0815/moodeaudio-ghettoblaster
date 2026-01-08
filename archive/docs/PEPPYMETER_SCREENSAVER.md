# PEPPYMETER SCREENSAVER

## 🎨 FUNKTION

PeppyMeter wird als Screensaver verwendet:
- **Nach 10 Minuten Inaktivität:** PeppyMeter erscheint, Chromium (Web-UI) wird versteckt
- **Bei Touch:** PeppyMeter verschwindet, Chromium (Web-UI) wird wieder angezeigt

---

## 🎛️ STEUERUNG

### **Service starten:**
```bash
sudo systemctl start peppymeter-screensaver.service
```

### **Service stoppen:**
```bash
sudo systemctl stop peppymeter-screensaver.service
```

### **Service aktivieren (Autostart):**
```bash
sudo systemctl enable peppymeter-screensaver.service
```

### **Service deaktivieren:**
```bash
sudo systemctl disable peppymeter-screensaver.service
```

### **Status prüfen:**
```bash
systemctl status peppymeter-screensaver.service
```

### **Logs anzeigen:**
```bash
journalctl -u peppymeter-screensaver.service -f
```

---

## ⚙️ KONFIGURATION

### **Timeout ändern (Standard: 10 Minuten = 600 Sekunden):**

Editieren: `sudo nano /usr/local/bin/peppymeter-screensaver.sh`

Zeile ändern:
```bash
INACTIVITY_TIMEOUT=600  # 10 minutes in seconds
```

Beispiele:
- 5 Minuten: `INACTIVITY_TIMEOUT=300`
- 15 Minuten: `INACTIVITY_TIMEOUT=900`
- 30 Minuten: `INACTIVITY_TIMEOUT=1800`

Nach Änderung Service neu starten:
```bash
sudo systemctl restart peppymeter-screensaver.service
```

---

## 🔧 WIE ES FUNKTIONIERT

1. **Überwachung:** Script überwacht Touch-Events und Inaktivitätszeit
2. **Timeout erreicht:** Nach 10 Minuten ohne Touch:
   - PeppyMeter wird angezeigt
   - Chromium-Fenster wird versteckt
3. **Touch erkannt:** Bei Berührung:
   - PeppyMeter wird versteckt
   - Chromium-Fenster wird wieder angezeigt
   - Timer wird zurückgesetzt

---

## 📝 HINWEISE

- **PeppyMeter Service:** Muss aktiv sein (`peppymeter.service`)
- **Chromium:** Muss laufen (`localdisplay.service`)
- **Touchscreen:** Muss funktionieren und erkannt werden
- **X Server:** Muss laufen (Display :0)

---

## 🐛 TROUBLESHOOTING

### **Screensaver startet nicht:**
```bash
# Prüfe Service-Status
systemctl status peppymeter-screensaver.service

# Prüfe Logs
journalctl -u peppymeter-screensaver.service -n 50
```

### **Touch wird nicht erkannt:**
```bash
# Prüfe Touchscreen
xinput list | grep -i "WaveShare"

# Teste Touch-Events
xinput test <touchscreen-id>
```

### **Fenster werden nicht gewechselt:**
```bash
# Prüfe ob Fenster existieren
xdotool search --classname peppymeter
xdotool search --classname chromium
```

---

**Status:** ✅ Aktiviert und konfiguriert


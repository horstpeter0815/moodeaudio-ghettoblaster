# PEPPYMETER STEUERUNG

## 🎛️ AKTIVIEREN / DEAKTIVIEREN

### **PeppyMeter STOPPEN (Deaktivieren):**
```bash
sudo systemctl stop peppymeter.service
```

### **PeppyMeter STARTEN (Aktivieren):**
```bash
sudo systemctl start peppymeter.service
```

### **PeppyMeter NEUSTARTEN:**
```bash
sudo systemctl restart peppymeter.service
```

---

## 📊 STATUS PRÜFEN

### **Aktuellen Status anzeigen:**
```bash
systemctl status peppymeter.service
```

### **Schnell-Check (aktiv/inaktiv):**
```bash
systemctl is-active peppymeter.service
```

---

## 🔄 AUTOSTART KONFIGURIEREN

### **Autostart AKTIVIEREN** (startet beim Boot):
```bash
sudo systemctl enable peppymeter.service
```

### **Autostart DEAKTIVIEREN** (startet nicht beim Boot):
```bash
sudo systemctl disable peppymeter.service
```

### **Autostart-Status prüfen:**
```bash
systemctl is-enabled peppymeter.service
```

---

## 🎨 SKIN WECHSELN

### **Skin ändern:**
1. Editieren: `sudo nano /etc/peppymeter/config.txt`
2. Zeile ändern: `meter = emerald` (oder blue, red, gold)
3. Neustarten: `sudo systemctl restart peppymeter.service`

**Verfügbare Skins:**
- `emerald` (grün)
- `blue` (blau)
- `red` (rot)
- `gold` (gold)

---

## 📝 KURZ-REFERENZ

| Aktion | Befehl |
|--------|--------|
| **Stoppen** | `sudo systemctl stop peppymeter.service` |
| **Starten** | `sudo systemctl start peppymeter.service` |
| **Neustarten** | `sudo systemctl restart peppymeter.service` |
| **Status** | `systemctl status peppymeter.service` |
| **Autostart ON** | `sudo systemctl enable peppymeter.service` |
| **Autostart OFF** | `sudo systemctl disable peppymeter.service` |

---

**Hinweis:** Alle Befehle müssen auf dem Raspberry Pi 5 ausgeführt werden (via SSH oder direkt).


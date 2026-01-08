# PEPPYMETER PYGAME FENSTER FIX

**Problem:** Falsches Fenster wird angezeigt

**Lösung:** PeppyMeter pygame-Fenster verwenden (nicht Chromium)

---

## ✅ IMPLEMENTIERT

### **1. PeppyMeter Config:**
- `output.display = True` → pygame-Fenster aktiviert
- `output.http = False` → HTTP deaktiviert (nicht benötigt)

### **2. PeppyMeter Service:**
- `/etc/systemd/system/peppymeter.service`
- `ExecStartPost=/usr/local/bin/peppymeter-position.sh` → Positioniert Fenster nach Start

### **3. Position-Script:**
- `/usr/local/bin/peppymeter-position.sh`
- Verschiebt pygame-Fenster auf Position 0,0
- Bringt Fenster in den Vordergrund

### **4. Chromium:**
- Gestoppt (nicht mehr benötigt)
- PeppyMeter pygame-Fenster wird direkt angezeigt

---

**Jetzt sollte das PeppyMeter pygame-Fenster sichtbar sein!**


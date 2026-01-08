# 🎯 Smart AI Manager Cockpit

**Grafisches Dashboard für System-Übersicht**

---

## 🚀 STARTEN

```bash
cd cockpit
./START_COCKPIT.sh
```

Oder manuell:
```bash
cd cockpit
pip3 install -r requirements.txt
python3 app.py
```

---

## 📊 DASHBOARD

Nach dem Start:
- **URL:** http://localhost:5000
- **Auto-Refresh:** Alle 5 Sekunden
- **API:** http://localhost:5000/api/status

---

## 🎨 FEATURES

### **Zentrum:**
- 🤖 Smart AI Manager (in der Mitte)
- Pulsierende Animation wenn aktiv

### **Branches (um das Zentrum):**
- 🔨 Build System
- 🖥️ Pi System
- 🗄️ Storage Management
- 🧪 Test System
- 🐛 Debugger
- 📚 Documentation
- 🤖 Autonomous System
- 🧹 Cleanup System

### **Status-Panel:**
- Speicherplatz (GB und %)
- Pi Status (Online/Offline + IP)
- Aktive Prozesse (Anzahl + Liste)
- Letzte Aktualisierung

### **Log-Panel:**
- Letzte 10 Log-Einträge
- Auto-Update

---

## 🔄 AUTO-UPDATE

- **Status-Update:** Alle 5 Sekunden
- **Pi-Check:** Kontinuierlich
- **Prozess-Monitoring:** Echtzeit

---

## 📋 API

### **GET /api/status**

Gibt JSON mit:
- `timestamp` - Zeitstempel
- `processes` - Aktive Prozesse
- `pi` - Pi-Status (online/offline, IP)
- `storage` - Speicherplatz-Info
- `logs` - Letzte Log-Einträge

---

**Status:** ✅ BEREIT


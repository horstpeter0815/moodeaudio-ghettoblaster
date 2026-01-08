# 🧹 STORAGE CLEANUP PLAN

**Datum:** 2025-12-08  
**Zweck:** Systematische Bereinigung und Strukturierung

---

## 📋 ANALYSE: WAS BRAUCHEN WIR?

### **✅ BEHALTEN (Kritisch für Zukunft):**

1. **Build-System:**
   - `imgbuild/` - Build-Konfiguration
   - `moode-source/` - Source-Dateien
   - `custom-components/` - Custom Components
   - `hifiberry-os/` - HiFiBerryOS Source

2. **Dokumentation:**
   - `THEORIE_ANALYSE_*.md` - Theorie-Dokumentation
   - `DEBUGGER_CONNECTION_GUIDE.md` - Debugger-Anleitung
   - Aktive Dokumentation

3. **Scripts (Wichtig):**
   - `AUTONOMOUS_WORK_SYSTEM.sh` - Autonomes System
   - `INTEGRATE_CUSTOM_COMPONENTS.sh` - Integration
   - `SETUP_NAS.sh` - NAS Setup
   - `ARCHIVE_TO_NAS.sh` - NAS Archivierung

4. **Services & Scripts:**
   - `custom-components/services/` - Alle Services
   - `custom-components/scripts/` - Alle Scripts

5. **Test-System:**
   - `complete_test_suite.sh` - Test-Suite
   - `complete-sim-test/` - Simulation-Tests

---

### **❌ LÖSCHEN (Geschichte/Garbage):**

1. **Boot-Versuche:**
   - Alte Boot-Logs
   - Boot-Versuche mit Config-Variationen
   - Command-Line-Versuche
   - Test-Boot-Versuche

2. **Alte Images:**
   - `.img` Dateien (außer aktuellste)
   - `.img.gz` Dateien
   - `.img.zip` Dateien

3. **Alte Logs:**
   - `.log` Dateien (älter als 30 Tage)
   - Build-Logs (älter als 7 Tage)

4. **Temporäre Dateien:**
   - `*.tmp`
   - `*.bak`
   - `*.backup`
   - `*.old`

5. **Duplikate:**
   - Mehrfache Versuche
   - Alte Test-Dateien

---

## 📁 NEUE STRUKTUR

```
cursor/
├── build/                    # Build-Artefakte
│   ├── images/              # Aktuelle Images
│   ├── logs/                # Build-Logs (7 Tage)
│   └── temp/                # Temporäre Build-Dateien
│
├── archive/                  # Archiv (→ NAS)
│   ├── old-images/          # Alte Images
│   ├── old-logs/            # Alte Logs (>30 Tage)
│   └── history/             # Historische Versuche
│
├── logs/                     # Aktive Logs
│   ├── autonomous/          # Autonomes System
│   ├── build/               # Build-Logs
│   └── test/                # Test-Logs
│
├── tests/                    # Test-System
│   ├── unit/                # Unit-Tests
│   ├── integration/         # Integration-Tests
│   └── simulation/          # Simulation-Tests
│
├── docs/                     # Dokumentation
│   ├── theory/              # Theorie-Analysen
│   ├── guides/              # Anleitungen
│   └── active/              # Aktive Dokumentation
│
└── scripts/                  # Scripts
    ├── build/               # Build-Scripts
    ├── deploy/              # Deploy-Scripts
    └── maintenance/         # Maintenance-Scripts
```

---

## 🔄 LOGGING-SYSTEM

### **Log-Struktur:**
```
logs/
├── autonomous/
│   └── autonomous-work-YYYY-MM-DD.log
├── build/
│   └── build-YYYY-MM-DD-HHMMSS.log
├── test/
│   └── test-YYYY-MM-DD-HHMMSS.log
└── system/
    └── system-YYYY-MM-DD.log
```

### **Log-Rotation:**
- Aktive Logs: 7 Tage
- Archivierte Logs: 30 Tage → NAS
- Alte Logs: >30 Tage → NAS → nach 2-4 Wochen löschen

---

## 🗄️ NAS-INTEGRATION

### **NAS-Struktur:**
```
fritz-nas-archive/
├── hifiberry-project-archive/
│   ├── images/              # Alte Images
│   ├── logs/                # Alte Logs
│   ├── history/             # Historische Versuche
│   └── temp/                # Temp-Ordner (2-4 Wochen)
│       └── big-data-dumps/  # Große Daten-Dumps
```

### **Auto-Cleanup:**
- Temp-Ordner: Nach 2-4 Wochen automatisch löschen
- Alte Archive: Nach 6 Monaten prüfen

---

## ✅ CLEANUP-PROZESS

1. **Analyse** (was brauchen wir?)
2. **Kategorisierung** (behalten vs. löschen)
3. **Archivierung** (→ NAS)
4. **Löschung** (nur nach Archivierung)
5. **Strukturierung** (neue Ordnerstruktur)
6. **Dokumentation** (was wurde gemacht)

---

**Status:** 📋 PLAN ERSTELLT


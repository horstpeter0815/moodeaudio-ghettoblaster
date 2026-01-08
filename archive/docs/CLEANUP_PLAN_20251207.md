# 🧹 CLEANUP PLAN - SYSTEM AUFRÄUMEN

**Datum:** 2025-12-07  
**Status:** ✅ IN ARBEIT  
**Zweck:** System gründlich aufräumen, saubere Struktur etablieren

---

## 📊 AKTUELLER STATUS

- **912 .md Dateien** im Root-Verzeichnis
- **Viele Redundanzen:** FINAL, COMPLETE, STATUS, SUMMARY
- **Viele Marketing-Namen:** Verstoß gegen Namenskonvention
- **Veraltete Dateien:** > 90 Tage alt

---

## 🎯 CLEANUP-STRATEGIE

### **1. Kategorien:**

#### **✅ BEHALTEN (Aktive Dokumentation):**
- Master-Dokumente (`CORE_KNOWLEDGE_MASTER.md`, etc.)
- Aktive Konfiguration (`NAMING_CONVENTION.md`, etc.)
- Aktuelle Fixes (letzte 30 Tage)
- Wissensbasen (`REPOSITORY_KNOWLEDGE_BASE.md`, etc.)

#### **📦 ARCHIVIEREN (Temp-Ordner, 2 Wochen):**
- Veraltete Status-Reports (> 30 Tage)
- Redundante Dokumentation
- Test-Ergebnisse (älter als 7 Tage)
- Zwischenstände

#### **🗑️ LÖSCHEN (Sofort):**
- Doppelte Dateien
- Leere/ungültige Dateien
- Veraltete Marketing-Namen (> 90 Tage)

---

## 📋 CLEANUP-PROTOKOLL

### **Schritt 1: Temp-Ordner erstellen**
```bash
mkdir -p temp-archive-20251207
```

### **Schritt 2: Kategorisieren**
- Dateien nach Kategorien sortieren
- Redundanzen identifizieren
- Veraltete markieren

### **Schritt 3: Verschieben**
- Archivieren → `temp-archive-20251207/`
- Löschen → Direkt löschen

### **Schritt 4: Dokumentation**
- Cleanup dokumentieren
- Neue Struktur dokumentieren
- Index aktualisieren

---

## 🔄 NACH CLEANUP

### **Neue Struktur:**
```
documentation/
├── master/              # Master-Dokumente
├── active/              # Aktive Dokumentation
├── knowledge/           # Wissensbasen
└── fixes/               # Aktuelle Fixes
```

### **Regeln:**
- ✅ Nur beschreibende Namen
- ✅ Chronologische Datierung
- ✅ Keine Marketing-Namen
- ✅ Strukturierte Kategorien

---

**Status:** ✅ PLAN ERSTELLT  
**Nächster Schritt:** Cleanup ausführen


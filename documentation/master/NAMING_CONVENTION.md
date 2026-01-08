# 📋 NAMENSKONVENTION - PROJEKT-DATEIEN

**Datum:** 2025-12-07  
**Zweck:** Klare, chronologische und sinnvolle Namensgebung für alle Projekt-Dateien

---

## ✅ PRINZIPIEN

### **1. Chronologische Namen:**
- Format: `KATEGORIE_YYYYMMDD.sh` oder `KATEGORIE_YYYYMMDD.md`
- Beispiel: `BUILD_20251207.sh`, `SSH_FIX_20251207.sh`

### **2. Beschreibende Namen:**
- Was macht die Datei? → Name spiegelt Funktion wider
- Beispiel: `BUILD.sh`, `SSH_FIX.sh`, `NETWORK_FIX.sh`

### **3. KEINE Marketing-Namen:**
- ❌ KEIN "Guaranteed", "Final", "Complete", "Ultimate"
- ❌ KEIN "Now", "Quick", "Easy"
- ✅ Klare, technische Namen

---

## 📋 NAMENSKATEGORIEN

### **Build-Scripts:**
- `BUILD_YYYYMMDD.sh` - Haupt-Build-Script
- `INTEGRATE_CUSTOM_COMPONENTS.sh` - Integration (kein Datum, da permanent)

### **Fix-Scripts:**
- `SSH_FIX_YYYYMMDD.sh` - SSH-Fix
- `NETWORK_FIX_YYYYMMDD.sh` - Network-Fix
- `DISPLAY_FIX_YYYYMMDD.sh` - Display-Fix

### **Test-Scripts:**
- `TEST_YYYYMMDD.sh` - Test-Suite
- `SIMULATION_YYYYMMDD.sh` - Simulation

### **Dokumentation:**
- `STATUS_YYYYMMDD.md` - Status-Dokument
- `SOLUTION_YYYYMMDD.md` - Lösungs-Dokument
- `ANALYSIS_YYYYMMDD.md` - Analyse-Dokument

### **Services:**
- `ssh-robust.service` - Robuste SSH-Lösung (kein "guaranteed")
- `network-robust.service` - Robuste Network-Lösung

---

## 🔄 UMBENENNUNGEN (2025-12-07)

### **Alte Namen → Neue Namen:**
- `BUILD_NOW_GUARANTEED.sh` → `BUILD_20251207.sh`
- `SSH_GUARANTEED_FIX.sh` → `SSH_FIX_20251207.sh`
- `NETWORK_GUARANTEED_FIX.sh` → `NETWORK_FIX_20251207.sh`
- `FINAL_GUARANTEED_SOLUTION.md` → `SSH_NETWORK_SOLUTION_20251207.md`

### **Services:**
- `ssh-guaranteed.service` → `ssh-robust.service` (in zukünftigen Builds)
- `network-guaranteed.service` → `network-robust.service` (in zukünftigen Builds)

---

## 📋 BEISPIELE

### **Gut:**
- ✅ `BUILD_20251207.sh`
- ✅ `SSH_FIX_20251207.sh`
- ✅ `TEST_SUITE_20251207.sh`
- ✅ `DISPLAY_CONFIG_20251207.md`

### **Schlecht:**
- ❌ `BUILD_NOW_GUARANTEED.sh`
- ❌ `FINAL_COMPLETE_SOLUTION.md`
- ❌ `QUICK_EASY_FIX.sh`
- ❌ `ULTIMATE_GUARANTEED_FIX.sh`

---

## 🎯 ZUKÜNFTIGE REGELN

1. **Chronologisch:** Datum im Format `YYYYMMDD`
2. **Beschreibend:** Name sagt, was die Datei macht
3. **Technisch:** Keine Marketing-Begriffe
4. **Konsistent:** Gleiche Kategorien = gleiche Namensstruktur

---

**Status:** ✅ NAMENSKONVENTION DOKUMENTIERT  
**Gilt ab:** 2025-12-07

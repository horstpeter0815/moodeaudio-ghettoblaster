# ✅ NAMENSKONVENTION VERBESSERT - 2025-12-07

**Datum:** 2025-12-07  
**Status:** ✅ IMPLEMENTIERT  
**Zweck:** Chronologisch sortierbare Image-Namen

---

## 🔧 ÄNDERUNGEN

### **Vorher:**
- Format: `2025-12-07-moode-r1001-arm64-lite.img`
- Problem: Nicht optimal sortierbar, Bindestriche im Datum

### **Nachher:**
- Format: `moode-r1001-arm64-lite-20251207_233829.img`
- Vorteile:
  - ✅ Chronologisch sortierbar
  - ✅ Klare Trennung Datum/Zeit (`_`)
  - ✅ Keine Bindestriche im Datum
  - ✅ Zeitstempel enthalten (HHMMSS)

---

## 📋 IMPLEMENTIERTE ÄNDERUNGEN

### **Datei:** `imgbuild/pi-gen-64/build.sh`

**Geändert:**
```bash
# Alt:
export IMG_DATE="${IMG_DATE:-"$(date +%Y-%m-%d)"}"
export IMG_FILENAME="${IMG_FILENAME:-"${IMG_DATE}-${IMG_NAME}"}"

# Neu:
export IMG_DATE="${IMG_DATE:-"$(date +%Y%m%d_%H%M%S)"}"
export IMG_FILENAME="${IMG_FILENAME:-"${IMG_NAME}-${IMG_DATE}"}"
```

**Ergebnis:**
- `IMG_DATE`: `20251207_233829` (statt `2025-12-07`)
- `IMG_FILENAME`: `moode-r1001-arm64-20251207_233829` (statt `2025-12-07-moode-r1001-arm64`)

---

## ✅ VORTEILE

1. **Chronologische Sortierung:**
   - `ls -1 *.img` sortiert automatisch chronologisch
   - Neuestes Image ist immer das letzte

2. **Klare Struktur:**
   - `NAME-TIMESTAMP.img` statt `TIMESTAMP-NAME.img`
   - Name zuerst, dann Zeitstempel

3. **Konsistenz:**
   - Gleiches Format wie andere Dateien (`YYYYMMDD_HHMMSS`)
   - Keine Bindestriche im Datum

---

## 📋 NÄCHSTER BUILD

Beim nächsten Build wird das Image automatisch mit dem neuen Format benannt:
- `moode-r1001-arm64-lite-20251207_HHMMSS.img`

---

**Status:** ✅ NAMENSKONVENTION VERBESSERT  
**Nächster Build verwendet automatisch das neue Format**


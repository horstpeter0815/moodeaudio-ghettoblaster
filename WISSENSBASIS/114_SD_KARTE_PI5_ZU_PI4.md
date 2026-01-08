# SD-KARTE: PI 5 → PI 4 MOODE

**Datum:** 03.12.2025  
**SD-Karte:** /dev/disk4 (63.9 GB)  
**Status:** ✅ Identifiziert, ⏳ Bereit für moOde Pi 4

---

## IDENTIFIZIERTES SYSTEM

### **Aktuell auf SD-Karte:**
- **OS:** moOde Audio
- **Hardware:** Raspberry Pi 5
- **Audio:** HiFiBerry AMP100 (`dtoverlay=hifiberry-amp100-pi5`)
- **Backup:** `SD_CARD_BACKUPS/20251203_020434/` (86 MB)

---

## NÄCHSTE SCHRITTE

### **1. moOde Image für Pi 4:**

**Option A: Herunterladen**
```bash
./download-moode-pi4.sh
```

**Option B: Manuell**
- https://moodeaudio.org/
- moOde r900 (oder neueste Version)
- ARM64 für Pi 4

### **2. SD-Karte brennen:**

```bash
# Image-Pfad setzen
export MOODE_IMAGE=/path/to/moode-r900-arm64.img

# Brennen
./burn-moode-pi4.sh
```

**Oder direkt:**
```bash
MOODE_IMAGE=/path/to/moode-r900-arm64.img ./burn-moode-pi4.sh
```

---

## SCRIPTE

1. **download-moode-pi4.sh** - Herunterladen (falls automatisch möglich)
2. **burn-moode-pi4.sh** - Image auf SD-Karte brennen

---

## BACKUP

**Altes System gesichert in:**
- `SD_CARD_BACKUPS/20251203_020434/`

**Kann wiederhergestellt werden falls nötig.**

---

**Status:** ⏳ Warte auf moOde Image für Pi 4


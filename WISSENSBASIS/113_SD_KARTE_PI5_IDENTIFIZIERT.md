# SD-KARTE PI 5 IDENTIFIZIERT

**Datum:** 03.12.2025  
**SD-Karte:** /dev/disk4 (63.9 GB)  
**Status:** ✅ Identifiziert und gesichert

---

## SYSTEM-IDENTIFIKATION

### **Gefundenes System:**
- **OS:** moOde Audio
- **Hardware:** Raspberry Pi 5
- **Audio:** HiFiBerry AMP100 (`dtoverlay=hifiberry-amp100-pi5`)
- **Display:** Standard (kein spezielles Overlay)

### **Config.txt:**
```
dtoverlay=hifiberry-amp100-pi5
dtoverlay=vc4-kms-v3d
dtparam=audio=on
display_auto_detect=1
```

### **Cmdline.txt:**
```
console=serial0,115200 console=tty1 root=PARTUUID=976f52d1-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=DE
```

---

## BACKUP

**Verzeichnis:** `SD_CARD_BACKUPS/20251203_020434/`  
**Größe:** 86 MB  
**Inhalt:** Komplette Boot-Partition

---

## NÄCHSTER SCHRITT

**Ziel:** moOde Audio für Pi 4 auf SD-Karte brennen

**Vorgehen:**
1. ⏳ moOde Image für Pi 4 herunterladen
2. ⏳ SD-Karte formatieren
3. ⏳ moOde Image brennen

**Script:** `burn-moode-pi4.sh` (bereit)

---

**Status:** ✅ Identifiziert, ⏳ Bereit für moOde Pi 4


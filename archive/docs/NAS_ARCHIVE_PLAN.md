# 📦 FRITZ NAS ARCHIVIERUNGS-PLAN

**Datum:** 2025-12-08  
**NAS:** Fritz Box mit 500GB verfügbar  
**Geschwindigkeit:** Langsam (nur für Archive, nicht für aktive Arbeit)

---

## 🎯 KONZEPT

### **Lokaler Speicher (Mac):**
- ✅ Schnell
- ✅ Für aktive Arbeit
- ✅ Aktuelle Builds, Scripts, Code

### **NAS (Fritz Box):**
- ⚠️ Langsam
- ✅ Für Archive
- ✅ Alte Builds, Logs, Backups
- ✅ Nicht mehr benötigte Dateien

---

## 📋 WAS KANN ARCHIVIERT WERDEN?

### **1. Alte Build-Logs (~5-10GB)**
```
*.log
imgbuild/deploy/*.log
complete-sim-logs/
system-sim-test/
```

### **2. Alte Kernel-Builds (~3-5GB)**
```
kernel-build/ (alte Versionen)
drivers-repos/ (alte Builds)
```

### **3. Alte Dokumentation/Backups (~1-2GB)**
```
SD_CARD_BACKUPS/
temp-archive-*/
```

### **4. Komplettes Projekt-Backup (~30GB)**
- Vollständiges Backup des Projekts
- Nur bei Bedarf

**Gesamt archivierbar:** ~10-20GB (ohne Vollbackup)

---

## 🚀 VERWENDUNG

### **Option 1: Automatisches Script**
```bash
# NAS konfigurieren
export NAS_HOST="fritz.box"
export NAS_SHARE="archive"
export NAS_USER="admin"
export NAS_PASS="ihr-passwort"

# Archivierung starten
./ARCHIVE_TO_NAS.sh
```

### **Option 2: Manuell mounten**
```bash
# NAS mounten
mkdir -p /Volumes/fritz-nas-archive
mount_smbfs //admin:passwort@fritz.box/archive /Volumes/fritz-nas-archive

# Dateien kopieren
rsync -av --progress alte-dateien/ /Volumes/fritz-nas-archive/hifiberry-project/

# Nach Kopie lokal löschen (optional)
rm -rf alte-dateien/
```

---

## ⚙️ KONFIGURATION

### **NAS-Verbindung prüfen:**
```bash
# Ping testen
ping -c 1 fritz.box

# Shares anzeigen
smbutil view //fritz.box
```

### **Mount-Point:**
- Standard: `/Volumes/fritz-nas-archive`
- Kann angepasst werden in `ARCHIVE_TO_NAS.sh`

---

## 📊 SPEICHERPLATZ-STRATEGIE

### **Aktuell:**
- Mac frei: 135GB
- Projekt: 30GB
- Verfügbar: 105GB für aktive Arbeit

### **Nach Archivierung:**
- Mac frei: ~150GB (nach Archivierung von ~15GB)
- NAS verwendet: ~15GB von 500GB
- NAS verfügbar: ~485GB für weitere Archive

### **Für 500GB Projekt-Speicher:**
- Lokal: 135GB verfügbar
- NAS: 500GB verfügbar (langsam)
- **Gesamt: 635GB verfügbar**

---

## ⚠️ WICHTIGE HINWEISE

1. **NAS ist langsam** - nur für Archive nutzen
2. **Backup vor Löschen** - immer erst archivieren, dann löschen
3. **Regelmäßige Archivierung** - alte Logs/Builds regelmäßig archivieren
4. **Aktive Arbeit lokal** - alle aktiven Dateien bleiben auf Mac

---

## 🔄 REGELMÄSSIGE ARCHIVIERUNG

### **Wöchentlich:**
- Alte Log-Dateien (>1 Woche)
- Alte Build-Artefakte

### **Monatlich:**
- Komplettes Projekt-Backup
- Alte Kernel-Builds

### **Bei Bedarf:**
- Große temporäre Dateien
- Nicht mehr benötigte Builds

---

**Status:** ✅ Script bereit, wartet auf NAS-Verbindung


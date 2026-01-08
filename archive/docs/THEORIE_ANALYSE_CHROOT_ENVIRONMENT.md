# 📚 THEORIE-ANALYSE: CHROOT-ENVIRONMENT

**Datum:** 2025-12-08  
**Zweck:** Vollständiges Verständnis des Chroot-Environments im Build-Prozess

---

## 🔍 WAS IST CHROOT?

### **Definition:**
- **chroot** = "change root"
- Ändert das Root-Verzeichnis für einen Prozess
- Prozess sieht nur das neue Root-Verzeichnis
- Kann nicht auf Dateien außerhalb zugreifen

### **Im Build-Kontext:**
- **HOST:** Build-System (Mac/Docker)
- **CHROOT:** rootfs-Verzeichnis (zukünftiges Pi-System)
- **Zweck:** Befehle im Kontext des Pi-Systems ausführen

---

## 🏗️ PI-GEN BUILD-PROZESS

### **Struktur:**
```
pi-gen-64/
├── work/
│   └── stage3/
│       └── rootfs/          ← Das ist das CHROOT
│           ├── bin/
│           ├── etc/
│           ├── usr/
│           └── ...
└── stage3/
    └── 03-ghettoblaster-custom/
        ├── 00-deploy.sh      ← Läuft AUF HOST
        ├── 00-run.sh         ← Wrapper für chroot
        └── 00-run-chroot.sh  ← Läuft IM CHROOT
```

---

## 📋 DATEIEN IM BUILD-PROZESS

### **1. 00-deploy.sh (HOST)**
```bash
# Läuft AUF HOST (nicht im chroot)
# Kopiert Dateien von moode-source/ → rootfs/
cp -r "${MOODE_SOURCE}/lib/systemd/system/"* "${ROOTFS}/lib/systemd/system/"
cp -r "${MOODE_SOURCE}/usr/local/bin/"* "${ROOTFS}/usr/local/bin/"
```

**Was passiert:**
- Dateien werden von `moode-source/` nach `rootfs/` kopiert
- **Kann KEINE systemd-Befehle ausführen** (rootfs ist noch nicht bootfähig)
- **Kann KEINE User erstellen** (rootfs ist noch nicht aktiv)
- **Kann KEINE Pakete installieren** (rootfs ist noch nicht aktiv)

**Warum wichtig:**
- Dateien müssen VOR chroot kopiert werden
- Sonst sind sie im chroot nicht verfügbar

---

### **2. 00-run.sh (HOST → CHROOT)**
```bash
# Wrapper-Script
# Führt 00-run-chroot.sh IM CHROOT aus
```

**Was passiert:**
- Script wird in chroot-Umgebung ausgeführt
- Alle Befehle laufen im Kontext des rootfs
- Kann systemd-Befehle ausführen
- Kann User erstellen
- Kann Pakete installieren

---

### **3. 00-run-chroot.sh (CHROOT)**
```bash
# Läuft IM CHROOT (im rootfs)
# Kann systemd-Befehle ausführen
systemctl enable first-boot-setup.service
useradd -m -s /bin/bash -u 1000 -g 1000 andre
```

**Was passiert:**
- Befehle laufen im Kontext des Pi-Systems
- `systemctl enable` erstellt Symlinks in `/etc/systemd/system/`
- `useradd` erstellt User im rootfs
- `apt-get install` installiert Pakete im rootfs

**KRITISCH:**
- Services werden nur **enabled**, nicht **gestartet**
- Services starten erst beim **ERSTEN BOOT** des Pi

---

## ⚠️ PROBLEM: "WILL BE APPLIED ON FIRST BOOT"

### **Was passiert im chroot:**
```bash
# Im 00-run-chroot.sh:
if ! command -v dtc &> /dev/null; then
    echo "⚠️  dtc not found, overlays will be compiled on first boot"
fi
```

**Problem:**
- Es wird nur eine **WARNUNG** ausgegeben
- **KEIN Script** wird erstellt, das das beim ersten Boot macht
- **KEIN Service** wird erstellt, der das beim ersten Boot macht

**Ergebnis:**
- Overlays werden **NICHT** kompiliert
- Hardware funktioniert **NICHT**
- Display funktioniert **NICHT**

---

## ✅ LÖSUNG: FIRST-BOOT-SETUP

### **Was wurde gemacht:**

1. **first-boot-setup.service erstellt**
   - Wird im chroot enabled (`systemctl enable`)
   - Startet automatisch beim ersten Boot

2. **first-boot-setup.sh erstellt**
   - Wird im chroot kopiert
   - Führt alle "will be applied on first boot" Dinge aus

3. **Marker-File-Mechanismus**
   - Prüft ob bereits ausgeführt (`/var/lib/first-boot-setup.done`)
   - Läuft nur einmal beim ersten Boot

---

## 🔄 CHROOT vs. HOST - VERGLEICH

| Aspekt | HOST (00-deploy.sh) | CHROOT (00-run-chroot.sh) |
|--------|---------------------|---------------------------|
| **Läuft auf** | Build-System | rootfs (Pi-System) |
| **Kann systemd** | ❌ Nein | ✅ Ja |
| **Kann User erstellen** | ❌ Nein | ✅ Ja |
| **Kann Pakete installieren** | ❌ Nein | ✅ Ja |
| **Kann Services starten** | ❌ Nein | ❌ Nein (nur enable) |
| **Services starten** | ❌ Nein | ❌ Nein (erst beim Boot) |

---

## 📊 WAS PASSIERT WANN?

### **Build-Zeit (chroot):**
1. Dateien werden kopiert (00-deploy.sh)
2. Services werden enabled (00-run-chroot.sh)
3. User werden erstellt (00-run-chroot.sh)
4. Pakete werden installiert (00-run-chroot.sh)
5. **ABER:** Services werden **NICHT** gestartet

### **Boot-Zeit (Pi):**
1. Kernel bootet
2. systemd startet
3. Services starten (nach Abhängigkeiten)
4. **first-boot-setup.service** läuft einmal
5. Overlays werden kompiliert
6. Patches werden angewendet
7. Scripts werden erstellt
8. Normale Services starten

---

## 🎯 KRITISCHE ERKENNTNISSE

### **1. Chroot kann Services nur ENABLEN, nicht STARTEN**
- `systemctl enable` erstellt Symlinks
- `systemctl start` funktioniert nicht im chroot (System läuft nicht)
- Services starten erst beim Boot

### **2. "Will be applied on first boot" bedeutet NICHTS ohne Script**
- Nur eine Warnung reicht nicht
- Es muss ein Script geben, das das macht
- Es muss ein Service geben, der das Script ausführt

### **3. first-boot-setup.service ist KRITISCH**
- Ohne ihn werden "will be applied on first boot" Dinge NICHT gemacht
- System funktioniert nicht beim ersten Boot
- Hardware funktioniert nicht

---

## ✅ ZUSAMMENFASSUNG

**Chroot-Environment:**
- Ermöglicht Befehle im Kontext des Pi-Systems
- Kann Services enable, aber nicht starten
- Services starten erst beim Boot

**Problem war:**
- "Will be applied on first boot" Dinge wurden nicht gemacht
- Kein Script, kein Service, nichts

**Lösung:**
- first-boot-setup.service erstellt
- Läuft automatisch beim ersten Boot
- Macht alle notwendigen Dinge

---

**Status:** ✅ CHROOT-ENVIRONMENT VOLLSTÄNDIG VERSTANDEN


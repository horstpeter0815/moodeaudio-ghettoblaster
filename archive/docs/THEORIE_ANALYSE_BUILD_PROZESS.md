# 📚 THEORIE-ANALYSE: BUILD-PROZESS

**Datum:** 2025-12-08  
**Zweck:** Vollständiges Verständnis des Build-Prozesses

---

## 🔨 PI-GEN BUILD-PROZESS

### **Struktur:**
```
pi-gen-64/
├── stage0/  - Basis-Setup (apt, locale, firmware)
├── stage1/  - Boot-Dateien, Netzwerk, Pakete
├── stage2/  - System-Tweaks, Cloud-Init, moOde-Install
├── stage3/  - moOde-Install, Custom Components
│   └── 03-ghettoblaster-custom/
│       ├── 00-deploy.sh      - Kopiert Dateien VOR chroot
│       ├── 00-run.sh          - Wrapper für chroot
│       └── 00-run-chroot.sh   - Läuft IM chroot
├── stage4/  - Optionale Pakete
└── stage5/  - Optionale Extras
```

### **Build-Ablauf:**

1. **Stage 0-2:** Basis-System wird aufgebaut
2. **Stage 3:** moOde wird installiert
3. **Stage 3 - 03-ghettoblaster-custom:**
   - **00-deploy.sh** läuft AUF HOST (nicht im chroot)
     - Kopiert Services von `moode-source/lib/systemd/system/` → `rootfs/lib/systemd/system/`
     - Kopiert Scripts von `moode-source/usr/local/bin/` → `rootfs/usr/local/bin/`
   - **00-run-chroot.sh** läuft IM CHROOT (im rootfs)
     - Erstellt User 'andre'
     - Kompiliert Overlays (falls dtc verfügbar)
     - Wendet worker.php patch an
     - Aktiviert Services mit `systemctl enable`
     - Setzt Permissions

### **KRITISCHER PUNKT:**
- `systemctl enable` im chroot aktiviert Services für den BOOT
- Services werden NICHT gestartet (`systemctl start` fehlt)
- Services starten erst beim ERSTEN BOOT des Pi

---

## 🚀 BOOT-SEQUENZ (SYSTEMD)

### **Boot-Targets (Reihenfolge):**
1. `sysinit.target` - System-Initialisierung
2. `basic.target` - Basis-Services
3. `multi-user.target` - Multi-User-Modus
4. `graphical.target` - Grafisches System (falls aktiviert)

### **Service-Start-Reihenfolge:**

#### **1. Early Boot (vor multi-user.target):**
- `enable-ssh-early.service` - SSH so früh wie möglich aktivieren
- `fix-user-id.service` - User UID prüfen/korrigieren
- `fix-ssh-sudoers.service` - SSH/Sudoers fixen

#### **2. First Boot (einmalig):**
- `first-boot-setup.service` - **NEU!** Läuft einmal beim ersten Boot
  - Kompiliert Overlays
  - Wendet worker.php patch an
  - Erstellt fehlende Scripts
  - Prüft User andre

#### **3. Network (nach network.target):**
- `network-guaranteed.service` - Netzwerk garantieren
- `fix-network-ip.service` - IP-Adresse fixen

#### **4. Display (nach graphical.target):**
- `disable-console.service` - Console auf tty1 deaktivieren
- `xserver-ready.service` - X Server bereit machen
- `auto-fix-display.service` - Display-Service fixen (falls fehlt)
- `localdisplay.service` - Chromium starten

### **Service-Abhängigkeiten:**

```
enable-ssh-early.service
  └─> fix-ssh-sudoers.service
      └─> fix-user-id.service
          └─> first-boot-setup.service (einmalig)
              └─> network.target
                  └─> auto-fix-display.service
                      └─> graphical.target
                          └─> xserver-ready.service
                              └─> localdisplay.service
```

---

## ⚠️ PROBLEM: "WILL BE APPLIED ON FIRST BOOT"

### **Was passiert im Build (chroot):**
```bash
# Im 00-run-chroot.sh:
if ! command -v dtc &> /dev/null; then
    echo "⚠️  dtc not found, overlays will be compiled on first boot"
fi
```

**Problem:** Es wird nur eine WARNUNG ausgegeben, aber **KEIN Script erstellt**, das das beim ersten Boot macht!

### **Lösung:**
- `first-boot-setup.service` wurde erstellt
- Läuft automatisch beim ersten Boot
- Führt alle "will be applied on first boot" Dinge aus

---

## 🔍 CHROOT vs. HOST

### **00-deploy.sh (HOST):**
- Läuft auf dem Build-System (Mac/Docker)
- Kopiert Dateien von `moode-source/` → `rootfs/`
- **Kann KEINE systemd-Befehle ausführen** (rootfs ist noch nicht bootfähig)

### **00-run-chroot.sh (CHROOT):**
- Läuft IM rootfs (chroot-Umgebung)
- Kann `systemctl enable` ausführen
- Kann User erstellen
- Kann Pakete installieren
- **ABER:** Services werden nur enabled, nicht gestartet

---

## 📋 WAS PASSIERT BEIM ERSTEN BOOT?

### **1. Kernel bootet**
- Lädt Device-Tree-Overlays
- Initialisiert Hardware

### **2. systemd startet**
- Startet `sysinit.target`
- Startet `basic.target`
- Startet `multi-user.target`

### **3. Services starten (nach Abhängigkeiten):**
- `enable-ssh-early.service` → SSH aktivieren
- `fix-user-id.service` → User prüfen
- `first-boot-setup.service` → **Overlays kompilieren, Patches anwenden**
- `network.target` → Netzwerk aktivieren
- `graphical.target` → X Server starten
- `xserver-ready.service` → X Server bereit machen
- `localdisplay.service` → Chromium starten

### **KRITISCH:**
- Wenn `first-boot-setup.service` fehlt → Overlays werden NICHT kompiliert
- Wenn Overlays nicht kompiliert → Hardware funktioniert nicht
- Wenn Hardware nicht funktioniert → Display funktioniert nicht

---

## ✅ LÖSUNG: FIRST-BOOT-SETUP

### **Was macht first-boot-setup.service:**
1. Prüft ob bereits ausgeführt (Marker-File)
2. Kompiliert Overlays (falls dtc verfügbar)
3. Wendet worker.php patch an
4. Erstellt fehlende Scripts
5. Prüft/erstellt User andre
6. Aktiviert Services
7. Erstellt Marker-File (läuft nur einmal)

### **Warum wichtig:**
- Viele Dinge können im chroot NICHT gemacht werden (dtc fehlt, etc.)
- Müssen beim ersten Boot gemacht werden
- **Ohne first-boot-setup.service passiert das NICHT automatisch**

---

## 🎯 ZUSAMMENFASSUNG

**Build-Prozess:**
1. HOST kopiert Dateien (00-deploy.sh)
2. CHROOT aktiviert Services (00-run-chroot.sh)
3. Services werden enabled, aber nicht gestartet

**Boot-Prozess:**
1. systemd startet Services nach Abhängigkeiten
2. first-boot-setup.service läuft einmal
3. Alle "will be applied on first boot" Dinge werden gemacht
4. Dann starten normale Services

**Problem war:**
- first-boot-setup.service fehlte
- "Will be applied on first boot" Dinge wurden NICHT gemacht
- System funktionierte nicht beim ersten Boot

**Lösung:**
- first-boot-setup.service erstellt
- Läuft automatisch beim ersten Boot
- Macht alle notwendigen Dinge

---

**Status:** ✅ THEORIE VERSTANDEN


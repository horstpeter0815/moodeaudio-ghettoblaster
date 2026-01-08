# 📚 THEORIE-ANALYSE: BOOT-SEQUENZ

**Datum:** 2025-12-08  
**Zweck:** Vollständiges Verständnis der Boot-Sequenz vom Kernel bis zu den Services

---

## 🚀 SYSTEMD BOOT-SEQUENZ (VOLLSTÄNDIG)

### **1. Kernel Boot**
```
Kernel startet
  └─> Init-System (systemd) startet
      └─> sysinit.target
```

### **2. sysinit.target**
- **Zweck:** System-Initialisierung
- **Services:** Basis-System-Services
- **Wichtig:** Dateisysteme mounten, Basis-Setup

### **3. basic.target**
- **Zweck:** Basis-Services bereit
- **Services:** Alle grundlegenden Services
- **Wichtig:** System ist grundsätzlich funktionsfähig

### **4. local-fs.target**
- **Zweck:** Lokale Dateisysteme gemountet
- **Services:** Mount-Services
- **Wichtig:** Dateisysteme sind verfügbar

### **5. network-pre.target**
- **Zweck:** Netzwerk-Vorbereitung
- **Services:** Netzwerk-Interface-Vorbereitung
- **Wichtig:** Netzwerk-Hardware initialisiert

### **6. network.target**
- **Zweck:** Netzwerk bereit
- **Services:** Netzwerk-Interfaces aktiv
- **Wichtig:** Netzwerk ist verfügbar (aber nicht unbedingt verbunden)

### **7. network-online.target**
- **Zweck:** Netzwerk verbunden
- **Services:** Netzwerk-Verbindung etabliert
- **Wichtig:** Netzwerk ist tatsächlich verbunden (DHCP, etc.)

### **8. multi-user.target**
- **Zweck:** Multi-User-Modus
- **Services:** Alle User-Services
- **Wichtig:** System ist für Benutzer bereit

### **9. graphical.target**
- **Zweck:** Grafisches System
- **Services:** X Server, Display-Manager
- **Wichtig:** Grafisches System ist bereit

---

## 📋 UNSERE SERVICES IN DER BOOT-SEQUENZ

### **Phase 1: Early Boot (vor multi-user.target)**

#### **ssh-guaranteed.service**
```
After=sysinit.target basic.target
Before=network.target moode-startup.service
```
- **Startet:** Sehr früh, nach sysinit/basic
- **Zweck:** SSH garantieren (9 Sicherheitsebenen)
- **Kritisch:** Muss vor moOde laufen

#### **network-guaranteed.service**
```
After=network-pre.target
Before=network.target
```
- **Startet:** Vor network.target
- **Zweck:** Netzwerk garantieren (4 Fallback-Mechanismen)
- **Kritisch:** Stellt sicher dass Netzwerk funktioniert

#### **enable-ssh-early.service**
```
After=network-online.target
Before=moode-startup.service
```
- **Startet:** Nach network-online, vor moOde
- **Zweck:** SSH aktivieren bevor moOde es deaktivieren kann
- **Kritisch:** Muss vor moOde laufen

---

### **Phase 2: First Boot (einmalig)**

#### **first-boot-setup.service** ⭐
```
After=network.target local-fs.target
Before=localdisplay.service auto-fix-display.service
```
- **Startet:** Nach network.target, vor Display-Services
- **Zweck:** Alles beim ersten Boot einrichten
- **Macht:**
  1. Kompiliert Overlays (falls dtc verfügbar)
  2. Wendet worker.php patch an
  3. Erstellt fehlende Scripts
  4. Prüft/erstellt User andre
  5. Aktiviert Services
- **Kritisch:** Läuft nur einmal (Marker-File)

---

### **Phase 3: Multi-User (nach multi-user.target)**

#### **fix-user-id.service**
```
After=multi-user.target moode-startup.service
```
- **Startet:** Nach multi-user.target
- **Zweck:** User andre UID prüfen/korrigieren
- **Kritisch:** moOde benötigt UID 1000

#### **fix-ssh-sudoers.service**
```
After=multi-user.target moode-startup.service
```
- **Startet:** Nach multi-user.target
- **Zweck:** SSH/Sudoers nach jedem Boot fixen
- **Kritisch:** Stellt sicher dass SSH funktioniert

#### **disable-console.service**
```
After=multi-user.target
Before=localdisplay.service
```
- **Startet:** Nach multi-user.target, vor localdisplay
- **Zweck:** Console auf tty1 deaktivieren
- **Kritisch:** Verhindert Console auf Display

#### **i2c-stabilize.service**
```
After=network.target
Before=localdisplay.service
```
- **Startet:** Nach network.target, vor localdisplay
- **Zweck:** I2C-Bus stabilisieren
- **Kritisch:** Hardware muss stabil sein

#### **i2c-monitor.service**
```
After=network.target
```
- **Startet:** Nach network.target
- **Zweck:** I2C-Bus überwachen
- **Kritisch:** Kontinuierliche Überwachung

#### **audio-optimize.service**
```
After=network.target
Before=mpd.service
```
- **Startet:** Nach network.target, vor mpd
- **Zweck:** Audio optimieren
- **Kritisch:** Audio muss vor mpd optimiert sein

---

### **Phase 4: Graphical (nach graphical.target)**

#### **xserver-ready.service**
```
After=graphical.target
Wants=graphical.target
```
- **Startet:** Nach graphical.target
- **Zweck:** X Server bereit machen
- **Macht:**
  - Prüft ob X Server läuft
  - Prüft ob Display verfügbar ist
  - Wartet bis X Server bereit ist (max. 30 Sekunden)
- **Kritisch:** localdisplay.service benötigt X Server

#### **auto-fix-display.service**
```
After=network.target
Before=localdisplay.service
```
- **Startet:** Nach network.target, vor localdisplay
- **Zweck:** Display-Service fixen falls fehlt
- **Macht:**
  - Erstellt localdisplay.service falls fehlt
  - Erstellt xserver-ready.sh falls fehlt
  - Erstellt start-chromium-clean.sh falls fehlt
  - Prüft/erstellt User andre
- **Kritisch:** Stellt sicher dass localdisplay.service existiert

#### **localdisplay.service**
```
After=graphical.target xserver-ready.service
Wants=graphical.target xserver-ready.service
Requires=graphical.target
```
- **Startet:** Nach graphical.target UND xserver-ready.service
- **Zweck:** Chromium auf Display starten
- **Macht:**
  - Prüft X Server (xserver-ready.sh)
  - Startet Chromium (start-chromium-clean.sh)
  - Konfiguriert Display (xrandr)
- **Kritisch:** Haupt-Service für Display

#### **ft6236-delay.service**
```
After=localdisplay.service xserver-ready.service
Requires=graphical.target
```
- **Startet:** Nach localdisplay.service
- **Zweck:** FT6236 Touchscreen laden
- **Macht:**
  - Wartet 2 Sekunden
  - Lädt ft6236 Modul
  - Wartet 1 Sekunde
- **Kritisch:** Touchscreen muss nach Display geladen werden

#### **peppymeter.service**
```
After=localdisplay.service mpd.service
```
- **Startet:** Nach localdisplay.service
- **Zweck:** PeppyMeter starten
- **Kritisch:** Benötigt Display und MPD

#### **peppymeter-extended-displays.service**
```
After=localdisplay.service peppymeter.service mpd.service
Requires=graphical.target
```
- **Startet:** Nach localdisplay, peppymeter, mpd
- **Zweck:** PeppyMeter Extended Displays
- **Kritisch:** Benötigt alle drei Services

---

## 🔄 VOLLSTÄNDIGE BOOT-REIHENFOLGE

```
1. Kernel bootet
   └─> systemd startet
       └─> sysinit.target
           └─> basic.target
               └─> local-fs.target
                   └─> network-pre.target
                       └─> network-guaranteed.service (garantiert Netzwerk)
                           └─> network.target
                               └─> network-online.target
                                   └─> enable-ssh-early.service (SSH aktivieren)
                                       └─> multi-user.target
                                           └─> first-boot-setup.service ⭐ (einmalig)
                                               ├─> fix-user-id.service (UID prüfen)
                                               ├─> fix-ssh-sudoers.service (SSH fixen)
                                               └─> disable-console.service (Console deaktivieren)
                                                   └─> graphical.target
                                                       └─> xserver-ready.service (X Server bereit)
                                                           └─> auto-fix-display.service (Display fixen)
                                                               └─> localdisplay.service (Chromium starten)
                                                                   └─> ft6236-delay.service (Touchscreen laden)
                                                                       └─> peppymeter.service (PeppyMeter starten)
                                                                           └─> peppymeter-extended-displays.service
```

---

## ⚠️ KRITISCHE ABHÄNGIGKEITEN

### **localdisplay.service benötigt:**
1. ✅ `graphical.target` - Grafisches System
2. ✅ `xserver-ready.service` - X Server bereit
3. ✅ User `andre` mit UID 1000
4. ✅ `/usr/local/bin/start-chromium-clean.sh` existiert
5. ✅ `/usr/local/bin/xserver-ready.sh` existiert
6. ✅ XAUTHORITY gesetzt (`/home/andre/.Xauthority`)
7. ✅ DISPLAY=:0 gesetzt
8. ✅ X Server läuft und antwortet

### **Wenn etwas fehlt:**
- Service startet nicht
- Oder startet aber Chromium nicht
- Oder Chromium startet aber kein Display
- Oder Display zeigt aber keine Grafik

---

## 🎯 PROBLEM-ANALYSE: WARUM FUNKTIONIERTE ES NICHT?

### **Mögliche Ursachen:**

1. ❌ **first-boot-setup.service fehlte**
   - → Overlays wurden nicht kompiliert
   - → Hardware funktionierte nicht
   - → Display funktionierte nicht

2. ❌ **xserver-ready.service fehlte**
   - → X Server wurde nicht geprüft
   - → localdisplay.service startete zu früh
   - → Chromium konnte nicht starten

3. ❌ **auto-fix-display.service fehlte**
   - → localdisplay.service existierte nicht
   - → Service konnte nicht starten

4. ❌ **User andre hatte falsche UID**
   - → moOde zeigte Fehler
   - → Services konnten nicht als andre laufen

5. ❌ **Scripts fehlten**
   - → Services konnten nicht starten
   - → Chromium konnte nicht gestartet werden

6. ❌ **Abhängigkeiten falsch**
   - → Services starteten in falscher Reihenfolge
   - → Services starteten bevor Voraussetzungen erfüllt waren

---

## ✅ LÖSUNG: ALLES KORRIGIERT

### **Was wurde gemacht:**

1. ✅ **first-boot-setup.service erstellt**
   - Läuft automatisch beim ersten Boot
   - Macht alle "will be applied on first boot" Dinge

2. ✅ **auto-fix-display.service erstellt**
   - Läuft vor localdisplay.service
   - Stellt sicher dass alles existiert

3. ✅ **Abhängigkeiten korrekt gesetzt**
   - Services starten in richtiger Reihenfolge
   - Alle Voraussetzungen werden erfüllt

4. ✅ **Alle Scripts werden erstellt**
   - Im Build oder beim ersten Boot
   - Alles ist verfügbar

---

**Status:** ✅ BOOT-SEQUENZ VOLLSTÄNDIG VERSTANDEN


# 📚 THEORIE-ANALYSE: SERVICE-ABHÄNGIGKEITEN

**Datum:** 2025-12-08  
**Zweck:** Vollständiges Verständnis der Service-Abhängigkeiten und Boot-Reihenfolge

---

## 🔗 SERVICE-ABHÄNGIGKEITEN (DEPENDENCIES)

### **systemd Dependency-Typen:**

1. **After=** - Startet NACH diesem Service/Target
2. **Before=** - Startet VOR diesem Service/Target
3. **Requires=** - Harte Abhängigkeit (wenn fehlschlägt, wird dieser Service gestoppt)
4. **Wants=** - Weiche Abhängigkeit (wenn fehlschlägt, wird dieser Service trotzdem gestartet)
5. **WantedBy=** - Wird von diesem Target gewollt (enable erstellt Symlink)

---

## 📋 UNSERE SERVICES - ABHÄNGIGKEITEN

### **1. enable-ssh-early.service**
```
After=network.target
Before=multi-user.target
```
- **Zweck:** SSH so früh wie möglich aktivieren
- **Startet:** Nach network.target, vor multi-user.target
- **Kritisch:** Muss vor moOde laufen (moOde könnte SSH deaktivieren)

### **2. fix-ssh-sudoers.service**
```
After=enable-ssh-early.service
```
- **Zweck:** SSH/Sudoers nach jedem Boot fixen
- **Startet:** Nach enable-ssh-early.service
- **Kritisch:** Stellt sicher dass SSH funktioniert

### **3. fix-user-id.service**
```
After=local-fs.target
Before=multi-user.target
```
- **Zweck:** User andre UID prüfen/korrigieren
- **Startet:** Nach local-fs.target, vor multi-user.target
- **Kritisch:** moOde benötigt UID 1000

### **4. first-boot-setup.service** ⭐ NEU
```
After=network.target local-fs.target
Before=localdisplay.service auto-fix-display.service
```
- **Zweck:** Alles beim ersten Boot einrichten
- **Startet:** Nach network.target, vor Display-Services
- **Kritisch:** Macht alle "will be applied on first boot" Dinge

### **5. auto-fix-display.service**
```
After=network.target
Before=localdisplay.service
```
- **Zweck:** Display-Service fixen falls fehlt
- **Startet:** Nach network.target, vor localdisplay.service
- **Kritisch:** Stellt sicher dass localdisplay.service existiert

### **6. disable-console.service**
```
After=multi-user.target
Before=localdisplay.service
```
- **Zweck:** Console auf tty1 deaktivieren
- **Startet:** Nach multi-user.target, vor localdisplay.service
- **Kritisch:** Verhindert Console auf Display

### **7. xserver-ready.service**
```
After=graphical.target
Wants=graphical.target
```
- **Zweck:** X Server bereit machen
- **Startet:** Nach graphical.target
- **Kritisch:** localdisplay.service benötigt X Server

### **8. localdisplay.service**
```
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service
Requires=graphical.target
```
- **Zweck:** Chromium auf Display starten
- **Startet:** Nach graphical.target UND xserver-ready.service
- **Kritisch:** Haupt-Service für Display

---

## 🔄 BOOT-REIHENFOLGE (VOLLSTÄNDIG)

### **Phase 1: Early Boot**
```
sysinit.target
  └─> basic.target
      └─> local-fs.target
          └─> fix-user-id.service (UID prüfen)
              └─> network.target
                  └─> enable-ssh-early.service (SSH aktivieren)
                      └─> fix-ssh-sudoers.service (SSH fixen)
```

### **Phase 2: First Boot (einmalig)**
```
network.target
  └─> first-boot-setup.service ⭐
      ├─> Overlays kompilieren
      ├─> worker.php patch anwenden
      ├─> Scripts erstellen
      └─> User prüfen
```

### **Phase 3: Multi-User**
```
multi-user.target
  └─> disable-console.service (Console deaktivieren)
      └─> graphical.target
          └─> xserver-ready.service (X Server bereit)
              └─> auto-fix-display.service (Display fixen)
                  └─> localdisplay.service (Chromium starten)
```

---

## ⚠️ KRITISCHE ABHÄNGIGKEITEN

### **localdisplay.service benötigt:**
1. ✅ `graphical.target` - Grafisches System
2. ✅ `xserver-ready.service` - X Server bereit
3. ✅ User `andre` mit UID 1000
4. ✅ `/usr/local/bin/start-chromium-clean.sh` existiert
5. ✅ `/usr/local/bin/xserver-ready.sh` existiert
6. ✅ XAUTHORITY gesetzt
7. ✅ DISPLAY=:0 gesetzt

### **Wenn etwas fehlt:**
- Service startet nicht
- Oder startet aber Chromium nicht
- Oder Chromium startet aber kein Display

---

## 🎯 PROBLEM-ANALYSE

### **Warum funktionierte es nicht?**

**Mögliche Ursachen:**
1. ❌ `first-boot-setup.service` fehlte → Overlays nicht kompiliert
2. ❌ `xserver-ready.service` fehlte → X Server nicht bereit
3. ❌ `auto-fix-display.service` fehlte → Service-Datei fehlte
4. ❌ User andre hatte falsche UID → moOde-Fehler
5. ❌ Scripts fehlten → Service konnte nicht starten
6. ❌ Abhängigkeiten falsch → Services starteten in falscher Reihenfolge

### **Lösung:**
- ✅ `first-boot-setup.service` erstellt
- ✅ `auto-fix-display.service` erstellt
- ✅ Abhängigkeiten korrekt gesetzt
- ✅ Alle Scripts werden erstellt

---

## 📊 SERVICE-STATUS-ÜBERSICHT

| Service | After | Before | WantedBy | Kritisch |
|---------|-------|--------|----------|----------|
| enable-ssh-early | network.target | multi-user.target | multi-user.target | ✅ |
| fix-ssh-sudoers | enable-ssh-early | - | multi-user.target | ✅ |
| fix-user-id | local-fs.target | multi-user.target | multi-user.target | ✅ |
| first-boot-setup | network.target | localdisplay | multi-user.target | ✅ |
| auto-fix-display | network.target | localdisplay | multi-user.target | ✅ |
| disable-console | multi-user.target | localdisplay | multi-user.target | ✅ |
| xserver-ready | graphical.target | - | multi-user.target | ✅ |
| localdisplay | graphical.target, xserver-ready | - | multi-user.target | ✅ |

---

**Status:** ✅ SERVICE-ABHÄNGIGKEITEN VERSTANDEN


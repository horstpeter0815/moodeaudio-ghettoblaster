# DEPENDENCY-MANAGEMENT ERKLÄRUNG

**Datum:** 1. Dezember 2025  
**Frage:** Wie werden Dependencies verwaltet? Welche System-Komponenten sind beteiligt?

---

## 🔍 WIE WERDEN DEPENDENCIES VERWALTET?

### **1. MODUL-ENTWICKLER DEFINIEREN DEPENDENCIES**

**Im Kernel-Modul-Quellcode:**
```c
// Beispiel: FT6236 Treiber
MODULE_DEPENDS("i2c-core", "input-core");

// Beispiel: VC4 Treiber
MODULE_DEPENDS("drm", "drm_kms_helper", "i2c-core", ...);
```

**Wo:**
- Im Quellcode des Moduls
- Entwickler definiert, welche Module benötigt werden
- Wird beim Kompilieren in Modul-Metadaten eingebettet

---

### **2. depmod (DEPENDENCY-GENERATOR)**

**Was ist depmod?**
- Linux-Tool, das Dependency-Datenbank erstellt
- Liest alle Kernel-Module
- Extrahiert Dependencies aus Modul-Metadaten
- Erstellt `modules.dep` Datei

**Wo läuft es?**
- Beim Kernel-Update
- Beim System-Update
- Manuell: `sudo depmod -a`

**Was macht es?**
```
1. Liest alle Module in /lib/modules/$(uname -r)/
2. Extrahiert Dependencies aus jedem Modul (modinfo)
3. Erstellt Dependency-Graph
4. Schreibt modules.dep Datei
```

**Output:**
```
/lib/modules/6.12.47+rpt-rpi-2712/modules.dep

ft6236.ko: i2c-core.ko input-core.ko
vc4.ko: drm.ko drm_kms_helper.ko i2c-core.ko ...
```

---

### **3. modprobe (MODULE-LADER)**

**Was ist modprobe?**
- Linux-Tool, das Module lädt
- Liest `modules.dep` Datei
- Lädt Module in korrekter Reihenfolge (Dependencies zuerst)
- Wird automatisch vom Kernel aufgerufen

**Wie funktioniert es?**
```
1. Kernel erkennt Hardware (via Device Tree)
2. Kernel ruft modprobe auf
3. modprobe liest modules.dep
4. modprobe prüft Dependencies
5. modprobe lädt zuerst Dependencies
6. Dann lädt modprobe das gewünschte Modul
```

**Beispiel:**
```bash
# Kernel will FT6236 laden
modprobe ft6236

# modprobe liest modules.dep:
# ft6236.ko: i2c-core.ko input-core.ko

# modprobe lädt zuerst:
# 1. i2c-core.ko
# 2. input-core.ko
# 3. ft6236.ko
```

---

### **4. KERNEL SELBST**

**Was macht der Kernel?**
- Verwaltet geladene Module
- Prüft Dependencies beim Laden
- Verhindert Laden, wenn Dependency fehlt
- Ruft modprobe automatisch auf

**Beim Boot:**
```
1. Kernel startet
2. Kernel liest Device Tree
3. Kernel erkennt Hardware-Nodes
4. Kernel ruft modprobe für jedes erkannte Gerät auf
5. modprobe lädt Module in Dependency-Reihenfolge
```

---

## 📋 SYSTEM-KOMPONENTEN

### **1. Kernel-Modul-Quellcode**
- **Wo:** `/usr/src/linux/drivers/...`
- **Was:** Entwickler definiert Dependencies
- **Wann:** Beim Entwickeln des Moduls

### **2. Kompilierte Module**
- **Wo:** `/lib/modules/$(uname -r)/kernel/...`
- **Was:** Kompilierte `.ko` Dateien mit Metadaten
- **Wann:** Beim Kernel-Build

### **3. modinfo (Metadaten-Extraktor)**
- **Wo:** Teil von `modutils` oder `kmod`
- **Was:** Liest Dependencies aus Modul-Metadaten
- **Wann:** Wird von depmod verwendet

### **4. depmod (Dependency-Generator)**
- **Wo:** `/sbin/depmod` oder `/usr/sbin/depmod`
- **Was:** Erstellt `modules.dep` Datei
- **Wann:** Beim Kernel-Update, System-Update, oder manuell

### **5. modules.dep (Dependency-Datenbank)**
- **Wo:** `/lib/modules/$(uname -r)/modules.dep`
- **Was:** Textdatei mit allen Dependencies
- **Wann:** Wird von depmod erstellt

### **6. modprobe (Module-Lader)**
- **Wo:** `/sbin/modprobe` oder `/usr/sbin/modprobe`
- **Was:** Lädt Module in korrekter Reihenfolge
- **Wann:** Wird automatisch vom Kernel aufgerufen

### **7. Kernel (Module-Manager)**
- **Wo:** Kernel selbst (im RAM)
- **Was:** Verwaltet geladene Module, ruft modprobe auf
- **Wann:** Beim Boot und zur Laufzeit

---

## 🔄 VOLLSTÄNDIGER ABLAUF

### **Beim Kernel-Build:**
```
1. Entwickler schreibt Modul-Quellcode
2. Entwickler definiert Dependencies (MODULE_DEPENDS)
3. Modul wird kompiliert
4. Dependencies werden in Modul-Metadaten eingebettet
```

### **Beim System-Update:**
```
1. Neue Kernel-Module werden installiert
2. depmod wird automatisch ausgeführt
3. depmod liest alle Module
4. depmod extrahiert Dependencies (modinfo)
5. depmod erstellt modules.dep Datei
```

### **Beim Boot:**
```
1. Kernel startet
2. Kernel liest Device Tree
3. Kernel erkennt Hardware (z.B. FT6236, VC4)
4. Kernel ruft modprobe für jedes Gerät auf
5. modprobe liest modules.dep
6. modprobe prüft Dependencies
7. modprobe lädt Module in korrekter Reihenfolge:
   - Zuerst Module mit wenigen Dependencies
   - Dann Module mit mehr Dependencies
```

---

## 💡 WARUM LÄDT FT6236 VOR VC4?

### **Dependencies:**

**FT6236:**
```
Dependencies: i2c-core, input-core
→ 2 Dependencies
→ Lädt schnell
```

**VC4:**
```
Dependencies: drm, drm_kms_helper, i2c-core, ...
→ Viele Dependencies
→ Lädt langsamer
```

### **modprobe lädt Module:**
```
1. FT6236: 2 Dependencies → lädt schnell
2. VC4: Viele Dependencies → braucht länger
3. FT6236 ist fertig, bevor VC4 startet
```

---

## ✅ ZUSAMMENFASSUNG

### **Welche System-Komponenten verwalten Dependencies?**

1. **Modul-Entwickler:**
   - Definiert Dependencies im Quellcode

2. **depmod:**
   - Erstellt Dependency-Datenbank (modules.dep)

3. **modprobe:**
   - Lädt Module in korrekter Reihenfolge

4. **Kernel:**
   - Verwaltet Module, ruft modprobe auf

### **Wo werden Dependencies gespeichert?**

- **Im Modul selbst:** Metadaten (modinfo)
- **In modules.dep:** Textdatei mit allen Dependencies
- **Im Kernel:** Verwaltet geladene Module

### **Wann werden Dependencies aufgelöst?**

- **Beim Boot:** Kernel ruft modprobe auf
- **Zur Laufzeit:** Wenn neues Gerät erkannt wird
- **Automatisch:** Kernel macht das selbst

---

**Status:** ✅ **ERKLÄRT - DEPENDENCY-MANAGEMENT = KERNEL + depmod + modprobe**


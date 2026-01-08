# BLACKLIST-PROBLEM ANALYSE

**Datum:** 1. Dezember 2025  
**Frage:** Warum hat Kernel-Module-Blacklist nicht funktioniert?

---

## 🔍 WARUM BLACKLIST NICHT FUNKTIONIERT

### **PROBLEM 1: DEVICE TREE OVERLAY vs. KERNEL-MODUL**

**Was passiert:**

1. **Device Tree Overlay wird geladen:**
   ```
   config.txt: dtoverlay=ft6236
   → Firmware lädt Overlay
   → Device Tree Node wird erstellt
   → Hardware wird erkannt
   ```

2. **Kernel-Modul-Blacklist:**
   ```
   /etc/modprobe.d/blacklist-ft6236.conf: blacklist ft6236
   → Kernel lädt Modul nicht
   → ABER: Hardware ist bereits erkannt (via Device Tree)!
   ```

3. **Ergebnis:**
   - Device Tree Overlay hat **Priorität**
   - Hardware wird **trotzdem initialisiert**
   - Blacklist kommt **zu spät**

**Das Problem:**
- Blacklist blockiert nur **Kernel-Modul-Laden**
- ABER: Device Tree Overlay lädt Hardware **direkt**
- FT6236 wird **trotzdem initialisiert**

---

### **PROBLEM 2: FT6236 IST KEIN KERNEL-MODUL?**

**Mögliche Situation:**
- FT6236 könnte **in den Kernel eingebaut** sein (nicht als Modul)
- Blacklist funktioniert nur für **Module**, nicht für **eingebaute Treiber**

**Prüfung:**
```bash
# Ist FT6236 als Modul verfügbar?
modinfo ft6236

# Ist FT6236 im Kernel eingebaut?
grep FT6236 /boot/config
```

**Wenn FT6236 eingebaut ist:**
- Blacklist funktioniert **nicht**
- Treiber ist **immer aktiv**
- Kann nicht blockiert werden

---

### **PROBLEM 3: DEVICE TREE OVERLAY HAT PRIORITÄT**

**Boot-Sequenz:**

```
1. Firmware startet
2. Firmware liest config.txt
3. Firmware lädt Device Tree Overlays
   → FT6236-Overlay wird geladen
   → Hardware wird erkannt
4. Kernel startet
5. Kernel liest Device Tree
6. Kernel erkennt Hardware (bereits via Overlay)
7. Kernel versucht Modul zu laden
   → Blacklist blockiert Modul
   → ABER: Hardware ist bereits initialisiert!
```

**Das Problem:**
- Device Tree Overlay wird **vor** Kernel-Modul-Laden ausgeführt
- Hardware wird **bereits erkannt**
- Blacklist kommt **zu spät**

---

### **PROBLEM 4: BLACKLIST + OVERLAY = KONFLIKT**

**Was passiert:**

1. **Overlay lädt Hardware:**
   ```
   dtoverlay=ft6236
   → Hardware wird erkannt
   → Kernel versucht Treiber zu laden
   ```

2. **Blacklist blockiert Modul:**
   ```
   blacklist ft6236
   → Modul wird nicht geladen
   → ABER: Hardware ist bereits erkannt
   ```

3. **Ergebnis:**
   - Hardware ist erkannt, aber **kein Treiber**
   - Oder: Hardware wird **trotzdem initialisiert** (via Overlay)
   - Blacklist hat **keine Wirkung**

---

## 💡 WARUM BLACKLIST NICHT FUNKTIONIERT

### **Zusammenfassung:**

1. **Device Tree Overlay hat Priorität:**
   - Wird vor Kernel-Modul-Laden ausgeführt
   - Hardware wird bereits erkannt
   - Blacklist kommt zu spät

2. **FT6236 könnte eingebaut sein:**
   - Nicht als Modul, sondern im Kernel
   - Blacklist funktioniert nur für Module

3. **Overlay + Blacklist = Konflikt:**
   - Overlay lädt Hardware
   - Blacklist blockiert Modul
   - Hardware ist trotzdem erkannt

---

## ✅ LÖSUNG: OVERLAY ENTFERNEN + BLACKLIST

**Korrekte Vorgehensweise:**

1. **Overlay aus config.txt entfernen:**
   ```bash
   sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
   ```

2. **Blacklist setzen (falls Modul vorhanden):**
   ```bash
   echo "blacklist ft6236" | sudo tee /etc/modprobe.d/blacklist-ft6236.conf
   ```

3. **Später manuell laden:**
   ```bash
   # Via systemd-Service
   modprobe ft6236
   ```

**Warum das funktioniert:**
- Overlay wird nicht geladen → Hardware wird nicht erkannt
- Blacklist blockiert Modul → Modul wird nicht geladen
- Später manuell laden → Hardware wird erkannt + Modul geladen

---

## 📋 WAS WIR VERMUTLICH FALSCH GEMACHT HABEN

### **Vermutlich:**
1. ❌ Blacklist gesetzt, aber Overlay in config.txt gelassen
2. ❌ Overlay hat Hardware trotzdem geladen
3. ❌ Blacklist hatte keine Wirkung

### **Korrekt wäre:**
1. ✅ Overlay aus config.txt entfernen
2. ✅ Blacklist setzen (falls Modul)
3. ✅ Später manuell laden (via Service)

---

**Status:** ✅ **PROBLEM IDENTIFIZIERT - BLACKLIST FUNKTIONIERT NUR OHNE OVERLAY**


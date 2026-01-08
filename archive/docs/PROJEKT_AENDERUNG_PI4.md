# PROJEKT-ÄNDERUNG: PI 4 EINFÜHRUNG

**Datum:** 02.12.2025  
**Status:** In Arbeit  
**Änderung:** Pi 1 wird von Pi 5 auf Pi 4 gewechselt

---

## 📋 ÄNDERUNG

### **VORHER:**
- **Pi 1:** Raspberry Pi 5 (RaspiOS)
- **Pi 2:** Raspberry Pi 5 (moOde Audio)

### **NACHHER:**
- **Pi 1:** Raspberry Pi 4 (RaspiOS) - **NEU**
- **Pi 2:** Raspberry Pi 5 (moOde Audio) - **BLEIBT**

---

## 🎯 ENTWICKLUNGS-STRATEGIE

### **Ziel:**
- System-Entwicklung auf **zwei verschiedenen Hardware-Plattformen**:
  - **Pi 4:** Entwicklung und Tests
  - **Pi 5:** Entwicklung und Tests
- Vergleich der Funktionalität auf beiden Plattformen

### **Vorteile:**
- ✅ Hardware-Kompatibilität testen
- ✅ Unterschiede zwischen Pi 4 und Pi 5 identifizieren
- ✅ Robustere Lösung (funktioniert auf beiden Plattformen)

---

## 📊 AKTUELLE HARDWARE-KONFIGURATION

### **PI 1: Raspberry Pi 4** (192.168.178.62)
- **Status:** ⏸️ Wird ausgetauscht
- **OS:** RaspiOS (Debian 13)
- **Hardware:** Raspberry Pi 4
- **Display:** HDMI
- **Touchscreen:** FT6236
- **Audio:** (TBD)

### **PI 2: Raspberry Pi 5** (192.168.178.178)
- **Status:** ✅ Aktiv
- **OS:** moOde Audio
- **Hardware:** Raspberry Pi 5
- **Display:** HDMI
- **Touchscreen:** FT6236
- **Audio:** HiFiBerry AMP100

---

## 🔄 NÄCHSTE SCHRITTE

1. **Pi 1 herunterfahren** ✅
2. **Hardware-Austausch durchführen** (Benutzer)
3. **Pi 4 konfigurieren:**
   - IP-Adresse: 192.168.178.62 (beibehalten)
   - RaspiOS installieren
   - SSH-Zugriff einrichten
4. **Ansatz 1 auf Pi 4 implementieren:**
   - FT6236 Overlay aus config.txt entfernen
   - systemd-Service erstellen
   - Testen
5. **Vergleich Pi 4 vs Pi 5:**
   - Funktionalität vergleichen
   - Unterschiede dokumentieren

---

## 📝 DOKUMENTATION

- Hardware-Dokumentation aktualisiert
- Projekt-Übersicht aktualisiert
- Diese Änderung dokumentiert

---

**Status:** ⏸️ **WARTE AUF HARDWARE-AUSTAUSCH**


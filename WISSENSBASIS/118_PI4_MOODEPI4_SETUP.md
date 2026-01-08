# PI 4 MOODEPI4 SETUP

**Datum:** 03.12.2025  
**System:** moOde Audio auf Raspberry Pi 4  
**Hostname:** moodepi4  
**Benutzer:** andre  
**Passwort:** 0815  
**Status:** ⏳ Setup läuft

---

## SSH-SETUP

### **Scripts erstellt:**
1. `setup-pi4-ssh.sh` - SSH-Key Setup
2. `pi4-ssh.sh` - Effizientes Arbeiten

### **Verwendung:**
```bash
# SSH-Key Setup (einmalig)
./setup-pi4-ssh.sh

# Danach verwenden
./pi4-ssh.sh "hostname"
./pi4-ssh.sh "systemctl status mpd"
```

---

## SD-KARTE KONFIGURATION

**Bereits konfiguriert:**
- ✅ `display_rotate=3` (Landscape 270°)
- ✅ `dtoverlay=vc4-kms-v3d` (Display)
- ✅ `dtoverlay=ft6236` (Touchscreen)
- ✅ Pi 5 Overlays entfernt

---

## NÄCHSTE SCHRITTE

1. ⏳ Pi 4 booten
2. ⏳ SSH-Setup durchführen
3. ⏳ System analysieren
4. ⏳ Erkenntnisse von HiFiBerryOS übertragen
5. ⏳ Volume auf 0% setzen
6. ⏳ MPD Service optimieren

---

**Status:** ⏳ Warte auf Pi 4 Boot


# 🚀 Deploy Image to Pi 5 - Anleitung

**Pi 5 IP:** 192.168.178.161  
**Image:** `2025-12-07-moode-r1001-arm64-lite.img` (4.8 GB)

---

## 📋 METHODE 1: Manuell (Empfohlen)

### **Schritt 1: Image zu Pi 5 kopieren**

```bash
# Im Projekt-Verzeichnis:
scp 2025-12-07-moode-r1001-arm64-lite.img pi@192.168.178.161:/tmp/

# Passwort eingeben (falls nötig)
```

### **Schritt 2: Auf Pi 5 einloggen**

```bash
ssh pi@192.168.178.161
```

### **Schritt 3: SD-Karte finden**

```bash
lsblk
# Suche nach SD-Karte (z.B. /dev/sda oder /dev/mmcblk0)
```

### **Schritt 4: Image brennen**

```bash
# ⚠️ WICHTIG: Richtige SD-Karte wählen!
# Beispiel für /dev/sda:
sudo umount /dev/sda* 2>/dev/null
sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
sync
```

---

## 📋 METHODE 2: Mit Script (Interaktiv)

### **Schritt 1: Image kopieren**

```bash
./deploy-to-pi5-direct.sh
# Passwort eingeben wenn nötig
```

### **Schritt 2: Auf Pi 5 brennen**

```bash
ssh pi@192.168.178.161 'bash -s' < burn-image-on-pi.sh
```

---

## ⚠️ WICHTIGE HINWEISE

1. **SD-Karte:** Stelle sicher dass SD-Karte in Pi 5 ist
2. **Richtige Disk:** Prüfe doppelt welche Disk die SD-Karte ist!
3. **Datenverlust:** Alle Daten auf SD-Karte werden gelöscht
4. **Dauer:** Brennen dauert ~5-10 Minuten

---

## ✅ NACH DEM BRENNEN

1. SD-Karte aus Pi 5 entfernen
2. SD-Karte in Raspberry Pi 5 (Ziel-System) stecken
3. System booten
4. Web-UI: `http://192.168.178.161` oder `http://moode.local`
5. Features testen

---

**Status:** ✅ READY FOR DEPLOYMENT


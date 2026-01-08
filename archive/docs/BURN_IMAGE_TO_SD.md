# 🔥 Image auf SD-Karte brennen

**Image:** `2025-12-07-moode-r1001-arm64-lite.img`  
**Größe:** ~5.2 GB  
**Ziel:** Raspberry Pi 5

---

## 🛠️ METHODE 1: balenaEtcher (Empfohlen)

1. **balenaEtcher öffnen**
2. **"Flash from file"** wählen
3. **Image auswählen:** `2025-12-07-moode-r1001-arm64-lite.img`
4. **SD-Karte einstecken**
5. **"Select target"** → SD-Karte wählen
6. **"Flash!"** klicken
7. **Warten** (~5-10 Minuten)

---

## 🛠️ METHODE 2: dd (Terminal)

```bash
# 1. SD-Karte einstecken
# 2. Device finden:
diskutil list

# 3. SD-Karte unmounten (z.B. /dev/disk2):
diskutil unmountDisk /dev/disk2

# 4. Image brennen:
sudo dd if=2025-12-07-moode-r1001-arm64-lite.img of=/dev/rdisk2 bs=1m

# 5. Warten (~5-10 Minuten)
# 6. Sync:
sync
```

**⚠️ WICHTIG:** Richtige Disk wählen! Falsche Disk = Datenverlust!

---

## ✅ NACH DEM BRENNEN

1. **SD-Karte in Raspberry Pi 5 stecken**
2. **System booten**
3. **Web-UI öffnen:** `http://moode.local` oder IP-Adresse
4. **Features testen:**
   - Room Correction Wizard
   - Flat EQ Preset
   - PeppyMeter Extended Displays
   - Touch Gestures
   - Audio Output

---

**Status:** ✅ Image bereit zum Brennen


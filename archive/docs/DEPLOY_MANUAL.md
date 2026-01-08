# 🚀 Manuelles Deployment - JETZT

**Führe diese Befehle direkt im Terminal aus:**

---

## Schritt 1: Image kopieren

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

scp 2025-12-07-moode-r1001-arm64-lite.img pi@192.168.178.161:/tmp/
# Passwort: andre0815 (oder das richtige Passwort)
```

---

## Schritt 2: Auf Pi 5 einloggen

```bash
ssh pi@192.168.178.161
# Passwort eingeben
```

---

## Schritt 3: SD-Karte finden

```bash
lsblk
# Suche nach SD-Karte (z.B. /dev/sda oder /dev/mmcblk0)
```

---

## Schritt 4: Image brennen

```bash
# ⚠️ WICHTIG: Richtige SD-Karte wählen! (z.B. /dev/sda)
sudo umount /dev/sda* 2>/dev/null
sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
sync
```

**Dauer:** ~5-10 Minuten

---

## Schritt 5: Fertig!

1. SD-Karte aus Pi 5 entfernen
2. SD-Karte in Raspberry Pi 5 (Ziel-System) stecken
3. Hardware verbinden
4. System booten
5. Web-UI öffnen: `http://moode.local`

---

**Status:** ✅ BEREIT ZUM DEPLOYMENT


# 🔥 KOMPLETTER BEFEHL ZUM KOPIEREN

**Kopiere diesen kompletten Befehl und füge ihn im Terminal ein:**

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor" && diskutil unmountDisk /dev/disk4 && sudo dd if="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/2025-12-07-moode-r1001-arm64-lite.img" of=/dev/rdisk4 bs=4m status=progress && sync
```

---

## 📋 Was macht dieser Befehl?

1. **cd** - Wechselt ins Projekt-Verzeichnis
2. **diskutil unmountDisk** - Unmountet die SD-Karte
3. **sudo dd** - Brennt das Image auf die SD-Karte
4. **sync** - Synchronisiert alle Daten

---

## ⚠️ WICHTIG

- **sudo Passwort** wird abgefragt
- **Alle Daten** auf /dev/disk4 werden gelöscht
- **Dauer:** ~5-10 Minuten

---

## ✅ NACH DEM BRENNEN

1. SD-Karte sicher auswerfen
2. SD-Karte in Raspberry Pi 5 stecken
3. Hardware verbinden
4. System booten
5. Web-UI: http://moode.local


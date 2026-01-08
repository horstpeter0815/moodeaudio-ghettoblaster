# 🔧 NAS SETUP - FIX

**Problem:** `mkdir: /Volumes/fritz-nas-archive: Permission denied`

**Lösung:** Mount-Point wurde geändert zu `~/fritz-nas-archive` (im Home-Verzeichnis)

---

## ✅ Script wurde angepasst

Das Script verwendet jetzt:
- **Mount-Point:** `~/fritz-nas-archive` (statt `/Volumes/fritz-nas-archive`)
- **Kein sudo nötig**
- **Funktioniert ohne Permission-Probleme**

---

## 🚀 Jetzt ausführen

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./SETUP_NAS.sh
```

Das Script fragt nach:
- **Share-Name:** `IllerNAS` (wie Sie bereits eingegeben haben)
- **Benutzername:** `Andre` (wie Sie bereits eingegeben haben)
- **Passwort:** (Ihr Fritz Box Passwort)

---

## 📍 Mount-Point

Nach erfolgreichem Mount finden Sie das NAS unter:
```
~/fritz-nas-archive
```

Oder vollständig:
```
/Users/andrevollmer/fritz-nas-archive
```

---

**Viel Erfolg beim zweiten Versuch!**


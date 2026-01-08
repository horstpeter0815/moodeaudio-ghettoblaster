# 🔌 FRITZ NAS SETUP - SCHNELLANLEITUNG

## 📍 Schritt 1: Ins richtige Verzeichnis wechseln

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
```

## 🔧 Schritt 2: NAS Setup starten

```bash
./SETUP_NAS.sh
```

Das Script fragt Sie nach:
- **Share-Namen** (z.B. "fritz.nas", "usb_storage", etc.)
- **Benutzername** (Enter für "guest", oder Ihr Fritz Box Benutzername)
- **Passwort** (falls nicht guest)

## ✅ Schritt 3: Archivierung starten

Nach erfolgreichem Mount:

```bash
./ARCHIVE_TO_NAS.sh
```

---

## ⚠️ HINWEISE

### **Image-Fehler:**
Der Fehler `dd: ./imgbuild/deploy/moode-r1001-arm64-20251208_101237-lite.img: No such file or directory` ist **OK** - dieses Image wurde bereits gelöscht (wie gewünscht).

### **Script nicht gefunden:**
Wenn Sie `zsh: no such file or directory: ./SETUP_NAS.sh` sehen, sind Sie im falschen Verzeichnis. Wechseln Sie ins Projekt-Verzeichnis (siehe Schritt 1).

---

## 🎯 ALTERNATIVE: Manuelles Mounten

Falls das Script nicht funktioniert, können Sie das NAS manuell mounten:

```bash
# Mount-Point erstellen
mkdir -p /Volumes/fritz-nas-archive

# NAS mounten (mit Ihren Credentials)
mount_smbfs //benutzername:passwort@fritz.box/share-name /Volumes/fritz-nas-archive

# Prüfen
df -h /Volumes/fritz-nas-archive
```

---

**Viel Erfolg!**


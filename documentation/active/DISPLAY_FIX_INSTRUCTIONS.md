# 🖥️ DISPLAY & BROWSER FIX - ANLEITUNG

## ⚠️ PROBLEM
- Display zeigt "Mood Login" (Portrait-Modus)
- Browser (Chromium) startet nicht korrekt
- SSH funktioniert nicht

## ✅ LÖSUNG ÜBER WEB-UI

### 1. Web-UI öffnen
```
http://192.168.178.161
```
**WICHTIG:** moOde hat KEIN Login - direkt zugänglich!

### 2. Display-Rotation ändern
1. **Configure** → **System**
2. Suche nach **"Display Rotation"** oder **"Screen Rotation"**
3. Ändere auf **0°** (Landscape)
4. Klicke **"Save"** oder **"Update"**

### 3. Local Display aktivieren
1. **Configure** → **Peripherals**
2. Suche nach **"Local Display"** oder **"Kiosk Mode"**
3. Aktiviere **"Local Display"**
4. URL setzen: `http://localhost`
5. Klicke **"Save"** oder **"Update"**

### 4. System neu starten
1. **System** → **Restart** (oder **Power** → **Restart**)
2. Warte 1-2 Minuten bis System hochgefahren ist

### 5. Prüfen
- Display sollte jetzt im Landscape-Modus sein
- Browser sollte moOde-Interface zeigen (nicht "Mood Login")

---

## 🔧 ALTERNATIVE: Audio-Output konfigurieren

Nach dem Neustart:
1. **Configure** → **Audio**
2. **Output Device:** Wähle **"HiFiBerry AMP100"**
3. Klicke **"Save"**

---

## ❓ FALLS ES IMMER NOCH NICHT FUNKTIONIERT

### Prüfe Browser-Logs (falls SSH später funktioniert):
```bash
journalctl -u localdisplay.service -n 50
```

### Prüfe Chromium-Prozess:
```bash
ps aux | grep chromium
```

### Manuell Chromium starten (falls nötig):
```bash
sudo systemctl restart localdisplay.service
```

---

## 📝 HINWEISE

- **"Mood Login"** ist wahrscheinlich der Hostname oder ein Browser-Status
- moOde hat **KEIN Standard-Login** - Web-UI ist direkt zugänglich
- Display-Rotation ist bereits in `config.txt.overwrite` auf 0° gesetzt
- Nach dem Neustart sollte alles funktionieren


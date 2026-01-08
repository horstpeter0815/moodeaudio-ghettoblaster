# 📖 WAS BEDEUTET "GEMOUNTET"?

## 🔌 Einfache Erklärung

**"Gemountet"** bedeutet: **Das NAS ist mit Ihrem Mac verbunden und verfügbar**

### **Vergleich:**
- **Nicht gemountet:** Das NAS ist wie ein USB-Stick, der nicht eingesteckt ist
- **Gemountet:** Das NAS ist wie ein USB-Stick, der eingesteckt ist und im Finder sichtbar ist

---

## 🖥️ Wie sieht es aus?

### **Nicht gemountet:**
- Das NAS ist nicht im Finder sichtbar
- Sie können nicht darauf zugreifen
- Scripts können nicht darauf schreiben

### **Gemountet:**
- Das NAS erscheint im Finder (linke Seitenleiste)
- Sie können es öffnen wie einen Ordner
- Scripts können darauf zugreifen und Dateien kopieren
- Mount-Point: `/Volumes/IllerNAS`

---

## ✅ WIE PRÜFEN OB GEMOUNTET?

### **Methode 1: Finder**
- Öffnen Sie Finder
- Schauen Sie in der linken Seitenleiste
- Wenn "IllerNAS" oder ähnliches sichtbar ist → **gemountet**

### **Methode 2: Terminal**
```bash
# Prüfe ob gemountet
ls /Volumes/IllerNAS

# Oder
mount | grep IllerNAS
```

Wenn das Verzeichnis existiert → **gemountet**

---

## 🔧 WIE MOUNTEN?

### **Einfachste Methode: Finder**

1. **Finder öffnen**
2. **Cmd+K** drücken
3. **Eingeben:** `smb://fritz.box/IllerNAS`
4. **Verbinden klicken**
5. **Anmelden** mit Benutzername und Passwort

→ **Fertig! Das NAS ist jetzt gemountet**

---

## 📍 WO FINDEN SIE ES?

Nach dem Mounten finden Sie das NAS unter:

**Im Finder:**
- Linke Seitenleiste → "IllerNAS"

**Im Terminal:**
- `/Volumes/IllerNAS`

**Vollständiger Pfad:**
```
/Volumes/IllerNAS
```

---

## ⚠️ WICHTIG

- **Mounten ist temporär:** Nach Neustart muss neu gemountet werden
- **Automatisches Mounten:** macOS kann das NAS automatisch mounten (in Systemeinstellungen)
- **Scripts benötigen Mount:** Das Archivierungs-Script funktioniert nur, wenn das NAS gemountet ist

---

## 🎯 FÜR UNSER SYSTEM

**Sobald das NAS gemountet ist:**
- ✅ Das Archivierungs-Script kann starten
- ✅ Alte Dateien werden automatisch aufs NAS verschoben
- ✅ Sie haben 500GB zusätzlichen Speicherplatz

**Aktuell:**
- ⏳ Warten auf NAS-Mount
- ⏳ Dann kann Archivierung starten

---

**Zusammenfassung:** "Gemountet" = Das NAS ist verbunden und verfügbar, wie ein USB-Stick der eingesteckt ist.


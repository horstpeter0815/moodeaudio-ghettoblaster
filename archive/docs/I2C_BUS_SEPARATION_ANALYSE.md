# I2C-BUS-SEPARATION ANALYSE

**Datum:** 1. Dezember 2025  
**Frage:** Ist I2C-Bus-Separation praktikabel? Sollten wir diesen Ansatz weiterverfolgen?

---

## 🎯 ANSATZ 2: I2C-BUS-SEPARATION

### **Was:**
- FT6236 auf anderen I2C-Bus verschieben
- Display nutzt Bus 13 (RP1), FT6236 nutzt Bus 1
- Kein I2C-Bus-Konflikt mehr

---

## ❓ IST ES PRAKTIKABEL?

### **FRAGE 1: Unterstützt FT6236 Overlay I2C-Bus-Parameter?**

**Prüfung:**
```bash
# FT6236 Overlay-Dokumentation prüfen
cat /boot/firmware/overlays/README | grep -A 10 ft6236
```

**Mögliche Parameter:**
- `i2c-bus=1` - Expliziter I2C-Bus
- `i2c1` - I2C-Bus 1
- Standard: Automatisch (vermutlich Bus 13 auf Pi 5)

**Wenn unterstützt:**
```bash
dtoverlay=ft6236,i2c-bus=1
```

**Wenn NICHT unterstützt:**
- Overlay hat keinen `i2c-bus` Parameter
- Kann nicht auf anderen Bus verschoben werden
- Ansatz funktioniert nicht

---

### **FRAGE 2: Welche I2C-Busse sind verfügbar?**

**Raspberry Pi 5:**
- **Bus 1:** Standard I2C (GPIO 2/3)
- **Bus 13:** RP1 I2C Controller (GPIO 2/3 auf RP1)
- **Bus 14:** RP1 I2C Controller (alternative)

**Problem:**
- GPIO 2/3 sind auf Pi 5 mit RP1 verbunden
- Bus 1 und Bus 13 könnten **dasselbe** sein
- Oder: Bus 1 ist alt, Bus 13 ist neu (RP1)

**Prüfung nötig:**
- Welche Busse sind wirklich verfügbar?
- Sind Bus 1 und Bus 13 unterschiedlich?
- Kann FT6236 auf Bus 1?

---

### **FRAGE 3: Hardware-Verbindung**

**FT6236 Hardware:**
- FT6236 ist physisch an bestimmte GPIO-Pins angeschlossen
- GPIO-Pins bestimmen I2C-Bus
- Kann nicht einfach "verschoben" werden

**Problem:**
- Wenn FT6236 an GPIO 2/3 angeschlossen ist
- Dann ist es auf Bus 1 (oder Bus 13)
- Kann nicht auf anderen Bus "verschoben" werden
- Hardware-Limitierung!

---

## 💡 WANN FUNKTIONIERT ES?

### **Funktioniert WENN:**
1. ✅ FT6236 Overlay unterstützt `i2c-bus` Parameter
2. ✅ FT6236 ist an GPIO-Pins angeschlossen, die zu anderem Bus führen
3. ✅ Bus 1 und Bus 13 sind wirklich unterschiedlich
4. ✅ Display nutzt Bus 13, FT6236 kann auf Bus 1

### **Funktioniert NICHT WENN:**
1. ❌ FT6236 Overlay unterstützt keinen `i2c-bus` Parameter
2. ❌ FT6236 ist an GPIO 2/3 angeschlossen (Bus 1/13)
3. ❌ Bus 1 und Bus 13 sind dasselbe
4. ❌ Hardware-Limitierung (FT6236 kann nicht auf anderen Bus)

---

## 🔍 PRAKTIKABILITÄTS-PRÜFUNG

### **SCHRITT 1: Overlay-Parameter prüfen**

```bash
# Prüfe FT6236 Overlay-Dokumentation
cat /boot/firmware/overlays/README | grep -A 20 ft6236
```

**Erwartetes Ergebnis:**
- Liste aller verfügbaren Parameter
- `i2c-bus` oder ähnlicher Parameter vorhanden?

### **SCHRITT 2: Hardware-Verbindung prüfen**

```bash
# Prüfe welche GPIO-Pins FT6236 nutzt
# Prüfe ob auf anderen Bus verschoben werden kann
```

**Erwartetes Ergebnis:**
- FT6236 ist an GPIO 2/3 angeschlossen?
- Oder an andere GPIO-Pins (die zu anderem Bus führen)?

### **SCHRITT 3: I2C-Bus-Verfügbarkeit prüfen**

```bash
# Prüfe verfügbare I2C-Busse
ls -la /dev/i2c-*

# Prüfe ob Bus 1 und Bus 13 unterschiedlich sind
i2cdetect -y 1
i2cdetect -y 13
```

---

## ✅ EMPFEHLUNG

### **WENN I2C-BUS-SEPARATION MÖGLICH IST:**
- ✅ **BESTE LÖSUNG** (kein Timing-Problem)
- ✅ Beide können parallel laufen
- ✅ Keine Delays nötig
- ⭐⭐⭐⭐⭐

### **WENN I2C-BUS-SEPARATION NICHT MÖGLICH IST:**
- ❌ Hardware-Limitierung
- ❌ Overlay unterstützt Parameter nicht
- ❌ Bus 1 und Bus 13 sind dasselbe
- ⭐ (nicht praktikabel)

---

## 📋 ENTSCHEIDUNG

### **Option A: JETZT PRÜFEN**
- Overlay-Dokumentation prüfen
- Hardware-Verbindung prüfen
- I2C-Bus-Verfügbarkeit prüfen
- Dann entscheiden: weiterverfolgen oder ablehnen

### **Option B: JETZT ABLEHNEN**
- Zu unsicher (Hardware-Limitierung)
- Zu komplex zu prüfen
- Fokus auf Ansatz 1 (FT6236 Delay) - bereits geplant

### **Option C: PARALLEL VERFOLGEN**
- Ansatz 1 implementieren (FT6236 Delay)
- Ansatz 2 parallel prüfen
- Falls Ansatz 2 funktioniert: umstellen

---

## 🎯 MEINE EMPFEHLUNG

**Da wir wenig Zeit haben:**

1. **Ansatz 1 (FT6236 Delay) implementieren:**
   - Funktioniert garantiert
   - Bereits geplant
   - Schnell umsetzbar

2. **Ansatz 2 (I2C-Bus-Separation) prüfen:**
   - Schnelle Prüfung (5-10 Minuten)
   - Wenn möglich: Beste Lösung
   - Wenn nicht möglich: Ablehnen

3. **Ansatz 3 (systemd-Targets) als Backup:**
   - Falls Ansatz 1 nicht funktioniert
   - Professionell, aber komplexer

---

**Status:** ⏳ **ENTSCHEIDUNG AUSSTEHEND - PRÜFUNG NÖTIG**


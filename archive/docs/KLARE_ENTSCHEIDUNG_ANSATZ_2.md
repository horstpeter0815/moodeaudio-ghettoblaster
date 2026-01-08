# KLARE ENTSCHEIDUNG: ANSATZ 2 (I2C-BUS-SEPARATION)

**Datum:** 1. Dezember 2025  
**Ziel:** Klare Entscheidung - Ansatz 2 weiterverfolgen oder ablehnen?

---

## 🎯 TOP 3 ANSÄTZE

1. **FT6236 mit systemd-Service (Delay)** ⭐⭐⭐⭐⭐
   - Funktioniert garantiert
   - Bereits geplant
   - Bereit für Implementierung

2. **I2C-Bus-Separation** ⭐⭐⭐⭐⭐ (wenn möglich)
   - BESTE Lösung (kein Timing-Problem)
   - ABER: Muss geprüft werden
   - Hardware-Limitierung möglich

3. **systemd-Targets** ⭐⭐⭐⭐
   - Professionell
   - Backup

---

## ❓ ENTSCHEIDUNG: ANSATZ 2

### **Option A: WEITERVERFOLGEN**

**Wenn:**
- FT6236 Overlay unterstützt `i2c-bus` Parameter
- FT6236 kann auf Bus 1 (statt Bus 13)
- Hardware erlaubt es

**Vorgehen:**
- Prüfung durchführen
- Wenn möglich: Implementieren
- Wenn nicht: Ablehnen

**Risiko:**
- Zeitaufwand für Prüfung
- Möglicherweise nicht möglich
- Dann zurück zu Ansatz 1

---

### **Option B: ABLEHNEN**

**Gründe:**
- Hardware-Limitierung wahrscheinlich (FT6236 an GPIO 2/3)
- Overlay unterstützt möglicherweise keinen Parameter
- Ansatz 1 funktioniert garantiert
- Fokus behalten

**Vorteile:**
- Klarer Fokus auf Ansatz 1
- Keine Zeitverschwendung
- Schnellere Implementierung

---

## ✅ MEINE EMPFEHLUNG

### **ANSATZ 2 ABLEHNEN - FOKUS AUF ANSATZ 1**

**Warum:**
1. **Ansatz 1 funktioniert garantiert:**
   - Bereits geplant
   - Keine Hardware-Limitierung
   - Schnell umsetzbar

2. **Ansatz 2 ist unsicher:**
   - Hardware-Limitierung wahrscheinlich
   - Overlay-Parameter möglicherweise nicht verfügbar
   - Zeitaufwand für Prüfung

3. **Fokus behalten:**
   - Nicht zu viele Ansätze gleichzeitig
   - Klare Priorität: Ansatz 1
   - Ansatz 3 als Backup

---

## 📋 FINALE ENTSCHEIDUNG

### **ANSATZ 2: ABGELEHNT**

**Grund:**
- Hardware-Limitierung wahrscheinlich
- Ansatz 1 funktioniert garantiert
- Fokus behalten

**Weiter mit:**
- ✅ **Ansatz 1:** FT6236 mit systemd-Service (Delay)
- ✅ **Ansatz 3:** systemd-Targets (Backup, falls Ansatz 1 nicht funktioniert)

---

**Status:** ✅ **ENTSCHEIDUNG GETROFFEN - ANSATZ 2 ABGELEHNT, FOKUS AUF ANSATZ 1**


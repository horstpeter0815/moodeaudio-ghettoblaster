# Kernel-Downgrade Versuch - Ergebnis

## Problem
Kernel 6.1.42 (wie in Issue #5550 erfolgreich) ist **nicht mehr in den Repositories verfügbar**.

## Versuchte Methoden

### 1. ✅ Bookworm-Repository hinzugefügt
- Bookworm-Repository für Kernel-Pakete hinzugefügt
- Pin-File erstellt, um nur Kernel-Pakete von Bookworm zu holen

### 2. ❌ Kernel 6.1.42 nicht verfügbar
- `apt-cache madison linux-image-rpi-v8` zeigt keine 6.1.42 Version
- Weder in Trixie noch in Bookworm Repositories

### 3. ❌ Direkter Download fehlgeschlagen
- Versuch, Kernel-Paket direkt von archive.raspberrypi.com herunterzuladen
- Paket nicht gefunden (möglicherweise aus Repositories entfernt)

## Verfügbare Alternativen

### Option 1: OS auf Bookworm downgraden
**Vorteile:**
- Kernel 6.6.20 wäre verfügbar (wie in Issue #31 erwähnt)
- Stabiler als rpi-update

**Nachteile:**
- Größerer Schritt
- Könnte andere Pakete beeinträchtigen
- Backup erforderlich

### Option 2: Waveshare Pre-installed Image verwenden
**Vorteile:**
- Funktioniert garantiert (Bullseye mit Kernel 5.15.61)
- Bestätigt, dass Hardware funktioniert
- Keine Kernel-Downgrade-Probleme

**Nachteile:**
- Muss komplettes Image flashen
- Verliert aktuelle Konfiguration

### Option 3: Anderen verfügbaren Kernel testen
- Prüfe, welche Kernel-Versionen in Bookworm verfügbar sind
- Teste Kernel 6.6.20 (wie in Issue #31 erwähnt)

## Empfehlung
**Option 2 (Waveshare Pre-installed Image)** ist am sichersten, um zu bestätigen, dass die Hardware funktioniert. Danach können wir die Konfiguration auf das aktuelle System übertragen.

## Referenzen
- Issue #5550: https://github.com/raspberrypi/linux/issues/5550
- Issue #31: Waveshare Repository - empfiehlt 2023-12-05 Image (Kernel 6.6.20)


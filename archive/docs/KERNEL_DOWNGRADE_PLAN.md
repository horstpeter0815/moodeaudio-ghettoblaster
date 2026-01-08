# Kernel-Downgrade Plan - Kernel 6.1.42

## Ziel
Kernel von 6.12.47 (Trixie) auf 6.1.42 downgraden, wie in Issue #5550 erfolgreich getestet.

## Aktuelle Situation
- **OS:** Trixie (Debian 13)
- **Kernel:** 6.12.47+rpt-rpi-v8
- **Problem:** Kernel 6.1.42 ist nicht in Trixie-Repositories verfügbar

## Optionen

### Option 1: OS-Downgrade auf Bookworm (EMPFOHLEN)
**Vorteile:**
- Kernel 6.1.42 ist in Bookworm-Repositories verfügbar
- Stabiler als rpi-update
- Kann mit apt verwaltet werden

**Schritte:**
1. Backup des Systems erstellen
2. `/etc/apt/sources.list` auf Bookworm ändern
3. `apt update && apt install linux-image-6.1.42-rpi-v8`
4. Reboot

### Option 2: rpi-update mit Commit-Hash
**Nachteile:**
- rpi-update akzeptiert keine Command-Line-Parameter für Commits
- Kann System instabil machen
- Schwieriger zu verwalten

### Option 3: Manuelles Kernel-Paket installieren
**Schritte:**
1. Kernel-Paket von Bookworm-Repository herunterladen
2. Manuell mit `dpkg -i` installieren
3. Abhängigkeiten prüfen

## Empfohlener Ansatz
**Option 1 (OS-Downgrade auf Bookworm)** ist am sichersten und stabilsten.

## Risiken
- Kernel-Downgrade kann System instabil machen
- Einige Pakete könnten inkompatibel sein
- Backup vorher erstellen!

## Referenz
- Issue #5550: https://github.com/raspberrypi/linux/issues/5550
- Erfolgreich getestet mit Kernel 6.1.42 (Juli 2023)


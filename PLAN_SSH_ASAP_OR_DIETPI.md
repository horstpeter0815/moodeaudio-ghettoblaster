# Plan: SSH ASAP oder DietPi Recovery System

## Ziel
SSH-Zugriff so früh wie möglich, um Runtime-Evidence zu sammeln und Probleme zu debuggen.

---

## Option 1: SSH ASAP Service (EINFACHER - ZUERST VERSUCHEN)

### Was bereits erstellt wurde:
- ✅ `ssh-asap.service` - Startet SSH VOR sysinit.target
- ✅ `simple-boot-logger.sh` - Schreibt Boot-Logs nach `/var/log/boot-debug.log`
- ✅ `GET_BOOT_LOGS.sh` - Holt Logs vom Pi via SSH

### Nächste Schritte:
1. Neuen Build mit ssh-asap.service erstellen
2. Image auf SD-Karte schreiben
3. Pi booten
4. Warten bis SSH verfügbar ist (sollte sehr früh sein)
5. `GET_BOOT_LOGS.sh` ausführen um Runtime-Evidence zu sammeln

### Vorteile:
- Einfach (nur ein Service)
- Keine zusätzliche Partition nötig
- Direkt im Moode-System integriert

### Nachteile:
- Funktioniert nur wenn SSH wirklich startet
- Wenn Boot komplett hängt, hilft es nicht

---

## Option 2: DietPi als Recovery-System (FALLBACK)

### Konzept:
- **Partition 1:** Moode Audio (Hauptsystem)
- **Partition 2:** DietPi (Recovery-System mit garantiertem SSH)
- **Boot-Manager:** PINN oder manueller Boot-Wechsel via cmdline.txt

### Vorgehen:

#### Schritt 1: SD-Karte vorbereiten
```bash
# SD-Karte partitionieren:
# - Partition 1: Moode Audio (wie bisher)
# - Partition 2: DietPi (z.B. 4GB)
# - Boot-Partition: Geteilt (oder separate)
```

#### Schritt 2: DietPi installieren
1. DietPi Image herunterladen
2. Auf Partition 2 installieren
3. SSH aktivieren (DietPi hat das standardmäßig)
4. IP: 192.168.10.3 (oder DHCP)

#### Schritt 3: Boot-Wechsel einrichten
**Option A: PINN Boot-Manager**
- PINN installieren
- Beim Boot: Auswahl zwischen Moode und DietPi

**Option B: Manueller Wechsel via cmdline.txt**
- `cmdline.txt` auf Boot-Partition ändern
- `root=PARTUUID=xxx-01` für Moode
- `root=PARTUUID=xxx-02` für DietPi

#### Schritt 4: Von DietPi aus Moode debuggen
```bash
# SSH zu DietPi (garantiert verfügbar)
ssh root@192.168.10.3

# Mounte Moode-Partition
mount /dev/mmcblk0p2 /mnt/moode

# Analysiere Moode-System
chroot /mnt/moode systemctl status NetworkManager-wait-online
chroot /mnt/moode journalctl -u NetworkManager-wait-online
```

### Vorteile:
- **Garantiert SSH** (DietPi hat das immer)
- Kann Moode-System analysieren ohne dass es booten muss
- Kann Fixes direkt auf Moode-Partition anwenden
- Unabhängig von Moode-Boot-Problemen

### Nachteile:
- Komplexer (zwei Systeme)
- Mehr Speicherplatz nötig
- Zusätzliche Konfiguration

---

## Empfehlung

**Zuerst Option 1 versuchen:**
- ssh-asap.service ist bereits erstellt
- Einfacher und schneller
- Wenn SSH funktioniert, haben wir alles was wir brauchen

**Falls Option 1 nicht funktioniert:**
- Dann Option 2 (DietPi Recovery) implementieren
- Garantiert SSH-Zugriff
- Kann Moode-System von außen debuggen

---

## Nächste Schritte

1. **Jetzt:** Neuen Build mit ssh-asap.service erstellen
2. **Testen:** Pi booten, prüfen ob SSH früh verfügbar ist
3. **Falls erfolgreich:** Runtime-Evidence sammeln mit GET_BOOT_LOGS.sh
4. **Falls nicht erfolgreich:** DietPi Recovery-System einrichten


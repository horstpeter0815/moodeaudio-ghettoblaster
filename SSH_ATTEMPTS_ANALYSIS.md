# SSH Versuche Analyse - Warum funktionieren sie nicht?

## Gefundene SSH-Services im Projekt

### 1. ssh-ultra-early.service
**Location:** `moode-source/lib/systemd/system/ssh-ultra-early.service`
**Timing:**
- `After=local-fs.target`
- `Before=sysinit.target`
- `Before=basic.target`
- `Before=network.target`
**Methode:** Ruft `/usr/local/bin/force-ssh-on.sh` auf
**Status:** ❓ Nicht aktiviert im Build (wird übersprungen)

### 2. ssh-guaranteed.service
**Location:** `moode-source/lib/systemd/system/ssh-guaranteed.service`
**Timing:**
- `After=local-fs.target`
- `Before=network.target`
- `Before=moode-startup.service`
- `Before=sysinit.target`
**Methode:** 9 Sicherheitsebenen (Flag, enable, start, unmask, config, keys, permissions, restart, firewall)
**Status:** ✅ Aktiviert im Build (Zeile 430-436)

### 3. enable-ssh-early.service
**Location:** `moode-source/lib/systemd/system/enable-ssh-early.service`
**Timing:**
- `After=local-fs.target`
- `Before=network.target`
- `Before=moode-startup.service`
**Methode:** Einfach: enable + start + Flag
**Status:** ❌ DEAKTIVIERT im Build (Zeile 272-276) - "redundant"

### 4. ssh-asap.service (NEU)
**Location:** `custom-components/services/ssh-asap.service`
**Timing:**
- `After=local-fs.target`
- `Before=sysinit.target`
- `Before=basic.target`
- `Before=network.target`
- `Before=cloud-init.target`
**Methode:** 4 Methoden (Flag, enable, start, direkt sshd)
**Status:** ✅ Aktiviert im Build (Zeile 417-423)

### 5. ssh-watchdog.service
**Location:** `moode-source/lib/systemd/system/ssh-watchdog.service`
**Timing:**
- `After=network-online.target`
- `Wants=network-online.target`
**Methode:** Überwacht SSH alle 30 Sekunden, startet neu wenn nötig
**Status:** ✅ Aktiviert im Build (Zeile 459-465)
**Problem:** Startet NACH network-online - zu spät wenn network-online hängt!

### 6. fix-ssh-service.service
**Location:** `custom-components/services/fix-ssh-service.service`
**Status:** ❌ DEAKTIVIERT (Zeile 407-411) - "kann Display blockieren"

### 7. fix-ssh-sudoers.service
**Location:** `moode-source/lib/systemd/system/fix-ssh-sudoers.service`
**Status:** ❌ DEAKTIVIERT (Zeile 261-265) - "redundant"

---

## Problem-Analyse

### Warum funktionieren die Services nicht?

**Hypothese 1: Timing-Problem**
- Services starten VOR network-online
- Aber SSH braucht Netzwerk um erreichbar zu sein
- **ABER:** SSH kann auch OHNE Netzwerk starten (lokal), nur nicht erreichbar

**Hypothese 2: Service wird nicht ausgeführt**
- Services sind enabled, aber werden nicht gestartet
- Mögliche Ursache: Dependencies blockieren
- Oder: Service-Datei wird nicht korrekt installiert

**Hypothese 3: SSH wird gestartet, aber sofort wieder gestoppt**
- Moode oder ein anderer Service stoppt SSH
- Oder: SSH startet, aber Port 22 ist nicht offen

**Hypothese 4: SSH startet, aber Netzwerk ist nicht bereit**
- SSH läuft, aber Pi hat keine IP-Adresse
- Kann nicht erreicht werden, obwohl SSH läuft

**Hypothese 5: Service-Dateien werden nicht korrekt kopiert**
- Services sind in `moode-source/lib/systemd/system/`
- Werden sie nach `/lib/systemd/system/` kopiert?
- Oder nur nach `/etc/systemd/system/`?

---

## Was fehlt: Runtime-Evidence

**Wir wissen NICHT:**
1. Werden die Services überhaupt gestartet?
2. Wenn ja, wann genau?
3. Gibt es Fehlermeldungen?
4. Läuft SSH, aber ohne Netzwerk?
5. Wird SSH gestartet und dann wieder gestoppt?

**Das ist das Problem:** Wir raten, statt zu wissen.

---

## Lösung: Boot-Logging System

**Was wir brauchen:**
1. Service der SO FRÜH wie möglich startet
2. Schreibt ALLES in Log-Datei
3. Log-Datei ist via SSH abrufbar (wenn SSH funktioniert)
4. Oder: Log-Datei auf Boot-Partition (immer verfügbar)

**Nächster Schritt:**
- Boot-Logging Service erstellen
- Schreibt auf Boot-Partition (immer verfügbar, auch wenn rootfs nicht bootet)
- Oder: Schreibt auf rootfs, aber auch auf Boot-Partition als Backup


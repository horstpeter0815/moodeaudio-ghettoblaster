# SSH COMPLETE ANALYSIS - ROOT CAUSE

## Problem
SSH war NIE verfügbar nach 200+ Boots, trotz ENABLE_SSH=1 in config.

## Gefundene Fakten

### 1. ENABLE_SSH=1 ist gesetzt ✅
**Datei:** `imgbuild/pi-gen-64/config`
```
ENABLE_SSH=1
```

### 2. stage2 aktiviert SSH ✅
**Datei:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`
```bash
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
```
**→ SSH sollte aktiviert werden!**

### 3. stage3 Script versucht SSH zu aktivieren ✅
**Datei:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh`
- Mehrere Versuche SSH zu aktivieren
- SSH-Services werden erstellt
- /boot/firmware/ssh wird erstellt

## Mögliche Probleme

### Problem 1: SSH wird NACH stage3 deaktiviert
- Wird SSH von moOde deaktiviert?
- Wird SSH von einem anderen Service deaktiviert?
- Wird SSH beim ersten Boot deaktiviert?

### Problem 2: SSH-Service-Datei fehlt
- Ist sshd.service im Image?
- Ist OpenSSH installiert?
- Funktioniert systemctl enable ssh?

### Problem 3: Boot-Reihenfolge
- Wann startet SSH?
- Wird SSH vor dem Netzwerk gestartet?
- Wird SSH von first-boot-setup deaktiviert?

### Problem 4: moOde deaktiviert SSH
- Deaktiviert moOde SSH beim ersten Boot?
- Gibt es ein moOde-Script das SSH deaktiviert?
- Wird SSH von moOde's Setup deaktiviert?

## Nächste Schritte

1. ✅ Prüfen ob OpenSSH installiert ist
2. ✅ Prüfen ob sshd.service existiert
3. ✅ Prüfen ob SSH beim Boot gestartet wird
4. ✅ Prüfen ob moOde SSH deaktiviert
5. ✅ Prüfen Boot-Logs auf SSH-Fehler
6. ✅ Testen ob /boot/firmware/ssh funktioniert

## Kritische Tests

### Test 1: Ist OpenSSH installiert?
```bash
dpkg -l | grep openssh
which sshd
```

### Test 2: Ist sshd.service vorhanden?
```bash
ls -la /lib/systemd/system/sshd.service
ls -la /etc/systemd/system/multi-user.target.wants/sshd.service
```

### Test 3: Wird SSH beim Boot gestartet?
```bash
systemctl is-enabled ssh
systemctl is-active ssh
systemctl status ssh
```

### Test 4: Funktioniert /boot/firmware/ssh?
- Raspberry Pi OS aktiviert SSH wenn /boot/firmware/ssh existiert
- Wird das von moOde respektiert?

### Test 5: Wird SSH von moOde deaktiviert?
- Suche in moOde-Scripts nach SSH-Deaktivierung
- Prüfe moOde's first-boot Scripts

## Mögliche Lösungen

### Lösung 1: SSH NACH moOde aktivieren
- Erstelle Service der NACH moOde's Setup läuft
- Aktiviert SSH garantiert

### Lösung 2: SSH-Service-Datei direkt erstellen
- Erstelle Symlink manuell
- Überschreibe moOde's Deaktivierung

### Lösung 3: /boot/firmware/ssh verwenden
- Raspberry Pi OS aktiviert SSH automatisch
- Funktioniert das mit moOde?

### Lösung 4: SSH im first-boot-setup aktivieren
- Aktiviert SSH NACH moOde's Setup
- Garantiert dass SSH läuft


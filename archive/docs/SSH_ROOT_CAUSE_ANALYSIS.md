# SSH ROOT CAUSE ANALYSIS

## Problem
SSH war NIE verfügbar nach 200+ Boots, trotz zahlreicher "Fixes".

## Gefundene Probleme

### 1. hifiberry-tools.mk DEAKTIVIERT SSH
**Datei:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`
**Zeile 77-80:**
```makefile
# disable sshd by default
if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

**Problem:** Dies entfernt SSH NACH dem Build, egal was im chroot gemacht wurde.

### 2. Build-Reihenfolge Problem
- Chroot-Script aktiviert SSH
- hifiberry-tools wird NACHHER installiert
- hifiberry-tools DEAKTIVIERT SSH wieder

### 3. moOde könnte SSH deaktivieren
- MoOde könnte SSH beim ersten Boot deaktivieren
- Muss geprüft werden

### 4. SSH-Service könnte fehlen
- Prüfen ob sshd.service überhaupt im Image ist
- Prüfen ob OpenSSH installiert ist

## Lösungsansätze

### Lösung 1: hifiberry-tools.mk ändern
**Problem:** Wir verwenden pi-gen, nicht hifiberry buildroot direkt.

### Lösung 2: SSH NACH hifiberry-tools aktivieren
**Problem:** Wann wird hifiberry-tools installiert? Ist das relevant für pi-gen?

### Lösung 3: SSH im first-boot-setup aktivieren
**Problem:** Wird das NACH moOde's Deaktivierung ausgeführt?

### Lösung 4: SSH-Service-Datei direkt erstellen
**Problem:** Wird das überschrieben?

## Nächste Schritte

1. ✅ Prüfen ob OpenSSH im Image ist
2. ✅ Prüfen ob sshd.service im Image ist
3. ✅ Prüfen wann moOde SSH deaktiviert
4. ✅ Prüfen Boot-Reihenfolge
5. ✅ Testen ob SSH-Service-Datei existiert
6. ✅ Testen ob /boot/ssh Datei funktioniert

## Kritische Fragen

1. **Ist OpenSSH überhaupt installiert?**
   - Prüfe: `dpkg -l | grep openssh`
   - Prüfe: `which sshd`

2. **Ist sshd.service vorhanden?**
   - Prüfe: `/lib/systemd/system/sshd.service`
   - Prüfe: `/etc/systemd/system/sshd.service`

3. **Wird SSH von moOde deaktiviert?**
   - Suche in moOde-Scripts nach SSH-Deaktivierung

4. **Funktioniert /boot/ssh Flag?**
   - Raspberry Pi OS aktiviert SSH wenn /boot/ssh existiert
   - Wird das von moOde respektiert?

5. **Wann läuft first-boot-setup?**
   - Läuft es VOR oder NACH moOde's Setup?
   - Wird SSH danach wieder deaktiviert?


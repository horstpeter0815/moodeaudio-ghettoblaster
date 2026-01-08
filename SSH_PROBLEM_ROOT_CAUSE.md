# SSH Problem Root Cause Analysis

## Gefundene SSH-Services (7 Stück!)

1. **ssh-ultra-early.service** - Nicht aktiviert
2. **ssh-guaranteed.service** - ✅ Aktiviert
3. **enable-ssh-early.service** - ❌ Deaktiviert ("redundant")
4. **ssh-asap.service** - ✅ Aktiviert (NEU)
5. **ssh-watchdog.service** - ✅ Aktiviert (aber zu spät - nach network-online)
6. **fix-ssh-service.service** - ❌ Deaktiviert
7. **fix-ssh-sudoers.service** - ❌ Deaktiviert

## KRITISCHES PROBLEM GEFUNDEN

### Services werden kopiert von:
- `moode-source/lib/systemd/system/` → `/lib/systemd/system/` ✅
- `custom-components/services/` → **WIRD NICHT KOPIERT!** ❌

### ssh-asap.service ist in:
- `custom-components/services/ssh-asap.service` ❌
- **Wird NICHT ins Image kopiert!**

### ssh-guaranteed.service ist in:
- `moode-source/lib/systemd/system/ssh-guaranteed.service` ✅
- Wird kopiert

## ROOT CAUSE

**ssh-asap.service wird NICHT ins Image kopiert!**

Der Build prüft:
```bash
if [ -f "/lib/systemd/system/ssh-asap.service" ]; then
    systemctl enable ssh-asap.service
```

Aber die Datei existiert nicht, weil `custom-components/services/` nicht kopiert wird!

## LÖSUNG

**Option 1: ssh-asap.service nach moode-source kopieren**
```bash
cp custom-components/services/ssh-asap.service moode-source/lib/systemd/system/
```

**Option 2: custom-components kopieren im Build**
- Build-Script erweitern um custom-components zu kopieren

**Option 3: ssh-guaranteed.service verbessern**
- ssh-guaranteed.service ist bereits aktiviert
- Aber vielleicht startet es nicht früh genug?

## NÄCHSTER SCHRITT

1. Prüfen ob custom-components kopiert werden
2. Falls nicht: ssh-asap.service nach moode-source kopieren
3. Oder: Build-Script erweitern


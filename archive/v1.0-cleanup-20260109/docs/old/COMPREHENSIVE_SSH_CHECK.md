# Comprehensive SSH Services Check

## ✅ Services vorhanden in moode-source/lib/systemd/system/

1. ✅ ssh-asap.service - **JETZT KOPIERT**
2. ✅ ssh-guaranteed.service - vorhanden
3. ✅ ssh-watchdog.service - vorhanden
4. ✅ ssh-ultra-early.service - vorhanden (aber nicht aktiviert)
5. ✅ enable-ssh-early.service - vorhanden (aber deaktiviert)
6. ✅ boot-debug-logger.service - **JETZT KOPIERT**

## ✅ Scripts vorhanden in moode-source/usr/local/bin/

1. ✅ force-ssh-on.sh - vorhanden (wird von ssh-ultra-early.service verwendet)
2. ✅ simple-boot-logger.sh - **JETZT KOPIERT**

## ❌ PROBLEM GEFUNDEN: boot-debug-logger.sh fehlt!

**boot-debug-logger.service** ruft auf:
- `ExecStart=/usr/local/bin/boot-debug-logger.sh start`
- `ExecStartPost=/usr/local/bin/boot-debug-logger.sh monitor`

**ABER:** Diese Datei existiert NICHT!

**Lösung:** 
- Option 1: boot-debug-logger.sh erstellen
- Option 2: boot-debug-logger.service anpassen um simple-boot-logger.sh zu verwenden

## Timing-Analyse

### ssh-asap.service
- After=local-fs.target
- Before=sysinit.target ✅
- Before=cloud-init.target ✅
- **Startet am frühesten!**

### ssh-guaranteed.service
- After=local-fs.target
- Before=sysinit.target ✅
- Before=network.target ✅
- **ABER:** Nicht Before=cloud-init.target ⚠️

### ssh-watchdog.service
- After=network-online.target ⚠️ **ZU SPÄT!**
- Startet erst wenn network-online erreicht ist

### ssh-ultra-early.service
- After=local-fs.target
- Before=sysinit.target ✅
- **ABER:** Nicht aktiviert im Build

## Build-Integration Check

### 00-run-chroot.sh aktiviert:
1. ✅ ssh-asap.service (Zeile 417-423)
2. ✅ ssh-guaranteed.service (Zeile 430-436)
3. ✅ ssh-watchdog.service (Zeile 459-465)
4. ✅ boot-debug-logger.service (Zeile 446-448)

### 00-run-chroot.sh deaktiviert:
1. ❌ enable-ssh-early.service (Zeile 272-276)
2. ❌ fix-ssh-sudoers.service (Zeile 261-265)
3. ❌ fix-ssh-service.service (Zeile 407-411)

## Kopier-Logik Check

### 00-run.sh kopiert:
- ✅ moode-source/lib/systemd/system/* → rootfs/lib/systemd/system/
- ✅ moode-source/usr/local/bin/* → rootfs/usr/local/bin/

**Status:** ✅ Alle Services werden kopiert!

## Verbleibende Probleme

1. ❌ **boot-debug-logger.sh fehlt** - Service wird fehlschlagen
2. ⚠️ **ssh-watchdog startet zu spät** - nach network-online
3. ⚠️ **ssh-guaranteed hat kein Before=cloud-init.target**

## Empfohlene Fixes

1. **boot-debug-logger.sh erstellen** oder Service anpassen
2. **ssh-watchdog.service Timing ändern** - nicht auf network-online warten
3. **ssh-guaranteed.service** Before=cloud-init.target hinzufügen


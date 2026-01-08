# 🔍 VOLLSTÄNDIGE LISTE ALLER ERKENNTNISSE - config.txt Überschreibungsproblem

**Datum:** 2025-12-21  
**Status:** Laufende Recherche - Liste wird kontinuierlich erweitert

---

## 📋 ERKENNTNISSE ÜBER DAS ÜBERSCHREIBUNGSPROBLEM

### 1. **HAUPTPROBLEM: worker.php überschreibt config.txt**

**Datei:** `moode-source/www/daemon/worker.php`  
**Zeilen:** 105-118

**Mechanismus:**
- `worker.php` ruft `chkBootConfigTxt()` auf (Zeile 106)
- Wenn Headers fehlen → überschreibt komplette `config.txt` mit Default
- Zwei verschiedene Overwrite-Pfade:
  - Zeile 110: `sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');` (bei "Required header missing")
  - Zeile 116: `sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');` (bei "Main header missing" + REBOOT!)

**Quelle der Default config.txt:**
- `/usr/share/moode-player/boot/firmware/config.txt` (im Image)
- Wird komplett nach `/boot/firmware/config.txt` kopiert

---

### 2. **chkBootConfigTxt() FUNKTION - DIE PRÜFLOGIK**

**Datei:** `moode-source/www/inc/common.php`  
**Zeilen:** 559-594

**Prüflogik:**
1. Liest `config.txt` Zeile für Zeile
2. **KRITISCH:** Prüft Zeile 1 (`$lines[1]`) auf Main Header
   - `if (str_contains($lines[1], CFG_MAIN_FILE_HEADER))`
   - **WICHTIG:** Array-Index ist 1 (nicht 0!), also zweite Zeile!
3. Zählt dann alle 5 Headers:
   - Main Header (Zeile 1): `# This file is managed by moOde`
   - Device filters: `# Device filters`
   - General settings: `# General settings`
   - Do not alter: `# Do not alter this section`
   - Audio overlays: `# Audio overlays`
4. Wenn `$headerCount == 5` → OK
5. Wenn `$headerCount < 5` → "Required header missing" → OVERWRITE
6. Wenn Zeile 1 falsch → "Main header missing" → OVERWRITE + REBOOT

**Rückgabewerte:**
- `'Required headers present'` → Alles OK
- `'Required header missing'` → Overwrite (Zeile 110)
- `'Main header missing'` → Overwrite + Reboot (Zeile 116)

---

### 3. **DIE 5 ERFORDERLICHEN HEADERS (EXAKT)**

**Datei:** `moode-source/www/inc/constants.php`  
**Zeilen:** 158-163

**Exakte Header-Strings:**
1. `# This file is managed by moOde` (CFG_MAIN_FILE_HEADER)
2. `# Device filters` (CFG_DEVICE_FILTERS_HEADER)
3. `# General settings` (CFG_GENERAL_SETTINGS_HEADER)
4. `# Do not alter this section` (CFG_DO_NOT_ALTER_HEADER)
5. `# Audio overlays` (CFG_AUDIO_OVERLAYS_HEADER)

**Konstante:** `CFG_HEADERS_REQUIRED = 5`

**WICHTIG:**
- Header müssen **exakt** so sein (keine Leerzeichen, keine Variationen)
- Main Header muss in **Zeile 1** sein (Array-Index 1 in PHP!)
- Alle anderen Headers können irgendwo im File sein

---

### 4. **ARRAY-INDEX PROBLEM: Zeile 1 vs. $lines[1]**

**KRITISCHER BUG/UNKLARHEIT:**
- PHP `file()` gibt Array zurück, Index beginnt bei 0
- `$lines[0]` = erste Zeile
- `$lines[1]` = zweite Zeile
- **ABER:** Code prüft `$lines[1]` auf Main Header!
- **BEDEUTUNG:** Main Header muss in Zeile 2 sein? Oder ist das ein Bug?

**Mögliche Erklärungen:**
1. **Bug in moOde:** Sollte `$lines[0]` sein, ist aber `$lines[1]`
2. **Absicht:** Erste Zeile ist leer oder Kommentar, Main Header in Zeile 2
3. **File-Format:** moOde erwartet bestimmtes Format

**BEWEIS AUS CODE:**
```php
$lines = file(BOOT_CONFIG_TXT, FILE_IGNORE_NEW_LINES);
if (str_contains($lines[1], CFG_MAIN_FILE_HEADER)) {
    // Prüft Zeile 2 (Index 1)!
}
```

---

### 5. **updBootConfigTxt() - ANDERE ÜBERSCHREIBUNGEN**

**Datei:** `moode-source/www/inc/common.php`  
**Zeilen:** 596-662

**Funktion:** Wird von verschiedenen PHP-Skripten aufgerufen, um `config.txt` zu modifizieren

**Aufrufer:**
- `moode-source/www/inc/audio.php` (Zeilen 19, 33, 35, 40)
- `moode-source/www/inc/network.php` (Zeilen 234, 240)
- `moode-source/www/inc/autocfg.php` (Zeilen 148, 153, 174, 179, 184, 668, 685)
- `moode-source/www/daemon/worker.php` (Zeilen 375, 379, 3325, 3329, 3339, 3546, 3550, 3569)

**Modifizierte Settings:**
- `upd_audio_overlay` - Audio-Overlay ändern
- `upd_force_eeprom_read` - EEPROM-Read Flag
- `upd_hdmi_enable_4kp60` - 4K60 HDMI
- `upd_dsi_scn_rotate` - Display-Rotation (nur Touch1)
- `upd_pi_audio_driver` - Pi Audio Driver
- `upd_pci_express` - PCI Express
- `upd_fan_temp0` - Fan Temperature
- `upd_disable_bt` - Bluetooth deaktivieren
- `upd_disable_wifi` - WiFi deaktivieren

**WICHTIG:** Diese Funktionen verwenden `sed` zum Modifizieren, überschreiben NICHT die ganze Datei!

---

### 6. **worker-php-patch.sh - DER AKTUELLE FIX**

**Datei:** `moode-source/usr/local/bin/worker-php-patch.sh`

**Was macht der Patch:**
- Findet die Zeile in `worker.php`, die `config.txt` kopiert
- Fügt Code hinzu, der nach dem Kopieren `display_rotate=0` wiederherstellt
- Verhindert, dass `display_rotate` verloren geht

**Patch-Code:**
```bash
sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
    // Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
    sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
    sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"
```

**PROBLEM:** Dieser Patch stellt nur `display_rotate` wieder her, nicht andere Settings!

**Angewendet in:**
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh` (während Build)
- `moode-source/usr/local/bin/first-boot-setup.sh` (beim ersten Boot)

---

### 7. **BOOT-SEQUENZ - WANN PASSIERT WAS**

**Timeline:**
1. **00:00** - Kernel Boot, liest `/boot/firmware/config.txt`
2. **00:05** - Systemd startet
3. **00:10** - `ssh-ultra-early.service` (force-ssh-on.sh)
4. **00:15** - `network-guaranteed.service`
5. **00:20** - `first-boot-setup.service` (first-boot-setup.sh)
   - Kompiliert Overlays
   - Wendet worker.php Patch an
   - Erstellt User "andre"
6. **00:30** - moOde Services starten
7. **00:35** - `worker.php` Daemon startet
8. **00:40** - `worker.php` prüft UserID
9. **01:00-03:00** - `worker.php` wartet auf Linux Startup (max 3 Minuten)
10. **03:05** - ⚠️ **KRITISCH:** `worker.php` ruft `chkBootConfigTxt()` auf
11. **03:06** - Wenn Headers fehlen → **OVERWRITE config.txt!**
12. **03:07** - `worker.php` setzt Initialisierung fort

**WICHTIG:** Overwrite passiert NACH allen anderen Boot-Services!

---

### 8. **WARUM WIRD config.txt ÜBERSCHRIEBEN?**

**Mögliche Gründe:**
1. **Headers fehlen komplett** - config.txt wurde manuell erstellt ohne Headers
2. **Header falsch formatiert** - Leerzeichen, Groß-/Kleinschreibung, etc.
3. **Header in falscher Zeile** - Main Header nicht in Zeile 1 (oder Zeile 2?)
4. **Header doppelt** - Mehrere gleiche Header verwirren die Zählung
5. **Header beschädigt** - Datei wurde korrupt oder unvollständig geschrieben
6. **macOS Datei-Operationen** - `.DS_Store`, `.fseventsd` könnten Datei beschädigen
7. **SD-Karte Probleme** - Schreibfehler, unvollständige Syncs

---

### 9. **AKTUELLE LÖSUNGSANSÄTZE (BEREITS IMPLEMENTIERT)**

**A) worker-php-patch.sh**
- **Pro:** Stellt `display_rotate` nach Overwrite wieder her
- **Contra:** Nur `display_rotate`, nicht andere Settings
- **Contra:** Workaround, nicht Root Cause Fix

**B) Headers in config.txt hinzufügen**
- **Pro:** Verhindert Overwrite komplett
- **Contra:** Wenn Headers fehlen → Overwrite passiert trotzdem
- **Status:** Wird in verschiedenen Scripts versucht

**C) config.txt schreibgeschützt machen**
- **Pro:** Verhindert Overwrite
- **Contra:** Verhindert auch legitime Updates
- **Contra:** moOde braucht Schreibzugriff für Updates

---

### 10. **PROBLEME MIT AKTUELLEN FIXES**

**Problem 1: Headers werden nicht korrekt erkannt**
- Test Suite findet Headers manchmal nicht
- `awk`/`grep` Kommandos funktionieren nicht zuverlässig
- macOS vs. Linux Unterschiede

**Problem 2: Zeile 1 vs. Zeile 2 Unklarheit**
- Code prüft `$lines[1]` (zweite Zeile)
- Dokumentation sagt "Zeile 1"
- Welches ist korrekt?

**Problem 3: SD-Karte nicht gemountet**
- Scripts können `config.txt` nicht finden
- `/Volumes/bootfs` existiert nicht
- User muss SD-Karte manuell mounten

**Problem 4: Permissions**
- `sudo` erforderlich für Schreibzugriff
- Scripts schlagen fehl ohne `sudo`
- macOS verhindert manche Operationen

---

### 11. **MOODE DEFAULT config.txt STRUKTUR**

**Datei:** `moode-source/usr/share/moode-player/boot/firmware/config.txt` (im Image)

**Erwartete Struktur:**
```
# This file is managed by moOde

# Device filters
[pi5]
...

# General settings
[all]
...

# Do not alter this section
...

# Audio overlays
...
```

**WICHTIG:** Diese Struktur muss in jeder `config.txt` vorhanden sein!

---

### 12. **WEITERE ÜBERSCHREIBUNGSQUELLEN**

**A) first-boot-setup.sh**
- **Datei:** `moode-source/usr/local/bin/first-boot-setup.sh`
- **Status:** Überschreibt NICHT config.txt (nur Overlays, SSH)

**B) pi-gen Build Scripts**
- **Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`
- **Status:** Installiert Default config.txt während Build
- **Relevanz:** Nur während Image-Build, nicht beim Boot

**C) Backup/Restore**
- **Datei:** `moode-source/www/util/backup_manager.py`
- **Status:** Kann config.txt während Restore überschreiben
- **Relevanz:** Nur wenn Backup/Restore durchgeführt wird

---

### 13. **TEST SUITE ERKENNTNISSE**

**Datei:** `tools/test/complete-verification.sh`

**Geprüfte Punkte:**
1. Zeile 1 Main Header (exakt)
2. Alle 5 Headers (exakt)
3. SSH-Flag Datei
4. `display_rotate=2` in `[pi5]` Section
5. `fbcon=rotate:3` in `cmdline.txt`
6. Overwrite-Simulation
7. Default config.txt Vergleich
8. config.txt Struktur

**Aktuelle Probleme:**
- `awk` Kommando für `display_rotate` funktioniert nicht immer
- Header-Prüfung zu strikt (keine Variationen erlaubt)
- SD-Karte nicht immer gefunden

---

### 14. **MACOS-SPEZIFISCHE PROBLEME**

**A) Datei-System Unterschiede**
- macOS erstellt `.DS_Store`, `.fseventsd` auf SD-Karten
- `worker.php` löscht diese (Zeilen 123-125), aber könnte Dateien beschädigen

**B) sed vs. gsed**
- macOS `sed` ist BSD-Version, nicht GNU
- `-i` Flag funktioniert anders
- Scripts müssen `gsed` verwenden oder Workarounds

**C) Permissions**
- macOS verhindert manche Schreiboperationen
- `sudo` erforderlich für viele Operationen
- Scripts müssen `sudo` richtig handhaben

---

### 15. **PHP file() FUNKTION VERHALTEN**

**PHP `file()` Funktion:**
- Gibt Array zurück, Index beginnt bei 0
- `FILE_IGNORE_NEW_LINES` entfernt `\n` am Ende
- Leere Zeilen werden als leere Strings gespeichert

**Beispiel:**
```php
$lines = file('config.txt', FILE_IGNORE_NEW_LINES);
// $lines[0] = erste Zeile
// $lines[1] = zweite Zeile
// ...
```

**KRITISCH:** Code prüft `$lines[1]` (zweite Zeile) auf Main Header!

---

### 16. **MÖGLICHE ROOT CAUSE FIXES**

**A) Headers immer korrekt setzen**
- ✅ Alle 5 Headers in config.txt
- ✅ Main Header in Zeile 1 (oder Zeile 2?)
- ✅ Exakte String-Matches
- **Problem:** Wenn Headers fehlen → Overwrite passiert trotzdem

**B) worker.php patchen**
- ✅ Patch erweitern, um ALLE Settings wiederherzustellen
- ✅ Nicht nur `display_rotate`, sondern auch HDMI, Audio, etc.
- **Problem:** Komplex, muss bei jedem moOde Update neu angewendet werden

**C) chkBootConfigTxt() modifizieren**
- ✅ Funktion so ändern, dass sie Settings erhält
- ✅ Merge statt kompletter Overwrite
- **Problem:** Erfordert moOde Source-Modifikation

**D) config.txt Backup vor Overwrite**
- ✅ Backup erstellen, bevor Overwrite
- ✅ Settings aus Backup wiederherstellen
- **Problem:** Komplex, Timing-Probleme

---

### 17. **DOKUMENTATION ÜBER DAS PROBLEM**

**Gefundene Dokumentation:**
- `BOOT_PROCESS_COMPLETE_WITH_OVERWRITE.md` - Vollständige Boot-Prozess Analyse
- `CRITICAL_FINDING_WORKER_PHP.md` - Kritischer Fund zu worker.php
- `COMPLETE_BOOT_PROCESS_ANALYSIS.md` - Boot-Sequenz Analyse
- `SHELL_SCRIPT_SEARCH_RESULTS.md` - Shell-Script Suche (keine gefunden)
- `IMPORTANT_INSIGHTS_RECOVERY.md` - Wichtige Erkenntnisse

**Konsens:** worker.php ist der Hauptverursacher, nicht Shell-Scripts!

---

### 18. **OFFENE FRAGEN**

1. **Warum prüft Code `$lines[1]` statt `$lines[0]`?**
   - Bug oder Absicht?
   - Sollte Main Header in Zeile 1 oder Zeile 2 sein?

2. **Warum werden Headers manchmal nicht erkannt?**
   - Encoding-Probleme?
   - Leerzeichen-Probleme?
   - Datei-Beschädigung?

3. **Warum funktioniert worker-php-patch.sh nicht immer?**
   - Timing-Probleme?
   - Patch wird überschrieben?
   - Patch wird nicht angewendet?

4. **Warum wird config.txt manchmal leer oder korrupt?**
   - SD-Karte Probleme?
   - Unvollständige Schreibvorgänge?
   - macOS Datei-Operationen?

5. **Gibt es andere Überschreibungsquellen?**
   - Andere PHP-Scripts?
   - Systemd Services?
   - Cron Jobs?

---

### 19. **NÄCHSTE SCHRITTE**

**A) Debugging mit Runtime-Logs**
- Instrumentierung von `chkBootConfigTxt()`
- Loggen aller Header-Prüfungen
- Loggen aller Overwrite-Operationen

**B) Testen mit verschiedenen config.txt Varianten**
- Headers in verschiedenen Zeilen
- Headers mit/ohne Leerzeichen
- Headers mit verschiedenen Encodings

**C) Analysieren der Default config.txt**
- Welche Headers sind vorhanden?
- Welche Struktur hat sie?
- Warum wird sie als "korrekt" erkannt?

**D) Prüfen der SD-Karte**
- Aktuelle config.txt lesen
- Headers prüfen
- Struktur analysieren

---

### 20. **ZUSAMMENFASSUNG**

**HAUPTPROBLEM:**
- `worker.php` überschreibt `config.txt` komplett, wenn Headers fehlen
- Overwrite passiert bei jedem Boot, nach Linux Startup
- Alle custom Settings gehen verloren

**ROOT CAUSE:**
- `chkBootConfigTxt()` prüft auf 5 exakte Headers
- Wenn Headers fehlen → kompletter Overwrite mit Default
- Keine Merge-Logik, keine Settings-Erhaltung

**AKTUELLE FIXES:**
- `worker-php-patch.sh` stellt `display_rotate` wieder her
- Headers werden in config.txt hinzugefügt
- Beide sind Workarounds, keine Root Cause Fixes

**PROBLEME:**
- Headers werden nicht immer korrekt erkannt
- Zeile 1 vs. Zeile 2 Unklarheit
- macOS-spezifische Probleme
- SD-Karte nicht immer verfügbar

**NÄCHSTE SCHRITTE:**
- Runtime-Logging implementieren
- Verschiedene config.txt Varianten testen
- Default config.txt analysieren
- SD-Karte prüfen

---

---

### 21. **KRITISCHER BUG: $lines[1] vs. $lines[0] - MPD.CONF ANALOGIE**

**Gefunden in:** `moode-source/www/daemon/worker.php` Zeile 905

**Analoges Problem bei mpd.conf:**
```php
$lines = file(MPD_CONF);
if (!str_contains($lines[1], 'This file is managed by moOde')) {
    // Prüft auch Zeile 2 (Index 1)!
}
```

**BEDEUTUNG:**
- moOde verwendet **konsistent** `$lines[1]` (zweite Zeile) für Header-Prüfung
- Dies ist **KEIN Bug**, sondern **Absicht**!
- **FOLGERUNG:** Main Header muss in **Zeile 2** sein, nicht Zeile 1!

**MÖGLICHE ERKLÄRUNG:**
- Zeile 1 könnte leer sein oder Kommentar
- Zeile 2 ist die erste "echte" Zeile
- moOde erwartet bestimmtes File-Format

**WICHTIG:** Alle Fixes müssen Main Header in **Zeile 2** setzen, nicht Zeile 1!

---

### 22. **BOOT_CONFIG_TXT KONSTANTE**

**Datei:** `moode-source/www/inc/constants.php`  
**Zeile:** 86

**Definition:**
```php
const BOOT_DIR = '/boot/firmware';
const BOOT_CONFIG_TXT = BOOT_DIR . '/config.txt';
```

**Bedeutung:**
- `BOOT_CONFIG_TXT = '/boot/firmware/config.txt'`
- Wird überall in moOde verwendet
- Konsistenter Pfad für alle Operationen

---

### 23. **DEFAULT config.txt QUELLE**

**Datei:** `moode-source/usr/share/moode-player/boot/firmware/config.txt` (im Image)

**Wird kopiert von:**
- `imgbuild/pi-gen-64/stage1/00-boot-files/files/config.txt` (während Build)

**Struktur:**
- Enthält alle 5 Headers
- Enthält Standard-Settings für Pi 5
- Wird als "korrekt" erkannt von `chkBootConfigTxt()`

**WICHTIG:** Diese Datei ist die Quelle für alle Overwrites!

---

### 24. **config.txt.overwrite - CUSTOM BUILD TEMPLATE**

**Datei:** `moode-source/boot/firmware/config.txt.overwrite`

**Zweck:**
- Template für Custom Build
- Wird während Build verwendet
- Enthält Ghettoblaster-spezifische Settings

**Struktur:**
- Zeile 1: `#########################################`
- Zeile 2: `# Ghettoblaster Custom Build`
- Zeile 3: `# This file is managed by moOde` ← **Main Header in Zeile 3!**

**PROBLEM:** Main Header ist in Zeile 3, nicht Zeile 2!
- `chkBootConfigTxt()` prüft `$lines[1]` (Zeile 2)
- Wenn Main Header in Zeile 3 ist → wird nicht erkannt!

---

### 25. **PHP file() FUNKTION - LEERE ZEILEN**

**PHP `file()` Verhalten:**
- Leere Zeilen werden als leere Strings (`""`) gespeichert
- `FILE_IGNORE_NEW_LINES` entfernt nur `\n`, nicht leere Strings
- `$lines[0]` könnte leer sein, `$lines[1]` ist erste nicht-leere Zeile

**MÖGLICHE ERKLÄRUNG:**
- Wenn Zeile 1 leer ist → `$lines[0] = ""`
- Main Header in Zeile 2 → `$lines[1] = "# This file is managed by moOde"`
- Code prüft `$lines[1]` → findet Header → OK!

**FOLGERUNG:** 
- Zeile 1 kann leer sein oder Kommentar
- Main Header muss in Zeile 2 sein (erste "echte" Zeile)

---

### 26. **str_contains() vs. == VERGLEICH**

**In `chkBootConfigTxt()`:**
- Main Header: `str_contains($lines[1], CFG_MAIN_FILE_HEADER)` → **Substring-Suche**
- Andere Headers: `$line == CFG_DEVICE_FILTERS_HEADER` → **Exakter Match**

**BEDEUTUNG:**
- Main Header kann **Teil** einer längeren Zeile sein
- Andere Headers müssen **exakt** matchen

**BEISPIEL:**
- `"# This file is managed by moOde"` → OK (exakt)
- `"# This file is managed by moOde - Custom Build"` → OK (enthält String)
- `"# Device filters"` → OK (exakt)
- `"# Device filters - Custom"` → **NICHT OK** (nicht exakt!)

---

### 27. **MACOS DOT-FILES PROBLEM**

**Gefunden in:** `moode-source/www/daemon/worker.php` Zeilen 123-125

**Code:**
```php
if (file_exists(BOOT_DIR . '/.fseventsd')) {
    sysCmd('rm -rf ' . BOOT_DIR . '/.fseventsd');
    sysCmd('rm -rf ' . BOOT_DIR . '/.Spotlight-V100');
}
```

**Problem:**
- macOS erstellt `.fseventsd` und `.Spotlight-V100` auf SD-Karten
- Diese könnten `config.txt` beschädigen oder beeinflussen
- moOde löscht sie, aber **NACH** `chkBootConfigTxt()`!

**TIMING:**
1. macOS erstellt Dot-Files auf SD-Karte
2. `chkBootConfigTxt()` liest `config.txt` (könnte beschädigt sein)
3. Overwrite passiert
4. Dot-Files werden gelöscht

**MÖGLICHE FOLGE:** Dot-Files könnten `config.txt` beschädigen, bevor sie gelöscht werden!

---

### 28. **FILE_ENCODING UND LINE ENDINGS**

**Mögliche Probleme:**
- Windows: `\r\n` (CRLF)
- Unix: `\n` (LF)
- macOS: `\r` (CR) oder `\n` (LF)

**PHP `file()` Verhalten:**
- Liest Datei Zeile für Zeile
- Entfernt `\n` mit `FILE_IGNORE_NEW_LINES`
- **Entfernt NICHT** `\r`!

**PROBLEM:**
- Wenn `config.txt` Windows-Format hat → `\r` bleibt in Strings
- `"# This file is managed by moOde\r"` != `"# This file is managed by moOde"`
- Header wird nicht erkannt!

**LÖSUNG:** `config.txt` muss Unix-Format (LF) haben!

---

### 29. **ZUSAMMENFASSUNG DER NEUEN ERKENNTNISSE**

**KRITISCH:**
1. **Main Header muss in Zeile 2 sein** (`$lines[1]`), nicht Zeile 1!
2. **Zeile 1 kann leer sein** oder Kommentar
3. **str_contains()** für Main Header (Substring), **==** für andere (exakt)
4. **Line Endings** müssen Unix-Format (LF) sein
5. **macOS Dot-Files** könnten `config.txt` beschädigen

**AKTUELLE PROBLEME:**
- `config.txt.overwrite` hat Main Header in Zeile 3 → wird nicht erkannt!
- Scripts setzen Main Header in Zeile 1 → wird nicht erkannt!
- Windows-Format könnte Header-Prüfung stören

**NÄCHSTE SCHRITTE:**
- Main Header in **Zeile 2** setzen (nicht Zeile 1!)
- Zeile 1 leer lassen oder Kommentar
- Unix Line Endings sicherstellen
- macOS Dot-Files vor `chkBootConfigTxt()` löschen

---

---

### 30. **PI-GEN BUILD SCRIPTS - config.txt INSTALLATION**

**Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`

**Was passiert:**
```bash
install -m 644 files/config.txt "${ROOTFS_DIR}/boot/firmware/"
```

**KRITISCHES PROBLEM:**
- Die Standard `config.txt` aus `stage1/00-boot-files/files/config.txt` wird installiert
- Diese Datei hat **KEINE moOde Headers**!
- Sie ist die Standard Raspberry Pi config.txt ohne moOde-spezifische Struktur

**Inhalt der Standard config.txt:**
- Zeile 1: `# For more options and information see`
- Zeile 2: `# http://rptl.io/configtxt`
- **KEIN** `# This file is managed by moOde` Header!
- **KEINE** der 5 erforderlichen Headers!

**FOLGE:**
- Beim ersten Boot prüft `worker.php` → Headers fehlen → **OVERWRITE!**
- Default config.txt wird kopiert → Headers sind jetzt vorhanden
- Aber alle Custom Settings sind verloren!

---

### 31. **config.txt.overwrite - WIRD NICHT VERWENDET!**

**Dateien:**
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run.sh` (Zeile 37-40)
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-deploy.sh` (Zeile 19-22)

**Was passiert:**
```bash
cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/"
```

**PROBLEM:**
- `config.txt.overwrite` wird nur **kopiert**, nicht verwendet!
- Es bleibt als separate Datei im `/boot/firmware/` Verzeichnis
- Die **echte** `config.txt` wird NICHT ersetzt!
- `config.txt.overwrite` wird **ignoriert**!

**WARUM:**
- pi-gen installiert Standard config.txt in stage1
- Custom Scripts kopieren nur `config.txt.overwrite` als separate Datei
- Es gibt **KEIN Script**, das `config.txt.overwrite` → `config.txt` umbenennt oder kopiert!

---

### 32. **config.txt.overwrite STRUKTUR PROBLEM**

**Datei:** `moode-source/boot/firmware/config.txt.overwrite`

**Struktur:**
```
Zeile 1: #########################################
Zeile 2: # Ghettoblaster Custom Build
Zeile 3: # This file is managed by moOde  ← Main Header in Zeile 3!
```

**PROBLEM:**
- Main Header ist in **Zeile 3**, nicht Zeile 2!
- `chkBootConfigTxt()` prüft `$lines[1]` (Zeile 2)
- Zeile 2 ist `# Ghettoblaster Custom Build` → wird nicht erkannt!

**FOLGE:**
- Selbst wenn `config.txt.overwrite` verwendet würde → Header würde nicht erkannt!
- `worker.php` würde es als "Main header missing" behandeln → Overwrite + Reboot!

---

### 33. **BUILD SEQUENZ - WANN WIRD WAS INSTALLIERT**

**Timeline:**
1. **Stage 1 (00-boot-files):**
   - Standard `config.txt` wird installiert → `/boot/firmware/config.txt`
   - **KEINE moOde Headers!**

2. **Stage 3 (03-ghettoblaster-custom):**
   - `config.txt.overwrite` wird kopiert → `/boot/firmware/config.txt.overwrite`
   - **Wird NICHT verwendet!**

3. **Boot:**
   - Kernel liest `/boot/firmware/config.txt` (Standard, keine Headers)
   - `worker.php` prüft → Headers fehlen → **OVERWRITE!**
   - Default moOde config.txt wird kopiert → Headers vorhanden, aber Custom Settings verloren

**PROBLEM:** Es gibt **KEINEN** Schritt, der die Standard config.txt durch config.txt.overwrite ersetzt!

---

### 34. **MOODE DEFAULT config.txt QUELLE**

**Datei:** `/usr/share/moode-player/boot/firmware/config.txt` (im Image)

**Wird erstellt von:**
- moOde Build-Prozess (nicht pi-gen)
- Wird während moOde Installation ins Image kopiert
- Enthält alle 5 Headers korrekt

**Wird verwendet für:**
- Overwrite, wenn Headers fehlen (worker.php Zeile 110, 116)
- Als "korrekte" Referenz

**WICHTIG:** Diese Datei hat die korrekte Struktur mit Headers!

---

### 35. **LÖSUNGSANSÄTZE FÜR BUILD-PROBLEM**

**A) config.txt.overwrite → config.txt ersetzen**
- In `00-run.sh` oder `00-deploy.sh`: `mv config.txt.overwrite config.txt`
- **Problem:** Überschreibt Standard config.txt, könnte andere Settings verlieren

**B) config.txt.overwrite in config.txt mergen**
- Header aus config.txt.overwrite in Standard config.txt einfügen
- **Problem:** Komplex, könnte Konflikte verursachen

**C) Standard config.txt mit Headers versehen**
- `stage1/00-boot-files/files/config.txt` modifizieren
- Headers hinzufügen
- **Problem:** Ändert Standard pi-gen Template

**D) Post-Build Script**
- Nach Build: `config.txt.overwrite` → `config.txt` kopieren
- **Problem:** Timing, muss nach allen Stages passieren

**E) moOde Installation modifizieren**
- Während moOde Installation: config.txt mit Headers versehen
- **Problem:** Erfordert moOde Source-Modifikation

---

### 36. **ZUSAMMENFASSUNG PI-GEN PROBLEME**

**HAUPTPROBLEM:**
1. Standard config.txt hat keine moOde Headers
2. config.txt.overwrite wird nicht verwendet
3. config.txt.overwrite hat Header in falscher Zeile (3 statt 2)
4. Kein Script ersetzt Standard config.txt mit Custom Version

**ROOT CAUSE:**
- pi-gen installiert Standard config.txt ohne Headers
- Custom Scripts kopieren nur config.txt.overwrite, verwenden es aber nicht
- Beim Boot fehlen Headers → worker.php überschreibt alles

**LÖSUNG:**
- config.txt.overwrite muss **ersetzt** werden, nicht nur kopiert
- Header muss in **Zeile 2** sein, nicht Zeile 3
- Oder: Standard config.txt muss Headers bekommen

---

**Status:** 🔍 **RECHERCHE LAUFEND - LISTE WIRD ERWEITERT**


# Naming Rules für Scripts und Configs

## WICHTIGE REGEL:

**NIE Scripts/Configs mit finalen Namen benennen BEVOR sie getestet und verifiziert wurden!**

## Richtige Vorgehensweise:

### 1. Script erstellen:
- Name: `test_*.sh` oder `try_*.sh`
- Beispiel: `test_rotation_fix.sh`

### 2. Script ausführen und testen:
- Script ausführen
- Prüfen ob es funktioniert
- Warten auf Verifikation vom Benutzer

### 3. ERST NACH VERIFIZIERUNG umbenennen:
- Wenn Benutzer bestätigt: "Es funktioniert"
- DANN umbenennen zu: `WORKING_CONFIG.sh` oder `FINAL_CONFIG.sh`
- Oder: `rotation_fix_working.sh`

## Falsche Namen (NICHT verwenden):
- ❌ `MAKE_ROTATION_PERMANENT.sh` (bevor es getestet wurde)
- ❌ `FIX_EVERYTHING_NOW.sh` (bevor es funktioniert)
- ❌ `FINAL_CONFIG.sh` (bevor es verifiziert wurde)

## Richtige Namen (verwenden):
- ✅ `test_rotation_fix.sh` (zum Testen)
- ✅ `try_fix_rotation.sh` (zum Versuchen)
- ✅ `rotation_fix_test.sh` (zum Testen)

## Nach Verifikation:
- ✅ `WORKING_CONFIG.sh` (nach erfolgreicher Verifikation)
- ✅ `rotation_fix_verified.sh` (nach Verifikation)
- ✅ `FINAL_CONFIG.sh` (nur wenn wirklich final)

## Status: ✅ Regel verstanden und angewendet


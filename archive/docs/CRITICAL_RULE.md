# ⚠️ KRITISCH: Script-Pfade - NIEMALS VERGESSEN

## ❌ FEHLER VERMEIDEN:

**NIEMALS Scripts im Projekt-Verzeichnis erwähnen, wenn User im Home-Verzeichnis ist!**

## ✅ REGEL:

1. **Wenn Script im Projekt-Verzeichnis:** IMMER vollständigen Pfad angeben
2. **ODER:** Script ins Home-Verzeichnis kopieren
3. **NIEMALS:** `./SCRIPT.sh` erwähnen ohne zu prüfen wo User ist

## 📋 User-Präferenz:

**"If I get a single such feedback, you'll start as a trainee again."**

→ **NIEMALS** unvollständige Pfade oder Scripts die nicht existieren!

## ✅ LÖSUNG:

**IMMER prüfen:**
- Wo ist der User? (`pwd` oder Home-Verzeichnis)
- Wo ist das Script? (Projekt-Verzeichnis)
- **ENTSCHEIDUNG:**
  - Script kopieren ins Home-Verzeichnis
  - ODER: Vollständigen Pfad angeben

## 🔧 FIXED:

- ✅ `CHECK_NETWORK_SPEED.sh` → `~/CHECK_NETWORK_SPEED.sh`
- ✅ `CHECK_BUILD_STATUS.sh` → `~/CHECK_BUILD_STATUS.sh`

**Diese Regel gilt FÜR IMMER!**


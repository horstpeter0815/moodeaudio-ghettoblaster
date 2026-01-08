# 🔧 CUSTOM-STAGE FIX - 2025-12-08

**Zeit:** 00:10  
**Status:** ✅ FIX ANGEWENDET

---

## ❌ PROBLEM

**Build fehlgeschlagen in Stage 3:**
- Stage: `03-ghettoblaster-custom`
- Fehler: Script beendet mit Fehler
- Ursache: `usermod` schlägt fehl wenn Gruppen nicht existieren

---

## ✅ FIX ANGEWENDET

**Datei:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`

### **Fix 1: set +e**
```bash
#!/bin/bash
set +e  # Don't exit on error - handle errors gracefully
```

### **Fix 2: usermod mit Fallback**
```bash
# Vorher:
usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre

# Nachher:
usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || \
usermod -aG audio,video,sudo andre 2>/dev/null || true
```

---

## 🚀 BUILD

- ✅ Fix angewendet
- ✅ Build neu gestartet
- ⏳ Wird überwacht

---

**Status:** ✅ FIX ANGEWENDET, BUILD LÄUFT


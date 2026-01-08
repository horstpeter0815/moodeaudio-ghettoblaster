# ⚠️ KRITISCHE FIXES - PERMANENTE PROBLEME

## 🔴 Problem #1: SSH NICHT AKTIVIERT

**Problem:** SSH ist nach jedem Build standardmäßig deaktiviert.

**Auswirkung:**
- Kein SSH-Zugriff nach Boot
- Konfiguration nur über Web-UI möglich
- Automatisierung nicht möglich
- **PERMANENTES PROBLEM** - tritt bei jedem Build auf

**Fix implementiert:**
1. ✅ `imgbuild/moode-cfg/config`: `ENABLE_SSH=1` (war 0)
2. ✅ `stage3_03-ghettoblaster-custom_00-run-chroot.sh`: SSH aktivieren im Build
3. ✅ `/boot/firmware/ssh` Datei erstellen (Raspberry Pi Standard)

**Datum:** 2025-12-07
**Status:** ✅ FIXED im Source

---

## 📋 CHECKLISTE FÜR JEDEN BUILD:

- [ ] SSH aktiviert? (`ENABLE_SSH=1` in config)
- [ ] SSH-Service enabled im Build-Script?
- [ ] `/boot/firmware/ssh` Datei erstellt?
- [ ] Test nach Build: SSH funktioniert?

---

## 🔧 Implementierte Fixes:

### 1. SSH Aktivierung
```bash
# In stage3_03-ghettoblaster-custom_00-run-chroot.sh:
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
touch /boot/firmware/ssh 2>/dev/null || true
```

### 2. Config-File
```bash
# In imgbuild/moode-cfg/config:
ENABLE_SSH=1  # War: 0
```

---

**Diese Fixes müssen bei jedem Build aktiv sein!**


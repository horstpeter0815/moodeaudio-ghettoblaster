# ⚠️ KRITISCH: IP-ADRESSEN - NIEMALS VERGESSEN!

**Datum:** 2025-12-22
**Status:** ✅ PERMANENTE ERINNERUNG

---

## 🚫 IP .101 = FREMDER WLAN-ROUTER (NICHT DER PI!)

**WICHTIG:** 
- **192.168.1.101** = **FREMDER WLAN-ROUTER** (NICHT der Pi!)
- **NIEMALS** diese IP für SSH oder Verbindungen zum Pi verwenden!
- Der Benutzer hat das **100+ MAL** gesagt!

---

## ✅ RICHTIGE PI-IP-ADRESSEN:

1. **192.168.10.2** = Direct LAN (Mac ↔ Pi, statisch konfiguriert)
2. **192.168.1.100** = Mögliche LAN-IP (wenn Router vorhanden)
3. **moodepi5.local** = Hostname (mDNS)
4. **GhettoBlaster.local** = Hostname (mDNS)

---

## 🔍 PRÜFUNG BEI IP-ERKENNUNG:

**BEVOR eine IP verwendet wird:**
1. ✅ Prüfe: Endet die IP mit `.101`? → **FREMDER ROUTER, IGNORIEREN!**
2. ✅ Prüfe: Ist es `192.168.10.2`? → **RICHTIG (Direct LAN)**
3. ✅ Prüfe: Hostname `moodepi5.local`? → **RICHTIG**
4. ✅ Prüfe: Hostname `GhettoBlaster.local`? → **RICHTIG**

---

## 📝 BEI JEDEM SCRIPT:

**ALLE Scripts müssen:**
- `.101` explizit **AUSSCHLIESSEN**
- Oder als "fremder Router" markieren
- **NUR** die richtigen IPs verwenden

---

**Diese Erinnerung muss bei JEDEM IP-Check beachtet werden!**


# 🔍 PI LAN-VERBINDUNG

**Datum:** 2025-12-07  
**Status:** Pi mit LAN-Kabel zum Router verbunden

---

## 📋 NETZWERK-KONFIGURATION

- ✅ Pi mit LAN-Kabel zum Router verbunden
- ⏳ Warte auf IP-Adresse (DHCP)
- ⏳ Warte auf Boot-Abschluss

---

## 🔍 SUCHE NACH PI

### **Bekannte IPs:**
- `192.168.178.143` (erwartete IP)
- `192.168.178.142` (Repeater - nicht der Pi)

### **mDNS Hostnames:**
- `GhettoBlaster.local`
- `moode.local`
- `raspberrypi.local`

---

## ⏳ BOOT-PROZESS

Der Pi braucht normalerweise:
- **1-2 Minuten:** Boot + Netzwerk-Konfiguration
- **2-3 Minuten:** Services starten
- **3-5 Minuten:** Vollständig bereit

---

## 📋 PRÜF-SCHRITTE

### **1. Netzwerk-Scan:**
```bash
# Suche nach Pi im Netzwerk:
for ip in 192.168.178.{140..160}; do
  ping -c 1 -W 1 $ip >/dev/null 2>&1 && echo "✅ $ip erreichbar"
done
```

### **2. mDNS prüfen:**
```bash
ping -c 1 GhettoBlaster.local
ping -c 1 moode.local
```

### **3. Web-UI prüfen:**
- Öffne: `http://192.168.178.143`
- Oder: `http://GhettoBlaster.local`

---

## 🛠️ BEI PROBLEMEN

### **Pi nicht erreichbar:**
- Warte 2-3 Minuten (Boot + DHCP)
- Prüfe LAN-Kabel
- Prüfe Router (vergeben IPs?)
- Prüfe Display (zeigt Boot-Log?)

### **DHCP funktioniert nicht:**
- Router prüfen
- LAN-Kabel prüfen
- Pi-Netzwerk-LED prüfen

---

**Status:** ⏳ WARTE AUF PI BOOT + DHCP  
**Nächster Schritt:** Erneut prüfen in 1-2 Minuten


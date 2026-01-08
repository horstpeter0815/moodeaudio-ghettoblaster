# 🔍 PI NETZWERK-DIAGNOSE

**Problem:** Pi ist nicht erreichbar (192.168.178.143)

---

## 🔍 MÖGLICHE URSACHEN

### **1. Falsche IP-Adresse**
- Pi hat neue IP bekommen (DHCP)
- Pi ist in anderem Netzwerk

### **2. Netzwerk-Problem**
- Pi nicht mit Netzwerk verbunden
- Falsches Netzwerk (WLAN vs. Ethernet)
- Router-Problem

### **3. Pi-Problem**
- Pi läuft nicht
- Pi hat Netzwerk-Problem
- SSH deaktiviert

---

## 🔧 LÖSUNGEN

### **Option 1: Pi IP finden**

```bash
# Netzwerk scannen
nmap -sn 192.168.178.0/24

# Oder mit arp
arp -a | grep -i raspberry

# Oder Hostname versuchen
ping GhettoBlaster.local
```

### **Option 2: Pi physisch prüfen**

1. **LED prüfen:**
   - Rote LED = Strom OK
   - Grüne LED = Aktivität

2. **Netzwerk-Kabel prüfen:**
   - Ethernet-Kabel verbunden?
   - WLAN aktiviert?

3. **Display prüfen:**
   - Zeigt der Pi etwas an?
   - Boot-Meldungen sichtbar?

### **Option 3: Pi direkt verbinden**

**Serial Console:**
- USB-zu-Serial Adapter
- Direkter Zugriff ohne Netzwerk

**HDMI:**
- Monitor anschließen
- Tastatur anschließen
- Direkt am Pi arbeiten

---

## 📋 CHECKLISTE

- [ ] Netzwerk-Scan durchgeführt
- [ ] Alternative IPs geprüft
- [ ] Hostname geprüft (GhettoBlaster.local)
- [ ] ARP-Tabelle geprüft
- [ ] Pi physisch geprüft (LEDs, Kabel)
- [ ] Display angeschlossen (falls verfügbar)

---

## 🎯 NÄCHSTE SCHRITTE

1. **Netzwerk-Scan durchführen** um Pi zu finden
2. **Pi physisch prüfen** (LEDs, Kabel)
3. **Alternative Verbindungsmethoden** nutzen (Serial, HDMI)
4. **Falls Pi gefunden:** Neue IP notieren und Fix-Script anpassen

---

**Status:** 🔍 DIAGNOSE LÄUFT


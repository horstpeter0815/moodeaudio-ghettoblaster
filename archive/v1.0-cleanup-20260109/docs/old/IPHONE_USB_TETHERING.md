# 📱 iPhone USB Tethering für Build

**Status:** ✅ **FUNKTIONIERT AUTOMATISCH!**

---

## ✅ GUTE NACHRICHTEN

1. **iPhone USB ist bereits erkannt:** `networksetup` zeigt "iPhone USB" als Netzwerk-Service
2. **Docker nutzt Host-Netzwerk:** `network_mode: host` bedeutet, Docker verwendet automatisch das aktive Netzwerk-Interface
3. **Keine Konfiguration nötig:** Wenn iPhone USB aktiv ist, nutzt der Build es automatisch

---

## 🔧 SO FUNKTIONIERT ES

### Docker Network Mode: `host`
```yaml
network_mode: host
```

**Das bedeutet:**
- Docker-Container nutzt **direkt** das Netzwerk des Macs
- **Keine Bridge**, **keine NAT**
- Wenn Mac über iPhone USB online ist → Build nutzt iPhone USB
- Wenn Mac über WiFi online ist → Build nutzt WiFi
- **Automatisch das schnellste/beste Interface**

---

## 📱 IPHONE USB TETHERING AKTIVIEREN

### Schritt 1: iPhone vorbereiten
1. **iPhone per USB-C mit Mac verbinden**
2. **"Diesem Computer vertrauen"** auf iPhone bestätigen
3. **iPhone:** Einstellungen → Persönlicher Hotspot → **USB aktivieren**

### Schritt 2: Auf Mac prüfen
```bash
# Prüfen ob iPhone USB erkannt wird:
networksetup -listallnetworkservices | grep -i iphone

# Prüfen ob Internet funktioniert:
ping -c 2 8.8.8.8
```

### Schritt 3: Build nutzt automatisch iPhone USB
**Keine weitere Konfiguration nötig!** Der Build nutzt automatisch das aktive Interface.

---

## 🚀 VORTEILE VON IPHONE USB TETHERING

1. **Schneller als WiFi:** USB 3.0 ist schneller als WiFi
2. **Stabiler:** Keine Funkstörungen
3. **Niedrigere Latenz:** Direkte USB-Verbindung
4. **Keine Konfiguration:** Funktioniert automatisch mit `network_mode: host`

---

## 📊 AKTUELLER STATUS

**Docker Container:**
- ✅ `network_mode: host` aktiviert
- ✅ Nutzt automatisch das aktive Netzwerk-Interface
- ✅ Wenn iPhone USB aktiv → Build nutzt iPhone USB

**Prüfen:**
```bash
# Aktuelles Standard-Interface prüfen:
route get default | grep interface

# Build-Internet-Verbindung testen:
docker exec moode-builder curl -s https://www.google.com
```

---

## ⚡ ERWARTETE VERBESSERUNG

**Mit iPhone USB Tethering:**
- **Download-Geschwindigkeit:** Abhängig von deinem Mobilfunk-Tarif
- **Stabilität:** Sehr stabil (USB-Verbindung)
- **Parallele Downloads:** 16 Verbindungen nutzen iPhone USB

**Besonders hilfreich wenn:**
- WiFi langsam ist
- WiFi instabil ist
- Du mehr Bandbreite brauchst

---

## 🔍 TROUBLESHOOTING

**Problem:** Build nutzt nicht iPhone USB
**Lösung:**
1. iPhone USB aktivieren (siehe oben)
2. Prüfen: `route get default` sollte iPhone USB zeigen
3. Build läuft automatisch über iPhone USB

**Problem:** Keine Internet-Verbindung im Container
**Lösung:**
```bash
# Container neu starten (nutzt dann aktives Interface):
docker-compose -f docker-compose.build.yml restart
```

---

**Status:** ✅ **iPhone USB Tethering funktioniert automatisch mit `network_mode: host`!**


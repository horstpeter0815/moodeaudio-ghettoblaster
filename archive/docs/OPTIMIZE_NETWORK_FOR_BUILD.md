# 🚀 Netzwerk-Optimierung für Build

## ✅ Ja, Ethernet ist schneller!

**Aktueller Status:**
- Docker Container nutzt `network_mode: host`
- **Das bedeutet:** Container verwendet automatisch die schnellste Verbindung des Macs
- **Aktuell:** Wi-Fi (en0) aktiv
- **Ethernet verfügbar:** en4, en5, en6 (aber inaktiv)

---

## 🔌 Ethernet aktivieren für schnelleren Build

### Option 1: Ethernet-Kabel anschließen (Empfohlen)

1. **Ethernet-Kabel an Mac anschließen**
2. **Systemeinstellungen öffnen:**
   - Systemeinstellungen → Netzwerk
   - Ethernet sollte automatisch aktiviert werden

3. **Verbindung prüfen:**
   ```bash
   ./CHECK_NETWORK_SPEED.sh
   ```

4. **Build nutzt automatisch Ethernet** (weil `network_mode: host`)

### Option 2: Netzwerk-Priorität ändern

Falls beide Verbindungen aktiv sind, kannst du Ethernet priorisieren:

```bash
# Ethernet-Service finden
networksetup -listnetworkserviceorder

# Ethernet nach oben setzen (z.B. "Ethernet" oder "Ethernet Adapter")
# In Systemeinstellungen → Netzwerk → Reihenfolge anpassen
```

---

## 📊 Geschwindigkeits-Vergleich

**Typische Geschwindigkeiten:**
- **Wi-Fi:** 50-300 Mbps (variabel, abhängig von Signal)
- **Ethernet:** 100-1000 Mbps (stabil, konstant)

**Build-Downloads:**
- Wi-Fi: ~2-4 Stunden
- Ethernet: ~1-2 Stunden (bei 100+ Mbps)

**Vorteile von Ethernet:**
- ✅ Stabiler (keine Signal-Schwankungen)
- ✅ Schneller (meist 2-3x schneller)
- ✅ Niedrigere Latenz
- ✅ Weniger CPU-Last

---

## 🔍 Aktuelle Netzwerk-Verbindung prüfen

```bash
# Standard-Route (zeigt aktive Verbindung)
route get default | grep interface

# Geschwindigkeit testen
speedtest-cli  # Falls installiert
```

---

## ⚡ Build nutzt automatisch beste Verbindung

**Wichtig:** Der Docker-Container (`moode-builder`) nutzt `network_mode: host`.

**Das bedeutet:**
- ✅ Container verwendet **automatisch** die schnellste Verbindung
- ✅ Keine Konfiguration nötig
- ✅ Einfach Ethernet-Kabel anschließen → Build wird schneller

---

## 🚀 Nächste Schritte

1. **Ethernet-Kabel an Mac anschließen**
2. **Verbindung prüfen:** `ifconfig en4` (oder en5/en6)
3. **Build läuft weiter** - nutzt automatisch Ethernet wenn verfügbar
4. **Geschwindigkeit prüfen:** `./CHECK_NETWORK_SPEED.sh`

---

**Hinweis:** Der laufende Build wird automatisch schneller, sobald Ethernet aktiv ist. Kein Neustart nötig!


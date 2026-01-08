# 🔌 USB-Ethernet Adapter Setup

## ✅ Status

**USB-Ethernet Adapter erkannt:**
- **Gerät:** AX88179A (en8)
- **Status:** ✅ Aktiv
- **IP:** 192.168.2.1
- **Geschwindigkeit:** 100baseTX (100 Mbps)

## ⚠️ Problem

Der USB-Ethernet-Adapter ist aktiv, aber:
- Auf **anderem Netzwerk** (192.168.2.1) als Wi-Fi (192.168.178.24)
- **Standard-Route** nutzt noch Wi-Fi (en0)
- Build nutzt daher noch Wi-Fi

## 🔧 Lösung: Ethernet für Internet konfigurieren

### Option 1: DHCP aktivieren (Empfohlen)

1. **Systemeinstellungen öffnen:**
   - Systemeinstellungen → Netzwerk
   - "AX88179A" auswählen

2. **Konfiguration:**
   - **Konfiguration:** "DHCP verwenden" wählen
   - **Router anschließen:** USB-Ethernet-Kabel an Router (nicht direkt an Pi)

3. **Prüfen:**
   ```bash
   ./CHECK_NETWORK_SPEED.sh
   ```

### Option 2: Netzwerk-Priorität ändern

Falls beide Verbindungen aktiv sind:

1. **Systemeinstellungen → Netzwerk**
2. **Reihenfolge anpassen:**
   - "AX88179A" nach oben ziehen
   - Oder: Wi-Fi deaktivieren während Build läuft

### Option 3: Manuelle IP-Konfiguration

Falls DHCP nicht funktioniert:

```bash
# IP-Adresse setzen (im gleichen Netzwerk wie Router)
sudo networksetup -setmanual "AX88179A" 192.168.178.25 255.255.255.0 192.168.178.1
```

---

## 🚀 Build nutzt automatisch beste Verbindung

**Wichtig:** Docker Container nutzt `network_mode: host`

**Das bedeutet:**
- ✅ Container verwendet **automatisch** die Verbindung mit Internet-Zugang
- ✅ Wenn Ethernet Internet hat → Build nutzt Ethernet
- ✅ Wenn nur Wi-Fi Internet hat → Build nutzt Wi-Fi

**Aktuell:** Wi-Fi hat Internet → Build nutzt Wi-Fi

**Nach Konfiguration:** Ethernet hat Internet → Build nutzt Ethernet (schneller!)

---

## 📊 Geschwindigkeits-Vergleich

**USB-Ethernet (100 Mbps):**
- ✅ Stabiler als Wi-Fi
- ✅ Niedrigere Latenz
- ✅ Weniger CPU-Last
- ⚠️ 100 Mbps (nicht Gigabit, aber ausreichend)

**Wi-Fi (aktuell):**
- ⚠️ Variabel (50-300 Mbps)
- ⚠️ Signal-Schwankungen möglich

---

## 🔍 Aktueller Status prüfen

```bash
./CHECK_NETWORK_SPEED.sh
```

**Erwartetes Ergebnis nach Konfiguration:**
- ✅ Ethernet (en8) als Standard-Route
- ✅ IP im gleichen Netzwerk wie Router (192.168.178.x)
- ✅ Internet-Zugang über Ethernet

---

## 💡 Empfehlung

**Für schnellsten Build:**
1. USB-Ethernet-Kabel an **Router** anschließen (nicht direkt an Pi)
2. DHCP aktivieren in Systemeinstellungen
3. Build nutzt automatisch Ethernet

**Alternative:**
- Wi-Fi während Build deaktivieren
- Dann nutzt System automatisch Ethernet


# 🔌 Ethernet-Status

## ⚠️ Aktueller Status:

**Ethernet-Adapter:** AX88179A (en8)
- ✅ **Aktiv** (Kabel angeschlossen)
- ❌ **DHCP nicht aktiv** (noch manuelle IP: 192.168.2.1)
- ❌ **Nicht als Standard-Route** (Wi-Fi wird genutzt)

**Problem:**
- Ethernet hat manuelle IP ohne Router
- Build nutzt daher noch Wi-Fi (langsamer)

---

## 🔧 Lösung: DHCP aktivieren

### Schritt-für-Schritt:

1. **Systemeinstellungen öffnen:**
   - Apple-Menü → Systemeinstellungen
   - Oder: `open "x-apple.systempreferences:com.apple.preference.network"`

2. **Netzwerk auswählen:**
   - Links: "Netzwerk" klicken

3. **AX88179A auswählen:**
   - Links: "AX88179A" (USB-Ethernet) auswählen

4. **DHCP aktivieren:**
   - Rechts oben: "Konfiguration" Dropdown
   - **"DHCP verwenden"** auswählen

5. **Fertig!**
   - Monitor erkennt es automatisch
   - Build nutzt dann Ethernet (schneller!)

---

## 📊 Nach DHCP-Aktivierung:

**Erwartetes Ergebnis:**
- ✅ Ethernet erhält IP vom Router (z.B. 192.168.178.x)
- ✅ Ethernet wird Standard-Route
- ✅ Build nutzt automatisch Ethernet
- ✅ **2-3x schnellerer Download**

---

## 🔍 Status prüfen:

```bash
./CHECK_NETWORK_SPEED.sh
```

**Oder manuell:**
```bash
# Prüfe IP
ifconfig en8 | grep "inet "

# Prüfe Standard-Route
route get default | grep interface
```

---

## ⚡ Schnell-Lösung:

**Script ausführen (öffnet Systemeinstellungen):**
```bash
./CONFIGURE_ETHERNET_AUTO.sh
```

Dann manuell DHCP aktivieren (siehe Schritte oben).

---

**Monitor läuft wieder - erkennt automatisch wenn DHCP aktiv ist!** 🔄


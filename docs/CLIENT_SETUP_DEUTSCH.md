# WireGuard Client Setup - Deutsch

## Für: andre.vollmer.mail@gmail.com

Dein Peer wurde auf dem Server hinzugefügt! Hier ist alles was du brauchst.

---

## ✅ Server Status

- **Peer hinzugefügt:** ✅ Ja
- **Dein Public Key:** `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=`
- **Deine VPN IP:** `10.8.0.2/32`
- **Server Public IP:** `223.206.210.138`
- **Server Port:** `51820/UDP`

---

## WICHTIG: Du brauchst deinen PRIVATE Key!

Du hast deinen **Public Key** geschickt (das war richtig für den Server).

Aber für die Client-Konfiguration brauchst du deinen **PRIVATE Key** - den hast du beim Generieren erstellt.

### Hast du deinen Private Key noch?

Wenn du beim Generieren `wg genkey` verwendet hast, wurde der Private Key ausgegeben. Hast du ihn gespeichert?

**Falls JA:** Verwende diesen Private Key in der Konfiguration unten.

**Falls NEIN:** Generiere neue Keys (siehe unten).

---

## Schritt 1: WireGuard auf Mac installieren

### Option A: Mac App Store (Einfachste)
1. Mac App Store öffnen
2. Nach "WireGuard" suchen
3. "Installieren" klicken
4. WireGuard öffnen

### Option B: Homebrew
```bash
brew install --cask wireguard
```

---

## Schritt 2: Private Key prüfen oder neu generieren

### Falls du deinen Private Key noch hast:
Verwende diesen in der Konfiguration.

### Falls du den Private Key verloren hast:
Generiere neue Keys:

```bash
# Neue Keys generieren
wg genkey | tee ~/wireguard-private.key | wg pubkey > ~/wireguard-public.key

# Private Key anzeigen (WICHTIG: Speichern!)
cat ~/wireguard-private.key

# Public Key anzeigen (diesen an den Server-Admin schicken)
cat ~/wireguard-public.key
```

**WICHTIG:** Wenn du neue Keys generierst, muss der neue Public Key auf dem Server aktualisiert werden!

---

## Schritt 3: Client-Konfiguration erstellen

Erstelle eine Datei `moode-pi.conf` mit diesem Inhalt:

```ini
[Interface]
PrivateKey = DEIN_PRIVATE_KEY_HIER
Address = 10.8.0.2/24

[Peer]
PublicKey = MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=
Endpoint = 223.206.210.138:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```

**Wichtig:** Ersetze `DEIN_PRIVATE_KEY_HIER` mit deinem tatsächlichen Private Key.

---

## Schritt 4: Konfiguration in WireGuard importieren

### Mit WireGuard GUI:
1. WireGuard öffnen
2. "+" Button klicken (unten links) oder "Add Tunnel"
3. "Import from file" oder "Create from file" wählen
4. Deine `moode-pi.conf` Datei auswählen
5. Namen vergeben (z.B. "MoodePi5")
6. "Save" klicken

---

## Schritt 5: Verbinden

1. In WireGuard GUI den Schalter neben "MoodePi5" aktivieren
2. Status sollte "Active" (grün) zeigen
3. Du bist verbunden! 🎉

---

## Schritt 6: Verbindung testen

### VPN testen:
```bash
# Server anpingen
ping 10.8.0.1

# Sollte Antworten zeigen:
# PING 10.8.0.1 (10.8.0.1): 56 data bytes
# 64 bytes from 10.8.0.1: icmp_seq=0 ttl=64 time=XX ms
```

### Web-Interface testen:
Browser öffnen: `http://10.8.0.1/`

### SSH testen:
```bash
ssh andre@10.8.0.1
# Passwort: 0815
```

---

## Schnellreferenz

| Item | Wert |
|------|------|
| Server Public IP | `223.206.210.138` |
| Server VPN IP | `10.8.0.1` |
| Deine VPN IP | `10.8.0.2` |
| WireGuard Port | `51820/UDP` |
| Server Public Key | `MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=` |
| Dein Public Key | `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=` |
| SSH User | `andre` |
| SSH Passwort | `0815` |

---

## Dein Projekt: Touchscreen Driver Fix

Du möchtest folgendes Problem lösen:
> "Der Waveshare Touchscreen-Treiber initialisiert vor dem Display-Panel, was I2C-Konflikte und instabiles Verhalten beim Boot verursacht."

### Relevante Dateien:
- `/boot/firmware/config.txt` - Device Tree Overlays
- `/etc/modules-load.d/` - Modul-Ladereihenfolge
- `/etc/systemd/system/` - Service-Abhängigkeiten
- Device Tree Overlays: `custom-components/overlays/`
- I2C Stabilisierung: `custom-components/scripts/i2c-stabilize.sh`

### Nützliche Befehle:
```bash
# I2C Geräte prüfen
i2cdetect -y 1

# Modul-Ladereihenfolge prüfen
ls -la /etc/modules-load.d/

# Systemd Services prüfen
systemctl list-units | grep -i touch
systemctl list-units | grep -i display

# Boot-Logs prüfen
journalctl -b | grep -i "ft6236\|touch\|display\|i2c"
```

Siehe auch: `docs/TOUCHSCREEN_DRIVER_FIX_GUIDE.md` (auf Englisch, aber mit allen technischen Details)

---

## Hilfe bei Problemen

### Kann nicht verbinden
- Prüfe WireGuard zeigt "Active" (grün)
- Prüfe dein Private Key ist korrekt
- Prüfe Firewall erlaubt UDP Port 51820
- Versuche anderes Netzwerk (manche blockieren VPNs)

### Verbunden aber kein Zugriff
- Prüfe: `ping 10.8.0.1` funktioniert
- Prüfe Web-Interface: `http://10.8.0.1/`
- Versuche SSH: `ssh andre@10.8.0.1`

### Verbindung bricht ab
- Stelle sicher `PersistentKeepalive = 25` ist in der Config
- Prüfe Internet-Verbindung
- Aktualisiere WireGuard auf neueste Version

---

*Setup Datum: 2026-01-14*  
*Server: MoodePi5 (192.168.2.3 / 223.206.210.138)*

# Raspberry Pi OS Installation Guide

## Schritt 1: RaspiOS auf SD-Karte installieren

### Option A: Mit Raspberry Pi Imager (empfohlen)

```bash
# Installiere Raspberry Pi Imager
brew install raspberry-pi-imager

# Starte Imager
raspberry-pi-imager
```

Dann:
1. Wähle "Raspberry Pi OS (other)" → "Raspberry Pi OS Lite (64-bit)"
2. Wähle deine SD-Karte
3. Klicke auf "Write"

### Option B: Manuell mit Script

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./INSTALL_RASPIOS.sh
```

**WICHTIG:** Das Script löscht alle Daten auf der SD-Karte!

## Schritt 2: SSH aktivieren

Nach dem Schreiben der SD-Karte:

1. Mounte die SD-Karte (bootfs Partition)
2. Erstelle eine leere Datei `ssh` im bootfs Verzeichnis:
   ```bash
   touch /Volumes/bootfs/ssh
   ```
3. Erstelle `wpa_supplicant.conf` für WiFi (optional):
   ```bash
   cat > /Volumes/bootfs/wpa_supplicant.conf << 'EOF'
   country=DE
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1

   network={
       ssid="Martin Router King"
       psk="DEIN_WIFI_PASSWORT"
   }
   EOF
   ```

## Schritt 3: Pi booten und Tools installieren

1. SD-Karte in Pi einstecken
2. Pi booten
3. SSH zum Pi:
   ```bash
   ssh pi@raspberrypi.local
   # Default password: raspberry
   ```

4. Tools installieren:
   ```bash
   # Kopiere das Script auf den Pi
   scp INSTALL_REST_TOOLS.sh pi@raspberrypi.local:~/
   
   # Oder lade es direkt herunter und führe aus
   curl -sSL https://raw.githubusercontent.com/.../INSTALL_REST_TOOLS.sh | bash
   ```

## Schritt 4: REST API Tools verifizieren

```bash
# Auf dem Pi ausführen:
~/test_rest_api.sh
```

## Installierte Tools

- **curl, wget** - HTTP Clients
- **python3, pip3** - Python mit pip
- **requests, flask, fastapi** - Python REST Libraries
- **Node.js, npm** - JavaScript Runtime
- **httpie** - REST Client (CLI)
- **jq** - JSON Processor
- **sqlite3, mysql-client, postgresql-client** - Database Clients
- **redis-tools** - Redis Client
- **mosquitto-clients** - MQTT Client

## Moode Audio REST API

Moode Audio bietet ein REST API auf Port 81:
- API Endpoint: `http://localhost:81/api/`
- Dokumentation: `http://localhost:81/api/help`

### Beispiel API Calls:

```bash
# System Info
curl http://localhost:81/api/system

# Player Status
curl http://localhost:81/api/player

# Library Info
curl http://localhost:81/api/library
```

## Nächste Schritte

1. Installiere Moode Audio auf dem Pi (falls noch nicht geschehen)
2. Teste die REST API Tools
3. Entwickle deine REST Integration


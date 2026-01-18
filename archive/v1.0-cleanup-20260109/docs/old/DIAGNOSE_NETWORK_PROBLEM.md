# Netzwerk-Problem Diagnose

## Was funktionierte gestern:
- Mac: 192.168.10.1 (USB Ethernet en8)
- Pi: 192.168.10.2 (statische IP)
- Direkte Verbindung, kein Internet Sharing

## Mögliche Probleme:

### 1. Mac-Seite:
- USB Ethernet Interface (en8) muss aktiv sein
- IP muss 192.168.10.1 sein
- Interface muss "UP" sein

### 2. Pi-Seite:
- Ethernet.nmconnection muss korrekt sein
- Statische IP: 192.168.10.2
- Gateway: 192.168.10.1
- NetworkManager muss die Config laden

### 3. Hardware:
- USB Ethernet Kabel verbunden?
- Kabel funktioniert?
- Pi erkennt eth0?

### 4. Timing:
- Pi bootet noch?
- NetworkManager startet spät?
- Config wird nicht geladen?

## Lösungsschritte:

1. Mac prüfen: `ifconfig en8` - muss 192.168.10.1 zeigen
2. Mac Interface aktivieren: `sudo ifconfig en8 up`
3. Pi Config prüfen: Statische IP korrekt?
4. Pi neu starten nach Config-Änderung
5. Warten bis Boot komplett fertig (30-60 Sekunden)


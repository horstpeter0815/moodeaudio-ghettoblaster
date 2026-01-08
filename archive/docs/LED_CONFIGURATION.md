# Raspberry Pi LED Konfiguration

## Ziel
- **Status-LED**: Rot → Grün ändern
- **LED-Modus**: Heartbeat (blinkt im Takt der CPU-Aktivität)

## Methode 1: Über config.txt (permanent)

Füge folgende Zeilen zur `/boot/firmware/config.txt` hinzu (oder `/boot/config.txt` je nach System):

```
# Status LED auf grün und heartbeat setzen
dtparam=act_led_trigger=heartbeat
dtparam=act_led_activelow=off
```

**Hinweis**: Bei HiFiBerryOS könnte der Pfad `/boot/config.txt` sein.

## Methode 2: Über sysfs (temporär, bis zum nächsten Reboot)

```bash
# LED auf heartbeat setzen
echo heartbeat | sudo tee /sys/class/leds/led0/trigger

# LED auf grün ändern (falls unterstützt)
# Für Pi 4: Die rote LED ist normalerweise die Power-LED
# Die grüne LED ist die Activity-LED
```

## Methode 3: Permanente sysfs-Konfiguration

Erstelle eine systemd-Service-Datei oder füge es zu `/etc/rc.local` hinzu:

```bash
# In /etc/rc.local vor "exit 0":
echo heartbeat > /sys/class/leds/led0/trigger
```

## Raspberry Pi 4 spezifisch

Auf dem Pi 4:
- **Rote LED**: Power-LED (kann nicht geändert werden)
- **Grüne LED**: Activity-LED (kann konfiguriert werden)

Die Activity-LED (grün) kann auf heartbeat gesetzt werden.

## Testen

Nach dem Ändern der `config.txt`:
```bash
sudo reboot
```

Nach dem Booten prüfen:
```bash
cat /sys/class/leds/led0/trigger
# Sollte "heartbeat" anzeigen
```

## Verfügbare Trigger-Modi

- `heartbeat` - Blinkt im Takt der CPU-Aktivität
- `mmc0` - Blinkt bei SD-Karten-Aktivität
- `timer` - Blinkt in regelmäßigen Abständen
- `none` - LED aus
- `default-on` - LED dauerhaft an


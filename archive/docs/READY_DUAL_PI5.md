# Bereit für Dual Raspberry Pi 5 Test

## Setup-Zusammenfassung

- **2x Raspberry Pi 5** - identisch
- **2x Moode Audio** - frisch installiert, identisch
- **2x Waveshare 7.9" DSI LCD** - identisch
- **DSI Port:** DSI0 (Primary DSI) ✅
- **DIP Switches:** I2C0 ✅
- **GPIO:** 5V und GND verbunden
- **Power:** 27W für beide

## Wichtige Klärung

**DSI0 ist der richtige Port!**
- Primary DSI Port
- Standard für DSI-Displays
- Config: `dsi0` Parameter

**I2C0 passt zu DSI0:**
- DIP Switches auf I2C0
- Config: `i2c0` Parameter

## Erstellte Dateien

1. **DSI_PORT_CLARIFICATION.md** - DSI Port Erklärung
2. **DUAL_PI5_TEST_PLAN.md** - Detaillierter Test-Plan
3. **DUAL_PI5_SYNC_TEST.sh** - Synchroner Test-Script
4. **DSI0_CONFIG.txt** - Korrekte Config.txt für DSI0/I2C0

## Nächste Schritte

1. **Beide Pi 5 booten lassen**
2. **IP-Adressen herausfinden:**
   ```bash
   # Beispiel:
   export PI5_1_IP=192.168.178.123
   export PI5_2_IP=192.168.178.124
   ```

3. **Synchroner Test ausführen:**
   ```bash
   ./DUAL_PI5_SYNC_TEST.sh
   ```

4. **Config.txt auf beiden anpassen:**
   - Siehe `DSI0_CONFIG.txt`
   - **WICHTIG:** `dsi0` und `i2c0` verwenden!

5. **Beide gleichzeitig rebooten**

6. **Ergebnisse vergleichen**

## Erwartetes Ergebnis

**Wenn beide identisch:**
- ✅ Gleiche I2C-Ergebnisse (0x45 Panel, 0x14 Touch)
- ✅ Gleiche Framebuffer-Größe
- ✅ Gleiche dmesg-Ausgaben
- ✅ Beide Displays funktionieren

**Wenn unterschiedlich:**
- ❌ Hardware-Defekt möglich
- ❌ Weitere Diagnose nötig

---

**Bereit für synchronen Dual-Pi5-Test mit DSI0/I2C0!**


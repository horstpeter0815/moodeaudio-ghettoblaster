# DSI Port Klärung - Raspberry Pi 5

## DSI Ports auf Raspberry Pi 5

**DSI0 (Primary DSI):**
- Haupt-DSI-Port
- Standard für DSI-Displays
- **Das ist der richtige Port für Waveshare Display!**

**DSI1 (Secondary DSI):**
- Sekundärer DSI-Port
- Wird selten verwendet
- Meist für spezielle Anwendungen

## Für Waveshare 7.9" DSI LCD

✅ **DSI0 ist der richtige Port!**
- Display an DSI0 anschließen
- Config: `dsi0` Parameter im Overlay
- DIP Switches: I2C0 (passt zu DSI0)

## Config.txt Parameter

```ini
# Für DSI0:
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0

# NICHT dsi1 verwenden!
```

---

**Antwort: DSI0 ist der richtige Port für das Waveshare Display!**


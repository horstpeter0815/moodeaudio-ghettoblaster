# Funktionierende Pi 5 Config wiederhergestellt

## Durchgeführte Aktionen

1. ✅ Peppy-Config gesichert als `config.txt.peppy_backup`
2. ✅ Funktionierende Config wiederhergestellt
3. ✅ Config basiert auf:
   - PI4_VS_PI5_CONFIG_DIFFERENCES.md (vc4-kms-v3d-pi5 für Pi 5)
   - EXACT_WAVESHARE_CONFIG.md (Waveshare Wiki)
   - DSI0/I2C0 für Pi 5

## Wiederhergestellte Config

**Wichtigste Parameter:**
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 spezifisch!)
- `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0`
- `disable_fw_kms_setup=0` (aktiviert)
- `fbcon=map=1` (Framebuffer aktiviert)

## Nächste Schritte

1. **Reboot durchführen**
2. **Prüfen ob Display funktioniert**
3. **Prüfen ob Touchscreen funktioniert**
4. **Auf zweiten Pi 5 warten und identisch konfigurieren**

---

**Status:** Funktionierende Config wiederhergestellt. **REBOOT ERFORDERLICH!**


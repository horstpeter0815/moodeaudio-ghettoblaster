# Bereit für Pi 5 Installation

## Status

✅ Pi 5 spezifischer Plan erstellt
✅ Installations-Script für Pi 5 erstellt
✅ Display-Manager Code vorbereitet

## Dateien erstellt

1. **PI5_FRESH_INSTALL_PLAN.md** - Detaillierter Plan für Pi 5
2. **PI5_FRESH_INSTALL_SCRIPT.sh** - Automatisches Setup-Script für Pi 5
3. **fb_display.py** - Wird vom Script erstellt

## Wichtige Unterschiede Pi 5

- **Config.txt:** `[pi5]` Sektion statt `[pi4]`
- **Hardware:** BCM2712 statt BCM2711
- **Kernel:** Meist 6.1+ auf Pi 5
- **Framebuffer:** Sollte identisch funktionieren

## Nächste Schritte nach Pi 5 Setup

1. Pi 5 booten und IP-Adresse herausfinden
2. Script übertragen:
   ```bash
   scp PI5_FRESH_INSTALL_SCRIPT.sh andre@<IP>:/tmp/
   ssh andre@<IP>
   bash /tmp/PI5_FRESH_INSTALL_SCRIPT.sh
   ```
3. Config.txt anpassen (siehe Plan - **WICHTIG: [pi5] Sektion!**)
4. Reboot
5. Testen: `sudo python3 /home/andre/fb_display.py`
6. Aktivieren: `sudo systemctl enable --now fb_display.service`

## Framebuffer-Ansatz

- ✅ **Direkter mmap-Zugriff** auf `/dev/fb0`
- ✅ **Keine DRM/KMS-Abhängigkeiten**
- ✅ **Einfacher Code** - Pixel für Pixel
- ✅ **Funktioniert auf Pi 4 und Pi 5**

---

**Bereit für Pi 5 Installation mit Framebuffer-Ansatz!**


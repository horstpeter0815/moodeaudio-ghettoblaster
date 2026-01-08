# SCHNELLER FIX - Pi 5 Landscape

**Problem:** Display abgeschnitten, muss Landscape sein, flackert manchmal

---

## ✅ SCHNELLE LÖSUNG

**Diese 4 Befehle auf Pi 5 ausführen:**

```bash
# 1. Alte Einstellungen entfernen
sudo sed -i '/^display_rotate=/d' /boot/config.txt
sudo sed -i '/^hdmi_group=/d' /boot/config.txt

# 2. Neue Einstellungen hinzufügen (wie HiFiBerry Pi 4)
echo "display_rotate=3" | sudo tee -a /boot/config.txt
echo "hdmi_group=0" | sudo tee -a /boot/config.txt

# 3. Display Service neu starten
sudo systemctl restart localdisplay
```

**Fertig!** Display sollte jetzt vollständiges Landscape zeigen.

---

## 🔍 WAS DAS MACHT

- **display_rotate=3**: Dreht Portrait 270° zu Landscape
- **hdmi_group=0**: Standard HDMI (wie funktionierender Pi 4)
- **Ergebnis**: Vollständiges Landscape (1280x400), kein Cutoff, weniger Flackern

---

**Status:** Lösung bereit, auf Pi 5 ausführen!


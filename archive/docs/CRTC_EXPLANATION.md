# CRTC Explained - Was ist CRTC?

**User-Frage:** Was ist CRTC und warum braucht ein Display einen CRTC?

---

## 🎯 Was ist CRTC?

**CRTC = Cathode Ray Tube Controller**

Aber heute: **CRTC = Display Controller** (für alle Display-Typen, nicht nur CRT!)

### Funktionen eines CRTC:

1. **Display Timing generieren**
   - Horizontale/Vertikale Sync-Signale
   - Pixel Clock
   - Blanking-Perioden

2. **Scanout (Bildausgabe)**
   - Liest Pixel-Daten aus Framebuffer
   - Sendet sie an Display-Encoder
   - Steuert Zeilen- und Frame-Ausgabe

3. **Display Mode Management**
   - Aktiviert/Deaktiviert Display-Modes
   - Ändert Auflösung
   - Ändert Refresh-Rate

---

## 🔗 DRM Pipeline

**DRM (Direct Rendering Manager) Pipeline:**

```
Framebuffer → CRTC → Encoder → Connector → Display
```

### Komponenten:

1. **Framebuffer:**
   - Speicher-Bereich mit Pixel-Daten
   - Mehrere Framebuffer möglich (Double/Triple Buffering)

2. **CRTC (Controller):**
   - **Liest** Pixel aus Framebuffer
   - **Generiert** Display-Timing-Signale
   - **Steuert** Scanout-Prozess

3. **Encoder:**
   - **Konvertiert** digitale Signale für Display-Interface
   - DSI-Encoder, HDMI-Encoder, etc.

4. **Connector:**
   - **Physische** Display-Verbindung
   - DSI-1, HDMI-A-1, etc.
   - Erkennt ob Display "connected" ist

---

## ❌ Warum braucht ein Display einen CRTC?

**Ohne CRTC:**
- Display ist erkannt (connected) ✅
- Display-Mode ist bekannt ✅
- **ABER:** Kein Scanout-Prozess! ❌
- **Ergebnis:** Display bleibt **disabled** → kein Bild!

**Mit CRTC:**
- CRTC liest Pixel aus Framebuffer ✅
- CRTC generiert Timing-Signale ✅
- CRTC sendet Daten an Encoder ✅
- **Ergebnis:** Display ist **enabled** → Bild wird angezeigt! ✅

---

## 🐛 Unser Problem: `possible_crtcs=0x0`

**Fehlermeldung:**
```
Bogus possible_crtcs: [ENCODER:32:DSI-32] possible_crtcs=0x0 (full crtc mask=0x0)
```

**Bedeutung:**
- Encoder `DSI-32` existiert ✅
- Connector `DSI-1` ist connected ✅
- **ABER:** `possible_crtcs=0x0` = **Kein CRTC verfügbar!** ❌

**Warum?**
- FKMS hat **keinen CRTC erstellt** für DSI-1
- Oder CRTC wurde erstellt, aber **nicht mit Encoder verknüpft**
- Encoder kann **keinen CRTC zugewiesen** bekommen

---

## 🔍 Wie werden CRTCs erstellt? (FKMS)

**In `vc4_firmware_kms.c`:**

1. **FKMS fragt Firmware** nach Displays
2. **Firmware meldet** verfügbare Displays (HDMI, DSI, etc.)
3. **FKMS erstellt CRTC** für jedes gemeldete Display
4. **FKMS verknüpft** Encoder mit CRTC

**Problem:**
- Wenn **Firmware DSI nicht meldet** → kein CRTC!
- Wenn **Firmware DSI falsch meldet** → falscher CRTC!
- Wenn **Overlay DSI falsch konfiguriert** → CRTC wird nicht verknüpft!

---

## 💡 Mögliche Lösungen

### Lösung 1: Firmware meldet DSI nicht
- Prüfe Firmware-Logs
- Prüfe ob DSI-Overlay korrekt geladen wird
- Prüfe Device Tree

### Lösung 2: FKMS erstellt keinen CRTC für DSI
- Prüfe `vc4_fkms_create_screen()` Funktion
- Prüfe warum DSI-CRTC nicht erstellt wird
- Möglicherweise Bug in FKMS DSI-Support

### Lösung 3: CRTC wird nicht mit Encoder verknüpft
- Prüfe `possible_crtcs` Zuweisung
- Prüfe Overlay-Konfiguration
- Möglicherweise falsche Encoder-CRTC-Verknüpfung

---

**Nächster Schritt:** Code analysieren um zu verstehen warum `possible_crtcs=0x0`!


# Alternative Display-Methoden ohne CRTC

## Status: CRTCs existieren, aber nicht zugewiesen

### Gefunden:
- **CRTCs vorhanden:** `crtc-0`, `crtc-1` (full crtc mask=0x3)
- **DSI-1:** connected, 2 Modi verfügbar (1280x400)
- **Problem:** `possible_crtcs=0x0` - kein CRTC dem DSI-Encoder zugewiesen

### Versuchte Methoden:

#### 1. modetest - Direkte CRTC-Zuweisung
```bash
modetest -M vc4 -s 33@0:1280x400  # Connector 33 (DSI-1) an CRTC 0
modetest -M vc4 -s 33@1:1280x400  # Connector 33 (DSI-1) an CRTC 1
```

#### 2. Framebuffer-Zugriff
- `/dev/fb0` existiert (1024x768) - aber nicht DSI
- `vc4drmfb` wurde erstellt, aber nicht für DSI

#### 3. X11 mit modesetting Driver
- X11 erkennt DSI-1
- Kann aber keinen CRTC finden: `xrandr: cannot find crtc for output DSI-1`

### Nächste Schritte:

1. **Manuelle CRTC-Zuweisung über debugfs** (falls möglich)
2. **Kernel-Patch:** FKMS so modifizieren, dass CRTC für DSI erstellt wird
3. **Firmware-Patch:** Firmware so modifizieren, dass DSI gemeldet wird
4. **Direkter DSI-Zugriff:** Umgehung von DRM/KMS komplett

---

**Hinweis:** Das Kernproblem ist, dass FKMS nur CRTCs für Displays erstellt, die die Firmware meldet. Die Firmware meldet DSI nicht, daher kein CRTC.


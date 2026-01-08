# Drei-Panel-Analyse - Systematische Untersuchung

**Datum:** 2025-11-25 22:45  
**Getestete Panels:** 3 verschiedene Waveshare DSI Displays

---

## Test-Ergebnisse: ALLE 3 PANELS GLEICH

### ✅ Was funktioniert (alle 3):
- **DSI-1:** `connected`, `1280x400`
- **Framebuffer:** `/dev/fb0` existiert
- **Panel-Device:** `1-0045` erkannt (I2C Bus 1)
- **vc4:** Initialisiert
- **I2C:** 0 Fehler (nach Hard Reset)

### ❌ Was NICHT funktioniert (alle 3):
- **DSI-1:** `disabled` (kein CRTC zugewiesen)
- **CRTC:** `possible_crtcs=0x0` (full crtc mask=0x1)
- **LED:** Blinkt (Panel wartet auf DSI-Daten)
- **Display:** Zeigt nichts

---

## Root Cause Analysis

### Problem identifiziert:

**CRTC-Zuweisungs-Problem:**
```
Bogus possible_crtcs: [ENCODER:32:DSI-32] possible_crtcs=0x0 (full crtc mask=0x1)
```

**Bedeutung:**
- `possible_crtcs=0x0`: DSI-Encoder hat KEINEN zugewiesenen CRTC
- `full crtc mask=0x1`: Es GIBT einen CRTC (bit 0 = CRTC 0)
- **Aber:** CRTC wird nicht dem DSI-Encoder zugewiesen!

**Warum:**
- fkms erstellt CRTCs, aber weist sie nicht richtig zu
- DSI-Encoder wird erkannt, aber nicht mit CRTC verbunden
- Ohne CRTC → keine Datenübertragung → Display bleibt `disabled`

---

## Vergleich: fkms vs. echtes KMS

### fkms (aktuell):
- ✅ DSI-1 erkannt
- ✅ Framebuffer erstellt
- ❌ CRTC nicht zugewiesen
- ❌ DSI-1 bleibt `disabled`

### Echtes KMS (getestet):
- ❌ DSI-1 wird NICHT erkannt (nur card0)
- ❌ Kein Framebuffer
- ❌ Panel-Device nicht erkannt

**Erkenntnis:** fkms ist näher dran, aber CRTC-Zuweisung fehlt!

---

## Lösungsansätze

### Option 1: CRTC manuell zuweisen (via sysfs/kernel)

**Versuch:**
- CRTC explizit dem DSI-Encoder zuweisen
- Via `/sys/class/drm/` Interface

**Problem:** Keine direkte sysfs-Schnittstelle für CRTC-Zuweisung

### Option 2: fkms Source Code patchen

**Versuch:**
- fkms Source Code finden
- CRTC-Zuweisungs-Logik anpassen
- Für DSI-Encoder CRTC zuweisen

**Problem:** Komplex, braucht Kernel-Patch

### Option 3: Device Tree Overlay anpassen

**Versuch:**
- Overlay erweitern um CRTC explizit zu definieren
- CRTC-Property zum DSI-Encoder hinzufügen

**Problem:** Unklar ob fkms das unterstützt

### Option 4: Alternative: DRM-Tools verwenden

**Versuch:**
- `modetest` oder ähnliche Tools
- CRTC manuell aktivieren
- Display-Output forcieren

**Versuch wert:** Hoch - könnte sofort funktionieren!

---

## Nächste Schritte (Priorität)

### 1. DRM-Tools testen (SOFORT)
```bash
# Prüfe ob modetest installiert ist
which modetest

# Falls nicht: Installieren
sudo apt install libdrm-tests

# CRTC aktivieren
modetest -c <connector_id> -s <crtc_id>@<mode>
```

### 2. fkms Source Code analysieren
- Wo wird CRTC erstellt?
- Warum wird er nicht zugewiesen?
- Kann man das patchen?

### 3. Device Tree Overlay erweitern
- CRTC explizit definieren
- DSI-Encoder mit CRTC verbinden

---

## Erkenntnisse

1. **Problem ist 100% konfigurationsbedingt** (alle 3 Panels gleich)
2. **Hardware funktioniert** (DSI-1 erkannt, Framebuffer existiert)
3. **Nur CRTC-Zuweisung fehlt** (letztes Hindernis)
4. **fkms ist näher dran** als echtes KMS

---

**Status:** Problem klar identifiziert, Lösungsansätze definiert


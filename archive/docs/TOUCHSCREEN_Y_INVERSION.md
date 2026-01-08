# ✅ TOUCHSCREEN: NUR Y-ACHSE (OBEN/UNTEN) INVERTIERT

**Datum:** 2025-11-30  
**Status:** ✅ **KONFIGURIERT**

---

## 🎯 KONFIGURATION

### Matrix für nur Y-Inversion (oben/unten invertiert)
```
1 0 0
0 -1 1
0 0 1
```

**Bedeutung:**
- X-Achse: Normal (1 0 0)
- Y-Achse: Invertiert (0 -1 1)
- Translation: Y=1 (für 0-1 Koordinatenbereich)

---

## 🔧 IMPLEMENTIERUNG

### PI5 (Ghettoblaster)
- **Gerät:** WaveShare WaveShare (ID 10)
- **Befehl:**
  ```bash
  xinput set-prop 10 "Coordinate Transformation Matrix" 1 0 0 0 -1 1 0 0 1
  ```
- **Persistenz:** In `.xinitrc` gespeichert

### PI4 (moodepi4)
- **Geräte:** vc4-hdmi-0 (ID 6), vc4-hdmi-1 (ID 7)
- **Befehl:**
  ```bash
  xinput set-prop 6 "Coordinate Transformation Matrix" 1 0 0 0 -1 1 0 0 1
  xinput set-prop 7 "Coordinate Transformation Matrix" 1 0 0 0 -1 1 0 0 1
  ```
- **Persistenz:** In `.xinitrc` gespeichert

---

## 📝 MATRIX-ÜBERSICHT

| Matrix | X-Achse | Y-Achse | Verwendung |
|--------|---------|---------|------------|
| `1 0 0 0 1 0 0 0 1` | Normal | Normal | Keine Inversion |
| `1 0 0 0 -1 1 0 0 1` | Normal | Invertiert | **Aktuell - Nur Y invertiert (oben/unten)** |
| `-1 0 1 0 -1 1 0 0 1` | Invertiert | Invertiert | Beide Achsen invertiert |
| `0 -1 1 -1 0 1 0 0 1` | Vertauscht+Y | Vertauscht+X | X/Y vertauscht + beide invertiert |

---

**Status:** ✅ **NUR Y-ACHSE (OBEN/UNTEN) INVERTIERT - BITTE TESTEN!**


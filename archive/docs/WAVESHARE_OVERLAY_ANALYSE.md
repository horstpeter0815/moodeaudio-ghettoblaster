# Waveshare Overlay Analyse - Hardcodierte Werte

## Dekompiliertes Overlay

Das Overlay wurde erfolgreich dekompiliert: `waveshare-overlay-decompiled.dts`

## Hardcodierte Werte

### 1. **I2C-Adressen (HARDCODED)**

```dts
panel_disp1@45 {
    reg = <0x45>;  // I2C-Adresse 0x45 (69 decimal)
    compatible = "waveshare,10.1inch-panel";  // DEFAULT!
}

goodix@14 {
    reg = <0x14>;  // I2C-Adresse 0x14 (20 decimal) - Touchscreen
    compatible = "goodix,gt911";
}
```

**WICHTIG:**
- Panel-Adresse: **0x45** (hardcodiert)
- Touchscreen-Adresse: **0x14** (hardcodiert)
- Default Panel: **10.1inch** (wird durch Parameter überschrieben)

### 2. **I2C-Bus (HARDCODED)**

```dts
__fixups__ {
    i2c_csi_dsi = "/fragment@2:target:0";  // I2C Bus 10 (DSI I2C)
}
```

**Das bedeutet:**
- Overlay verwendet **i2c_csi_dsi** (I2C Bus 10)
- Das ist der DSI I2C Bus (I2C0 auf dem Display)
- **Kann NICHT geändert werden** ohne Overlay zu modifizieren

### 3. **DSI-Interface (HARDCODED)**

```dts
__fixups__ {
    dsi1 = "/fragment@0:target:0";  // DSI-1 Interface
}
```

**Das bedeutet:**
- Overlay verwendet **DSI-1** (hardcodiert)
- Fragment 0 = DSI-1 Port
- **Kann NICHT geändert werden** ohne Overlay zu modifizieren

### 4. **7_9_inch Parameter (Überschreibt Default)**

Wenn `7_9_inch` Parameter verwendet wird:

```dts
7_9_inch = <0x03 0x636f6d70...>;  // Hex-encoded
```

**Decodiert bedeutet das:**
- `compatible = "waveshare,7.9inch-panel"`
- `touchscreen-size-x:0=4096` ❌ **FALSCH! (für 4K-TV, nicht für 7.9" Display)**
- `touchscreen-size-y:0=4096` ❌ **FALSCH! (für 4K-TV, nicht für 7.9" Display)**
- `touchscreen-inverted-x?` (optional)
- `touchscreen-swapped-x-y?` (optional)

**KORREKTE WERTE für 7.9" Display (1280x400):**
- `touchscreen-size-x = 1280` ✅
- `touchscreen-size-y = 400` ✅

**Das Overlay setzt falsche Werte! Muss überschrieben werden!**

### 5. **disable_touch Parameter**

```dts
disable_touch = <0x04 0x73746174...>;  // Hex-encoded
```

**Decodiert:**
- Setzt `status=disabled` für den Touchscreen (goodix@14)

## Dependency Cycle Ursache

### Fragment-Struktur:

```
Fragment 0: DSI-1 Port
  ↓ braucht Endpoint von
Fragment 2: Panel (über I2C)
  ↓ braucht I2C Bus von
i2c_csi_dsi (I2C Bus 10)
  ↓ braucht DSI-Info von
Fragment 0 ← ZYKLUS!
```

### Hardcodierte Abhängigkeiten:

1. **Panel braucht DSI-Host** (Fragment 0)
2. **DSI braucht Panel-Konfiguration** (über I2C, Fragment 2)
3. **I2C Bus braucht DSI-Info** (für Initialisierung)

**Alle sind hardcodiert im Overlay!**

## Lösungsansätze

### 1. **Overlay-Parameter nutzen**

Bereits vorhandene Parameter:
- `disable_touch` - Deaktiviert Touchscreen (reduziert I2C-Dependencies)
- `7_9_inch` - Setzt korrektes Panel
- `rotation` - Kann Initialisierungsreihenfolge beeinflussen

### 2. **I2C-Bus-Override**

Es gibt einen `i2c1` Parameter, aber:
- Standard ist `i2c_csi_dsi` (I2C Bus 10)
- `i2c1` würde auf GPIO I2C (Bus 1) wechseln
- **Aber:** Display ist auf I2C0 (Bus 10) eingestellt!

### 3. **DSI-Override**

Es gibt einen `dsi0` Parameter:
- Standard ist `dsi1`
- `dsi0` würde auf DSI-0 wechseln
- **Aber:** Pi 4 hat nur DSI-1!

## Problem-Identifikation

### Was funktioniert:
- ✅ Panel-Device wird erstellt (`panel_disp1@45`)
- ✅ I2C Bus 10 wird erstellt
- ✅ DSI-1 wird erkannt

### Was funktioniert nicht:
- ❌ Panel-Initialisierung (Dependency Cycle)
- ❌ I2C-Kommunikation (keine Devices auf Bus 10)
- ❌ Display zeigt kein Bild

### Hardcodierte Limitierungen:
1. **I2C-Adresse 0x45** kann nicht geändert werden
2. **I2C Bus 10** (i2c_csi_dsi) kann nicht geändert werden
3. **DSI-1** kann nicht geändert werden
4. **Dependency Cycles** sind im Overlay-Design eingebaut

## Mögliche Fixes

### 1. **Kernel-Module analysieren**

Prüfe `panel-waveshare-dsi.ko`:
- Wie initialisiert es das Panel?
- Welche I2C-Kommandos sendet es?
- Gibt es Power-Sequence-Probleme?

### 2. **Overlay modifizieren**

Erstelle ein angepasstes Overlay:
- Reduziere Dependencies
- Ändere Initialisierungsreihenfolge
- Füge Power-Delays hinzu

### 3. **Kernel-Parameter**

Experimentiere mit:
- `video=DSI-1:1280x400@60` (bereits gesetzt)
- Zusätzliche DSI-Parameter
- I2C-Delays

## Nächste Schritte

1. Analysiere Kernel-Modul `panel-waveshare-dsi.ko`
2. Prüfe Panel-Initialisierungssequenz
3. Teste verschiedene Overlay-Parameter-Kombinationen
4. Erwäge Overlay-Modifikation


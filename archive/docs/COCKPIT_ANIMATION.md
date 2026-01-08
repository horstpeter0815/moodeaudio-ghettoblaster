# Cockpit Animation

## Animation-Features:

### 1. Chain-Animation:
- **Audio Chain:** Läuft von rechts nach links
- **Video Chain:** Läuft von rechts nach links
- **Geschwindigkeit:** 1 Sekunde pro Box
- **Loop:** Startet wieder von rechts wenn links erreicht

### 2. Status-Farben:
- 🔴 **ROT (pending):** Noch nicht aktiv
- 🟠 **ORANGE (pending):** Wartet auf Aktivierung
- 🟢 **GRÜN (active):** Aktuell aktiv
- ⚫ **GRAU (inactive):** Nicht aktiv

### 3. Pfeil-Animation:
- Pfeile werden aktiviert wenn Box davor aktiv ist
- Zeigt Datenfluss von rechts nach links

## Visualisierung:

### Audio Chain (von rechts nach links):
```
[Output] → [MPD] → [ALSA] → [Hardware]
  🟢        🟢       🟢        🟢
```

### Video Chain (von rechts nach links):
```
[Display] → [Player] → [X11] → [Hardware]
   🟢         🟢         🟢        🟢
```

## Status:

- ✅ Animation implementiert
- ✅ Läuft kontinuierlich
- ✅ Zeigt Datenfluss von rechts nach links

---

**Cockpit läuft und zeigt Animation**


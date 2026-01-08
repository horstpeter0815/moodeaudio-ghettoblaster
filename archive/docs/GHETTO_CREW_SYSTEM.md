# GHETTO CREW - COMPLETE HIFI SYSTEM

**Datum:** 3. Dezember 2025  
**System-Name:** Ghetto Crew  
**Status:** ✅ FINAL NAMING

---

## 🎯 SYSTEM-NAME

### **Ghetto Crew** 🎵
Das komplette HiFi-System heißt **Ghetto Crew**

---

## 👥 DIE CREW

### **1. Ghetto Blaster** 🎵
- **Rolle:** Zentrale / Leader
- **Hardware:** Raspberry Pi 5
- **Software:** moOde Audio (Ghetto OS)
- **Display:** 1280x400 + Touchscreen
- **Audio:** HiFiBerry AMP100

### **2. Ghetto Scratch** 🎧
- **Rolle:** Vinyl Player
- **Hardware:** Raspberry Pi Zero 2W
- **Audio:** HiFiBerry ADC Pro
- **Funktion:** Web-Stream zu Ghetto Blaster

### **3. Ghetto Boom** 🔊
- **Rolle:** Linker Lautsprecher
- **Hardware:** Bose 901L + HiFiBerry BeoCreate
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)

### **4. Ghetto Mob** 🔊
- **Rolle:** Rechter Lautsprecher
- **Hardware:** Bose 901R + Custom Board
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)
- **Witz:** "Boom" rückwärts = "Mob" 😄

---

## 🎵 GHETTO CREW ARCHITECTURE

```
                    GHETTO CREW
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ GHETTO       │  │ GHETTO       │  │ GHETTO       │
│ BLASTER      │  │ SCRATCH      │  │ BOOM         │
│ (Leader)     │  │ (Vinyl)      │  │ (Links)      │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                 │
       │                  │                 │
       └──────────────────┴─────────────────┘
                          │
                          ▼
                   ┌──────────────┐
                   │ GHETTO       │
                   │ MOB          │
                   │ (Rechts)     │
                   └──────────────┘
```

---

## 🎯 SYSTEM-ÜBERSICHT

### **Ghetto Crew besteht aus:**
1. **Ghetto Blaster** - Master (Zentrale Steuerung)
2. **Ghetto Scratch** - Slave (Vinyl Player)
3. **Ghetto Boom** - Slave (Linker Lautsprecher)
4. **Ghetto Mob** - Slave (Rechter Lautsprecher)

### **Master-Slave Architektur:**
- **Ghetto Blaster** = Master
  - Steuert alle Slaves
  - Zentrale Kommandos
  - Status-Monitoring
  
- **Ghetto Boom** = Slave
  - Empfängt Befehle von Master
  - Sendet Status zurück
  
- **Ghetto Mob** = Slave
  - Empfängt Befehle von Master
  - Sendet Status zurück
  
- **Ghetto Scratch** = Slave
  - Streamt zu Master
  - Wird von Master gesteuert (zu bestätigen)

### **Zusammenarbeit:**
- Ghetto Blaster (Master) steuert alle Slaves
- Ghetto Scratch streamt zu Ghetto Blaster
- Ghetto Boom & Mob werden von Ghetto Blaster gesteuert
- Alle arbeiten zusammen als **Ghetto Crew**

---

## 💡 WARUM "CREW"?

- ✅ **Team:** Alle Komponenten arbeiten zusammen
- ✅ **Gemeinschaft:** Einheitliches System
- ✅ **Cool:** Passt zum "Ghetto" Theme
- ✅ **Memorable:** Einprägsamer Name

---

**Status:** ✅ SYSTEM-NAME FINALISIERT  
**Ghetto Crew - Das komplette HiFi-System!** 🎵


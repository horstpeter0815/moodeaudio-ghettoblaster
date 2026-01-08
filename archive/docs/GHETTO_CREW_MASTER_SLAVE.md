# GHETTO CREW MASTER-SLAVE ARCHITECTURE

**Datum:** 3. Dezember 2025  
**System:** Ghetto Crew  
**Status:** ✅ ARCHITECTURE DEFINED

---

## 🎯 MASTER-SLAVE BEZIEHUNG

### **Master:**
- **Ghetto Blaster** 🎵
  - Zentrale Steuerung
  - Kommandiert alle Slaves
  - Display & Interface
  - Audio-Steuerung

### **Slaves:**
- **Ghetto Boom** 🔊 (Slave)
  - Wird von Ghetto Blaster gesteuert
  - Empfängt Befehle
  - Sendet Status zurück

- **Ghetto Mob** 🔊 (Slave)
  - Wird von Ghetto Blaster gesteuert
  - Empfängt Befehle
  - Sendet Status zurück

- **Ghetto Scratch** 🎧 (Slave) ✅
  - **Aktuell:** Streamt zu Ghetto Blaster
  - **Zukunft:** Steuerung über Ghetto Blaster Display (Future Music)
  - **Status:** Slave bestätigt

---

## 🔗 KOMMUNIKATION

### **Ghetto Blaster → Ghetto Boom:**
- **Steuerung:** Volume, Crossover, Settings
- **Protokoll:** BeoCreate API / Web-Interface
- **Richtung:** Master → Slave

### **Ghetto Blaster → Ghetto Mob:**
- **Steuerung:** Volume, Crossover, Settings
- **Protokoll:** Custom Board API / Web-Interface
- **Richtung:** Master → Slave

### **Ghetto Blaster → Ghetto Scratch:**
- **Aktuell:** Empfängt Stream (HTTP/HTTPS)
- **Zukunft:** Steuerung über Display (Start/Stop, Settings)
- **Protokoll:** Web-Stream (aktuell), später API für Steuerung
- **Richtung:** Master → Slave (aktuell passiv, später aktiv)

### **Slaves → Ghetto Blaster:**
- **Status:** Volume, Status, Fehler
- **Protokoll:** API Responses, Status-Updates
- **Richtung:** Slaves → Master

---

## 🎛️ STEUERUNGS-MODELL

### **Master (Ghetto Blaster):**
```
Ghetto Blaster:
├── Steuert Ghetto Boom (Volume, Crossover, etc.)
├── Steuert Ghetto Mob (Volume, Crossover, etc.)
├── Empfängt Stream von Ghetto Scratch
└── Zeigt Status aller Slaves auf Display
```

### **Slaves:**
```
Ghetto Boom:
└── Empfängt Befehle von Ghetto Blaster
    └── Führt aus (Volume, Crossover, etc.)
    └── Sendet Status zurück

Ghetto Mob:
└── Empfängt Befehle von Ghetto Blaster
    └── Führt aus (Volume, Crossover, etc.)
    └── Sendet Status zurück

Ghetto Scratch:
└── Streamt zu Ghetto Blaster (aktuell)
    └── Später: Steuerung über Ghetto Blaster Display
        └── Plattenspieler-Steuerung (Future Music)
```

---

## 📅 ENTWICKLUNGSPHASEN

### **Phase 1: Aktuell (Basic Slave)**
- **Ghetto Scratch:** Streamt zu Ghetto Blaster
- **Steuerung:** Keine (nur Stream-Empfang)
- **Status:** Basic Slave

### **Phase 2: Zukunft (Future Music)**
- **Ghetto Scratch:** Steuerung über Ghetto Blaster Display
- **Funktionen:**
  - Plattenspieler-Steuerung
  - Start/Stop
  - Settings
  - Status-Anzeige
- **Status:** Erweiterte Slave-Funktionalität

---

## 🎯 ZUKUNFTS-VISION

### **Ghetto Blaster Display → Ghetto Scratch:**
- **Plattenspieler-Steuerung:**
  - Start/Stop
  - Geschwindigkeit (33/45 RPM)
  - Settings
  - Status-Monitoring

### **Interface:**
- Touchscreen-Steuerung auf Ghetto Blaster
- Visuelle Feedback
- Integration in moOde UI

---

**Status:** ✅ MASTER-SLAVE ARCHITECTURE DOKUMENTIERT  
**Ghetto Scratch:** Basic Slave (aktuell), erweiterte Steuerung (Zukunft)


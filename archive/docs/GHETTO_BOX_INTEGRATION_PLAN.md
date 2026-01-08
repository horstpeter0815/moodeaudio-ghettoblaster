# GHETTO BOOM & MOB INTEGRATION PLAN

**Datum:** 3. Dezember 2025  
**Komponenten:** Ghetto Boom (Bose 901L) & Ghetto Mob (Bose 901R)  
**Zentrale:** Ghetto Blaster  
**Witz:** "Boom" rückwärts = "Mob" 😄

---

## 🎯 ZIEL

**Integration der aktiven Lautsprecher in Ghetto Blaster:**
- Steuerung von Ghetto Box L & R
- Display-Umschaltung für Management
- Web Player Interface
- **Ideale Lösung:** Oversized Control für beide

---

## 📋 KOMPONENTEN

### **Ghetto Boom:**
- **Hardware:** Bose 901L + HiFiBerry BeoCreate
- **Software:** BeoCreate Software (vorhanden)
- **Kanal:** Links

### **Ghetto Mob:**
- **Hardware:** Bose 901R + Custom Board
- **Software:** Custom Software (vorhanden)
- **Kanal:** Rechts
- **Witz:** "Boom" rückwärts = "Mob" 😄

---

## 🎛️ STEUERUNGS-OPTIONEN

### **Option A: Display-Umschaltung** (Aktuell geplant)

**Konzept:**
- Ghetto Blaster Display umschaltbar
- Zwischen moOde UI und Lautsprecher-Management
- Settings für beide Lautsprecher

**Vorteile:**
- ✅ Einfach zu implementieren
- ✅ Nutzt vorhandenes Display
- ✅ Touchscreen-Steuerung

**Nachteile:**
- ⚠️ Nur ein System sichtbar
- ⚠️ Umschaltung nötig

### **Option B: Oversized Control** (Ideale Lösung) ⭐

**Konzept:**
- Einheitliche Steuerung für beide Lautsprecher
- Gleichzeitige Kontrolle
- Split-Screen oder Tabs

**Vorteile:**
- ✅ Beide Lautsprecher gleichzeitig sichtbar
- ✅ Bessere UX
- ✅ Keine Umschaltung nötig

**Nachteile:**
- ⚠️ Komplexere Implementierung
- ⚠️ Mehr UI-Design nötig

---

## 🔄 INTEGRATION PLAN

### **Phase 1: Vorbereitung**
- [ ] BeoCreate Software analysieren
- [ ] Custom Board Software analysieren
- [ ] Web-Interfaces identifizieren
- [ ] API-Endpoints dokumentieren

### **Phase 2: Display-Umschaltung (Kurzfristig)**
- [ ] UI-Modus für Lautsprecher-Management
- [ ] Umschalt-Button im moOde UI
- [ ] Settings-Panel für Ghetto Boom
- [ ] Settings-Panel für Ghetto Mob
- [ ] Web Player Integration

### **Phase 3: Oversized Control (Langfristig)**
- [ ] Unified Control Interface Design
- [ ] Split-Screen oder Tab-Layout
- [ ] Gleichzeitige Steuerung beider
- [ ] Status-Anzeige für beide
- [ ] Web Player für beide

---

## 🖥️ UI-KONZEPT

### **Display-Umschaltung:**
```
┌─────────────────────────────────┐
│  [moOde UI] [Lautsprecher]      │  ← Umschalt-Buttons
├─────────────────────────────────┤
│                                 │
│  Aktueller Modus: moOde UI     │
│  oder                           │
│  Lautsprecher-Management        │
│                                 │
└─────────────────────────────────┘
```

### **Oversized Control (Ideale Lösung):**
```
┌─────────────────────────────────┐
│  [Ghetto Boom] [Ghetto Mob]     │  ← Tabs
├─────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐   │
│  │   Boom   │  │   Mob    │   │
│  │          │  │          │   │
│  │  Volume  │  │  Volume  │   │
│  │  Source  │  │  Source  │   │
│  │  Status  │  │  Status  │   │
│  └──────────┘  └──────────┘   │
└─────────────────────────────────┘
```

---

## 🔧 TECHNISCHE IMPLEMENTATION

### **Web Player Integration:**
- MPD Streams zu beiden Lautsprechern
- Web-Interface für Steuerung
- Status-Updates
- Volume Control

### **API-Integration:**
- BeoCreate API (Ghetto Boom)
- Custom Board API (Ghetto Mob)
- Unified Control Layer

### **Display-Management:**
- Chromium Kiosk Mode
- UI-Modus-Umschaltung
- Touchscreen-Support

---

## 📊 PRIORITÄTEN

### **High Priority:**
1. ✅ Ghetto Blaster Custom Build (aktuell)
2. ⏳ Display-Umschaltung implementieren
3. ⏳ Web Player Integration

### **Medium Priority:**
1. ⏳ Oversized Control Design
2. ⏳ Unified API Layer
3. ⏳ Status-Monitoring

### **Low Priority:**
1. ⏳ Advanced Features
2. ⏳ Custom UI Themes
3. ⏳ Automation Rules

---

**Status:** 📋 INTEGRATION PLAN ERSTELLT  
**Nächster Schritt:** BeoCreate & Custom Software analysieren


# Docker RAM Optimierung - Lern-Guide

**Datum:** 6. Dezember 2025  
**Ziel:** Verstehen, warum und wie man Docker RAM optimiert

---

## 🎓 WARUM IST RAM WICHTIG?

### **Was passiert beim Build?**

1. **Paket-Installation:**
   - Viele Pakete werden gleichzeitig kompiliert
   - Jeder Compiler-Job braucht RAM
   - Mehr RAM = mehr parallele Jobs möglich

2. **Caching:**
   - Build-System cacht kompilierte Dateien
   - Mehr RAM = mehr Cache = schnellerer Build

3. **Swapping:**
   - Wenn RAM voll ist → Swap auf Festplatte
   - Swap ist 100-1000x langsamer als RAM
   - **Resultat:** Build wird extrem langsam

---

## 📊 AKTUELLE SITUATION

### **Dein Mac:**
- **Verfügbares RAM:** 48 GB
- **Docker Desktop RAM:** 7.6 GB (nur 16%!)
- **Problem:** 40 GB werden nicht genutzt!

### **Was passiert:**
```
Build braucht 10 GB RAM
↓
Docker hat nur 7.6 GB
↓
3 GB müssen auf Swap (Festplatte)
↓
Build wird 10-50x langsamer!
```

---

## 🔧 WIE ERHÖHT MAN DOCKER RAM?

### **Schritt-für-Schritt:**

#### **1. Docker Desktop öffnen**
- **Wo:** Menüleiste oben rechts (Docker-Icon)
- **Oder:** Applications → Docker Desktop

#### **2. Settings öffnen**
- **Klick:** Zahnrad-Icon (⚙️) oben rechts
- **Oder:** Menü "Docker Desktop" → "Settings" (⌘,)

#### **3. Resources → Advanced**
- **Links:** "Resources" in Seitenleiste
- **Oben:** "Advanced" Tab

#### **4. Memory erhöhen**
- **Finde:** "Memory" Slider oder Eingabefeld
- **Aktuell:** 8192 MB (7.6 GB)
- **Ändere auf:** 40960 MB (40 GB)
- **Warum 40 GB?**
  - Mac hat 48 GB → 40 GB für Docker
  - 8 GB bleiben für macOS
  - Optimal für Build-Performance

#### **5. Apply & Restart**
- **Klick:** "Apply & Restart"
- **Warte:** 1-2 Minuten (Docker startet neu)

---

## 📈 ERWARTETE VERBESSERUNG

### **Mit 7.6 GB RAM:**
- ⏱️ Build-Zeit: ~8-12 Stunden
- 🔄 Swapping: Viel
- ⚡ Parallele Jobs: 4-8
- 📊 CPU-Nutzung: 50-70%

### **Mit 40 GB RAM:**
- ⏱️ Build-Zeit: ~4-6 Stunden (50% schneller!)
- 🔄 Swapping: Minimal
- ⚡ Parallele Jobs: 16+ (alle CPUs)
- 📊 CPU-Nutzung: 80-95%

---

## 🎯 OPTIMALE KONFIGURATION

### **Für deinen Mac (48 GB RAM):**

| Komponente | RAM | Begründung |
|------------|-----|------------|
| **macOS System** | 8 GB | Basis-Betriebssystem |
| **Docker Desktop** | 40 GB | Build-Performance |
| **Reserve** | 0 GB | Alles genutzt! |

### **Warum nicht mehr?**
- macOS braucht mindestens 4-8 GB
- 40 GB ist optimal für Builds
- Mehr bringt kaum Vorteil

---

## 🔍 WIE PRÜFT MAN RAM-NUTZUNG?

### **1. Docker RAM prüfen:**
```bash
docker info | grep "Total Memory"
# Sollte zeigen: Total Memory: 40GiB
```

### **2. Container RAM-Nutzung:**
```bash
docker stats moode-builder
# Zeigt: CPU %, Memory Usage, Memory Limit
```

### **3. System-RAM prüfen:**
```bash
# Mac RAM insgesamt
sysctl hw.memsize
# Zeigt: 51539607552 (48 GB)

# Docker RAM
docker info | grep "Total Memory"
# Sollte zeigen: 40GiB
```

---

## 🚨 WARNUNGEN

### **Zu wenig RAM:**
- ❌ Build wird extrem langsam
- ❌ Viel Swapping
- ❌ System kann einfrieren

### **Zu viel RAM:**
- ⚠️ macOS hat zu wenig RAM
- ⚠️ System wird langsam
- ⚠️ Andere Apps können nicht laufen

### **Optimal:**
- ✅ 40 GB für Docker (von 48 GB)
- ✅ 8 GB für macOS
- ✅ Beste Balance

---

## 📚 WEITERE OPTIMIERUNGEN

### **1. CPU-Nutzung:**
- **Aktuell:** 16 CPUs zugewiesen ✅
- **Optimal:** Alle CPUs nutzen
- **MAKEFLAGS=-j16** → 16 parallele Jobs

### **2. I/O-Optimierung:**
- **Problem:** Viel Festplatten-I/O
- **Lösung:** Mehr RAM = weniger Swap = weniger I/O

### **3. Caching:**
- **Build-Cache:** Nutzt RAM
- **Mehr RAM:** Mehr Cache = schnellerer Build

---

## 🎓 LERNEN: WIE FUNKTIONIERT ES?

### **Docker Desktop Architektur:**

```
┌─────────────────────────────────────┐
│         macOS (48 GB RAM)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Docker Desktop VM            │  │
│  │   (40 GB RAM zugewiesen)       │  │
│  │                                 │  │
│  │  ┌───────────────────────────┐ │  │
│  │  │  Container (moode-builder) │ │  │
│  │  │  (40 GB Limit)             │ │  │
│  │  └───────────────────────────┘ │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   macOS System (8 GB)          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### **Warum VM?**
- Docker läuft in einer Linux-VM auf macOS
- VM hat eigenes RAM-Limit
- Container können nicht mehr nutzen als VM hat

---

## ✅ CHECKLISTE

- [ ] Docker Desktop geöffnet
- [ ] Settings → Resources → Advanced
- [ ] Memory auf 40 GB (40960 MB) gesetzt
- [ ] Apply & Restart geklickt
- [ ] Docker Desktop neu gestartet (Icon grün)
- [ ] RAM verifiziert: `docker info | grep "Total Memory"`
- [ ] Container neu gestartet
- [ ] Build läuft mit optimalen Ressourcen

---

## 🎯 FAZIT

**Warum 40 GB?**
- Optimal für Build-Performance
- Nutzt deine Hardware voll aus
- Build wird 2x schneller

**Was lernst du?**
- Wie Docker RAM funktioniert
- Warum mehr RAM = schnellerer Build
- Wie man Ressourcen optimal nutzt

---

**Status:** Bereit zum Lernen und Optimieren! 🚀


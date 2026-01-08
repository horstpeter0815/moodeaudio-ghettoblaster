# 🎵 SERVICES REPOSITORY MANAGER

**Zweck:** Auswahl und Download von Service-Repositories für Analyse

---

## 📋 VERFÜGBARE SERVICES

### **Haupt-Services (moOde/HiFiBerry):**

| Service | Repository | Geschätzte Größe | Status |
|---------|-----------|------------------|--------|
| **Shairport Sync** (Airplay) | `mikebrady/shairport-sync` | ~1-2 MB | ✅ |
| **Spotifyd** | `hifiberry/spotifyd` (Fork) | ~2-3 MB | ✅ |
| **Squeezelite** | `ralph-irving/squeezelite` | ~1-2 MB | ✅ |
| **MPD** | `MusicPlayerDaemon/MPD` | ~5-10 MB | ✅ |
| **Snapcast** | `badaix/snapcast` | ~2-3 MB | ✅ |
| **Roon RAAT** | Proprietär (kein Repo) | N/A | ❌ |
| **BlueZ/BlueALSA** | `bluez/bluez` | ~10-15 MB | ✅ |
| **MPRIS Proxy** | `Vudentz/BlueZ` (mpris-proxy) | ~0.5 MB | ✅ |
| **MPD-MPRIS** | `natsukagami/mpd-mpris` | ~0.5 MB | ✅ |
| **LMS-MPRIS** | `hifiberry/lmsmpris` | ~0.5 MB | ✅ |

### **Zusätzliche Services:**

| Service | Repository | Geschätzte Größe | Status |
|---------|-----------|------------------|--------|
| **UPnP/DLNA** | `medoc92/upmpdcli` | ~2-3 MB | ✅ |
| **PeppyMeter** | `project-owner/peppymeter` | ~1-2 MB | ✅ |
| **CamillaDSP** | `HEnquist/camilladsp` | ~3-5 MB | ✅ |
| **NQPTP** (Airplay 2) | `mikebrady/nqptp` | ~0.5 MB | ✅ |

---

## 💾 GESCHÄTZTER SPEICHERPLATZ-BEDARF

### **Minimal (nur Haupt-Services):**
- Shairport Sync: ~2 MB
- MPD: ~10 MB
- **Gesamt:** ~12-15 MB

### **Standard (Haupt + Multiroom):**
- Shairport Sync: ~2 MB
- MPD: ~10 MB
- Snapcast: ~3 MB
- Squeezelite: ~2 MB
- **Gesamt:** ~17-20 MB

### **Vollständig (alle Services):**
- Alle Haupt-Services: ~20 MB
- Alle Zusatz-Services: ~10 MB
- **Gesamt:** ~30-35 MB

### **Mit Git-History (vollständige Repos):**
- **Geschätzt:** ~100-200 MB (je nach History)

---

## 🎯 AUSWAHL-SYSTEM

### **Kategorien:**

1. **Airplay:**
   - ✅ Shairport Sync
   - ✅ NQPTP (Airplay 2)

2. **Streaming:**
   - ✅ Spotifyd
   - ✅ UPnP/DLNA

3. **Multiroom:**
   - ✅ Snapcast
   - ✅ Squeezelite

4. **Player:**
   - ✅ MPD
   - ✅ Roon (proprietär, kein Repo)

5. **Bluetooth:**
   - ✅ BlueZ/BlueALSA
   - ✅ MPRIS Proxy

6. **MPRIS (Metadata):**
   - ✅ MPD-MPRIS
   - ✅ LMS-MPRIS

7. **Audio Processing:**
   - ✅ CamillaDSP
   - ✅ PeppyMeter

---

## 📥 DOWNLOAD-OPTIONEN

### **Option 1: Shallow Clone (nur letzter Commit)**
```bash
git clone --depth 1 <repo-url>
```
- **Vorteil:** Schnell, wenig Speicher (~10-20% der Größe)
- **Nachteil:** Keine Git-History

### **Option 2: Full Clone (komplett)**
```bash
git clone <repo-url>
```
- **Vorteil:** Vollständige History
- **Nachteil:** Mehr Speicher

### **Option 3: Download ZIP (kein Git)**
```bash
wget <repo-url>/archive/refs/heads/main.zip
```
- **Vorteil:** Sehr klein, kein Git nötig
- **Nachteil:** Keine Updates möglich

---

## 🔧 NÄCHSTE SCHRITTE

1. **Auswahl treffen:** Welche Services brauchst du?
2. **Download-Script erstellen:** Mit Auswahl-Menü
3. **Repositories herunterladen:** In `services-repos/` Ordner
4. **Analyse starten:** Code-Scanning für Verständnis

---

**Bereit für Auswahl!** 🚀


# DOCKER BUILD OPTION - GHETTOBLASTER

**Datum:** 2. Dezember 2025  
**Frage:** Docker auf Mac installieren für moOde Build?

---

## ✅ JA - DOCKER KANN INSTALLIERT WERDEN

### **System-Anforderungen:**
- ✅ **macOS:** Aktuelle und 2 vorherige Versionen
- ✅ **RAM:** Mindestens 4 GB
- ✅ **Apple Silicon (M1/M2/M3):** Unterstützt
- ✅ **Intel:** Unterstützt

---

## 🐳 DOCKER INSTALLATION

### **Schritte:**

1. **Docker Desktop herunterladen:**
   - Für Apple Silicon: https://docs.docker.com/desktop/install/mac-install/#install-docker-desktop-on-mac
   - Für Intel: https://docs.docker.com/desktop/install/mac-install/#install-docker-desktop-on-mac

2. **Installation:**
   ```bash
   # DMG öffnen, Docker.app in Applications ziehen
   # Docker Desktop starten
   ```

3. **Optional (Apple Silicon):**
   ```bash
   # Rosetta 2 installieren für bessere Kompatibilität
   softwareupdate --install-rosetta
   ```

---

## 🤔 KANN MOODE BUILD IN DOCKER LAUFEN?

### **Theorie:**
- ✅ pi-gen (moOde Build-Tool) läuft auf Linux
- ✅ Docker kann Linux-Container auf Mac ausführen
- ✅ Build sollte theoretisch funktionieren

### **Praktische Überlegungen:**

**✅ Vorteile:**
- Build läuft in Linux-Umgebung
- Kein separates Linux-System nötig
- Isoliert vom Host-System

**⚠️ Herausforderungen:**
- **Cross-Compilation:** Raspberry Pi ARM-Images auf x86/ARM Mac
- **Performance:** Kann langsamer sein als native Linux
- **Disk Space:** Benötigt ~10GB+ für Build
- **Komplexität:** Docker-Setup + Volume-Mounting

---

## 💡 EMPFEHLUNG

### **Option A: Docker versuchen** ⭐

**Vorgehen:**
1. Docker Desktop installieren (15-30 Min)
2. Ubuntu/Debian Container erstellen
3. imgbuild in Container mounten
4. Build starten
5. Ergebnis testen

**Zeitaufwand:**
- Setup: 1-2 Stunden
- Build: 8-12 Stunden
- **Total: ~10-14 Stunden**

### **Option B: Alternative - Linux-System**

**Optionen:**
- Raspberry Pi 5 selbst (langsam, aber funktioniert)
- Linux Server/VM
- Cloud Build (AWS, etc.)

---

## 🚀 DOCKER SETUP PLAN

### **Schritt 1: Docker installieren**
```bash
# Docker Desktop herunterladen & installieren
# Start Docker Desktop App
docker --version  # Test
```

### **Schritt 2: Build-Container erstellen**
```bash
# Ubuntu/Debian Container mit allen Dependencies
docker run -it --name moode-build \
  -v /path/to/imgbuild:/workspace \
  ubuntu:22.04 bash
```

### **Schritt 3: Dependencies installieren**
```bash
# Im Container:
apt-get update
apt-get install -y <alle pi-gen dependencies>
```

### **Schritt 4: Build starten**
```bash
cd /workspace
./build.sh
```

---

## ⚠️ WICHTIGE PUNKTE

### **Disk Space:**
- Docker-Images: ~2-5 GB
- Build-Output: ~10 GB
- **Total: ~15-20 GB frei benötigt**

### **Performance:**
- Build dauert auf Mac in Docker: ~10-15 Stunden (länger als native)
- Apple Silicon: Kann schneller sein
- Intel: Kann deutlich länger dauern

### **Netzwerk:**
- Build lädt viele Packages
- Ethernet empfohlen (wenn möglich)

---

## ✅ FINALE EMPFEHLUNG

### **⭐ DOCKER INSTALLIEREN & VERSUCHEN**

**Warum:**
1. ✅ Macht Mac Build-fähig
2. ✅ Isoliert, sicher
3. ✅ Kein separates System nötig
4. ✅ Falls es nicht funktioniert: Alternative verfügbar

**ABER:**
- ⚠️ Setup benötigt Zeit
- ⚠️ Performance kann langsamer sein
- ⚠️ Alternative: Linux-System nutzen

---

**Status:** ✅ DOCKER IST EINE OPTION  
**Nächster Schritt:** Docker installieren & testen


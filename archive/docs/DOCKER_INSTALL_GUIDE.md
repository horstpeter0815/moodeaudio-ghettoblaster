# DOCKER INSTALLATION GUIDE - macOS

**System:** Apple Silicon (arm64), macOS 26.1  
**Status:** ✅ Docker kann installiert werden

---

## ✅ INSTALLATION

### **Schritt 1: Docker Desktop herunterladen**

Für **Apple Silicon** (dein Mac):
```
https://www.docker.com/products/docker-desktop/
```

Oder direkt:
- **Apple Silicon:** https://desktop.docker.com/mac/main/arm64/Docker.dmg
- **Intel:** https://desktop.docker.com/mac/main/amd64/Docker.dmg

### **Schritt 2: Installieren**

1. **DMG öffnen**
2. **Docker.app in Applications ziehen**
3. **Docker Desktop starten** (aus Applications)
4. **Setup durchführen** (Folge den Anweisungen)

### **Schritt 3: Testen**

```bash
docker --version
# Sollte etwas wie "Docker version 24.x.x" zeigen

docker run hello-world
# Sollte erfolgreich laufen
```

---

## ⚠️ OPTIONAL: Rosetta 2 (Apple Silicon)

Für bessere Kompatibilität mit x86-Containern:

```bash
softwareupdate --install-rosetta
```

**Aber:** Meist nicht nötig, da Docker native ARM-Container unterstützt.

---

## 🐳 DOCKER FÜR MOODE BUILD

### **Vorteile:**
- ✅ Build läuft in Linux-Umgebung
- ✅ Isoliert vom Host-System
- ✅ Kein separates Linux-System nötig

### **Herausforderungen:**
- ⚠️ **Cross-Compilation:** Raspberry Pi ARM-Images auf Apple Silicon
- ⚠️ **Performance:** Kann langsamer sein
- ⚠️ **Disk Space:** ~15-20 GB benötigt

### **Funktioniert es?**

**Theoretisch:** ✅ Ja, sollte funktionieren  
**Praktisch:** ⚠️ Muss getestet werden

**Grund:**
- pi-gen läuft auf Linux ✅
- Docker kann Linux-Container ausführen ✅
- Cross-Compilation (ARM auf ARM64) sollte funktionieren ✅
- **Aber:** Komplexität und Performance müssen getestet werden

---

## 💡 EMPFEHLUNG

### **Option A: Docker installieren & testen** ⭐

**Warum:**
1. ✅ Macht Mac Build-fähig
2. ✅ Isoliert, sicher
3. ✅ Falls erfolgreich: Perfekt

**Zeitaufwand:**
- Installation: 15-30 Minuten
- Setup: 1-2 Stunden
- Build: 8-15 Stunden (länger in Docker)

### **Option B: Alternative nutzen**

- Raspberry Pi 5 selbst (langsam, aber funktioniert)
- Linux Server/VM
- Cloud Build

---

## 🚀 NÄCHSTE SCHRITTE

### **Wenn du Docker installieren willst:**

1. **Jetzt:** Docker Desktop installieren
2. **Heute Nacht:** Ich bereite Build-Container vor
3. **Morgen:** Build testen

### **Wenn du noch warten willst:**

1. **Heute Nacht:** Ich nutze Zeit für Vorbereitung
2. **Morgen:** Entscheidung: Docker oder Alternative

---

**Status:** ✅ READY TO INSTALL  
**Empfehlung:** ⭐ Docker installieren & testen


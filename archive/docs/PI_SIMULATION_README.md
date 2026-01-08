# 🐳 PI BOOT SIMULATION MIT DOCKER

**Datum:** 2025-12-07  
**Zweck:** Pi-Boot-Prozess simulieren, um Services und Fixes zu testen, ohne SD-Karte zu brennen

---

## 🚀 SCHNELLSTART

```bash
# Simulation starten
./START_PI_SIMULATION.sh

# Oder manuell:
docker-compose -f docker-compose.pi-sim.yml up -d
```

---

## 📋 WAS WIRD GETESTET?

### **1. User-Konfiguration:**
- ✅ User `andre` mit UID 1000
- ✅ Password: `0815`
- ✅ Sudoers (NOPASSWD)

### **2. Hostname:**
- ✅ Hostname: `GhettoBlaster`

### **3. SSH:**
- ✅ SSH enabled
- ✅ SSH-Flag vorhanden

### **4. Services:**
- ✅ `enable-ssh-early.service`
- ✅ `fix-ssh-sudoers.service`
- ✅ `fix-user-id.service`
- ✅ `localdisplay.service`
- ✅ `disable-console.service`

### **5. Scripts:**
- ✅ `start-chromium-clean.sh`
- ✅ `xserver-ready.sh`
- ✅ `worker-php-patch.sh`

---

## 🔍 VERWENDUNG

### **Simulation starten:**
```bash
./START_PI_SIMULATION.sh
```

### **Tests ausführen:**
```bash
docker exec pi-simulator bash /test/test-services.sh
```

### **Shell öffnen:**
```bash
docker exec -it pi-simulator bash
```

### **Services prüfen:**
```bash
# Status aller Services
docker exec pi-simulator systemctl status enable-ssh-early.service
docker exec pi-simulator systemctl status fix-ssh-sudoers.service
docker exec pi-simulator systemctl status fix-user-id.service

# Services aktivieren
docker exec pi-simulator systemctl enable enable-ssh-early.service
docker exec pi-simulator systemctl start enable-ssh-early.service
```

### **Logs ansehen:**
```bash
docker logs pi-simulator
docker logs -f pi-simulator  # Follow mode
```

### **Container stoppen:**
```bash
docker-compose -f docker-compose.pi-sim.yml down
```

---

## ⚠️ LIMITIERUNGEN

### **Was funktioniert:**
- ✅ User-Konfiguration
- ✅ Hostname
- ✅ SSH-Konfiguration
- ✅ Sudoers
- ✅ Service-Dateien prüfen
- ✅ Scripts prüfen

### **Was nicht funktioniert:**
- ❌ Display (kein X Server)
- ❌ Chromium (kein Display)
- ❌ Audio (keine Hardware)
- ❌ GPIO/I2C (keine Hardware)
- ❌ Touchscreen (keine Hardware)

---

## 🛠️ TROUBLESHOOTING

### **Container startet nicht:**
```bash
# Prüfe Logs
docker logs pi-simulator

# Prüfe ob Container läuft
docker ps | grep pi-simulator
```

### **systemd funktioniert nicht:**
- Container muss mit `privileged: true` laufen
- `/sys/fs/cgroup` muss gemountet sein

### **Services nicht gefunden:**
- Services werden von `custom-components/services` gemountet
- Prüfe: `docker exec pi-simulator ls -la /lib/systemd/system/custom/`

---

## 📋 NÄCHSTE SCHRITTE

1. **Simulation starten:** `./START_PI_SIMULATION.sh`
2. **Tests ausführen:** Automatisch beim Start
3. **Services prüfen:** Via `systemctl status`
4. **Bei Erfolg:** Image auf SD-Karte brennen
5. **Auf Pi testen:** Echter Hardware-Test

---

**Status:** ✅ PI SIMULATION BEREIT  
**Verwendung:** `./START_PI_SIMULATION.sh`


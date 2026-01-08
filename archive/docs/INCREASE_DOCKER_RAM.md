# Docker Desktop RAM erhöhen - Schritt für Schritt

**Datum:** 6. Dezember 2025  
**Ziel:** Docker Desktop RAM von 7.6 GB auf 40 GB erhöhen

---

## 📋 SCHRITTE

### **1. Docker Desktop öffnen**
- Klicke auf das Docker-Icon in der Menüleiste (oben rechts)
- Oder öffne Docker Desktop App

### **2. Settings öffnen**
- Klicke auf das **Zahnrad-Icon** (⚙️) oben rechts
- Oder: **Docker Desktop → Settings** (⌘,)

### **3. Resources öffnen**
- Klicke auf **"Resources"** in der linken Seitenleiste
- Dann auf **"Advanced"**

### **4. Memory erhöhen**
- Finde den **"Memory"** Slider
- **Aktuell:** 7.6 GB (oder 8192 MB)
- **Ändere auf:** 40 GB (oder 40960 MB)
- Oder: Gib direkt **40960** in das Eingabefeld ein

### **5. Apply & Restart**
- Klicke auf **"Apply & Restart"**
- Docker Desktop wird neu gestartet
- Das kann 1-2 Minuten dauern

---

## ✅ VERIFIZIERUNG

Nach dem Neustart prüfen:

```bash
docker info | grep "Total Memory"
```

Sollte zeigen: **Total Memory: 40GiB** (oder ähnlich)

---

## 🚀 NÄCHSTE SCHRITTE

Sobald Docker Desktop neu gestartet ist:

1. **Container neu starten:**
   ```bash
   docker-compose -f docker-compose.build.yml up -d
   ```

2. **Build neu starten:**
   ```bash
   ./start-build-safe.sh
   ```

---

## ⚠️ HINWEISE

- **Docker Desktop muss komplett neu starten**
- **Warte bis Docker Desktop vollständig geladen ist** (Icon grün)
- **Container wird automatisch mit neuen Ressourcen gestartet**

---

**Status:** Warte auf Docker Desktop RAM-Erhöhung...


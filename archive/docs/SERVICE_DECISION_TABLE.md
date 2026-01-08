# SERVICE DECISION TABLE - HIGH-END AUDIO

**Datum:** 2. Dezember 2025  
**Status:** BEREIT FÜR ENTSCHEIDUNG  
**Zweck:** Gemeinsame Entscheidung über zu entfernende Services

---

## 📋 AKTUELLE SERVICES AUF DEM PI 5

### **ESSENTIELLE SERVICES (MÜSSEN BLEIBEN)**

| Service | Zweck | High-End Audio? | Entscheidung |
|---------|-------|----------------|--------------|
| `mpd.service` | Music Player Daemon - Audio-Core | ✅ **JA - ESSENTIELL** | ✅ **BLEIBT** |
| `localdisplay.service` | Display & X Server | ✅ **JA - Für Web-UI** | ✅ **BLEIBT** |
| `nginx.service` | Web-Server für moOde UI | ✅ **JA - Für Konfiguration** | ✅ **BLEIBT** |
| `php8.4-fpm.service` | PHP für Web-UI | ✅ **JA - Für Web-UI** | ✅ **BLEIBT** |

---

### **TOUCHSCREEN SERVICES (REDUNDANT - NUR EINEN BEHALTEN)**

| Service | Zweck | Redundant? | Empfehlung |
|---------|-------|------------|------------|
| `ft6236-delay.service` | Touchscreen-Init (sauber) | ❌ Nein | ✅ **BEHALTEN** |
| `touchscreen-fix.service` | Touchscreen-Fix | ⚠️ Ja (redundant) | ❌ **ENTFERNEN** |
| `touchscreen-bind.service` | Touchscreen-Binding | ⚠️ Ja (redundant) | ❌ **ENTFERNEN** |
| `waveshare-touchscreen-delay.service` | WaveShare Delay | ⚠️ Ja (redundant) | ❌ **ENTFERNEN** |

**Empfehlung:** Nur `ft6236-delay.service` behalten, Rest entfernen

---

### **PEPPYMETER SERVICES (OPTIONAL - VISUALIZER)**

| Service | Zweck | High-End Audio? | Empfehlung |
|---------|-------|----------------|------------|
| `peppymeter.service` | Audio-Visualizer | ❌ Nein (nur Visualisierung) | ⚠️ **OPTIONAL** |
| `peppymeter-screensaver.service` | PeppyMeter Screensaver | ❌ Nein | ⚠️ **OPTIONAL** |
| `peppymeter-position.service` | Position-Fix | ❌ Nein | ⚠️ **OPTIONAL** |
| `peppymeter-window-fix.service` | Window-Fix | ❌ Nein | ⚠️ **OPTIONAL** |

**Empfehlung:** Alle entfernen, wenn Visualizer nicht gewünscht (spart Ressourcen)

---

### **CHROMIUM SERVICES (REDUNDANT)**

| Service | Zweck | Redundant? | Empfehlung |
|---------|-------|------------|------------|
| `chromium-monitor.service` | Chromium Monitoring | ⚠️ Ja (localdisplay hat Restart=always) | ❌ **ENTFERNEN** |

**Empfehlung:** Entfernen (redundant)

---

### **DISPLAY SERVICES (PRÜFEN)**

| Service | Zweck | Notwendig? | Empfehlung |
|---------|-------|------------|------------|
| `display-rotate-fix.service` | Display-Rotation Fix | ⚠️ Nur wenn config.txt nicht korrekt | ⚠️ **PRÜFEN** |

**Empfehlung:** Entfernen, wenn config.txt korrekt ist (sollte sein)

---

### **AUDIO SERVICES (PRÜFEN)**

| Service | Zweck | Notwendig? | Empfehlung |
|---------|-------|------------|------------|
| `set-mpd-volume.service` | Setzt MPD Volume | ⚠️ Nur wenn automatisch gesetzt werden soll | ⚠️ **PRÜFEN** |

**Empfehlung:** Entfernen, wenn Volume manuell gesetzt wird

---

### **NETWORK/SHARING (NICHT FÜR AUDIO)**

| Service | Zweck | High-End Audio? | Empfehlung |
|---------|-------|----------------|------------|
| `samba-ad-dc.service` | Samba File-Sharing | ❌ Nein | ❌ **ENTFERNEN** |

**Empfehlung:** Entfernen (nicht für High-End Audio)

---

## 🎯 ZUSAMMENFASSUNG

### **MUSS BLEIBEN (4 Services):**
1. ✅ `mpd.service` - Audio-Core
2. ✅ `localdisplay.service` - Display
3. ✅ `nginx.service` - Web-UI
4. ✅ `php8.4-fpm.service` - Web-UI

### **EMPFOHLEN ZU BEHALTEN (1 Service):**
5. ✅ `ft6236-delay.service` - Touchscreen (wenn Touchscreen genutzt)

### **KANN ENTFERNT WERDEN (10 Services):**
1. ❌ `touchscreen-fix.service` - Redundant
2. ❌ `touchscreen-bind.service` - Redundant
3. ❌ `waveshare-touchscreen-delay.service` - Redundant
4. ❌ `peppymeter.service` - Optional (Visualizer)
5. ❌ `peppymeter-screensaver.service` - Optional
6. ❌ `peppymeter-position.service` - Optional
7. ❌ `peppymeter-window-fix.service` - Optional
8. ❌ `chromium-monitor.service` - Redundant
9. ❌ `display-rotate-fix.service` - Prüfen (wenn config.txt korrekt)
10. ❌ `samba-ad-dc.service` - Nicht für Audio
11. ❌ `set-mpd-volume.service` - Prüfen (wenn nicht benötigt)

---

## 💡 MEINE EMPFEHLUNG

**Für High-End Audio sollten wir behalten:**
- ✅ 4 Essentielle Services
- ✅ 1 Touchscreen-Service (ft6236-delay)

**Entfernen können wir:**
- ❌ Alle redundanten Touchscreen-Services (3 Services)
- ❌ Alle PeppyMeter-Services (4 Services) - **wenn Visualizer nicht gewünscht**
- ❌ chromium-monitor (1 Service)
- ❌ samba-ad-dc (1 Service)
- ❌ display-rotate-fix (1 Service) - **wenn config.txt korrekt**
- ❌ set-mpd-volume (1 Service) - **wenn nicht benötigt**

**Das würde bedeuten:**
- **Von 15 Services → 5 Services**
- **Weniger Ressourcen-Verbrauch**
- **Fokus auf High-End Audio**

---

## ❓ FRAGEN FÜR DICH

1. **PeppyMeter:** Willst du den Audio-Visualizer behalten oder entfernen?
2. **Touchscreen:** Reicht dir `ft6236-delay.service` oder brauchst du die anderen?
3. **Display-Rotation:** Ist deine config.txt korrekt? (Dann können wir display-rotate-fix entfernen)
4. **MPD Volume:** Soll das Volume automatisch gesetzt werden oder manuell?

---

**Status:** BEREIT FÜR DEINE ENTSCHEIDUNG  
**Nächster Schritt:** Gemeinsam durchgehen und Services entfernen


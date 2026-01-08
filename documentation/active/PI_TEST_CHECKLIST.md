# ✅ PI-TEST CHECKLISTE

**Datum:** 2025-12-07  
**Image:** 2025-12-07-moode-r1001-arm64-lite.img  
**Status:** ✅ Auf SD-Karte gebrannt

---

## 📋 VOR DEM BOOT

### **Hardware verbinden:**
- [ ] SD-Karte in Raspberry Pi 5 eingesteckt
- [ ] Display (Waveshare 1280x400) verbunden
- [ ] Audio (HiFiBerry AMP100) verbunden
- [ ] Netzwerk (LAN-Kabel ODER WLAN aktiv)
- [ ] Stromversorgung verbunden

---

## 🔍 BOOT-PROZESS

### **Nach dem Einschalten:**
- [ ] Pi bootet (LED blinkt)
- [ ] Keine Fehler im Boot-Prozess
- [ ] Boot dauert 1-2 Minuten

---

## 📺 DISPLAY-TEST

### **Was auf dem Display erscheinen sollte:**
- [ ] **Landscape** (nicht Portrait) ✅
- [ ] **Browser startet automatisch** ✅
- [ ] **Browser zeigt moOde Web-UI** ✅
- [ ] **Keine Console auf Display** ✅
- [ ] **Auflösung: 1280x400** ✅

### **Was NICHT erscheinen sollte:**
- [ ] ❌ Console/Terminal auf Display
- [ ] ❌ Portrait-Modus
- [ ] ❌ Schwarzer Bildschirm

---

## 🌐 NETZWERK-TEST

### **WLAN:**
- [ ] WLAN verbunden ("Martin Router King")
- [ ] IP-Adresse erhalten
- [ ] Internet-Verbindung funktioniert

### **SSH:**
- [ ] SSH aktiv (Port 22)
- [ ] Verbindung möglich:
  ```bash
  ssh andre@GhettoBlaster.local
  # Oder:
  ssh andre@<IP-ADRESSE>
  ```
- [ ] Login funktioniert (Password: 0815)

---

## 🔐 LOGIN-TEST

### **SSH-Login:**
- [ ] Username: `andre` ✅
- [ ] Password: `0815` ✅
- [ ] Login erfolgreich

### **Sudo-Test:**
- [ ] `sudo` funktioniert ohne Passwort:
  ```bash
  sudo whoami
  # Sollte "root" ausgeben, ohne Passwort-Abfrage
  ```

### **Hostname:**
- [ ] Hostname ist `GhettoBlaster`:
  ```bash
  hostname
  # Sollte "GhettoBlaster" ausgeben
  ```

---

## 🎵 AUDIO-TEST

### **HiFiBerry AMP100:**
- [ ] Audio-Device erkannt:
  ```bash
  aplay -l
  # Sollte HiFiBerry AMP100 zeigen
  ```
- [ ] Audio funktioniert (Test-Sound)

---

## 🖱️ TOUCHSCREEN-TEST

### **FT6236 Touchscreen:**
- [ ] Touchscreen erkannt
- [ ] Touch funktioniert auf Display
- [ ] Browser reagiert auf Touch

---

## 🌐 WEB-UI-TEST

### **Zugriff:**
- [ ] Web-UI erreichbar:
  - `http://GhettoBlaster.local`
  - Oder: `http://<IP-ADRESSE>`
- [ ] moOde Interface lädt
- [ ] Alle Funktionen verfügbar

---

## 🔧 SERVICES-TEST

### **Wichtige Services:**
- [ ] `localdisplay.service` läuft:
  ```bash
  systemctl status localdisplay.service
  ```
- [ ] `fix-ssh-sudoers.service` läuft:
  ```bash
  systemctl status fix-ssh-sudoers.service
  ```
- [ ] `disable-console.service` aktiv:
  ```bash
  systemctl status disable-console.service
  ```

---

## 📋 BEI PROBLEMEN

### **Display zeigt Console:**
```bash
sudo systemctl restart localdisplay.service
```

### **SSH nicht aktiv:**
```bash
sudo systemctl restart ssh
sudo systemctl status fix-ssh-sudoers.service
```

### **Display Portrait statt Landscape:**
```bash
# Prüfe config.txt
cat /boot/firmware/config.txt | grep display_rotate
# Sollte "display_rotate=0" sein
```

### **Browser startet nicht:**
```bash
# Prüfe Logs
sudo journalctl -u localdisplay.service -n 50
```

---

## ✅ ERFOLG

### **Wenn alles funktioniert:**
- ✅ Display zeigt Landscape mit Browser
- ✅ SSH funktioniert (andre/0815)
- ✅ Sudo funktioniert ohne Passwort
- ✅ Hostname ist GhettoBlaster
- ✅ Audio funktioniert
- ✅ Web-UI erreichbar

**🎉 SYSTEM IST BEREIT!**

---

**Status:** ✅ CHECKLISTE ERSTELLT  
**Nächster Schritt:** Pi booten und testen


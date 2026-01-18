# 🧙 Room Correction Wizard - Access Guide

## 🌐 IP Addresses for Wizard Access

### Current Active IPs:
- **WiFi:** `192.168.1.159` (nam yang 2 network)
- **Ethernet:** `192.168.2.3` (if connected)
- **Hostname:** `ghettoblaster.local` (recommended)

---

## 📍 How to Access the Wizard

### Step 1: Open moOde Web Interface
Open your browser and go to:
```
http://192.168.1.159/
```
or
```
http://ghettoblaster.local/
```

### Step 2: Navigate to Audio Settings
1. Click on **"Audio"** in the top menu
2. Or go directly to: `http://192.168.1.159/snd-config.php`

### Step 3: Open Room Correction Wizard
1. Scroll down to the **"Room Correction"** section
2. Click the **"Run Wizard"** button
3. The wizard modal will open

---

## 🧙 Wizard Steps

1. **Step 1:** Preparation instructions
2. **Step 2:** Ambient noise measurement (5 seconds)
3. **Step 3:** Continuous measurement with pink noise
4. **Step 4:** Upload measurement (optional)
5. **Step 5:** Analysis & Filter generation
6. **Step 6:** Apply & Test filter

---

## 🔗 Direct Links

### Main Interface:
- **WiFi:** http://192.168.1.159/
- **Ethernet:** http://192.168.2.3/
- **Hostname:** http://ghettoblaster.local/

### Audio Settings (direct):
- **WiFi:** http://192.168.1.159/snd-config.php
- **Ethernet:** http://192.168.2.3/snd-config.php
- **Hostname:** http://ghettoblaster.local/snd-config.php

---

## 📱 Mobile Access

The wizard works on mobile devices (iPhone/Android):
1. Connect to same WiFi network ("nam yang 2")
2. Open browser
3. Go to: `http://192.168.1.159/`
4. Navigate to Audio → Room Correction → Run Wizard

**Note:** Microphone permission is required for measurements!

---

## 🔧 Troubleshooting

### Can't access web interface?
```bash
# Check if web server is running
ssh andre@192.168.1.159 'systemctl status apache2 || systemctl status nginx'

# Check if Pi is reachable
ping 192.168.1.159
ping ghettoblaster.local
```

### Wizard button not showing?
- Make sure you're logged in to moOde
- Check browser console for errors
- Try refreshing the page

### Wizard not working?
- Check browser console (F12)
- Verify microphone permissions
- Check network connection

---

## 📝 Quick Reference

**Current WiFi IP:** `192.168.1.159`  
**Current Ethernet IP:** `192.168.2.3`  
**Hostname:** `ghettoblaster.local`  
**Wizard Path:** Audio Settings → Room Correction → Run Wizard

---

**Last Updated:** 2025-01-12

# Ausführung - Display Fix

## 🚀 Schnellste Methode

```bash
chmod +x DO_IT_NOW.sh
./DO_IT_NOW.sh
```

**Das Script:**
1. Installiert sshpass (falls nötig)
2. Führt Display-Fix aus
3. Zeigt Reboot-Befehl

---

## Alternative: Schritt für Schritt

### 1. sshpass installieren
```bash
brew install hudochenkov/sshpass/sshpass
```

### 2. Display-Fix ausführen
```bash
chmod +x FIX_MOODE_DISPLAY_FINAL.sh
./FIX_MOODE_DISPLAY_FINAL.sh
```

### 3. Pi rebooten
```bash
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.178.178 'sudo reboot'
```

Oder manuell:
```bash
ssh andre@192.168.178.178
sudo reboot
```

---

## Verifikation nach Reboot

```bash
chmod +x VERIFY_DISPLAY_FIX.sh
./VERIFY_DISPLAY_FIX.sh
```

---

**Status:** ✅ Scripts bereit


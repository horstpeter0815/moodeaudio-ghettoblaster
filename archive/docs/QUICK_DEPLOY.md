# ⚡ Quick Deploy - Pi 5

**Pi 5 IP:** 192.168.178.161  
**Image:** `2025-12-07-moode-r1001-arm64-lite.img`

---

## 🚀 SCHNELL-ANLEITUNG

```bash
# 1. Image kopieren (Passwort eingeben wenn nötig)
scp 2025-12-07-moode-r1001-arm64-lite.img pi@192.168.178.161:/tmp/

# 2. Auf Pi 5 einloggen
ssh pi@192.168.178.161

# 3. SD-Karte finden
lsblk

# 4. Image brennen (SD-Karte z.B. /dev/sda)
sudo umount /dev/sda* 2>/dev/null
sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
sync
```

---

**Dauer:** ~10-15 Minuten (Kopieren + Brennen)  
**Status:** ✅ READY


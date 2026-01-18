# 📋 Deploy Wizard Files - From Home Directory

**You're in home directory (~). Navigate to project first!**

---

## 🚀 QUICK FIX

**Run these commands:**

```bash
# 1. Navigate to project directory
cd /Users/andrevollmer/moodeaudio-cursor

# 2. Deploy wizard files
sudo mkdir -p /Volumes/rootfs/var/www/html/test-wizard
sudo mkdir -p /Volumes/rootfs/var/www/html/command
sudo cp test-wizard/wizard-functions.js /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
sudo cp moode-source/www/command/room-correction-wizard.php /Volumes/rootfs/var/www/html/command/room-correction-wizard.php

# 3. Verify
ls -la /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
ls -la /Volumes/rootfs/var/www/html/command/room-correction-wizard.php
```

---

## 📋 OR USE FULL PATHS

**If you want to stay in home directory:**

```bash
sudo mkdir -p /Volumes/rootfs/var/www/html/test-wizard
sudo mkdir -p /Volumes/rootfs/var/www/html/command
sudo cp /Users/andrevollmer/moodeaudio-cursor/test-wizard/wizard-functions.js /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
sudo cp /Users/andrevollmer/moodeaudio-cursor/moode-source/www/command/room-correction-wizard.php /Volumes/rootfs/var/www/html/command/room-correction-wizard.php
```

---

**Navigate to project directory first, then deploy!**


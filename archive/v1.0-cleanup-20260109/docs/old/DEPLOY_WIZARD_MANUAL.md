# 🚀 Deploy Wizard - Manual Instructions

**Since sudo requires password, here are the exact commands to run:**

---

## 📋 STEP-BY-STEP COMMANDS

### **Step 1: Create Directories**

```bash
sudo mkdir -p /Volumes/rootfs/var/www/html/test-wizard
sudo mkdir -p /Volumes/rootfs/var/www/html/command
sudo mkdir -p /Volumes/rootfs/var/www/html/templates
sudo mkdir -p /Volumes/rootfs/usr/local/bin
```

---

### **Step 2: Copy Files**

```bash
# Copy wizard JavaScript
sudo cp test-wizard/wizard-functions.js /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
sudo chmod 644 /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js

# Copy backend PHP
sudo cp moode-source/www/command/room-correction-wizard.php /Volumes/rootfs/var/www/html/command/room-correction-wizard.php
sudo chmod 644 /Volumes/rootfs/var/www/html/command/room-correction-wizard.php

# Copy Python scripts (if they exist)
sudo cp moode-source/usr/local/bin/generate-camilladsp-eq.py /Volumes/rootfs/usr/local/bin/generate-camilladsp-eq.py 2>/dev/null || echo "generate-camilladsp-eq.py not found"
sudo chmod 755 /Volumes/rootfs/usr/local/bin/generate-camilladsp-eq.py 2>/dev/null || true

sudo cp moode-source/usr/local/bin/analyze-measurement.py /Volumes/rootfs/usr/local/bin/analyze-measurement.py 2>/dev/null || echo "analyze-measurement.py not found"
sudo chmod 755 /Volumes/rootfs/usr/local/bin/analyze-measurement.py 2>/dev/null || true
```

---

### **Step 3: Verify Files Copied**

```bash
ls -la /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
ls -la /Volumes/rootfs/var/www/html/command/room-correction-wizard.php
```

---

### **Step 4: Eject SD Card**

```bash
diskutil eject /dev/disk4
```

---

## 🎯 OR: Run All Commands at Once

Copy and paste this entire block:

```bash
sudo mkdir -p /Volumes/rootfs/var/www/html/test-wizard && \
sudo mkdir -p /Volumes/rootfs/var/www/html/command && \
sudo mkdir -p /Volumes/rootfs/var/www/html/templates && \
sudo mkdir -p /Volumes/rootfs/usr/local/bin && \
sudo cp test-wizard/wizard-functions.js /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js && \
sudo chmod 644 /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js && \
sudo cp moode-source/www/command/room-correction-wizard.php /Volumes/rootfs/var/www/html/command/room-correction-wizard.php && \
sudo chmod 644 /Volumes/rootfs/var/www/html/command/room-correction-wizard.php && \
echo "✅ Deployment complete!"
```

---

**After running these commands, eject SD card and boot Pi!**


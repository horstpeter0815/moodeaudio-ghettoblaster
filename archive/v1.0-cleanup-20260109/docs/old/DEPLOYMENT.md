# Room Correction Wizard - Deployment Guide

## Quick Deploy to moOde System

### Automatic Deployment

```bash
./deploy-to-moode.sh [moode-ip]
```

Default IP: `10.10.11.39`

Example:
```bash
./deploy-to-moode.sh 10.10.11.39
```

### Manual Deployment

#### 1. Copy Frontend Files

```bash
# Copy main HTML file
scp test-wizard/index-simple.html andre@10.10.11.39:/tmp/
ssh andre@10.10.11.39 "sudo mv /tmp/index-simple.html /var/www/html/index-simple.html"

# Copy wizard JavaScript
scp test-wizard/wizard-functions.js andre@10.10.11.39:/tmp/
ssh andre@10.10.11.39 "sudo mkdir -p /var/www/html/test-wizard && sudo mv /tmp/wizard-functions.js /var/www/html/test-wizard/"

# Copy wizard HTML template
scp test-wizard/snd-config.html andre@10.10.11.39:/tmp/
ssh andre@10.10.11.39 "sudo mv /tmp/snd-config.html /var/www/html/test-wizard/"
```

#### 2. Copy Backend File

```bash
scp moode-source/www/command/room-correction-wizard.php andre@10.10.11.39:/tmp/
ssh andre@10.10.11.39 "sudo mv /tmp/room-correction-wizard.php /var/www/html/command/room-correction-wizard.php"
```

#### 3. Set Permissions

```bash
ssh andre@10.10.11.39 "sudo chown -R www-data:www-data /var/www/html/index-simple.html /var/www/html/test-wizard /var/www/html/command/room-correction-wizard.php && sudo chmod 644 /var/www/html/index-simple.html /var/www/html/test-wizard/* /var/www/html/command/room-correction-wizard.php"
```

### Access the Wizard

After deployment, access at:
- **URL:** `https://10.10.11.39:8443/index-simple.html`

### Files Deployed

1. **Frontend:**
   - `/var/www/html/index-simple.html` - Main wizard page
   - `/var/www/html/test-wizard/wizard-functions.js` - Wizard JavaScript logic
   - `/var/www/html/test-wizard/snd-config.html` - Wizard HTML template

2. **Backend:**
   - `/var/www/html/command/room-correction-wizard.php` - Backend API handler

### Verification

After deployment, verify files exist:

```bash
ssh andre@10.10.11.39 "ls -la /var/www/html/index-simple.html /var/www/html/test-wizard/* /var/www/html/command/room-correction-wizard.php"
```

### Testing

1. Open browser: `https://10.10.11.39:8443/index-simple.html`
2. Click "Start Room Correction Wizard"
3. Go through steps:
   - Step 1: Preparation
   - Step 3: Pink noise measurement (should hear pink noise!)
   - Step 4: Use Step 3 measurement
   - Step 5: Generate filter (should actually apply!)
   - Step 6: Filter status (should show "Active" not "SIMULATED")

### Troubleshooting

**Pink noise not playing:**
- Check volume level (ALSA volume, not MPD)
- Check audio device: `ssh andre@10.10.11.39 "aplay -l"`
- Check pink noise process: `ssh andre@10.10.11.39 "ps aux | grep speaker-test"`

**Filters not applying:**
- Check CamillaDSP status: `ssh andre@10.10.11.39 "systemctl status camilladsp"`
- Check filter preset: `ssh andre@10.10.11.39 "ls -la /var/lib/camilladsp/configs/"`

**Permission errors:**
- Ensure files owned by `www-data:www-data`
- Check Apache error log: `ssh andre@10.10.11.39 "sudo tail -f /var/log/apache2/error.log"`


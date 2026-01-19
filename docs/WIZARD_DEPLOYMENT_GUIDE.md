# Room Correction Wizard - Deployment Guide

**Date:** 2026-01-18  
**Target:** Ghettoblaster Pi 5 (192.168.2.1)  
**Status:** Ready to deploy

## Quick Deployment

From your Mac terminal:

```bash
cd /Users/andrevollmer/moodeaudio-cursor
./tools/deploy-wizard-to-pi.sh
```

The script will:
1. ✅ Verify all wizard files exist locally
2. ✅ Copy PHP backend to Pi
3. ✅ Copy HTML template to Pi
4. ✅ Copy Python scripts to Pi
5. ✅ Create required directories
6. ✅ Set correct permissions
7. ✅ Verify Python dependencies
8. ✅ Verify deployment success

## What Gets Deployed

### Files Copied to Pi

| Local File | Pi Destination | Purpose |
|------------|----------------|---------|
| `moode-source/www/command/room-correction-wizard.php` | `/var/www/html/command/` | PHP backend API |
| `custom-components/templates/room-correction-wizard-modal.html` | `/var/www/html/templates/` | Wizard UI |
| `moode-source/usr/local/bin/generate-camilladsp-eq.py` | `/usr/local/bin/` | PEQ filter generator |
| `moode-source/usr/local/bin/analyze-measurement.py` | `/usr/local/bin/` | Measurement analyzer |

### Directories Created

- `/var/lib/camilladsp/measurements` - Store measurement files
- `/var/lib/camilladsp/convolution` - Store FIR filter files
- `/var/lib/camilladsp/configs` - CamillaDSP configurations

## Required Dependencies

The wizard needs these Python packages on the Pi:

- `python3-scipy` - Scientific computing
- `python3-numpy` - Numerical arrays
- `python3-soundfile` - WAV file handling

**The deployment script will check and offer to install missing packages!**

## Accessing the Wizard

### Option 1: Web Interface (Preferred)

1. Open: `http://192.168.2.1/`
2. Navigate to: **Audio → Sound Config**
3. Look for: **Room Correction** section
4. Click: **Run Wizard**

### Option 2: Direct API Test

Test the backend directly:

```bash
# From your Mac
curl http://192.168.2.1/command/room-correction-wizard.php \
  -d 'cmd=start_wizard'

# Expected response:
# {"status":"ok","step":1,"message":"Wizard started"}
```

## Wizard Features

### 6-Step Process

**Step 1: Preparation**
- Position smartphone at listening position
- Grant microphone permissions
- Reduce ambient noise

**Step 2: Ambient Noise Measurement**
- Measures background noise (5 seconds)
- Automatically subtracted from results

**Step 3: Continuous Measurement with Pink Noise**
- Pink noise plays continuously
- Web Audio API real-time measurement
- 2-3 second rolling average
- Click "Apply Correction" when satisfied

**Step 4: Upload Measurement (Optional)**
- Can upload WAV file instead
- Supports `audio/wav` format

**Step 5: Analysis & Filter Generation**
- Shows frequency response graph
- Target curve selection (flat or house curve)
- Generates PEQ filter (12 bands, CamillaDSP Biquad)

**Step 6: Apply & Test**
- Before/after comparison
- Applies filter via CamillaDSP
- A/B test available

### Technical Details

**Pink Noise:**
- Uses `sox` to generate continuous pink noise
- Stops MPD service to free audio device
- Uses ALSA device: `_audioout` (if CamillaDSP active) or `plughw:0,0`
- Volume controlled by system/ALSA volume

**Filter Generation:**
- Python script generates CamillaDSP YAML config
- Output: Biquad filters (12 bands)
- Location: `/var/lib/camilladsp/configs/`
- Naming: `room_correction_peq_YYYY-MM-DD_HH-MM-SS`

**Correction Limits:**
- Bass range (20-35 Hz): ±15 dB maximum
- All other frequencies: ±10 dB maximum

## Troubleshooting

### Deployment Issues

**If SSH fails:**
```bash
# Test SSH connection first
ssh andre@192.168.2.1

# If password doesn't work, try with key:
ssh -i ~/.ssh/id_rsa andre@192.168.2.1
```

**If files don't copy:**
- Check Pi has enough disk space: `df -h`
- Check permissions: `ls -la /var/www/html/command/`
- Check web server running: `systemctl status nginx`

### Wizard Runtime Issues

**Wizard doesn't appear in UI:**
1. Check file exists: `ls -la /var/www/html/command/room-correction-wizard.php`
2. Check web server permissions: `sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php`
3. Check PHP errors: `sudo tail -f /var/log/nginx/error.log`

**Python script errors:**
```bash
# Test Python dependencies
python3 -c "import scipy, numpy, soundfile; print('All OK')"

# If missing, install:
sudo apt-get update
sudo apt-get install -y python3-scipy python3-numpy python3-soundfile
```

**Pink noise doesn't play:**
```bash
# Check sox is installed
which sox

# Install if missing
sudo apt-get install -y sox

# Test pink noise manually
sox -n -t alsa default synth 10 pinknoise
```

**CamillaDSP not working:**
```bash
# Check CamillaDSP status
systemctl status camilladsp

# Check config directory
ls -la /var/lib/camilladsp/configs/

# Check permissions
sudo chown -R www-data:www-data /var/lib/camilladsp/
```

## Manual Deployment (If Script Fails)

If the automated script doesn't work, copy files manually:

```bash
# 1. Copy PHP backend
scp moode-source/www/command/room-correction-wizard.php andre@192.168.2.1:/tmp/
ssh andre@192.168.2.1 "sudo mv /tmp/room-correction-wizard.php /var/www/html/command/ && sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php"

# 2. Copy HTML template
scp custom-components/templates/room-correction-wizard-modal.html andre@192.168.2.1:/tmp/
ssh andre@192.168.2.1 "sudo mv /tmp/room-correction-wizard-modal.html /var/www/html/templates/ && sudo chown www-data:www-data /var/www/html/templates/room-correction-wizard-modal.html"

# 3. Copy Python scripts
scp moode-source/usr/local/bin/generate-camilladsp-eq.py andre@192.168.2.1:/tmp/
scp moode-source/usr/local/bin/analyze-measurement.py andre@192.168.2.1:/tmp/
ssh andre@192.168.2.1 "sudo mv /tmp/*.py /usr/local/bin/ && sudo chmod +x /usr/local/bin/*.py"

# 4. Create directories
ssh andre@192.168.2.1 "sudo mkdir -p /var/lib/camilladsp/{measurements,convolution,configs} && sudo chown -R www-data:www-data /var/lib/camilladsp/"
```

## Integration with moOde UI

To add a button in moOde's Sound Config page, you'll need to modify:

**File:** `/var/www/html/snd-config.php`

Add button in the appropriate section:

```html
<button class="btn btn-primary btn-large" onclick="$('#room-correction-wizard-modal').modal('show')">
    <i class="fa-solid fa-wand-magic-sparkles"></i> Run Room Correction Wizard
</button>
```

And include the modal at the bottom:

```php
<?php include 'templates/room-correction-wizard-modal.html'; ?>
```

## Verification Checklist

After deployment, verify:

- [ ] Files exist on Pi:
  ```bash
  ssh andre@192.168.2.1 "ls -la /var/www/html/command/room-correction-wizard.php"
  ssh andre@192.168.2.1 "ls -la /var/www/html/templates/room-correction-wizard-modal.html"
  ssh andre@192.168.2.1 "ls -la /usr/local/bin/generate-camilladsp-eq.py"
  ssh andre@192.168.2.1 "ls -la /usr/local/bin/analyze-measurement.py"
  ```

- [ ] Permissions correct (www-data owns files):
  ```bash
  ssh andre@192.168.2.1 "ls -la /var/www/html/command/ | grep room-correction"
  ```

- [ ] Python dependencies installed:
  ```bash
  ssh andre@192.168.2.1 "python3 -c 'import scipy, numpy, soundfile; print(\"OK\")'"
  ```

- [ ] Directories exist:
  ```bash
  ssh andre@192.168.2.1 "ls -la /var/lib/camilladsp/"
  ```

- [ ] API responds:
  ```bash
  curl http://192.168.2.1/command/room-correction-wizard.php -d 'cmd=start_wizard'
  ```

## Next Steps After Deployment

1. **Test the wizard** with a real measurement
2. **Create room correction preset** for your listening room
3. **Compare before/after** using A/B test
4. **Save working configuration** to GitHub

## Support Files

**Deployment script:** `/Users/andrevollmer/moodeaudio-cursor/tools/deploy-wizard-to-pi.sh`

**Source files:**
- PHP: `moode-source/www/command/room-correction-wizard.php`
- HTML: `custom-components/templates/room-correction-wizard-modal.html`
- Python: `moode-source/usr/local/bin/generate-camilladsp-eq.py`
- Python: `moode-source/usr/local/bin/analyze-measurement.py`

**Documentation:**
- Full guide: `rag-upload-files/v1.0-docs/v1.0_room_correction_wizard.md`
- Integration plan: `.cursor/plans/proper_moode_boot_fix_with_wizard_integration.plan.md`

---

**Status:** Ready to deploy! Run `./tools/deploy-wizard-to-pi.sh` to begin. 🚀

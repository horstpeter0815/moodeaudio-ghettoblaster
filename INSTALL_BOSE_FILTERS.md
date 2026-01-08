# Installing Bose Wave Filters to moOde

The Bose Wave filter configuration file needs to be copied to your running moOde system.

## Quick Installation

**On your moOde system**, run:

```bash
# Copy the config file
sudo cp /path/to/moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml /usr/share/camilladsp/configs/

# Set permissions
sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml
```

## Or use SCP/SFTP

If you're working from a different computer:

1. Copy the file from source:
   ```bash
   scp moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml pi@your-moode-ip:/tmp/
   ```

2. On moOde system:
   ```bash
   sudo mv /tmp/bose_wave_filters.yml /usr/share/camilladsp/configs/
   sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml
   ```

## Where to Find It

After installation, the filter will appear in:

1. **Audio Config** → **CamillaDSP** dropdown → Select "bose_wave_filters"
2. **CamillaDSP Config** page → **Signal processing** dropdown → Select "bose_wave_filters"

## Verify Installation

Check if the file is in the right place:
```bash
ls -la /usr/share/camilladsp/configs/bose_wave_filters.yml
```

You should see the file listed.

## Apply the Filter

1. Go to **Audio Config** or **CamillaDSP Config**
2. In the **Signal processing** dropdown, select **"bose_wave_filters"**
3. Click **Apply** or **Save**
4. The filter is now active!

## Troubleshooting

If you don't see the filter:
- Make sure the file is at `/usr/share/camilladsp/configs/bose_wave_filters.yml`
- Check file permissions: `ls -la /usr/share/camilladsp/configs/bose_wave_filters.yml`
- Refresh the moOde web interface
- Check that CamillaDSP is enabled in Audio Config


# Copy Bose Wave Filters to moOde System

## Step 1: Copy the file from your Mac to the moOde system (courage)

From your Mac terminal, run:

```bash
# Replace 'pi' and 'courage' with your actual username and hostname if different
scp moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml pi@courage:/tmp/bose_wave_filters.yml
```

## Step 2: SSH into your moOde system and move the file

```bash
# SSH into moOde system
ssh pi@courage

# Once connected to moOde, run:
sudo mv /tmp/bose_wave_filters.yml /usr/share/camilladsp/configs/
sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml

# Verify it's there
ls -la /usr/share/camilladsp/configs/bose_wave_filters.yml
ls -1 /usr/share/camilladsp/configs/*.yml | grep bose
```

## Step 3: Refresh the web interface

1. Go back to your moOde web interface
2. Refresh the page (F5 or Cmd+R)
3. Go to **Audio Config** → **CamillaDSP** dropdown
4. Or go to **CamillaDSP Config** → **Signal processing** dropdown
5. You should now see "bose_wave_filters" in the list


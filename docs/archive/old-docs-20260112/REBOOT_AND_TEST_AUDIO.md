# Reboot and Test Audio - v1.0

## What We Fixed

✅ **MPD Device Default:** Database now defaults to `_audioout` (not `'0'`)
✅ **Audio Chain Script:** Ensures MPD device stays `_audioout` 
✅ **Service Order:** `fix-audio-chain.service` runs BEFORE `mpd.service`
✅ **Radio Loading:** Removed debug logging timeouts

## Reboot the Pi

### Option 1: Via SSH
```bash
ssh andre@192.168.10.2
sudo reboot
```

### Option 2: Via Web UI
- Go to: System → Power → Reboot

## What Should Happen

1. **Boot sequence:**
   - `fix-audio-chain.service` runs (before MPD)
   - Detects AMP100 card
   - Sets up `_audioout.conf`
   - Ensures MPD device is `_audioout`
   - MPD starts with correct device

2. **After boot:**
   - Audio chain should be ready
   - MPD should use `_audioout`
   - Radio stations should load fast
   - Play button should work

## Verification Commands

After reboot, SSH in and run:

```bash
ssh andre@192.168.10.2

# 1. Check audio chain service ran
sudo journalctl -u fix-audio-chain.service --no-pager -n 30

# 2. Check MPD is running
sudo systemctl status mpd

# 3. Check MPD device (should be _audioout)
grep "device" /etc/mpd.conf | grep _audioout

# 4. Check MPD is responding
mpc status

# 5. Check audio output device
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_mpd WHERE param='device';"

# 6. Test audio playback
mpc play
mpc volume 50
```

## Expected Results

✅ **fix-audio-chain.service:** Should show "Audio Chain Fix Complete"
✅ **MPD status:** Should be "active (running)"
✅ **MPD config:** Should have `device "_audioout"`
✅ **MPC status:** Should respond without errors
✅ **Database:** Should show `_audioout` as device
✅ **Playback:** Should work when you press play

## If Audio Doesn't Work

1. **Check service logs:**
   ```bash
   sudo journalctl -u fix-audio-chain.service --no-pager
   sudo journalctl -u mpd.service --no-pager -n 50
   ```

2. **Check audio chain:**
   ```bash
   aplay -l  # Should show AMP100
   cat /etc/alsa/conf.d/_audioout.conf  # Should exist
   ```

3. **Manually restart MPD:**
   ```bash
   sudo systemctl restart mpd
   mpc status
   ```

## Summary

All fixes are in the source files:
- ✅ Database default fixed
- ✅ Audio chain script fixed  
- ✅ Service order correct
- ✅ Radio loading fixed

**After reboot, audio should work!** 🎵

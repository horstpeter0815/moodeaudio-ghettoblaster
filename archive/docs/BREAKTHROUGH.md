# BREAKTHROUGH: 1280x400 Mode Available!

## Status
✅ **Mode `1280x400` is now available in KMS!**

## What Worked
1. **Removed `disable_fw_kms_setup=1`** - This allows firmware to control KMS
2. **Used `hdmi_timings`** instead of `hdmi_cvt`
3. **Firmware recognizes `hdmi_timings`**: `hdmi_timings:0=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0`
4. **KMS now shows `1280x400` in available modes**

## Configuration That Works

```ini
[pi5]
hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
display_rotate=0
```

**Important:** `disable_fw_kms_setup=1` must be REMOVED (not set).

## Next Steps
1. ✅ Verify mode can be activated via xrandr
2. ⏳ Ensure mode activates automatically on boot
3. ⏳ Apply to Moode Audio
4. ⏳ Test touchscreen

## Key Learning
- **`hdmi_timings` works better than `hdmi_cvt` on Pi 5**
- **`disable_fw_kms_setup=1` prevents firmware from controlling KMS**
- **Without `disable_fw_kms_setup`, firmware can inject custom modes into KMS**


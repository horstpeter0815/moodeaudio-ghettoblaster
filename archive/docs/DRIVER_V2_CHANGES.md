# Panel Driver V2 - Robust Timing Improvements

**Installation Date:** 2025-11-25 15:40 CET  
**Version:** panel-waveshare-dsi.ko V2 (with timing fixes)

---

## Changes Made

### 1. Added 200ms Startup Delay

**Location:** `ws_panel_probe()` function, line ~483

**Code Change:**
```c
i2c_set_clientdata(i2c, ts);
ts->i2c = i2c;

/* Give the panel time to power up and stabilize before I2C communication */
msleep(200);  // ← NEW: 200ms delay

ws_panel_i2c_write(ts, 0xc0, 0x01);
ws_panel_i2c_write(ts, 0xc2, 0x01);
ws_panel_i2c_write(ts, 0xac, 0x01);
```

**Reason:** Panel needs time to power up and stabilize before accepting I2C commands. Without delay, I2C writes timeout (-110 ETIMEDOUT).

---

### 2. Added I2C Retry Logic

**Location:** `ws_panel_i2c_write()` function, line ~332

**Code Change:**
```c
static void ws_panel_i2c_write(struct ws_panel *ts, u8 reg, u8 val)
{
	int ret, retries = 3;  // ← NEW: 3 retry attempts

	while (retries--) {
		ret = i2c_smbus_write_byte_data(ts->i2c, reg, val);
		if (ret == 0)
			return; /* Success */
		
		/* Timeout or other error - wait and retry */
		if (retries > 0) {
			msleep(50);  // ← NEW: 50ms between retries
			dev_warn(&ts->i2c->dev, "I2C write failed: %d, retrying...\n", ret);
		}
	}
	
	/* All retries exhausted */
	dev_err(&ts->i2c->dev, "I2C write failed after retries: %d\n", ret);
}
```

**Reason:** 
- Robust error handling for transient I2C failures
- 3 attempts with 50ms delays give panel time to respond
- Total possible delay per write: 150ms (3 × 50ms)

---

## Total Boot Delay Added

- **Initial delay:** 200ms (one-time at probe)
- **Potential retry delays:** 450ms maximum (3 writes × 3 retries × 50ms)
- **Realistic delay:** 200-400ms total (retries usually not needed after initial delay)

**User preference:** Boot time is not critical - reliability is priority.

---

## Expected Results After Reboot

### ✓ Expected to work:
1. No more "I2C write failed: -110" errors
2. Panel initializes successfully
3. DSI-1 connector appears in `/sys/class/drm/`
4. Framebuffer `/dev/fb0` is created and persists
5. Display shows output at 1280x400

### ⚠ Still needs fixing:
1. Audio system (HiFiBerry) - separate issue
2. Kernel oops on module unload - component framework issue

---

## Rollback Instructions

If the new driver causes problems:

```bash
# Restore previous version
sudo cp /lib/modules/6.12.47+rpt-rpi-v8/kernel/drivers/gpu/drm/panel/panel-waveshare-dsi.ko.backup-v2 \
       /lib/modules/6.12.47+rpt-rpi-v8/kernel/drivers/gpu/drm/panel/panel-waveshare-dsi.ko

# Update dependencies
sudo depmod -a

# Reboot
sudo reboot
```

---

## Next Steps After Reboot

1. Check dmesg for I2C errors:
   ```bash
   dmesg | grep -i "i2c write"
   ```

2. Verify DSI-1 connector:
   ```bash
   ls -la /sys/class/drm/ | grep DSI
   ```

3. Check framebuffer:
   ```bash
   ls -la /dev/fb0
   cat /sys/class/graphics/fb0/virtual_size
   ```

4. Verify display mode:
   ```bash
   cat /sys/class/drm/card*-DSI-1/modes
   ```

5. Run audio/video test script again:
   ```bash
   sudo bash /tmp/audio_video_test.sh
   ```

---

## Technical Notes

### Dependency Cycle
The device tree shows a dependency cycle between DSI and Panel:
```
/soc/dsi@7e700000: Fixed dependency cycle(s) with /soc/i2c0mux/i2c@1/panel_disp1@45
```

This means DSI waits for Panel, and Panel waits for DSI. The 200ms delay allows this cycle to resolve gracefully.

### I2C Bus 10
- Bus 10 is `i2c-22-mux (chan_id 1)` - an I2C multiplexer
- Panel is at address 0x45 (shown as "UU" when bound)
- Touchscreen at 0x14 is disabled (correctly)

---

**Status:** Driver installed, awaiting reboot test.


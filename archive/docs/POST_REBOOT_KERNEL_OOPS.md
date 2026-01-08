# Kernel Oops nach gepatchtem Modul - Post-Reboot-Analyse

## Zeitstempel
2025-11-25 12:45 CET

## Problem
Nach dem Reboot mit dem gepatchten `panel-waveshare-dsi.ko` Modul tritt ein **Kernel Oops** auf.

## Symptome

### 1. Modul-Status
```
✓ Modul geladen: panel_waveshare_dsi (20480 bytes, -1 use count)
✗ Kein Driver an 0x45 gebunden
✗ DSI-1 nicht verfügbar
✗ Framebuffer nicht verfügbar
```

### 2. dmesg Errors

#### I2C Write Failed
```
[    7.903090] panel-waveshare-dsi 10-0045: I2C write failed: -110
[    8.927069] panel-waveshare-dsi 10-0045: I2C write failed: -110
[    9.951123] panel-waveshare-dsi 10-0045: I2C write failed: -110
```

**Error Code:** `-110` = `ETIMEDOUT` (I2C Timeout)

#### Kernel Oops
```
[   26.367742] Internal error: Oops: 0000000096000005 [#1] PREEMPT SMP
[   26.367750] Modules linked in: panel_waveshare_dsi(O-)...
[   26.367967] pc : vc4_hvs_unbind+0x20/0x160 [vc4]
```

**Fault Location:** `vc4_hvs_unbind+0x20/0x160`
**Module:** `vc4` (VideoCore 4 DRM Driver)
**Tainted:** `G C O` (Crap module, Out-of-tree module)

#### Call Stack
```
device_release_driver_internal+0x1d4/0x230
driver_detach+0x54/0xc0
bus_remove_driver+0x74/0xd0
driver_unregister+0x38/0x78
i2c_del_driver+0x5c/0x78
ws_panel_driver_exit+0x18/0x900 [panel_waveshare_dsi]
__arm64_sys_delete_module+0x1c8/0x2c0
```

## Root Cause Analysis

### Problem 1: I2C Communication Failure
- **Symptom:** I2C write to 0x45 times out (-110)
- **Possible Causes:**
  1. Panel is not powered
  2. I2C Bus 10 (DSI I2C) is not initialized
  3. DSI interface is not enabled/configured
  4. Hardware connection issue
  5. Timing issue (too early access)

### Problem 2: Kernel Oops on Module Exit
- **Symptom:** Crash in `vc4_hvs_unbind` when module is unloaded
- **Possible Causes:**
  1. Module cleanup code is incorrect
  2. DRM resources were not properly initialized
  3. vc4 driver tries to access freed memory
  4. Mismatch between probe() and remove() sequences

## Analysis

### Why does I2C fail?

1. **Timing Issue:**
   - Module loads at ~6.8s (`panel_waveshare_dsi: loading out-of-tree module taints kernel.`)
   - First I2C write fails at 7.9s
   - This is very early in the boot sequence
   - DSI interface might not be fully initialized yet

2. **DSI Not Configured:**
   - `DSI-1 nicht verfügbar` in sysfs
   - This suggests the DRM/DSI subsystem never created the DSI-1 device
   - Without DSI-1, the panel driver can't communicate

3. **Power Sequence:**
   - Panel might need explicit power-on sequence
   - Backlight or regulator might not be enabled

### Why does the Kernel Oops happen?

The call stack shows:
```
ws_panel_driver_exit -> i2c_del_driver -> ... -> vc4_hvs_unbind
```

This is **wrong**. When an I2C driver exits, it should NOT trigger `vc4_hvs_unbind`.

**Hypothesis:**
- Our patched driver might have incorrectly modified the DRM panel registration
- When the driver exits (after I2C probe failed), it tries to unbind DRM resources
- But those resources were never properly initialized (because probe failed)
- This causes a NULL pointer dereference in `vc4_hvs_unbind`

## Comparison: Original vs. Patched Driver

### Original Driver Issues
- `ws_touchscreen` binds to 0x45 (panel address) instead of panel driver
- Panel never initializes

### Patched Driver Issues
- Driver loads and attempts I2C communication
- I2C times out (hardware/timing issue)
- Driver cleanup causes Kernel Oops
- **Worse than original!**

## Conclusion

The patch successfully changed the driver name from `ws_touchscreen` to `panel-waveshare-dsi`, but:

1. **I2C Communication still fails** (same -110 timeout as before)
2. **Kernel Oops is NEW** - our patch introduced a crash

This suggests:
- The root problem is NOT the driver name
- The root problem is **I2C Bus 10 not being initialized** or **DSI interface not configured**
- The original driver had the same I2C issue, but handled errors more gracefully
- Our patch might have broken error handling in the exit path

## Next Steps

### Option A: Fix the Kernel Oops
- Review the patch's exit/cleanup code
- Ensure proper error handling in probe()
- Add NULL checks before DRM resource cleanup

### Option B: Fix the Root Cause (I2C/DSI)
- Investigate why DSI-1 is not created
- Check Device Tree Overlay loading
- Verify I2C Bus 10 initialization sequence
- Add delays/waits for DSI readiness

### Option C: Try Original Driver with Different Approach
- Revert to original driver
- Focus on config.txt/DT Overlay
- Try different DSI initialization parameters
- Check if display needs manual power-on

## Recommended Action

**Revert the patched driver** and focus on why DSI-1 is not being created by the Device Tree Overlay.

The driver can't work if:
- DSI-1 device doesn't exist
- I2C Bus 10 can't communicate with panel
- Hardware is not properly initialized

We need to solve the hardware/DT initialization problem BEFORE modifying the driver.


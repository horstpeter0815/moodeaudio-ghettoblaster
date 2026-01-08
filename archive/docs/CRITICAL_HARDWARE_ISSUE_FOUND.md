# CRITICAL HARDWARE ISSUE - NO COMMON GROUND

**Discovered:** 2025-11-25 15:52 CET  
**Issue:** Panel and Raspberry Pi have SEPARATE power supplies with NO common ground

---

## Problem Analysis

### I2C Communication Requirements

I2C (Inter-Integrated Circuit) is a **single-ended signaling protocol** that requires:
1. **SDA (Data line)** - pulled up to VCC
2. **SCL (Clock line)** - pulled up to VCC  
3. **COMMON GROUND** ← **MISSING!**

Without a common ground reference, the voltage levels on SDA and SCL cannot be interpreted correctly by either device.

### Symptoms Explained

All observed symptoms now make perfect sense:

✓ **Panel device appears in system:**
- Device tree creates I2C device at 10-0045
- Driver binds successfully (shows "UU" in i2cdetect)
- Backlight device created

✗ **But I2C communication fails:**
- Every I2C write returns `-110` (ETIMEDOUT)
- Panel never responds
- Thousands of timeouts during boot

**Why:** Without common ground, the electrical signals cannot be properly transmitted.

---

## DSI Cable Ground Pins

### Standard DSI-1 Interface (15-pin)

Typical DSI cable pinout:
```
Pin 1:  GND          ← Ground
Pin 2:  DSI_D0-      Data lane 0 negative
Pin 3:  DSI_D0+      Data lane 0 positive
Pin 4:  GND          ← Ground
Pin 5:  DSI_D1-      Data lane 1 negative
Pin 6:  DSI_D1+      Data lane 1 positive
Pin 7:  GND          ← Ground
Pin 8:  DSI_CLK-     Clock negative
Pin 9:  DSI_CLK+     Clock positive
Pin 10: GND          ← Ground
Pin 11: DSI_D2- (if 4-lane)
Pin 12: DSI_D2+ (if 4-lane)
Pin 13: GND          ← Ground (if 4-lane)
Pin 14: DSI_D3- (if 4-lane)
Pin 15: DSI_D3+ (if 4-lane)
```

**Multiple ground pins are present in DSI cable!**

### I2C Pins on DSI Connector

The DSI connector on Raspberry Pi 4 also includes:
- **SDA** (I2C data)
- **SCL** (I2C clock)
- **GND** (Ground) ← Should provide common ground

---

## Why Ground Connection Might Be Broken

### Possible Causes:

1. **Faulty DSI cable**
   - Ground wire broken internally
   - Poor connection at connector

2. **Panel design issue**
   - Panel's ground isolated from DSI ground
   - Separate ground plane for panel electronics

3. **Improper cable seating**
   - Connector not fully inserted
   - Pins not making contact

4. **Waveshare design**
   - Intentional isolation (unlikely but possible)
   - Missing ground connection in panel PCB

---

## Diagnostic Steps

### Step 1: Verify DSI Cable Connection

```bash
# Power off both devices
# Re-seat DSI cable on both ends:
#   - Pi side: DSI-1 connector
#   - Panel side: connector on panel PCB
# Ensure connectors click firmly into place
```

### Step 2: Measure Ground Continuity

With **both devices powered OFF**:

```
Using multimeter in continuity mode:
1. Touch one probe to Pi GPIO ground (Pin 6, 9, 14, 20, 25, 30, 34, or 39)
2. Touch other probe to panel ground (check panel PCB for GND pad)
3. Should hear beep if ground connection exists
```

**If NO continuity:** Ground is not connected!

### Step 3: Manual Ground Connection

If DSI cable doesn't provide ground:

```
Connect a wire between:
- Pi Ground (any GPIO GND pin)
- Panel Ground (GND pad on panel or power supply GND)
```

---

## Expected Results After Ground Fix

Once common ground is established:

✓ I2C communication will work immediately
✓ No more `-110` (ETIMEDOUT) errors
✓ Panel initialization succeeds
✓ Display shows output
✓ DSI-1 connector appears with modes
✓ Framebuffer `/dev/fb0` is accessible

---

## Alternative: Check Panel Power Supply

### Verify Panel is Powered

The panel needs:
1. **DSI signal from Pi** (for display data)
2. **Separate power supply** (for panel electronics)
3. **Common ground** (for signal reference)

Check:
- Is panel power supply ON?
- Is power supply voltage correct (usually 5V or 12V)?
- Is power supply connected to panel?

---

## Waveshare 7.9" Specific Notes

From Waveshare documentation, the 7.9" panel typically requires:
- **Input:** 5V/2A (panel power)
- **DSI connection:** To Pi DSI-1 port
- **I2C:** Uses I2C_CSI_DSI (Bus 10) at address 0x45

The panel **should** get ground through DSI cable, but if using separate power supply without shared ground, this creates the exact problem we're seeing.

---

## Immediate Actions Required

1. **Check DSI cable connection** - re-seat both ends
2. **Verify continuity** between Pi GND and Panel GND
3. **If no continuity:** Add external ground wire
4. **Test I2C** after ground connection:
   ```bash
   i2cdetect -y 10
   # Should show address 0x45 (not UU)
   ```

5. **Reboot and check** for I2C errors:
   ```bash
   dmesg | grep "I2C write"
   # Should be NO errors
   ```

---

## Why All Other Symptoms Appeared Normal

- **Panel driver loads:** Yes - no ground needed for driver to load
- **I2C device created:** Yes - device tree creates it regardless
- **Driver binds:** Yes - binding happens before communication
- **Backlight device:** Yes - created during probe
- **vc4 initializes:** Yes - independent of panel I2C
- **DSI interface ready:** Yes - but no data reaches panel without ground

**Everything appears correct EXCEPT actual electrical communication.**

---

## Technical Background: Single-Ended vs Differential

### DSI Data Transmission (works without common ground)
- **Differential signaling** (DSI_D0+/DSI_D0-)
- Ground not strictly required for data
- Voltage difference between + and - carries signal

### I2C Transmission (REQUIRES common ground)
- **Single-ended signaling** (SDA, SCL)
- Voltages measured relative to ground
- Without common ground reference, no reliable communication

This is why:
- DSI might partially work (some initialization)
- But I2C completely fails (panel control)

---

## Conclusion

**The missing common ground between Pi and Panel is the root cause of all I2C timeout errors.**

All driver improvements (timing, retries, reordering) cannot solve a fundamental electrical connection problem.

**Fix the hardware ground connection first, then all software will work correctly.**

---

**Status:** Awaiting hardware ground verification and fix.


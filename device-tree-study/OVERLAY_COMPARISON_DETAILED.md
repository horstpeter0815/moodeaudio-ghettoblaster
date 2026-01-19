# Device Tree Overlay Comparison: Custom vs Upstream

**Date:** 2026-01-18
**Purpose:** Detailed line-by-line comparison of custom Ghettoblaster overlays vs upstream Raspberry Pi overlays

## Executive Summary

This document provides detailed diff analysis showing:
1. **What changed** - Specific line-by-line differences
2. **Why it changed** - Rationale for customization
3. **Is it necessary** - Can we use stock overlays instead?

## Comparison 1: HiFiBerry AMP100

### Files Compared

| Version | File | Lines | Compatible |
|---------|------|-------|------------|
| **Upstream** | `hifiberry-dacplus-overlay.dts` | 68 | All Pi models (bcm2835) |
| **Custom Simple** | `ghettoblaster-amp100.dts` | 35 | Pi 5 only (bcm2712) |
| **Custom Full** | `hifiberry-amp100-pi5-dsp-reset.dts` | 71 | Pi 5 only (bcm2712) |
| **Custom GPIO14** | `hifiberry-amp100-pi5-gpio14-active-low.dts` | 73 | Pi 5 only (bcm2712) |
| **Custom GPIO4+17** | `hifiberry-amp100-pi5-overlay.dts` | 72 | Pi 5 only (bcm2712) |
| **Unified** | `ghettoblaster-unified.dts` | 106 | Pi 5 only (bcm2712) |

### Diff Analysis: Upstream vs Custom Simple

#### Change 1: Compatible String

**Upstream:**
```dts
/ {
    compatible = "brcm,bcm2835";  // Works on all Pi models
}
```

**Custom:**
```dts
/ {
    compatible = "brcm,bcm2712";  // Pi 5 only
}
```

**Why:** Pi 5 uses different SoC (BCM2712 vs BCM2835/2711). Setting `brcm,bcm2712` ensures overlay only loads on Pi 5.

**Necessary?** NO - Upstream overlay uses `__fixups__` that resolve correctly on all Pi models including Pi 5.

**Recommendation:** Use upstream overlay.

#### Change 2: I2S Controller Targeting

**Upstream:**
```dts
frag1: fragment@1 {
    target = <&i2s_clk_consumer>;  // Symbolic reference
    __overlay__ {
        status = "okay";
    };
};

// Later resolved via __fixups__ to actual hardware path
```

**Custom:**
```dts
fragment@1 {
    target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";  // Explicit path
    __overlay__ {
        status = "okay";
    };
}
```

**Why:** Direct hardware path targeting, no symbolic resolution needed.

**Necessary?** NO - Symbolic reference works fine and is more portable.

**Advantage of upstream:** Works across Pi models without modification.

#### Change 3: Sound Node Creation

**Upstream:**
```dts
fragment@3 {
    target = <&sound>;  // Target existing sound node
    hifiberry_dacplus: __overlay__ {
        compatible = "hifiberry,hifiberry-dacplus";
        i2s-controller = <&i2s_clk_consumer>;
        status = "okay";
    };
};
```

**Custom:**
```dts
fragment@1 {
    target = <&i2s>;  // Different reference
    __overlay__ {
        compatible = "hifiberry,hifiberry-amp";  // Different compatible string
        i2s-controller = <&i2s>;
        status = "okay";
    };
};
```

**Why:** Custom uses different compatible string (`hifiberry-amp` vs `hifiberry-dacplus`).

**Necessary?** NO - Both AMP100 and DAC+ use same PCM5122 chip, same driver. `hifiberry-dacplus` driver works fine.

#### Change 4: Removed Headphone Amplifier Support

**Upstream includes:**
```dts
hpamp: hpamp@60 {
    compatible = "ti,tpa6130a2";
    reg = <0x60>;
    status = "disabled";
};
```

**Custom:** Removed entirely

**Why:** AMP100 has no headphone output (unlike DAC+ Pro).

**Necessary?** NO - It's disabled by default anyway, doesn't hurt to keep it.

#### Change 5: Removed __overrides__ Section

**Upstream has:**
```dts
__overrides__ {
    24db_digital_gain = <&hifiberry_dacplus>,"hifiberry,24db_digital_gain?";
    slave = <&hifiberry_dacplus>,"hifiberry-dacplus,slave?", ...;
    leds_off = <&hifiberry_dacplus>,"hifiberry-dacplus,leds_off?";
};
```

**Custom:** No `__overrides__` section

**Why:** Simpler, but loses parameter configurability.

**Necessary?** NO - Parameters are useful (especially 24db_digital_gain).

**Impact:** Can't use `dtoverlay=hifiberry-amp100,24db_digital_gain` with simple custom version.

### Diff Analysis: Custom Full vs Upstream

#### Addition 1: auto_mute Parameter

**Custom adds:**
```dts
__overrides__ {
    auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
    24db_digital_gain = <&sound>,"hifiberry,24db_digital_gain?";
    leds_off = <&sound>,"hifiberry-dacplus,leds_off?";
    mute_ext_ctl = <&sound>,"hifiberry-dacplus,mute_ext_ctl:0";
};
```

**Why:** Adds auto-mute functionality (mute amplifier on silence).

**Necessary?** YES - This is useful functionality not in upstream.

**Trade-off:** Must maintain custom overlay instead of using upstream.

#### Addition 2: Explicit Pi 5 Paths

**Custom uses:**
```dts
target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";
target-path = "/axi";
```

**Why:** Explicit targeting for Pi 5 hardware.

**Necessary?** NO - Symbolic references work fine.

#### Addition 3: Sound Node Creation

**Custom creates sound node:**
```dts
fragment@3 {
    target-path = "/axi";
    __overlay__ {
        sound {
            compatible = "hifiberry,hifiberry-dacplus";
            i2s-controller = <&i2s_a4000>;
            status = "okay";
        };
    };
};
```

**Upstream expects existing sound node:**
```dts
fragment@3 {
    target = <&sound>;  // Expects sound node to exist
    ...
};
```

**Why:** On Pi 5, sound node location might differ.

**Necessary?** Possibly - if Pi 5 base device tree doesn't have sound node in expected location.

### Diff Analysis: GPIO Variants

#### hifiberry-amp100-pi5-gpio14-active-low.dts

**Addition:**
```dts
reset-gpio = <&gpio 14 1>;  // GPIO 14, Active Low (flag 1)
```

**Purpose:** DSP reset control via GPIO 14.

**Issue:** GPIO 14 conflicts can occur with other uses.

**Recommendation:** Avoid unless DSP reset is essential.

#### hifiberry-amp100-pi5-overlay.dts

**Additions:**
```dts
mute-gpio = <&gpio 4 0>;
reset-gpio = <&gpio 17 0x11>;
```

**Purpose:** Both mute and reset GPIO control.

**Issue:** Uses two GPIOs, must verify no conflicts.

**Recommendation:** Only use if hardware requires these GPIOs.

### Diff Analysis: Unified Overlay

#### ghettoblaster-unified.dts

**Combines:** AMP100 + FT6236 touch in single overlay

**Structure:**
```dts
fragment@2 {
    target = <&i2c1>;
    __overlay__ {
        clock-frequency = <100000>;  // Stable 100kHz I2C
        
        pcm5122@4d { ... }   // DAC
        ft6236@38 { ... }    // Touch
    };
};
```

**Advantages:**
- Single overlay for both devices
- Guaranteed I2C stability (100kHz for both)
- No GPIO conflicts (no reset-gpio)

**Disadvantages:**
- Less modular (can't disable touch separately)
- Custom maintenance required

**Recommendation:** Use if touch overlay causes issues separately.

## Comparison 2: vc4-kms Display

### Files Compared

| Version | File | Lines | Compatible |
|---------|------|-------|------------|
| **Pi 4 Upstream** | `vc4-kms-v3d-overlay.dts` | 121 | Pi 4 and earlier |
| **Pi 5 Upstream** | `vc4-kms-v3d-pi5-overlay.dts` | 147 | Pi 5 only |

### Key Differences: Pi 4 vs Pi 5

#### Change 1: Compatible String

**Pi 4:**
```dts
compatible = "brcm,bcm2835";
```

**Pi 5:**
```dts
compatible = "brcm,bcm2712";
```

**Why:** Different SoC architecture.

**Necessary?** YES - Must use Pi 5 version on Pi 5.

#### Change 2: HDMI Controller Structure

**Pi 4:**
```dts
fragment@7 {
    target = <&hdmi>;  // Single HDMI port
    __overlay__ {
        status = "okay";
    };
};
```

**Pi 5:**
```dts
fragment@5 {
    target = <&hdmi0>;  // HDMI port 0
    __overlay__ {
        status = "okay";
    };
};

fragment@6 {
    target = <&hdmi1>;  // HDMI port 1
    __overlay__ {
        status = "okay";
    };
};
```

**Why:** Pi 5 has two HDMI ports, Pi 4 has one.

**Necessary?** YES - Hardware difference.

#### Change 3: Audio Parameters

**Pi 4:**
```dts
__overrides__ {
    audio   = <0>,"!13";
    noaudio = <0>,"=13";
};
```

**Pi 5:**
```dts
__overrides__ {
    audio   = <0>,"!14";        // HDMI0 audio
    audio1  = <0>,"!15";        // HDMI1 audio
    noaudio = <0>,"=14", <0>,"=15";  // Both off
};
```

**Why:** Separate audio control per HDMI port on Pi 5.

**Necessary?** YES - Hardware difference.

#### Change 4: IOMMU Support

**Pi 5 adds:**
```dts
fragment@17 {
    target = <&vc4>;
    __overlay__ {
        iommus = <&iommu4>;
    };
};
```

**Why:** Pi 5 has enhanced IOMMU support for better memory management.

**Necessary?** YES - Pi 5 hardware feature.

### Conclusion: Display Overlay

**MUST use `vc4-kms-v3d-pi5` on Pi 5** - not optional, hardware is different.

## Comparison 3: Touch Controller

### FT6236 Touch Overlay

**File:** `ghettoblaster-ft6236.dts` (35 lines)

**Status:** Custom only, no upstream equivalent.

**Structure:**
```dts
fragment@0 {
    target = <&i2c1>;
    __overlay__ {
        ft6236@38 {
            compatible = "focaltech,ft6236";
            reg = <0x38>;
            interrupt-parent = <&gpio>;
            interrupts = <25 2>;
            touchscreen-size-x = <1280>;
            touchscreen-size-y = <400>;
            touchscreen-inverted-x;
            touchscreen-inverted-y;
            touchscreen-swapped-x-y;
        };
    };
};
```

**Parameters:** None (all hardcoded)

**Necessary?** Possibly not - kernel may have built-in FT6236 support that auto-detects.

**Why not loaded in v1.0 config?** Touch works without it, suggesting kernel handles it.

## Summary Table: What to Use

| Component | Use This | Why |
|-----------|----------|-----|
| **Audio (basic)** | Upstream `hifiberry-dacplus` | Standard, maintained, has parameters |
| **Audio (with auto-mute)** | Custom `hifiberry-amp100-pi5-dsp-reset` | Adds auto_mute parameter |
| **Audio (unified)** | Custom `ghettoblaster-unified` | Audio + touch, stable I2C |
| **Display** | Upstream `vc4-kms-v3d-pi5` | REQUIRED for Pi 5 |
| **Touch** | None (works without overlay) | Kernel handles it |

## Detailed Recommendations

### Recommendation 1: Use Upstream HiFiBerry (Simplest)

**config.txt:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-dacplus
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Pros:**
- Standard upstream overlays
- Well maintained
- Parameters available (24db_digital_gain, slave, leds_off)
- Works on v1.0 working config

**Cons:**
- No auto_mute parameter
- No custom GPIO control

**When to use:** Default choice, proven working.

### Recommendation 2: Custom with Auto-Mute

**config.txt:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Pros:**
- Auto-mute on silence (reduces noise, saves power)
- Has parameters (24db_digital_gain, leds_off, mute_ext_ctl, auto_mute)
- Pi 5 optimized

**Cons:**
- Custom overlay (must maintain)
- Explicit Pi 5 paths (less portable)

**When to use:** When auto-mute is desired.

### Recommendation 3: Unified Overlay

**config.txt:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=ghettoblaster-unified,auto_mute
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Pros:**
- Single overlay for audio + touch
- Stable I2C (100kHz)
- Auto-mute support
- No GPIO conflicts

**Cons:**
- Custom overlay (must maintain)
- Less modular
- If touch has issues, affects audio too

**When to use:** When loading separate overlays causes conflicts.

## Why Custom Overlays Were Created

### Reason 1: Auto-Mute Feature

**Upstream doesn't have:** `auto_mute` parameter

**Why added:** Reduces noise and power consumption when audio is silent.

**Implementation:**
```dts
auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
```

**Value:** Quality of life improvement for amplifier.

### Reason 2: Pi 5 Explicit Paths

**Upstream uses:** Symbolic references (`<&i2s_clk_consumer>`)

**Custom uses:** Explicit paths (`/axi/pcie@1000120000/rp1/i2s@a4000`)

**Why:** Guarantee correct hardware targeting on Pi 5.

**Value:** Minimal - symbolic references work fine.

### Reason 3: I2C Clock Stability

**Unified overlay sets:**
```dts
clock-frequency = <100000>;  // 100kHz
```

**Why:** Some I2C devices (especially touch) are unstable at default 100kHz+.

**Value:** Ensures stable I2C communication.

### Reason 4: GPIO Control

**Some variants add:**
```dts
reset-gpio = <&gpio 14 1>;
mute-gpio = <&gpio 4 0>;
```

**Why:** Hardware control of DSP reset and amplifier mute.

**Value:** Depends on hardware requirements.

## Can We Use Stock Overlays?

### Answer: YES (Mostly)

**Evidence:** v1.0 working config uses stock overlays:
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100  # This is actually hifiberry-dacplus
```

**Proves:** Stock overlays are sufficient for basic operation.

**Trade-offs:**
- ✅ Use stock: Standard, maintained, proven working
- ✅ Use custom: Auto-mute, explicit control, I2C stability guarantee

## Migration Path

### From Custom to Stock

If using custom overlays and want to switch to stock:

1. **Backup current config:**
   ```bash
   sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
   ```

2. **Edit config.txt:**
   ```ini
   # Change from:
   dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute
   
   # To:
   dtoverlay=hifiberry-dacplus
   ```

3. **Reboot and test:**
   ```bash
   sudo reboot
   ```

4. **Verify:**
   ```bash
   i2cdetect -y 1  # Should show 0x4d
   aplay -l        # Should show HiFiBerry card
   ```

### From Stock to Custom

If using stock and want custom features (auto-mute):

1. **Compile custom overlay:**
   ```bash
   dtc -@ -I dts -O dtb -o hifiberry-amp100-pi5.dtbo hifiberry-amp100-pi5-dsp-reset.dts
   sudo cp hifiberry-amp100-pi5.dtbo /boot/firmware/overlays/
   ```

2. **Edit config.txt:**
   ```ini
   # Change from:
   dtoverlay=hifiberry-dacplus
   
   # To:
   dtoverlay=hifiberry-amp100-pi5,auto_mute
   ```

3. **Reboot and test**

## Maintenance Implications

### Using Upstream Overlays

**Maintenance:** None - Raspberry Pi Foundation maintains them

**Updates:** Automatic via `apt upgrade`

**Risk:** Low - widely tested

### Using Custom Overlays

**Maintenance:** Your responsibility

**Updates:** Must manually update when:
- Pi firmware changes device tree structure
- Kernel changes driver requirements
- New features needed

**Risk:** Medium - less testing, potential breakage on updates

## Conclusion

### Key Findings

1. **Upstream overlays work fine** on Pi 5 (proven by v1.0 working config)
2. **Custom overlays add features** (auto_mute) but require maintenance
3. **Explicit Pi 5 paths unnecessary** - symbolic references work
4. **Touch overlay not needed** - kernel handles it
5. **Pi 5 display overlay required** - vc4-kms-v3d-pi5 (not v3d)

### Best Practice

**Start with upstream overlays:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-dacplus
```

**Only use custom if:**
- You need auto_mute feature
- You experience I2C stability issues
- You need specific GPIO control

### Documentation Value

This comparison enables:
- ✅ Informed decisions about overlay choice
- ✅ Understanding trade-offs
- ✅ Migration paths in either direction
- ✅ Maintenance planning

**Status:** Phase 3 Complete - Detailed comparison documented

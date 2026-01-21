# Bose Wave Architecture - Physical Layout Clarification

## ❓ User Question: "Both speakers have a channel system, but only one is used?"

---

## 🔍 ACTUAL BOSE WAVE ARCHITECTURE

### Physical Layout (From 3D Scan)

```
┌─────────────────────────────────────────────────────┐
│  Bose Wave Radio - Internal View                     │
├─────────────────────────────────────────────────────┤
│                                                       │
│  LEFT DRIVER (10 cm)        RIGHT DRIVER (10 cm)    │
│       ↓                           ↓                  │
│   [Waveguide]              [Direct to Room]          │
│       ↓                           ↓                  │
│  ┌─────────────────┐         Direct Sound           │
│  │  3.98m Folded   │         (No Waveguide)         │
│  │  Waveguide Path │                                 │
│  │                 │                                 │
│  │  Entry: 6.5×6.5 │                                 │
│  │  Exit:  8×8     │                                 │
│  └─────────────────┘                                 │
│         ↓                                            │
│    Exit Port → Room                                  │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## ✅ ANSWER: Only ONE Driver Uses the Waveguide!

### The Two-Driver System:

**LEFT DRIVER (Bass Channel):**
- Fires INTO the 3.98m waveguide channel
- Waveguide amplifies 70-300 Hz naturally
- Exit port on side/front of unit
- This is the "bright magenta channel" you see in the 3D scan

**RIGHT DRIVER (Mids/Highs Channel):**
- Fires DIRECTLY into the room (no waveguide!)
- Handles 300 Hz - 20 kHz
- Direct radiation = better clarity for high frequencies
- No channel system needed

---

## 🤔 Why Not Both Drivers in Waveguides?

Good question! Here's why Bose designed it this way:

### Physics of Sound:

**Low Frequencies (Bass) - BENEFIT from waveguides:**
```
80 Hz wavelength = 4.29 meters (LONG!)
- Long path needed for resonance
- Horn loading increases efficiency
- Waveguide matches impedance
- Result: +9 dB natural amplification!
```

**High Frequencies (Mids/Highs) - DON'T benefit from waveguides:**
```
3000 Hz wavelength = 11.4 cm (SHORT!)
- Waveguide would cause phase issues
- Direct radiation = better dispersion
- Lower distortion
- Clearer sound
```

### Bose's Clever Design:

1. **One driver** handles bass (needs waveguide help)
2. **Other driver** handles mids/highs (works better direct)
3. **Result:** Best of both worlds!

---

## 📊 What You See in the 3D Scan

**The "bright magenta channel"** in your Blender model is:
- **ONE waveguide path** (3.98 meters folded)
- Connected to **LEFT driver only**
- Right driver has **NO channel** (fires direct)

**If you look closely at the physical Bose Wave:**
- One side has an **exit port** (waveguide output)
- Other side is **direct driver** (no port)

---

## 🎵 How the DSP Splits the Signal

### Signal Flow:

```
Audio Input (Stereo L+R)
         ↓
    [Sum to Mono]  ← Both channels mixed
         ↓
    ┌────┴────┐
    ↓         ↓
  Bass    Mids/Highs
  (70-300 Hz) (300Hz-20kHz)
    ↓         ↓
Left Driver  Right Driver
    ↓         ↓
 Waveguide   Direct
    ↓         ↓
    Room      Room
```

**Key Point:** 
- Both drivers get the SAME mono signal
- DSP splits by FREQUENCY (not left/right stereo!)
- Left driver → bass via waveguide
- Right driver → mids/highs direct

---

## 🔧 Current CamillaDSP Configuration

### What the DSP Does:

```yaml
# Step 1: Sum stereo to mono (L+R → Mono)
mixer: stereo_to_dual_mono
  - Bass output: (L + R) / 2
  - Mids output: (L + R) / 2

# Step 2: Filter by frequency
Bass channel (Left driver):
  - Lowpass @ 300 Hz
  - Boost @ 80 Hz (+9 dB)
  - Protect below 50 Hz

Mids channel (Right driver):
  - Highpass @ 300 Hz
  - Presence @ 3.5 kHz
  - Smooth highs @ 10 kHz
```

---

## 💡 Why This Design is Genius

### Bose Wave Advantages:

1. **Compact Size**
   - Folded waveguide fits in small cabinet
   - Deep bass from tiny enclosure

2. **Efficiency**
   - Horn loading = more output per watt
   - Small drivers produce big sound

3. **Clarity**
   - Bass through waveguide (efficient)
   - Highs direct (clear, low distortion)

4. **Simplicity**
   - Only ONE waveguide needed
   - Less complex than dual waveguides

---

## 🎯 Summary: Your Bose Wave Has...

✅ **Two drivers** (10 cm each, 3.5Ω)  
✅ **ONE waveguide** (3.98m path, for bass)  
✅ **Left driver** → waveguide → bass (70-300 Hz)  
✅ **Right driver** → direct → mids/highs (300Hz-20kHz)  
❌ **NO second waveguide** (not needed for highs!)

---

## 🔍 How to Verify This on Your Unit

### Physical Inspection:

1. **Look at the front/side of your Bose Wave**
2. **Find the EXIT PORT** (8×8 cm opening) - this is the waveguide output
3. **This port is on ONE SIDE ONLY** (not both!)
4. **Other driver fires through grill directly** (no port)

### Audio Test:

```bash
# Test bass channel (waveguide)
# Play 80 Hz tone → Should sound LOUD and punchy
# This is the waveguide resonance!

# Test mids channel (direct)
# Play 3 kHz tone → Should sound clear and direct
# This is the direct driver
```

---

## 📐 If You Want to See the 3D Model

```bash
# On your Mac Desktop:
cd "/Users/andrevollmer/Desktop/Blender/cursor"
open "waveguide_VISIBLE_CHANNEL.blend"

# In Blender you'll see:
# - Wireframe housing (see-through)
# - BRIGHT MAGENTA channel (the waveguide!)
# - Green entry port (left driver connection)
# - Orange exit port (waveguide output)
# - Red driver mount

# Note: Only ONE channel visible (not two!)
```

---

## ✅ Final Answer

**Both speakers are PHYSICAL drivers, but only ONE has a WAVEGUIDE CHANNEL.**

- **Left driver:** Bass via waveguide (channel system)
- **Right driver:** Mids/highs direct (no channel)

**Your DSP configuration correctly uses:**
- Left output → Bass (waveguide)
- Right output → Mids/Highs (direct)

**This is exactly how Bose designed it!**

The physics-optimized config I created exploits this:
- Boosts 80 Hz (waveguide resonance)
- Protects bass driver below 50 Hz
- Enhances presence on direct driver @ 3.5 kHz

**You're using the system exactly as designed!** 🎵

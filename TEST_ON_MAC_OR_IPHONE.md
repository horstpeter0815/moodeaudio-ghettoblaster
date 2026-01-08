# 🧪 Test on Mac or iPhone?

## Current Test Environment

**URL:** `http://localhost:8080`  
**Protocol:** HTTP (not HTTPS)  
**Access:** Only from your Mac (localhost)

---

## ✅ Recommendation: Test on Mac FIRST

### Why Mac First?
1. **Easier Debugging** - Browser DevTools (F12) is easier to use
2. **HTTP Works** - Localhost HTTP usually allows microphone access
3. **Faster Iteration** - No network delays
4. **Better Console** - See errors immediately

### How to Test on Mac:

1. **Open Browser** (Safari or Chrome)
   ```
   http://localhost:8080
   ```

2. **Grant Microphone Permission** (if asked)
   - Safari: Automatically prompts
   - Chrome: Automatically prompts
   - Click "Allow"

3. **Click "Run Wizard"** button

4. **Check Console** (Press F12)
   - See any errors
   - Watch logs

5. **Test the workflow:**
   - Step 1: Click "Start Measurement"
   - Step 2: Ambient noise measurement (grant microphone)
   - Step 3: Pink noise measurement
   - Continue through steps

---

## 📱 iPhone Testing

### iPhone Limitations:
- **HTTP doesn't allow microphone** on iPhone (security restriction)
- **Needs HTTPS** for microphone access
- **Needs to be on same network** as the Docker container

### Options for iPhone Testing:

#### Option 1: Test on Real moOde System (Recommended)
Once wizard works on Mac:
1. Deploy to your Raspberry Pi
2. Access via: `http://<pi-ip>/snd-config.php`
3. If you have HTTPS certificate: `https://<pi-ip>/snd-config.php`
4. Test on iPhone with real system

#### Option 2: Expose Docker to Network (Complex)
1. Change Docker port mapping
2. Access from iPhone: `http://<mac-ip>:8080`
3. **Still won't work for microphone** (HTTP restriction on iPhone)

#### Option 3: Use ngrok or similar (HTTPS tunnel)
1. Create HTTPS tunnel to localhost:8080
2. Access from iPhone via HTTPS URL
3. Microphone should work

---

## 🎯 Best Testing Strategy

### Phase 1: Mac Testing (NOW)
- ✅ Test at: `http://localhost:8080`
- ✅ Debug JavaScript errors
- ✅ Verify workflow
- ✅ Check all functions work
- ✅ Use mock microphone (simulated)

### Phase 2: Real System Testing (AFTER Mac works)
- ✅ Deploy to Raspberry Pi
- ✅ Test on iPhone via real moOde system
- ✅ Use real microphone
- ✅ Test with actual audio

---

## 🔧 Current Setup Status

```
Mac Browser → http://localhost:8080 → Docker Container
✅ HTTP works
✅ Microphone should work (localhost exception)
✅ Easy debugging
```

```
iPhone → http://localhost:8080 → ❌ Won't work (localhost only)
iPhone → http://<mac-ip>:8080 → ❌ Microphone won't work (HTTP)
iPhone → https://<pi-ip> → ✅ Should work (real moOde)
```

---

## 💡 Recommendation

**Start with Mac testing:**
1. Open `http://localhost:8080` on your Mac
2. Test the wizard there first
3. Fix any JavaScript/logic errors
4. Once working, deploy to Pi and test on iPhone

**Mac is easier for debugging!** 🎯


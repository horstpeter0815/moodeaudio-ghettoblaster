# 🧪 Room Correction Wizard - Test Environment Setup

## 🎯 Problem Solved

Instead of testing 200 times on iPhone, we now have a **Docker-based test environment** that simulates the wizard locally!

## 🚀 Quick Start

### 1. Start Test Server:

```bash
cd test-wizard
./start-test.sh
```

Or manually:
```bash
docker-compose -f docker-compose.wizard-test.yml up -d
```

### 2. Open Browser:

```
http://localhost:8080
```

### 3. Test the Wizard:

- Click "Run Wizard" button
- Use test controls to simulate different scenarios
- Watch console output for debugging

## ✅ What's Included

### Test Interface (`test-wizard/index.html`):
- Full wizard UI (loaded from actual `snd-config.html`)
- Test control buttons
- Console output for debugging
- Simulated microphone access
- Mock backend responses

### Docker Setup (`docker-compose.wizard-test.yml`):
- PHP Apache server
- Port 8080
- Serves test interface
- Loads actual wizard HTML

## 🎭 What's Mocked

### ✅ Simulated:
- **Web Audio API** - Mock AudioContext
- **Microphone** - Button to simulate grant/deny
- **Backend PHP** - Mock responses
- **Pink Noise** - Simulated (no real audio)

### ⚠️ Not Tested:
- Real microphone recording
- Actual audio playback  
- CamillaDSP integration
- Python scripts

## 🧪 Test Scenarios

### Scenario 1: Basic Flow
1. Click "Test: Open Wizard Modal"
2. Click "Test: Step 1"
3. Verify modal opens

### Scenario 2: Ambient Noise
1. Click "Test: Step 2 (Ambient Noise)"
2. Click "Simulate: Grant Microphone"
3. Watch console for logs

### Scenario 3: Full Flow
1. Click "Run Wizard" (real button)
2. Click "Start Measurement"
3. Grant microphone when prompted
4. Follow through steps

### Scenario 4: Error Handling
1. Click "Test: Step 2"
2. Click "Simulate: Deny Microphone"
3. Check error messages

## 📊 Console Output

The test interface includes a console that shows:
- ✅ Success messages (green)
- ⚠️ Warnings (yellow)
- ❌ Errors (red)
- 📡 Backend calls
- 🎤 Microphone events

## 🔧 Troubleshooting

### Issue: Docker won't start
```bash
# Check if port 8080 is in use
lsof -i :8080

# Stop existing container
docker-compose -f docker-compose.wizard-test.yml down
```

### Issue: Wizard HTML not loading
- Check if `moode-source/www/templates/snd-config.html` exists
- Check Docker logs: `docker-compose -f docker-compose.wizard-test.yml logs`

### Issue: JavaScript errors
- Open browser console (F12)
- Check for missing dependencies (jQuery, Bootstrap)
- Verify scripts are loading

## 🎯 Advantages

### ✅ Before (iPhone Testing):
- Need iPhone + Pi + Network
- 200 attempts to debug
- Hard to see what's happening
- Slow feedback loop

### ✅ Now (Docker Testing):
- Test on any computer
- Instant feedback
- See all logs/errors
- Fast iteration
- No hardware needed

## 📝 Workflow

### Development Cycle:

1. **Make Changes** to wizard code
2. **Restart Docker**: `docker-compose restart`
3. **Test in Browser**: `http://localhost:8080`
4. **Check Console**: See what's happening
5. **Fix Issues**: Fast iteration
6. **Test on Real System**: Once working

## 🚀 Next Steps

After local testing works:
1. Test on actual moOde system
2. Test with real iPhone
3. Verify microphone works
4. Check audio playback

---

**No more 200 attempts! Test locally first!** 🎉


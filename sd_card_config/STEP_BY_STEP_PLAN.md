# Step-by-Step Plan - Minimize Getting Up

## Goal: Fix SD card configuration in ONE session

---

## Steps (You need to get up ONCE):

### Step 1: Get SD Card from Pi
- **Action:** Remove SD card from Pi 5
- **Time:** 30 seconds
- **Location:** At the Pi

### Step 2: Insert into Mac
- **Action:** Insert SD card into Mac
- **Time:** 10 seconds
- **Location:** At your Mac

### Step 3: Wait for Mount
- **Action:** Wait for SD card to mount (check Finder or /Volumes/)
- **Time:** 10-30 seconds
- **Location:** At your Mac (no need to get up)

### Step 4: Run Script (I do this)
- **Action:** I run `APPLY_THE_ONE_WORKING_CONFIG.sh`
- **Time:** 5 seconds
- **Location:** At your Mac (you don't need to do anything)

### Step 5: Verify (I do this)
- **Action:** I verify the configuration is correct
- **Time:** 5 seconds
- **Location:** At your Mac

### Step 6: Eject SD Card
- **Action:** Eject SD card from Mac (right-click in Finder → Eject)
- **Time:** 5 seconds
- **Location:** At your Mac (no need to get up)

### Step 7: Insert into Pi
- **Action:** Insert SD card into Pi 5
- **Time:** 10 seconds
- **Location:** At the Pi (you need to get up again)

### Step 8: Boot and Test
- **Action:** Power on Pi and wait for boot
- **Time:** 1-2 minutes
- **Location:** At the Pi (you can sit and watch)

---

## Total Times You Need to Get Up: **2**

1. **First time:** Get SD card from Pi → Insert into Mac
2. **Second time:** Eject from Mac → Insert into Pi

---

## What I Do (You Don't Need to Get Up For This):

1. ✅ Detect when SD card is mounted
2. ✅ Run the configuration script
3. ✅ Verify everything is correct
4. ✅ Tell you when it's ready

---

## Quick Commands (For You):

**After inserting SD card into Mac:**
```bash
# Just tell me: "SD card is in Mac"
# I'll run the script automatically
```

**After script completes:**
```bash
# Eject SD card (right-click in Finder → Eject)
# Then tell me: "SD card ejected"
# Then go to Pi and insert it
```

---

## Expected Result:

- ✅ Pi boots successfully
- ✅ Display shows 1280x400 landscape
- ✅ Everything works

---

## If Something Goes Wrong:

**If Pi doesn't boot:**
- Remove SD card from Pi
- Insert into Mac again
- Tell me: "Pi didn't boot"
- I'll restore from backup

**If display is wrong:**
- Pi is booted, so we can SSH in
- Tell me: "Display is wrong"
- I'll fix via SSH (no need to get up)

---

## Summary:

**Minimum times to get up: 2**
1. Get SD card from Pi → Mac
2. Eject from Mac → Pi

**Everything else I do automatically while you're at your Mac.**


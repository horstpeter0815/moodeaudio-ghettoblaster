# moOde Display Issue - Deep Analysis

**Date:** 2026-01-20
**Status:** INVESTIGATING - NO ROOT CAUSE FOUND YET

---

## What I Know (Facts)

### User Reports
- Display shows wrong page after every boot
- Playlists are missing
- Orange accent colors are missing
- Has to tap screen or wait for things to load
- "Same problem as always"

### What I Found

1. **Service Timing**
   - localdisplay starts: 12:38:57
   - MPD starts: 12:39:09 (12 seconds later)
   - My "wait for MPD" fix didn't solve the problem

2. **Nginx Logs**
   - Access log: COMPLETELY EMPTY (no recent requests)
   - Error log: Only old errors from 12:23:28 (previous boot)
   - **Chromium is NOT making ANY HTTP requests to localhost!**

3. **Services Status**
   - PHP-FPM: Running, working (simple test.php loads fine)
   - nginx: Running
   - MPD: Running
   - localdisplay: Running, Chromium started at 12:43
   - Chromium cache: Cleared on startup (directory doesn't exist)

4. **Configuration**
   - Database: current_view = "playback,folder" (should show playback)
   - .xinitrc: Calls clearbrcache before starting Chromium
   - Chromium flags: --app=http://localhost/ --kiosk

---

## What I DON'T Know

### Critical Unknowns
1. **What does the user ACTUALLY see on the display?**
   - Blank screen?
   - moOde UI skeleton but no data?
   - Configuration page?
   - Error page?
   - Something else?

2. **Why is Chromium NOT requesting http://localhost/?**
   - Chromium is running with --app=http://localhost/
   - But nginx access log shows ZERO requests
   - This is impossible unless:
     a) Chromium is using offline cached version
     b) Chromium is failing to start properly
     c) Nginx access log is not logging localhost requests
     d) Something is blocking Chromium from making requests

3. **When the user "taps the screen", what happens?**
   - Does it reload the page?
   - Does it switch views?
   - Does data suddenly appear?

---

## What I've Tried (That Didn't Work)

1. ❌ Fixed service timing (added MPD wait) - didn't help
2. ❌ Restarted localdisplay - still no requests to server
3. ❌ Checked PHP-FPM - it works fine for test files
4. ❌ Database is correct (HiFiBerry, plughw, current_view)

---

## What I HAVEN'T Done Yet

1. Haven't asked user EXACTLY what they see
2. Haven't checked if Chromium process arguments are correct
3. Haven't verified if --app flag is actually working
4. Haven't checked if there's a Chromium error preventing page load
5. Haven't verified nginx access log configuration
6. Haven't checked Chromium's internal error logs

---

## Next Steps

### Must Do FIRST
**ASK USER:** "What exactly do you see on the display right now?"
- Need to understand what's actually being displayed
- This will tell me if it's a rendering issue, data loading issue, or complete failure

### Then Investigate
1. Check Chromium process arguments (ps aux)
2. Check if --app=http://localhost/ is in the actual running process
3. Find out why nginx isn't logging any requests
4. Check if Chromium has internal error logs
5. Verify if the HTML page is even being served at all

---

## Root Cause Hypothesis (UNVERIFIED!)

### Theory 1: Chromium Offline Cache
- Chromium loaded the page once (maybe weeks ago)
- Cached it offline in some persistent storage
- Now showing that cached version forever
- AJAX requests fail → no data/colors
- **Test:** Check for service worker or offline cache

### Theory 2: Chromium Start Failure
- --app flag not working
- Chromium showing blank/default page
- Never actually loading http://localhost/
- **Test:** Check Chromium internal logs

### Theory 3: Network Issue
- localhost resolution broken
- Chromium can't reach nginx
- **Test:** Check /etc/hosts, loopback interface

### Theory 4: Nginx Access Log Not Logging
- nginx IS serving pages
- But not logging localhost requests
- **Test:** Check nginx access log configuration

---

## Important Lessons

From .cursorrules:
> "NEVER claim 'root cause' without verification"

I claimed root cause (service timing) without verifying it fixed the problem. The user called me out correctly. I need to:
1. Test fixes BEFORE claiming success
2. Get user confirmation BEFORE documenting "root cause"
3. Be humble about what I don't know

---

## Status

**Current State:** BLOCKED - Need user input about what's actually displayed
**Next Action:** Ask user for description of what they see
**Confidence Level:** LOW - Too many unknowns

---

**DO NOT claim this is "fixed" or "root cause found" until USER confirms the display works correctly!**

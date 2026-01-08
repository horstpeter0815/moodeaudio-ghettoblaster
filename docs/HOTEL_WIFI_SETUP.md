# Hotel WiFi Setup Guide

## The Challenge with Hotel WiFi

Hotel WiFi networks often have these issues:

### 1. **Captive Portal** (Login Page)
- Most hotel WiFi requires you to open a browser and accept terms/login
- This is **hard for headless devices** like the Pi
- Solution: Connect Mac first, then Pi might work, or use Mac as bridge

### 2. **Client Isolation**
- Hotels often isolate devices from each other for security
- **Your Mac and Pi might not be able to see each other**
- Solution: Check if devices can ping each other

### 3. **No mDNS/Bonjour**
- `.local` hostnames (like `ghettoblaster.local`) might not work
- Solution: Use IP addresses

## Recommended Setup for Hotel

### Option A: Both on Hotel WiFi (Simplest if it works)

```
Hotel WiFi
    ├── Mac (gets IP like 192.168.1.100)
    └── Pi (gets IP like 192.168.1.101)
```

**Pros:** Simple, both have internet  
**Cons:** May not work due to client isolation or captive portal

### Option B: Mac Bridges Hotel WiFi to Pi (Recommended)

```
Hotel WiFi → Mac (Internet Sharing) → Pi
```

**Setup:**
1. Mac connects to hotel WiFi (completes captive portal if needed)
2. Mac shares connection via Ethernet to Pi
3. Pi gets internet through Mac

**Pros:** Reliable, Mac handles captive portal  
**Cons:** Need Ethernet cable

### Option C: Mac Creates WiFi AP for Pi (Your Current Setup)

```
Hotel WiFi → Mac (via another method) → WiFi AP "Ghettoblaster" → Pi
```

**Problem:** Mac can't be on hotel WiFi AND create WiFi AP simultaneously (needs two WiFi adapters)

## Current Network Status Check

Let me check your current network situation:


# moOde Audio Current Status

**Date:** 2025-01-09  
**IP:** 10.10.11.39

## Network Status

✅ **Online** - Ping successful (0.114ms response time)  
✅ **SSH Port Open** - Port 22 is listening  
⚠️ **Web UI** - Responds with HTTP 400 (server running but may have issues)  
❌ **SSH Authentication** - Failing (user "andre" and "moode" both fail)

## Current Issues

1. **SSH Authentication Failing**
   - Port 22 is open and accepting connections
   - But authentication fails for both "andre" and "moode" users
   - Possible causes:
     - User "andre" doesn't exist
     - User "moode" password incorrect
     - SSH configured for key-only authentication

2. **Web UI Returns 400 Bad Request**
   - Server is running (responds)
   - But returns error instead of web page
   - May need HTTPS or different URL

## What We Know

- ✅ System is booted and online
- ✅ SSH service is running (port 22 open)
- ✅ Network connectivity works
- ❌ Cannot authenticate via SSH
- ⚠️ Web UI has issues

## Next Steps

1. **Check Web UI** - Try https://10.10.11.39:8443 or check what port moOde uses
2. **Create User** - Need to create "andre" user in rootfs
3. **Fix SSH** - Ensure SSH accepts password authentication
4. **Check Display** - User mentioned display issues (black/white, weird edges)

---

**Status:** System online but SSH access blocked by authentication



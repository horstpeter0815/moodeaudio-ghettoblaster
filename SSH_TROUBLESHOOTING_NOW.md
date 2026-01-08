# SSH Troubleshooting - Current Issue

**Date:** 2025-01-09  
**Status:** SSH connection failing

## Current Situation

- ✅ Pi is online (ping works, Web UI responds)
- ✅ Port 22 is open (nc connection succeeds)
- ❌ SSH authentication failing
- ❌ User "andre" may not exist

## Possible Issues

1. **User doesn't exist** - "andre" may not be created on standard moOde
2. **Wrong password** - Password "0815" may be incorrect
3. **SSH service running but not accepting connections** - Configuration issue
4. **SSH only allows key-based auth** - Password auth disabled

## What We've Done

- ✅ Created SSH flag file on SD card
- ✅ SSH activation script exists
- ✅ Port 22 is open

## Next Steps to Try

1. **Try default moOde user:**
   ```bash
   ssh moode@10.10.11.39
   # Password: moodeaudio
   ```

2. **Check if user exists via Web UI:**
   - Open: http://10.10.11.39:8443
   - Go to System → User Management
   - Check if "andre" user exists

3. **Create user via Web UI if needed:**
   - System → User Management → Add User
   - Username: andre
   - Password: 0815
   - Grant sudo access

4. **Check SSH service status (if we can get in):**
   ```bash
   systemctl status ssh
   systemctl status sshd
   ```

## Test Commands

```bash
# Test with default moOde user
ssh moode@10.10.11.39
# Password: moodeaudio

# Or test with pi user
ssh pi@10.10.11.39
# Password: raspberry
```

---

**Status:** Need to verify user exists or create it



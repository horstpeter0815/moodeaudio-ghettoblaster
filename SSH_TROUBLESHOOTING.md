# SSH Troubleshooting - User Authentication Failed

## Current Status

✅ **Pi is reachable** - ping works  
✅ **SSH port 22 is open** - service is listening  
❌ **User "andre" authentication fails** - user may not exist yet

## Possible Causes

1. **Boot scripts haven't finished running yet**
   - Wait 2-3 minutes after boot
   - Scripts run via rc.local which executes during boot

2. **User creation script failed**
   - Script might have encountered an error
   - Check logs on Pi if console access available

3. **Script didn't run**
   - rc.local might not have executed
   - Script path might be wrong

## Diagnostic Steps (On Pi Console)

If you have console/serial access to the Pi:

```bash
# Check if user exists
cat /etc/passwd | grep andre

# Check if script exists
ls -la /boot/firmware/create-user-on-boot.sh
ls -la /boot/create-user-on-boot.sh

# Check rc.local
cat /etc/rc.local

# Check SSH service
systemctl status ssh

# Check boot logs
journalctl -b | grep -i ssh
journalctl -b | grep -i "create-user"

# Manually run user creation script
sudo /boot/firmware/create-user-on-boot.sh
```

## Manual User Creation (If Script Failed)

If the script didn't run, create user manually:

```bash
# On Pi console (as root)
useradd -m -s /bin/bash -u 1000 -g 1000 andre
echo "andre:0815" | chpasswd
echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre
chmod 0440 /etc/sudoers.d/andre
```

## Alternative: Check Script Execution

The script creates a marker file when it completes:

```bash
# Check if script ran
ls -la /var/lib/user-andre-created.done

# If marker exists, script ran (but user might not have been created)
# If marker doesn't exist, script hasn't run yet
```

## Next Steps

1. **Wait 2-3 minutes** - Boot scripts need time
2. **Check Pi console** - See what's happening
3. **Manually run script** - If needed
4. **Check logs** - See error messages

## If Still Not Working

The user creation script might need to be run manually or debugged. Check:
- Script permissions (should be executable)
- Script path (should be accessible)
- Script syntax (should be valid bash)


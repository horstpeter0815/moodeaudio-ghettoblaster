# Finding moOde Credentials

## Standard moOde Default Credentials

### SSH Access:
- **Username:** `pi`
- **Password:** `raspberry`

OR

- **Username:** `moode`  
- **Password:** `moodeaudio`

### SMB File Sharing (Finder):
Try these combinations:

1. **pi / raspberry**
2. **moode / moodeaudio**
3. **pi / moodeaudio**
4. **Guest** (no password - if guest access enabled)

## If Defaults Don't Work

The password may have been changed during moOde setup. Options:

1. **Check moOde Web Interface:**
   - Open: `http://GhettoBlaster.local` or `http://192.168.10.2`
   - Go to System > Configure
   - Check user settings

2. **Reset Password (if you have physical access):**
   - Connect keyboard/monitor to Pi
   - Login as `pi` user
   - Run: `passwd` to change password

3. **Check moOde Documentation:**
   - Standard moOde may use different defaults
   - Check the version you downloaded

## Alternative: Use SSH Instead

If SMB doesn't work, try SSH:

```bash
ssh pi@GhettoBlaster.local
# Password: raspberry

# or
ssh moode@GhettoBlaster.local  
# Password: moodeaudio
```

## Check What's Actually Running

To see what users exist on the Pi, you'd need SSH access or physical console access.


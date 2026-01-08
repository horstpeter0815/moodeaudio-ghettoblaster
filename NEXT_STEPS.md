# Next Steps - Boot and Test SSH

## Step 1: Safely Eject SD Card

**On Mac:**
```bash
# Option A: Use Finder
# Right-click on "bootfs" and "rootfs" volumes → Eject

# Option B: Use command line
diskutil eject disk4
```

**Important:** Make sure both partitions are unmounted before removing the SD card!

## Step 2: Insert SD Card into Raspberry Pi

- Insert the SD card into your Raspberry Pi
- Connect power to boot the Pi

## Step 3: Wait for Boot

- Give the Pi **30-60 seconds** to boot completely
- Watch for activity lights (if visible)
- The Pi needs time to:
  - Boot the system
  - Run rc.local
  - Execute ssh-activate.sh
  - Create user "andre"
  - Start SSH service

## Step 4: Test SSH Connection

Once booted, test SSH:

```bash
ssh andre@10.10.11.39
# Password: 0815
```

**Or use the test script:**
```bash
./test-ssh-after-boot.sh 10.10.11.39 andre 0815
```

## Step 5: Verify Everything Works

After SSH connection:

```bash
# Check user
whoami
# Should show: andre

# Check SSH service
sudo systemctl status ssh
# Should show: active (running)

# Check if user was created correctly
id
# Should show: uid=1000(andre) gid=1000(andre)
```

## Troubleshooting

### If SSH doesn't work:

1. **Wait longer** - Pi might still be booting
2. **Check IP address** - Verify Pi is at 10.10.11.39
3. **Check network** - Ensure Pi is connected to network
4. **Try different user** - Maybe try `moode` or `pi` if andre doesn't exist yet
5. **Check logs** - If you have console access, check boot logs

### If user doesn't exist:

The user creation script runs on first boot. If it didn't run:
- Check if `/boot/firmware/create-user-on-boot.sh` exists
- Check if `/boot/firmware/ssh-activate.sh` calls it
- Manually run: `sudo /boot/firmware/create-user-on-boot.sh`

---

**Ready to eject and boot!**


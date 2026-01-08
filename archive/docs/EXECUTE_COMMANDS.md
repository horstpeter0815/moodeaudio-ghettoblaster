# EXECUTE THESE COMMANDS ON PI 5 NOW

**Copy these commands and run them on your Pi 5:**

---

## IF YOU CAN SSH TO PI 5:

```bash
# SSH to Pi 5
ssh pi@<PI5_IP>

# Go to scripts directory
cd /path/to/cursor

# Make executable
chmod +x *.sh

# EXECUTE FIX
./fix_login_screen.sh

# Start X11
startx

# OR force start
./force_start_moode.sh
```

---

## IF YOU'RE AT LOGIN SCREEN ON PI 5:

1. Press `Ctrl+Alt+F1` (get to console)
2. Login
3. Run:
```bash
cd /path/to/cursor
chmod +x *.sh
./force_start_moode.sh
```
4. Wait 10 seconds
5. Press `Ctrl+Alt+F7` (back to X11)

---

## IF YOU'RE AT PI 5 CONSOLE:

```bash
# Navigate to scripts
cd /path/to/cursor

# Make executable
chmod +x *.sh

# Run fix
./fix_login_screen.sh

# Start X11
startx

# Check status
./check_moode_status.sh
```

---

## QUICK ONE-LINER (if scripts are in current directory):

```bash
chmod +x *.sh && ./fix_login_screen.sh && startx
```

---

**THESE ARE THE EXACT COMMANDS TO RUN ON PI 5. DO IT NOW.**


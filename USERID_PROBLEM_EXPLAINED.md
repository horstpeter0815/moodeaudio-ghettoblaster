# Username/UserID Problem - moOde Requirement

## THE PROBLEM

**moOde REQUIRES a user with UID:GID 1000:1000, or it won't function!**

---

## Root Cause

**File:** `moode-source/www/inc/common.php`  
**Function:** `getUserID()`  
**Lines:** 258-280

```php
function getUserID() {
    // 1. Cleanup from in-place update (if any)
    // - The moode-player pkg creates /home/pi containing .dircolors, piano.sh amd .xinitrc
    // - Delete '/home/pi' if no corresponding userid exists
    if (file_exists('/home/pi/') && empty(sysCmd('grep ":/home/pi:" /etc/passwd'))) {
        sysCmd('cp /home/pi/.xinitrc /tmp/xinitrc');
        sysCmd('rm -rf /home/pi/');
    }
    // 2. Check for no userid set in Pi Imager
    // - A locked password for userid pi is from the pi-gen image build
    // - It stays locked unless a userid is set in the Pi Imager
    if (sysCmd('cat /etc/shadow | grep "pi:" | cut -d ":" -f 2')[0] == '!') {
        $userId = NO_USERID_DEFINED;  // ← Returns error if pi password locked
    } else {
        // 3. Get userid and install xinitrc script to homedir
        $userId = sysCmd('grep 1000:1000 /etc/passwd | cut -d: -f1')[0];  // ← Looks for UID 1000:1000
        if (file_exists('/tmp/xinitrc')) {
            sysCmd('cp -f /tmp/xinitrc /home/' . $userId . '/.xinitrc');
        }
    }

    return $userId;
}
```

---

## What It Does

1. **Checks if user "pi" has locked password** (`!` in shadow file)
   - If locked → Returns `NO_USERID_DEFINED` (error)

2. **Looks for user with UID:GID 1000:1000**
   - Runs: `grep 1000:1000 /etc/passwd | cut -d: -f1`
   - Returns username if found
   - Returns empty if not found

3. **Worker.php checks this:**
   ```php
   $userId = getUserID();
   if ($userId == NO_USERID_DEFINED) {
       workerLog('worker: CRITICAL ERROR: Userid does not exist, moOde will not function');
   }
   ```

---

## The Problem

**moOde requires:**
- A user with **UID:GID 1000:1000**
- This user must exist in `/etc/passwd`
- If not found → moOde logs error and may not function properly

**Standard moOde:**
- Expects user "pi" with UID 1000:1000 (set in Pi Imager)
- If "pi" password is locked (`!` in shadow) → Error
- If no user with UID 1000:1000 exists → Error

**Your case:**
- Need user "andre" with UID 1000:1000
- Must exist before moOde starts
- If missing → moOde won't function

---

## The Solution

**Ensure user "andre" exists with UID:GID 1000:1000:**

1. **Create user "andre" with UID 1000:1000** (before moOde starts)
2. **Set password** (if needed)
3. **Verify it exists** before moOde worker.php runs

**This is why `fix-user-id.service` exists:**
- Checks if "andre" has UID 1000
- Creates/fixes user if needed
- Runs early in boot process

---

## Why This Matters

**moOde uses this user for:**
- Home directory: `/home/{userid}`
- File permissions
- Service user contexts
- Various moOde operations

**If user doesn't exist:**
- moOde logs: `CRITICAL ERROR: Userid does not exist, moOde will not function`
- moOde may not start properly
- Various features may not work

---

## Status

✅ **Root cause found:** moOde requires UID 1000:1000 user  
✅ **Problem identified:** User "andre" must exist with correct UID  
✅ **Solution exists:** `fix-user-id.service` should handle this  

**This is why user creation is critical - moOde won't work without it!**


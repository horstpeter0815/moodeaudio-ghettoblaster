# Why moOde Display Doesn't Start By Default

## Root Cause

**The database default value is `local_display = '0'` (OFF)**

File: `moode-source/var/local/www/db/moode-sqlite3.db.sql`
Line 592: `INSERT INTO cfg_system (id, param, value) VALUES (59, 'local_display', '0');`

## What This Means

1. **Default State**: moOde ships with `local_display = '0'` (disabled)
2. **Service Status**: The `localdisplay.service` is installed but only starts when the database says `local_display = '1'`
3. **User Must Enable**: Users are expected to enable it via the web UI (Configure → System → Local Display)

## Why It's Designed This Way

- Not all moOde users have a display attached
- Headless (no display) setups are common
- Users choose when to enable display functionality
- Saves resources if display isn't needed

## The Solution

To make display start automatically, you need to:

1. **Change the database default** in the SQL file before building
2. **OR** create a first-boot script that sets it to '1'
3. **OR** enable it manually via web UI (what users normally do)

## For Your Custom Build

You should modify the database initialization to set `local_display = '1'` by default, so it starts automatically on first boot.





# Cursor Password Handling

## Current Situation

When running commands that require `sudo` (like copying files to mounted SD cards), macOS prompts for your password. Cursor may have MCP servers or features to handle this, but they need to be configured.

## Options

### 1. Configure Sudo NOPASSWD (Recommended)

You can configure sudo to not require a password for specific commands:

```bash
# Edit sudoers file
sudo visudo

# Add this line (replace 'andrevollmer' with your username):
andrevollmer ALL=(ALL) NOPASSWD: /bin/cp /Volumes/rootfs/lib/systemd/system/*
andrevollmer ALL=(ALL) NOPASSWD: /bin/ln -s /lib/systemd/system/* /Volumes/rootfs/etc/systemd/system/*
andrevollmer ALL=(ALL) NOPASSWD: /bin/mkdir -p /Volumes/rootfs/etc/systemd/system/*
```

### 2. Use MCP Server (If Available)

Cursor may support MCP servers that can handle interactive prompts. Check:
- `.cursor/mcp.json` configuration
- Cursor documentation for password/authentication MCP servers
- MCP server marketplace

### 3. Credential Helper Script

Create a script that handles authentication:

```bash
#!/bin/bash
# ~/.cursor-askpass.sh
osascript -e 'text returned of (display dialog "Enter your password:" default answer "" with hidden answer)'
```

Then set:
```bash
export SUDO_ASKPASS=~/.cursor-askpass.sh
```

## For SD Card Operations

The `UPDATE_SD_CARD_SERVICES.sh` script requires sudo because:
- macOS mounts SD cards with restricted permissions
- System directories require root access

**Quick solution:** Run the script manually when needed:
```bash
sudo ~/moodeaudio-cursor/UPDATE_SD_CARD_SERVICES.sh
```

## Future Improvements

If Cursor adds MCP server support for password handling, we can:
1. Configure it in `.cursor/mcp.json`
2. Update scripts to use the MCP server
3. Enable automatic password prompts within Cursor


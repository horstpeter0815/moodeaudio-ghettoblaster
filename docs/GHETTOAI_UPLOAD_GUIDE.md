# 🤖 GhettoAI Upload Guide

## Quick Start

### Step 1: Navigate to Project Directory
```bash
cd ~/moodeaudio-cursor
```

### Step 2: Check Upload Status
```bash
./tools/ai.sh --status
```

This will tell you if the knowledge base needs to be refreshed.

### Step 3: Get Open WebUI Token

1. Open Open WebUI in browser: http://localhost:3000
2. Open Developer Tools (F12 or Cmd+Option+I)
3. Go to Console tab
4. Type: `localStorage.token`
5. Copy the token (starts with `eyJ...`)

### Step 4: Upload to GhettoAI

**Option A: Using environment variable**
```bash
cd ~/moodeaudio-cursor
OPENWEBUI_TOKEN='<paste-token-here>' ./tools/ai.sh --upload
```

**Option B: Using --token flag**
```bash
cd ~/moodeaudio-cursor
./tools/ai.sh --upload --token '<paste-token-here>'
```

## Example

```bash
# 1. Go to project directory
cd ~/moodeaudio-cursor

# 2. Check status
./tools/ai.sh --status

# 3. Upload (replace <token> with actual token)
OPENWEBUI_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' ./tools/ai.sh --upload
```

## Troubleshooting

### "command not found: ./tools/ai.sh"
**Solution:** Make sure you're in the project root directory:
```bash
cd ~/moodeaudio-cursor
pwd  # Should show: /Users/andrevollmer/moodeaudio-cursor
```

### "Permission denied"
**Solution:** Make script executable:
```bash
chmod +x tools/ai.sh
```

### "Open WebUI not reachable"
**Solution:** 
1. Check if Open WebUI is running: http://localhost:3000
2. Verify Ollama is running: `ollama list`
3. Check Docker: `docker ps | grep open-webui`

### "Invalid token"
**Solution:**
1. Make sure you copied the FULL token (it's long, starts with `eyJ`)
2. Token should be in single quotes: `'eyJ...'`
3. Try getting a fresh token from browser console

## Available Commands

```bash
./tools/ai.sh --verify      # Verify AI setup
./tools/ai.sh --openwebui   # Check Open WebUI status
./tools/ai.sh --manifest    # Regenerate manifest
./tools/ai.sh --status       # Check if upload needed
./tools/ai.sh --upload      # Upload files (needs token)
```

## Files Being Uploaded

All files from `rag-upload-files/` directory:
- `v1.0-docs/` - Version 1.0 documentation
- `documentation/` - General documentation
- `configs/` - Configuration files
- `scripts/` - Scripts
- `source-code/` - Source code

## After Upload

Test GhettoAI with these questions:
- "How does the room correction wizard work?"
- "What is the current network configuration?"
- "What IP addresses should I use for SSH?"

---

**Last Updated:** 2025-01-12

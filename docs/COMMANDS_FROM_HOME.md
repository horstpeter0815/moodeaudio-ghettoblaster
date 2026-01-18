# 📍 Commands From Home Directory

**Cursor Rule:** All commands should work from the HOME directory (`~`)

## ✅ Correct Way (From Home)

All commands use absolute paths or `~/moodeaudio-cursor/`:

```bash
# From HOME directory (~)
~/moodeaudio-cursor/tools/ai.sh --status
~/moodeaudio-cursor/tools/toolbox.sh
~/moodeaudio-cursor/scripts/maintenance/PROJECT_CLEANUP.sh
```

## ❌ Wrong Way (Requires cd)

```bash
# Don't do this - requires cd first
cd ~/moodeaudio-cursor
./tools/ai.sh --status
```

## Quick Reference

### GhettoAI Upload (From Home)
```bash
# Option 1: Helper script
bash ~/moodeaudio-cursor/UPLOAD_TO_GHETTOAI.sh

# Option 2: Direct command
OPENWEBUI_TOKEN='<token>' ~/moodeaudio-cursor/tools/ai.sh --upload
```

### Toolbox (From Home)
```bash
~/moodeaudio-cursor/tools/toolbox.sh
```

### Maintenance Scripts (From Home)
```bash
~/moodeaudio-cursor/scripts/maintenance/PROJECT_CLEANUP.sh
~/moodeaudio-cursor/scripts/maintenance/UPDATE_GHETTOAI.sh
~/moodeaudio-cursor/scripts/maintenance/MAINTAIN_TOOLBOX.sh
```

### Network Test (From Home)
```bash
~/moodeaudio-cursor/scripts/network/TEST_NETWORK_CONFIG.sh
```

## Why?

- Commands work from anywhere
- No need to remember to `cd` first
- Consistent behavior
- Easier for automation

---

**Remember:** Always use `~/moodeaudio-cursor/` paths when running commands from home!

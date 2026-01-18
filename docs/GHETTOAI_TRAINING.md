# GhettoAI Training (RAG) – Open WebUI

This project uses **RAG (Retrieval-Augmented Generation)** for "training": you ingest project docs/configs/code into Open WebUI Knowledge so the assistant can answer precisely about *this* moOde build.

## Quick Start (Automated)

```bash
# 1. Check if KB needs refresh
cd ~/moodeaudio-cursor && ./tools/ai.sh --status

# 2. If refresh needed, upload all files
OPENWEBUI_TOKEN='<your-token>' ./tools/ai.sh --upload
```

### Getting the Token
1. Open `http://localhost:3000` in your browser
2. Open DevTools → Console
3. Run: `localStorage.token`
4. Copy the JWT (starts with `eyJ...`)

---

## When to Refresh

The `--status` command tells you if a refresh is needed. Triggers:
- **Files changed** in `rag-upload-files/` since last upload
- **>30 days** since last upload (even without changes)

Run `./tools/ai.sh --status` to check anytime.

---

## Manual Upload (Alternative)

If the automated upload doesn't work, you can upload manually:

### 1) Prepare the upload bundle

```bash
cd ~/moodeaudio-cursor && ./tools/ai.sh --manifest
```

This regenerates:
- `rag-upload-files/FILE_LIST.txt`
- `rag-upload-files/MANIFEST.md` (recommended upload order)

### 2) Upload into Open WebUI

1. Open Open WebUI: `http://localhost:3000`
2. Go to **Knowledge** (Arbeitsbereich → Wissen)
3. Open **GhettoAI** knowledge base (or create it if missing)
4. Click the **+** button → Upload files/directories
5. Upload in this order (see `rag-upload-files/MANIFEST.md`):
   - `rag-upload-files/v1.0-docs/`
   - `rag-upload-files/documentation/`
   - `rag-upload-files/configs/`
   - `rag-upload-files/scripts/`
   - `rag-upload-files/source-code/`
   - `rag-upload-files/web-interface/`

**Tip:** Set visibility to "Öffentlich" (Public) if upload fails with permission errors.

---

## Create an Agent (One-Time Setup)

In Open WebUI → **Create → Agent**:

- **Name**: GhettoAI
- **System prompt**: copy the "Suggested system prompt" from `rag-upload-files/MANIFEST.md`
- Attach the **GhettoAI** knowledge base

---

## Quick Validation Questions

Ask:
- "How is the Waveshare 7.9 HDMI display rotated to 1280x400?"
- "Which ALSA chain is used for PeppyMeter + CamillaDSP?"
- "How do I deploy changes using the toolbox?"
- "How do I test systemd fixes before building?"
- "How do I check SD card status on macOS?"
- "What Docker testing tools are available?"

---

## Toolbox Integration

The toolbox has a dedicated AI menu:

```bash
cd ~/moodeaudio-cursor && ./tools/toolbox.sh
# → 9) AI / RAG Tools
```

## Recent Updates (January 15, 2026)

### Docker Testing and Profiling Toolbox
- New Docker-based testing infrastructure for systemd configurations
- Test fixes before building (saves 8-12 hours)
- Boot performance profiling with systemd-analyze
- Dependency analysis and circular dependency detection
- See: `tools/test/README.md` for full documentation

### SD Card Management Tools
- macOS-specific SD card status checker
- Auto-detection of Raspberry Pi SD cards
- Safe burn procedures
- Complete guide: `docs/SD_CARD_MACOS_GUIDE.md`

### Key Learnings
- Docker testing is essential before builds
- Shell execution has limitations (cannot execute sudo interactively)
- Focus on script quality over repeated execution attempts
- Comprehensive documentation is critical

See `docs/LEARNING_SESSION_20260115.md` for complete details.

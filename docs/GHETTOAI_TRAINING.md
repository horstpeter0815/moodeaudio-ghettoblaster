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

---

## Toolbox Integration

The toolbox has a dedicated AI menu:

```bash
cd ~/moodeaudio-cursor && ./tools/toolbox.sh
# → 9) AI / RAG Tools
```

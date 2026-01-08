# Quick Setup - Next Steps After Account Creation

**Account Created:** ✅  
**Password:** 0815 0815

## Step 1: Configure Ollama Connection (2 minutes)

1. In Open WebUI (http://localhost:3000), go to:
   - **Settings** (gear icon, top right)
   - **Connection** tab

2. Set Ollama Base URL:
   ```
   http://host.docker.internal:11434
   ```
   (This allows the Docker container to access Ollama on your Mac)

3. Click **Test Connection** or **Save**

4. Verify model appears:
   - Go to **Models** section
   - You should see `llama3.2:3b` available

## Step 2: Enable RAG (2 minutes)

1. In Open WebUI, go to:
   - **Settings** → **RAG** tab

2. Enable RAG:
   - ✅ Check "Enable RAG"
   - Select vector database: **ChromaDB** (recommended)
   - Chunk Size: `512`
   - Chunk Overlap: `50`
   - Top K Results: `5`

3. Click **Save**

## Step 3: Upload Files to RAG (10-15 minutes)

1. Go to **Knowledge** section (or **RAG** in sidebar)

2. Create collections/categories:
   - Click **New Collection** or **Add Knowledge**
   - Create categories:
     - `moOde Documentation`
     - `moOde Source Code`
     - `moOde Scripts`
     - `moOde Configs`
     - `moOde Web Interface`

3. Upload files from:
   ```
   ~/moodeaudio-cursor/rag-upload-files/
   ```

   Upload in this order:
   - **First:** `documentation/` folder (48 files)
   - **Second:** `source-code/` folder (62 files)
   - **Third:** `scripts/` folder (28 files)
   - **Fourth:** `configs/` folder (45 files)
   - **Fifth:** `web-interface/` folder (35 files)

   **Tip:** You can upload entire folders or select multiple files at once.

4. Wait for indexing to complete (progress indicator will show)

## Step 4: Test RAG (2 minutes)

1. Go to **Chat** section

2. Ask test questions:
   - "How does network configuration work in moOde?"
   - "What scripts are available for the setup wizard?"
   - "Explain the audio chain in this project"

3. Verify AI responds with information from your project files

## Step 5: Create First Agent (5 minutes)

1. Go to **Create** → **Agent** (or **Agents** section)

2. Create **Network Configuration Agent**:
   - **Name:** `moOde Network Config Agent`
   - **Description:** `Helps with moOde network configuration and troubleshooting`
   - **Knowledge Base:** Select the collections you uploaded
   - **Model:** `llama3.2:3b`
   - **System Prompt:** (see CREATE_MOODE_AGENTS_GUIDE.md for full prompt)

3. Save and test with: "Check network configuration"

## Quick Test Commands

```bash
# Verify Ollama is accessible from container
docker exec open-webui curl -s http://host.docker.internal:11434/api/tags

# Check Open WebUI logs
docker logs open-webui --tail 50

# Verify files are ready
ls -la ~/moodeaudio-cursor/rag-upload-files/
```

## Troubleshooting

**If Ollama connection fails:**
- Verify Ollama is running: `ollama list`
- Try alternative URL: `http://172.17.0.1:11434` (Docker bridge IP)
- Check Docker network: `docker network inspect bridge`

**If RAG doesn't work:**
- Make sure ChromaDB is selected
- Wait for indexing to complete
- Try uploading a single file first to test

**If upload fails:**
- Check file sizes (some files may be too large)
- Try uploading in smaller batches
- Check browser console for errors (F12)

## Next Steps After Setup

Once RAG is working:
1. Create the 3 agents (Network, Docs, Build)
2. Test with real moOde tasks
3. Create prompt templates
4. Enable context memory

See `MOODE_AI_WORKFLOW_GUIDE.md` for daily usage.


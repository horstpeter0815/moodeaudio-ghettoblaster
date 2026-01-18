# RAG Upload Guide - moOde Project Files

## Files Prepared

All moOde project files have been organized in: `~/moodeaudio-cursor/rag-upload-files/`

### Directory Structure

```
rag-upload-files/
├── documentation/     - All .md documentation files
├── source-code/       - PHP includes and command handlers
├── scripts/           - Shell scripts
├── configs/           - Configuration files
└── web-interface/     - Web UI PHP files
```

## Upload Instructions

### Step 1: Enable RAG in Open WebUI

1. Open http://localhost:3000
2. Go to **Settings** → **RAG** (or **Knowledge**)
3. Enable "Enable RAG"
4. Select vector database: **ChromaDB** (recommended)
5. Configure chunking:
   - Chunk Size: `512`
   - Chunk Overlap: `50`
   - Top K Results: `5`
6. Save settings

### Step 2: Upload Files

#### Option A: Upload by Category (Recommended)

1. Go to **Knowledge** or **RAG** section in Open WebUI
2. Click **"Upload Documents"** or **"Add Knowledge"**
3. Upload each category separately:
   - First: `rag-upload-files/documentation/` (all .md files)
   - Second: `rag-upload-files/scripts/` (all .sh files)
   - Third: `rag-upload-files/source-code/` (PHP files)
   - Fourth: `rag-upload-files/configs/` (config files)
   - Fifth: `rag-upload-files/web-interface/` (web UI files)

#### Option B: Upload Entire Directory

1. Use "Upload Folder" feature if available
2. Select `rag-upload-files/` directory
3. All files will be indexed

### Step 3: Verify Upload

Test with these questions in Open WebUI chat:

1. "How does network configuration work in moOde?"
2. "What scripts are available for network setup?"
3. "Explain the audio chain in this project"
4. "How is CamillaDSP configured?"

The AI should respond based on your actual project files!

## File Counts

Check `rag-upload-files/FILE_LIST.txt` for exact counts.

## Tips

- Upload in batches to avoid timeouts
- Start with documentation files (smallest, most important)
- Add source code files gradually
- Tag files with categories for better organization
- Test after each batch upload


# Ghetto AI v1.0 Training Guide

**Purpose:** Upload v1.0 documentation to Ghetto AI (Open WebUI RAG) for training

## Files Ready for Upload

All v1.0 documentation files are prepared in: `~/moodeaudio-cursor/rag-upload-files/v1.0-docs/`

### Files to Upload:
1. `v1.0_display_audio_setup.md` - Complete display & audio configuration guide
2. `v1.0_config_inventory.md` - Configuration inventory (what to keep/remove)
3. `v1.0_cleanup_status.md` - Cleanup status report
4. `V1.0_DISPLAY_AUDIO_SUMMARY.md` - Quick summary
5. `V1.0_DISPLAY_AUDIO_README.md` - Root-level summary

## Upload Steps

### Step 1: Open Ghetto AI (Open WebUI)
1. Open http://localhost:3000 in your browser
2. Log in (password: 0815 0815)

### Step 2: Navigate to Knowledge/RAG Section
1. Click on **"Knowledge"** or **"RAG"** in the sidebar
2. Or go to **Settings** → **RAG**

### Step 3: Upload v1.0 Documentation
1. Click **"Upload Documents"** or **"Add Knowledge"**
2. Navigate to: `~/moodeaudio-cursor/rag-upload-files/v1.0-docs/`
3. Select all 5 markdown files:
   - `v1.0_display_audio_setup.md`
   - `v1.0_config_inventory.md`
   - `v1.0_cleanup_status.md`
   - `V1.0_DISPLAY_AUDIO_SUMMARY.md`
   - `V1.0_DISPLAY_AUDIO_README.md`
4. Click **"Upload"**

### Step 4: Verify Upload
Test Ghetto AI with these questions:

1. **"How is the Ghetto Blaster display configured?"**
   - Should reference `v1.0_display_audio_setup.md`
   - Should mention Waveshare 7.9", 1280x400 landscape, `.xinitrc` rotation

2. **"What is the audio routing chain?"**
   - Should explain: MPD → PeppyMeter → CamillaDSP → DAC
   - Should mention HiFiBerry AMP100

3. **"What is the maximum safe volume?"**
   - Should answer: 75% (191/255)
   - Should warn about current volume being too high

4. **"What files should be preserved during cleanup?"**
   - Should reference `v1.0_config_inventory.md`
   - Should list critical config files

5. **"What is Ghetto AI?"**
   - Should explain it's the AI assistant (Open WebUI with Ollama)
   - Should mention it's running on Mac

## Expected Behavior

After training, Ghetto AI should:
- ✅ Understand the complete display/audio setup
- ✅ Know about volume safety limits
- ✅ Reference specific configuration files
- ✅ Understand the system architecture
- ✅ Provide accurate troubleshooting advice

## Notes

- Files are already prepared in `rag-upload-files/v1.0-docs/`
- Upload can be done in one batch (all 5 files together)
- RAG indexing may take a few minutes after upload
- Test with questions to verify knowledge base is working

---

**Created:** January 7, 2026  
**For:** Ghetto AI (Open WebUI)  
**System:** Ghetto Blaster v1.0


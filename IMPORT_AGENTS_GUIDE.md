# Import Agents Guide - Quick & Easy! 🚀

## ✅ Files Ready for Import

I've created 3 JSON files in the project root:
- `import-network-agent.json` ← Network Configuration Agent
- `import-docs-agent.json` ← Documentation Generator Agent
- `import-build-agent.json` ← Build & Deployment Agent

## 📥 Import Steps (30 seconds per agent!)

### 1. Open Open WebUI
Navigate to: **http://localhost:3000/workspace/models**

### 2. Click "Importieren" Button
You should see it in the top right area of the Models page.

### 3. Import Each Agent

**Import Agent 1: Network Config**
1. Click "Importieren"
2. Select file: `import-network-agent.json`
3. Click "Open"
4. ✅ Agent created!

**Import Agent 2: Documentation Generator**
1. Click "Importieren" again
2. Select file: `import-docs-agent.json`
3. Click "Open"
4. ✅ Agent created!

**Import Agent 3: Build Agent**
1. Click "Importieren" again
2. Select file: `import-build-agent.json`
3. Click "Open"
4. ✅ Agent created!

## ✅ Verification

After importing all 3:
1. Refresh the page (Cmd+R or F5)
2. You should see **"Modelle 3"** instead of "Modelle 0"
3. All 3 agents should be listed:
   - moOde Network Config Agent
   - moOde Documentation Generator
   - moOde Build Agent

## 🎯 Using Your Agents

### Start a Chat
1. Go to main page: **http://localhost:3000/**
2. Click "New Chat"
3. At the top of the chat window, click the **model selector** (shows current model name)
4. Choose one of your moOde agents from the dropdown

### Test Prompts

**Network Config Agent:**
```
Check the network configuration for moOde and explain how WiFi client setup works
```

**Documentation Generator:**
```
Document the SETUP_GHETTOBLASTER_WIFI_CLIENT.sh script
```

**Build Agent:**
```
Check if the moOde build environment is ready
```

## 🔧 Troubleshooting

### If import fails with "duplicate ID" error:
The agents might already exist. Check the Models page for existing agents with similar names and delete them first.

### If agents don't appear after import:
1. Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R
2. Log out and log back in
3. Restart Open WebUI: `docker restart open-webui`

### If you can't find the Import button:
Look for:
- "Importieren" (German)
- An upload icon (⬆️ or 📁)
- In the top toolbar area next to "+ Neues Modell"

## 📊 Next Steps After Import

Once all 3 agents are working:

1. **Test each agent** with moOde-specific tasks
2. **Enable Context Memory**: Settings → Chat Settings → Memory
3. **Create custom prompts** for common tasks
4. **Integrate into workflow** - use agents for:
   - Network troubleshooting
   - Automatic documentation generation
   - Build validation and deployment

## 📁 Files Location

All import files are in:
```
~/moodeaudio-cursor/
  ├── import-network-agent.json
  ├── import-docs-agent.json
  └── import-build-agent.json
```

---

**Estimated Time: 2 minutes to import all 3 agents!** ⚡


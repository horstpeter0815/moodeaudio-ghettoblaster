# Quick Agent Creation Guide

## ⚠️ Important: Use the Simple Copy-Paste File

I've prepared `AGENTS_COPY_PASTE_SIMPLE.txt` with clean configurations.

## Steps to Create Each Agent:

### 1. Open Agent Creation Page
- Navigate to: http://localhost:3000/workspace/models
- Click the **"+ Neues Modell"** (+ button) in the top right

### 2. Fill in Agent 1: Network Config Agent

**Modellname:**
```
moOde Network Config Agent
```

**Wählen Sie ein Basismodell:**
- Select: `llama3.2:3b` from dropdown

**Beschreibung:**
```
Automatically checks and fixes moOde network configuration issues.
```

**System-Prompt:**
- Copy from `AGENTS_COPY_PASTE_SIMPLE.txt` → Agent 1 section
- Paste into the large text field

**Click:** "Speichern & Erstellen"

---

### 3. Repeat for Agent 2: Documentation Generator

- Click "+ Neues Modell" again
- Name: `moOde Documentation Generator`
- Base model: `llama3.2:3b`
- Description: Copy from file
- System Prompt: Copy from Agent 2 section
- Save

---

### 4. Repeat for Agent 3: Build Agent

- Click "+ Neues Modell" again
- Name: `moOde Build Agent`
- Base model: `llama3.2:3b`
- Description: Copy from file
- System Prompt: Copy from Agent 3 section
- Save

---

## Verification

After creating all 3 agents:
1. Go to http://localhost:3000/workspace/models
2. You should see "Modelle 3" instead of "Modelle 0"
3. All 3 agents should be listed

## Using the Agents

1. Start a new chat
2. Click the model selector at the top
3. Choose one of your moOde agents
4. Ask moOde-specific questions!

## Files to Use:
- **`AGENTS_COPY_PASTE_SIMPLE.txt`** ← Use this for copy-pasting
- **`AGENT_CONFIGURATIONS_READY.md`** ← Reference if you need full details


# How to Use Your moOde Agents in Open WebUI

## Where to Find the Agents

The agents are stored as **"Models"** in Open WebUI. They appear in the model selector when you start a chat.

## Step-by-Step: Using an Agent

### 1. Start a New Chat
- Open http://localhost:3000
- Click on "New Chat" or the chat icon (💬)

### 2. Select an Agent (Model)
- At the top of the chat, you'll see a **model selector**
- It might show "llama3.2:3b" by default
- Click on it to open the dropdown menu

### 3. Choose Your moOde Agent
You should see these in the list:
- **moOde Network Config Agent** - For network configuration help
- **moOde Documentation Generator** - For generating documentation
- **moOde Build Agent** - For build and deployment tasks

### 4. Start Chatting
Once you select an agent, just type your question or request:

**Examples:**
- With Network Agent: "How do I set up WiFi client mode in moOde?"
- With Docs Agent: "Generate documentation for the network configuration scripts"
- With Build Agent: "Is the current build ready for deployment?"

## Where Agents Appear in the UI

### Option 1: Model Selector (in Chat)
```
┌─────────────────────────────────┐
│  Select Model ▼                 │
├─────────────────────────────────┤
│  llama3.2:3b                    │
│  moOde Network Config Agent ✓   │
│  moOde Documentation Generator  │
│  moOde Build Agent              │
└─────────────────────────────────┘
```

### Option 2: Workspace / Models Section
- Look for "Workspace" or "Models" in the left sidebar
- Click to see all your models/agents
- You can view, edit, or manage them there

## Troubleshooting

### I don't see the agents in the dropdown
1. **Refresh the page** (Cmd+R or F5)
2. **Clear browser cache** (Cmd+Shift+R or Ctrl+Shift+R)
3. **Check you're logged in** with the account you created (password: 0815 0815)
4. **Restart the container** if needed:
   ```bash
   docker restart open-webui
   ```

### How do I know which agent I'm talking to?
- The selected agent name appears at the top of the chat
- Each agent has a specific system prompt that guides its responses
- Network Agent: Knows about network configuration
- Docs Agent: Focuses on documentation
- Build Agent: Specializes in builds and deployment

### Can I use multiple agents in the same conversation?
- No, you can only use one agent per chat
- Start a new chat and select a different agent to switch

### What's the difference between agents and regular models?
- **Regular models** (like llama3.2:3b): General-purpose AI
- **Your agents**: Specialized with system prompts for moOde tasks
- **Your agents have access to your knowledge base** with moOde files

## Quick Test

1. Open http://localhost:3000
2. Start a new chat
3. Click the model selector
4. Select "moOde Network Config Agent"
5. Ask: "What network scripts are available in the moOde project?"
6. The agent should reference your actual project files!

## Next Steps

Once the agents are working:
- Test each agent with moOde-specific questions
- Save useful prompts as templates
- Enable context memory (Settings → Memory)
- Create more specialized agents if needed

The agents are ready - just find them in the model selector!


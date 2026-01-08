# moOde AI Workflow Integration Guide

## Overview

This guide shows how to use the local AI (Ollama + Open WebUI) for common moOde Audio development tasks.

## Quick Start

1. **Access Open WebUI:** http://localhost:3000
2. **Select Model:** `llama3.2:3b`
3. **Use RAG:** AI has access to your moOde project files
4. **Use Agents:** For automated tasks

## Common Tasks

### 1. Network Troubleshooting

**Prompt:**
```
Check the network configuration in my moOde project. 
Identify any issues and suggest fixes based on the project files.
```

**Or use Network Config Agent:**
- Select "moOde Network Config Agent"
- Task: "Check and fix network configuration issues"

### 2. Code Review

**Prompt:**
```
Review this script for best practices and potential issues:
[Paste script code]

Consider:
- Error handling
- Code style (absolute paths, backups, etc.)
- moOde project conventions
```

### 3. Documentation Generation

**Prompt:**
```
Generate documentation for this script:
[Paste script code]

Include:
- Purpose and usage
- Parameters
- Examples
- Dependencies
```

**Or use Documentation Agent:**
- Select "moOde Documentation Generator"
- Task: "Generate documentation for network scripts"

### 4. Build and Deployment

**Prompt:**
```
Check if the current build is ready for deployment.
Validate configurations and suggest any fixes needed.
```

**Or use Build Agent:**
- Select "moOde Build Agent"
- Task: "Validate build and prepare for SD card deployment"

### 5. Understanding moOde Code

**Prompt:**
```
Explain how [feature] works in moOde based on the project files.
For example: "How does the Room EQ Wizard work?"
```

The AI will search your uploaded files and explain based on actual code.

### 6. Creating New Scripts

**Prompt:**
```
Create a script that [description] following moOde project conventions:
- Use absolute paths: cd ~/moodeaudio-cursor && ...
- Include error handling: set -e
- Add comments with ##
- Create backups before changes
- Follow project code style
```

### 7. Fixing Issues

**Prompt:**
```
I'm having this issue: [describe problem]

Based on the moOde project files, suggest a fix.
Include:
- Root cause analysis
- Solution steps
- Script to apply fix
```

## Using RAG (Retrieval Augmented Generation)

When RAG is enabled, the AI automatically searches your uploaded files:

**Example Questions:**
- "How does network configuration work in moOde?"
- "What scripts handle the setup wizard?"
- "How is CamillaDSP configured?"
- "Explain the audio chain in this project"
- "What's the difference between NetworkManager and wpa_supplicant?"

The AI will:
1. Search your uploaded files
2. Find relevant code/documentation
3. Answer based on actual project content

## Using Agents

### Network Config Agent

**When to use:**
- Network connection issues
- Configuration conflicts
- Service file problems
- NetworkManager issues

**Example:**
```
Agent: moOde Network Config Agent
Task: "Check why Ethernet isn't connecting and fix it"
```

### Documentation Generator Agent

**When to use:**
- New scripts need documentation
- Existing code needs comments
- README updates needed
- API documentation

**Example:**
```
Agent: moOde Documentation Generator
Task: "Generate documentation for all network-related scripts"
```

### Build Agent

**When to use:**
- Before building
- Validating configurations
- Preparing deployment
- Testing builds

**Example:**
```
Agent: moOde Build Agent
Task: "Check if build #36 is ready for deployment"
```

## Prompt Templates

Save these as templates in Open WebUI for quick access:

### Template 1: Network Troubleshooting
```
Analyze the network configuration in my moOde project and:
1. Identify current issues
2. Explain root causes
3. Propose fixes based on project files
4. Provide script to apply fixes
```

### Template 2: Code Review
```
Review this code following moOde project standards:
[Code]

Check for:
- Error handling
- Code style compliance
- Best practices
- Potential bugs
```

### Template 3: Script Creation
```
Create a [type] script for moOde that:
- [Requirements]

Follow moOde conventions:
- Absolute paths
- Error handling
- Comments
- Backups
```

## Best Practices

1. **Be Specific:** Include context about what you're working on
2. **Reference Files:** Mention specific files when relevant
3. **Ask Follow-ups:** Refine answers with additional questions
4. **Use RAG:** Let AI search your files automatically
5. **Test Agents:** Start with simple tasks, then complex ones
6. **Update Knowledge:** Add new files to RAG as project evolves

## Integration with Development Workflow

### Daily Development

1. **Morning:** Ask AI to review yesterday's changes
2. **Coding:** Use AI for code suggestions and reviews
3. **Testing:** Ask AI to validate configurations
4. **Documentation:** Auto-generate docs as you code

### Before Commits

1. **Code Review:** Use AI to review changes
2. **Documentation:** Ensure docs are up to date
3. **Testing:** Validate with AI suggestions

### Troubleshooting

1. **Describe Issue:** Tell AI what's wrong
2. **Get Analysis:** AI searches project files
3. **Apply Fix:** Use suggested solutions
4. **Verify:** Test and confirm

## Tips

- **Context Matters:** Mention which part of moOde you're working on
- **File References:** Reference specific files when asking questions
- **Iterative:** Refine prompts based on results
- **Combine:** Use multiple agents for complex tasks
- **Learn:** AI learns from your corrections and feedback

## Troubleshooting AI Responses

**If AI doesn't understand:**
- Be more specific about moOde context
- Reference specific files or features
- Provide code examples

**If RAG doesn't find files:**
- Verify files are uploaded
- Check file names and paths
- Try re-uploading if needed

**If agents don't work:**
- Check agent configuration
- Verify knowledge base is accessible
- Test with simpler tasks first

## Next Steps

1. Complete manual setup (RAG, agents)
2. Start using AI for daily tasks
3. Refine prompts based on results
4. Create more specialized agents
5. Share successful workflows


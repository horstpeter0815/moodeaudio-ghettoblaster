# Cursor Tools and MCP Servers for moOde Project

## Current Setup

### MCP Server Configured
**File:** `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/andrevollmer/moodeaudio-cursor"]
    }
  }
}
```

**Status:** ✅ Filesystem MCP server enabled

## Available MCP Tools

### 1. Filesystem MCP (✅ Active)
**Tools available:**
- `mcp_filesystem_read_file` - Read files
- `mcp_filesystem_write_file` - Write files
- `mcp_filesystem_list_directory` - List directories
- `mcp_filesystem_search_files` - Search for files
- `mcp_filesystem_get_file_info` - Get file metadata
- `mcp_filesystem_create_directory` - Create directories
- `mcp_filesystem_move_file` - Move/rename files

**Useful for:**
- Reading configuration files
- Writing service files
- Searching for specific files
- Managing project structure

### 2. Browser MCP (✅ Available)
**Tools available:**
- `mcp_cursor-ide-browser_browser_navigate` - Navigate to URLs
- `mcp_cursor-ide-browser_browser_snapshot` - Get page snapshot
- `mcp_cursor-ide-browser_browser_click` - Click elements
- `mcp_cursor-ide-browser_browser_type` - Type text
- `mcp_cursor-ide-browser_browser_take_screenshot` - Take screenshots

**Useful for:**
- Testing moOde Web UI (http://192.168.10.2)
- Automating browser tasks
- Taking screenshots of display
- Testing Room Correction Wizard
- Verifying Web UI functionality

## Potential MCP Servers to Add

### 1. Terminal/SSH MCP
**Purpose:** Execute commands on Pi remotely

**Could provide:**
- SSH connection to Pi
- Remote command execution
- File transfer
- Service management

**Useful for:**
- Testing fixes on Pi without manual SSH
- Automating deployment
- Checking Pi status
- Running commands remotely

### 2. Database MCP
**Purpose:** Access moOde SQLite database

**Could provide:**
- Query moOde database
- Update configuration
- Read settings
- Check system state

**Useful for:**
- Reading moOde configuration
- Updating display settings
- Checking audio configuration
- Verifying system state

### 3. GitHub MCP
**Purpose:** Access GitHub repositories

**Could provide:**
- Read GitHub repos
- Check for updates
- Read documentation
- Access issues/PRs

**Useful for:**
- Reading moOde source code
- Checking for updates
- Reading driver documentation
- Accessing forum solutions

## How to Use Current Tools

### Filesystem MCP
Already available - I can use these tools to:
- Read files directly (faster than read_file)
- Write files directly
- Search for files
- List directories

### Browser MCP
Already available - I can use these tools to:
- Navigate to moOde Web UI
- Test functionality
- Take screenshots
- Automate browser tasks

**Example use case:**
```bash
# I could navigate to http://192.168.10.2
# Take a screenshot
# Test if Web UI is working
# Automate Room Correction Wizard testing
```

## Recommendations

### High Priority
1. **Use Browser MCP** - Test moOde Web UI automatically
2. **Use Filesystem MCP** - Faster file operations

### Medium Priority
3. **Add Terminal/SSH MCP** - Remote Pi access
4. **Add Database MCP** - moOde database access

### Low Priority
5. **Add GitHub MCP** - Repository access (we have local clones)

## Current Capabilities

**What I can do NOW:**
- ✅ Read/write files via MCP (faster)
- ✅ Navigate and test moOde Web UI via browser
- ✅ Take screenshots of Web UI
- ✅ Automate browser tasks
- ✅ Search files efficiently

**What would be useful:**
- ⏳ SSH to Pi automatically
- ⏳ Query moOde database
- ⏳ Execute commands on Pi remotely

## Next Steps

1. **Use Browser MCP** to test moOde Web UI
2. **Use Filesystem MCP** for faster file operations
3. **Consider adding** Terminal/SSH MCP for Pi access
4. **Consider adding** Database MCP for moOde config access


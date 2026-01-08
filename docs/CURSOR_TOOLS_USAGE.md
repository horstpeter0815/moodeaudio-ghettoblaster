# Cursor Tools Usage Guide

## Available MCP Tools

### 1. Filesystem MCP ✅ Active
**Location:** `.cursor/mcp.json`

**Tools:**
- `mcp_filesystem_read_file` - Read files
- `mcp_filesystem_write_file` - Write files  
- `mcp_filesystem_list_directory` - List directories
- `mcp_filesystem_search_files` - Search files
- `mcp_filesystem_get_file_info` - File metadata

**Use cases:**
- Reading configuration files on SD card
- Writing service files
- Searching for specific files
- Managing project structure

### 2. Browser MCP ✅ Available
**Tools:**
- `mcp_cursor-ide-browser_browser_navigate` - Navigate to URL
- `mcp_cursor-ide-browser_browser_snapshot` - Get page snapshot
- `mcp_cursor-ide-browser_browser_click` - Click elements
- `mcp_cursor-ide-browser_browser_type` - Type text
- `mcp_cursor-ide-browser_browser_take_screenshot` - Screenshots

**Use cases:**
- **Test moOde Web UI** (http://192.168.10.2)
- **Automate Room Correction Wizard testing**
- **Take screenshots of display**
- **Verify Web UI functionality**
- **Test network connectivity via browser**

**Example workflow:**
1. Navigate to http://192.168.10.2
2. Take snapshot to see page state
3. Click buttons/interact with UI
4. Take screenshot to verify
5. Test Room Correction Wizard

## Why Browser MCP is Useful

**Current problem:** Manual testing of moOde Web UI
**With Browser MCP:** Automated testing

**Benefits:**
- Test Web UI without manual browser
- Automate repetitive tasks
- Take screenshots automatically
- Verify functionality programmatically
- Test Room Correction Wizard end-to-end

## How to Use

### Browser MCP Example
```bash
# I can do this:
1. Navigate to http://192.168.10.2
2. Take snapshot to see what's on page
3. Click "System" menu
4. Take screenshot
5. Verify display is working
```

### Filesystem MCP Example
```bash
# I can do this:
1. Read /Volumes/rootfs/etc/systemd/system/*.service
2. Write new service files directly
3. Search for specific configurations
4. List directory contents
```

## Recommendations

### High Priority
1. **Use Browser MCP** to test moOde Web UI
   - Navigate to Pi IP
   - Test functionality
   - Take screenshots
   - Automate testing

2. **Use Filesystem MCP** for file operations
   - Faster than regular read/write
   - Better for SD card operations

### Medium Priority
3. **Add Terminal/SSH MCP** (if available)
   - Remote Pi access
   - Command execution
   - Service management

4. **Add Database MCP** (if available)
   - moOde database access
   - Configuration queries

## Next Steps

1. **Test Browser MCP** - Navigate to moOde Web UI when Pi is ready
2. **Use Filesystem MCP** - For all file operations
3. **Document usage** - How we use these tools
4. **Automate testing** - Use Browser MCP for Web UI tests


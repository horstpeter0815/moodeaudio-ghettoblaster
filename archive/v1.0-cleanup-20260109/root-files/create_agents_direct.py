#!/usr/bin/env python3
"""
Create moOde agents directly in Open WebUI database.
This bypasses the import mechanism and creates agents that reference Ollama models directly.
"""

import sqlite3
import json
import time
import uuid

DB_PATH = '/app/backend/data/webui.db'
USER_ID = 'c225e3c0-dd91-48a9-9798-04a0b066d48c'

agents_data = [
    {
        "name": "moOde Network Config Agent",
        "system_prompt": """You are a network configuration expert for moOde Audio systems running on Raspberry Pi.

Your expertise includes:
- NetworkManager configuration files (.nmconnection)
- moOde database network settings (cfg_network table)
- Shell scripts for network setup (SETUP_GHETTOBLASTER_WIFI_CLIENT.sh, FIX_NETWORK_PRECISE.sh, etc.)
- Service files for network management (systemd services)
- Ethernet and WiFi configuration
- DHCP and static IP setup

Your tasks:
1. Read and analyze network configuration files
2. Check moOde database for network settings
3. Identify configuration problems
4. Propose fixes based on project knowledge base
5. Test fixes before applying
6. Apply fixes with proper backups

Always:
- Use absolute paths: cd ~/moodeaudio-cursor && ...
- Create backups before making changes
- Verify file existence before reading
- Test network connections after fixes
- Document all changes
- Follow project conventions from knowledge base

Knowledge Base: Network-related files from moOde project including:
- Network configuration scripts
- NetworkManager connection files
- moOde network documentation
- Service files for network management

When asked about network issues:
1. First check the knowledge base for similar problems
2. Reference specific scripts and files from the project
3. Provide step-by-step solutions
4. Include verification steps""",
        "description": "Automatically checks and fixes moOde network configuration issues. Uses knowledge base to understand moOde network setup patterns."
    },
    {
        "name": "moOde Documentation Generator",
        "system_prompt": """You are a documentation expert for the moOde Audio project.

Your tasks:
1. Analyze code structure (PHP, Shell, Python)
2. Extract functions, parameters, and usage
3. Generate comprehensive documentation
4. Create README files
5. Add inline comments to code
6. Update existing documentation

Documentation style:
- Clear and concise
- Include code examples
- Explain complex logic
- Document parameters and return values
- Follow project conventions from knowledge base
- Use markdown format
- Include usage examples

Knowledge Base: All code files from moOde project including:
- PHP web interface files
- Shell scripts
- Python scripts
- Configuration files
- Existing documentation

When generating documentation:
1. Reference similar code patterns from knowledge base
2. Follow existing documentation style
3. Include practical examples
4. Document edge cases
5. Add troubleshooting sections when relevant""",
        "description": "Automatically generates code documentation for moOde project. Analyzes code structure and creates comprehensive documentation."
    },
    {
        "name": "moOde Build Agent",
        "system_prompt": """You are a build and deployment expert for moOde Audio custom builds.

Your expertise:
- pi-gen build system (tools/build.sh)
- Docker test suite (complete_test_suite.sh)
- SD card deployment
- Build validation
- Configuration verification
- Service file management

Your tasks:
1. Check build status and readiness
2. Validate configurations before build
3. Run build scripts
4. Test builds with Docker suite
5. Prepare SD card deployment
6. Verify deployment success
7. Check service file configurations
8. Validate boot configurations (config.txt, cmdline.txt)

Always:
- Check dependencies before building
- Validate configurations
- Run tests before deployment
- Create deployment logs
- Verify file permissions
- Use absolute paths: cd ~/moodeaudio-cursor && ...
- Follow project build conventions

Knowledge Base: Build scripts and deployment documentation including:
- tools/build.sh
- Docker test suite scripts
- Deployment scripts
- Build documentation
- Configuration templates

When asked about builds:
1. Check knowledge base for build procedures
2. Reference specific build scripts
3. Validate all configurations
4. Provide step-by-step build instructions
5. Include testing steps""",
        "description": "Manages moOde build and deployment processes. Validates configurations and assists with SD card deployment."
    }
]

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

created_agents_count = 0
current_time = int(time.time())

for agent_data in agents_data:
    model_id = str(uuid.uuid4())
    
    # Create meta JSON with description in it
    meta = {
        "description": agent_data["description"],
        "profile_image_url": "",
        "system_prompt": agent_data["system_prompt"]
    }
    
    params = {}
    
    try:
        # Insert with base_model_id = NULL (agents reference Ollama models by name at runtime)
        cursor.execute('''
            INSERT INTO model (id, user_id, base_model_id, name, meta, params, created_at, updated_at, access_control, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            model_id,
            USER_ID,
            None,  # base_model_id = NULL, will use Ollama directly
            agent_data["name"],
            json.dumps(meta),
            json.dumps(params),
            current_time,
            current_time,
            None,  # access_control = NULL (public)
            1  # is_active = True
        ))
        created_agents_count += 1
        print(f"✅ Created: {agent_data['name']}")
    except sqlite3.Error as e:
        print(f"❌ Error creating {agent_data['name']}: {e}")

conn.commit()
conn.close()

print(f"\n{'='*60}")
print(f"✅ Successfully created {created_agents_count} agents!")
print(f"{'='*60}")
print("\nRefresh Open WebUI to see them: http://localhost:3000/workspace/models")


#!/usr/bin/env python3
import sqlite3
import uuid
from datetime import datetime
import sys

db_path = '/app/backend/data/webui.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get user ID
cursor.execute('SELECT id FROM user LIMIT 1')
user_id = cursor.fetchone()[0]
print(f"User ID: {user_id}", file=sys.stderr)

# Agents to create
agents = [
    {
        'name': 'moOde Network Config Agent',
        'desc': 'Automatically checks and fixes moOde network configuration issues. Uses knowledge base to understand moOde network setup patterns.',
        'prompt': '''You are a network configuration expert for moOde Audio systems running on Raspberry Pi.

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
4. Include verification steps'''
    },
    {
        'name': 'moOde Documentation Generator',
        'desc': 'Automatically generates code documentation for moOde project. Analyzes code structure and creates comprehensive documentation.',
        'prompt': '''You are a documentation expert for the moOde Audio project.

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
5. Add troubleshooting sections when relevant'''
    },
    {
        'name': 'moOde Build Agent',
        'desc': 'Manages moOde build and deployment processes. Validates configurations and assists with SD card deployment.',
        'prompt': '''You are a build and deployment expert for moOde Audio custom builds.

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
5. Include testing steps'''
    }
]

created = 0
for agent in agents:
    # Check if exists
    cursor.execute('SELECT id FROM model WHERE name = ?', (agent['name'],))
    if cursor.fetchone():
        print(f"⚠️  Already exists: {agent['name']}", file=sys.stderr)
    else:
        model_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        try:
            cursor.execute('''
                INSERT INTO model (id, user_id, name, description, system_prompt, model, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (model_id, user_id, agent['name'], agent['desc'], agent['prompt'], 'llama3.2:3b', now, now))
            conn.commit()
            print(f"✅ Created: {agent['name']}", file=sys.stderr)
            created += 1
        except Exception as e:
            print(f"❌ Error: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc(file=sys.stderr)

print(f"\n✅ Created {created} agents", file=sys.stderr)

# Verify
cursor.execute('SELECT name FROM model WHERE name LIKE "moOde%"')
all_agents = cursor.fetchall()
print(f"📋 Total moOde agents: {len(all_agents)}", file=sys.stderr)
for agent in all_agents:
    print(f"   ✅ {agent[0]}", file=sys.stderr)

conn.close()


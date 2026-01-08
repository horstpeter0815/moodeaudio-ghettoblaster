#!/bin/bash
# Create Room Correction Wizard Agent in Open WebUI

echo "Creating moOde Room Correction Wizard Agent..."

docker exec open-webui python3 << 'PYTHON_SCRIPT'
import sqlite3
import json
import time
import uuid
import os

DB_PATH = '/app/backend/data/webui.db'
USER_ID = 'c225e3c0-dd91-48a9-9798-04a0b066d48c'  # From previous agent creation

agent_data = {
    'name': 'moOde Room Correction Wizard Agent',
    'system_prompt': '''You are a Room Correction Wizard expert for moOde Audio systems running on Raspberry Pi with HiFiBerry AMP100.

Your expertise includes:
- Room Correction Wizard backend (room-correction-wizard.php)
- Pink noise generation via speaker-test
- ALSA audio routing (_audioout → peppy → camilladsp → DAC)
- Frequency response measurement and analysis
- CamillaDSP EQ filter generation (PEQ bands)
- iPhone microphone integration for measurements
- Display switching during wizard mode
- MPD state management (stop/restore)

Your tasks:
1. Troubleshoot pink noise generation issues
2. Debug audio routing problems
3. Help with frequency response measurements
4. Generate and apply EQ filters
5. Fix wizard display issues
6. Manage MPD state during measurements
7. Verify audio chain is working correctly

Technical Details:
- Pink noise device: hw:0,0 (direct hardware, card 0 = HiFiBerry)
- Volume control: amixer -c 0 (ALSA mixer, not MPD)
- MPD must be stopped before pink noise starts
- Wizard backend: /var/www/command/room-correction-wizard.php
- Wizard frontend: /var/www/wizard/display.html
- PID file: /tmp/pink_noise.pid
- Log file: /tmp/pink_noise.log

Common Issues:
- Pink noise not playing: Check MPD is stopped, verify hw:0,0 device, check volume unmuted
- Audio routing: _audioout → peppy → camilladsp → DAC
- Device busy: Stop MPD first, wait 1-2 seconds
- Volume too high: Maximum safe is 75% (191/255)

Always:
- Use absolute paths: cd ~/moodeaudio-cursor && ...
- Check MPD status before starting pink noise
- Verify volume is set correctly (amixer -c 0)
- Test audio chain step by step
- Check logs in /tmp/pink_noise.log
- Verify process is running (ps aux | grep speaker-test)

Knowledge Base: Room Correction Wizard files including:
- room-correction-wizard.php (backend API)
- wizard-control.js (frontend control)
- display.html (wizard interface)
- Audio routing documentation
- CamillaDSP configuration

When asked about wizard issues:
1. Check if pink noise process is running
2. Verify MPD is stopped
3. Check audio device (hw:0,0)
4. Verify volume is unmuted and set correctly
5. Check logs for errors
6. Test audio chain step by step
7. Provide step-by-step solutions''',
    'description': 'Expert assistant for the Room Correction Wizard. Helps with acoustic measurements, pink noise generation, EQ filter creation, and troubleshooting wizard issues.',
    'base_model_name': 'llama3.2:3b',
    'knowledge_base_ids': [],
    'tools': [],
    'access_control': None,
    'is_active': True
}

try:
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get base model ID
    cursor.execute('SELECT id FROM model WHERE name = ?', (agent_data['base_model_name'],))
    base_model_row = cursor.fetchone()
    base_model_id = base_model_row[0] if base_model_row else None
    
    if not base_model_id:
        print(f'❌ Error: Base model {agent_data["base_model_name"]} not found')
        print('   Please ensure llama3.2:3b is downloaded in Open WebUI')
        conn.close()
        exit(1)
    
    model_id = str(uuid.uuid4())
    current_time = int(time.time())
    
    meta = {
        'system_prompt': agent_data['system_prompt'],
        'knowledge_collections': agent_data['knowledge_base_ids'],
        'tools': agent_data['tools'],
        'description': agent_data['description']
    }
    params = {}
    
    cursor.execute('''
        INSERT INTO model (id, user_id, base_model_id, name, meta, params, created_at, updated_at, access_control, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        model_id,
        USER_ID,
        base_model_id,
        agent_data['name'],
        json.dumps(meta),
        json.dumps(params),
        current_time,
        current_time,
        json.dumps(agent_data['access_control']),
        agent_data['is_active']
    ))
    
    conn.commit()
    conn.close()
    print(f'✅ Created agent: {agent_data["name"]}')
    print(f'   Model ID: {model_id}')
    print(f'   Base Model: {agent_data["base_model_name"]}')
    print('')
    print('Agent is now available in Open WebUI!')
    print('Go to http://localhost:3000 and select it from the model dropdown.')
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
    print('')
    print('Please add agent manually using WIZARD_AGENT_CONFIG.md')
    exit(1)
PYTHON_SCRIPT

echo ""
echo "Done!"


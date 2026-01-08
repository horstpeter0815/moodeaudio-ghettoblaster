#!/usr/bin/env python3
import sqlite3
import json
import uuid
import time

db = '/app/backend/data/webui.db'
conn = sqlite3.connect(db)
c = conn.cursor()

uid = c.execute('SELECT id FROM user LIMIT 1').fetchone()[0]
now = int(time.time() * 1000000)

agents = [
    ('moOde Network Config Agent', 'Network configuration expert for moOde Audio systems'),
    ('moOde Documentation Generator', 'Automatically generates code documentation for moOde project'),
    ('moOde Build Agent', 'Manages moOde build and deployment processes')
]

created = 0
for name, desc in agents:
    c.execute('SELECT id FROM model WHERE name = ?', (name,))
    if c.fetchone():
        print(f'Exists: {name}')
        continue
    
    mid = str(uuid.uuid4())
    meta = json.dumps({'description': desc, 'system_prompt': f'You are {desc}.'})
    params = json.dumps({'model': 'llama3.2:3b'})
    
    c.execute('''
        INSERT INTO model (id, user_id, name, meta, params, created_at, updated_at, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (mid, uid, name, meta, params, now, now, 1))
    print(f'Created: {name}')
    created += 1

conn.commit()
print(f'\nCreated {created} agents')

c.execute('SELECT name FROM model WHERE name LIKE "moOde%" ORDER BY name')
results = c.fetchall()
print(f'Total moOde agents: {len(results)}')
for r in results:
    print(f'  ✅ {r[0]}')

conn.close()


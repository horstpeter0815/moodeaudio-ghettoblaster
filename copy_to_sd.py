#!/usr/bin/env python3
import shutil
import os

# Copy wizard-functions.js
shutil.copy('test-wizard/wizard-functions.js', '/Volumes/bootfs/moode_deploy/test-wizard/')
print('✓ wizard-functions.js copied')

# Copy snd-config.html
shutil.copy('test-wizard/snd-config.html', '/Volumes/bootfs/moode_deploy/test-wizard/')
print('✓ snd-config.html copied')

# Create command directory and copy room-correction-wizard.php
os.makedirs('/Volumes/bootfs/moode_deploy/command', exist_ok=True)
shutil.copy('moode-source/www/command/room-correction-wizard.php', '/Volumes/bootfs/moode_deploy/command/')
print('✓ room-correction-wizard.php copied')

# List all files
print('\n=== Files on SD card ===')
for root, dirs, files in os.walk('/Volumes/bootfs/moode_deploy'):
    for file in files:
        path = os.path.join(root, file)
        rel_path = os.path.relpath(path, '/Volumes/bootfs/moode_deploy')
        size = os.path.getsize(path)
        print(f'{rel_path} ({size:,} bytes)')

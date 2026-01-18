#!/usr/bin/env python3
import shutil
import os
import sys

boot_path = '/Volumes/bootfs'
if not os.path.exists(boot_path):
    print('ERROR: SD card not mounted at /Volumes/bootfs')
    sys.exit(1)

print('SD card found! Copying files...\n')

# 1. Copy updated room-correction-wizard.php
command_src = '/Users/andrevollmer/moodeaudio-cursor/moode-source/www/command/room-correction-wizard.php'
command_dst = os.path.join(boot_path, 'moode_deploy', 'command', 'room-correction-wizard.php')
os.makedirs(os.path.dirname(command_dst), exist_ok=True)
if os.path.exists(command_src):
    shutil.copy2(command_src, command_dst)
    print(f'✓ Copied room-correction-wizard.php')
else:
    print(f'✗ Source not found: {command_src}')
    sys.exit(1)

# 2. Copy test-wizard files
test_wizard_src = '/Users/andrevollmer/moodeaudio-cursor/test-wizard'
test_wizard_dst = os.path.join(boot_path, 'moode_deploy', 'test-wizard')
os.makedirs(test_wizard_dst, exist_ok=True)
for file in ['index-simple.html', 'wizard-functions.js', 'snd-config.html']:
    src = os.path.join(test_wizard_src, file)
    dst = os.path.join(test_wizard_dst, file)
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f'✓ Copied {file}')
    else:
        print(f'✗ Source not found: {src}')
        sys.exit(1)

print('\n✓ All files copied to SD card!')
print('\nNext steps:')
print('1. Eject SD card from Mac')
print('2. Insert SD card into Raspberry Pi')
print('3. Boot the Pi')
print('4. Open: https://10.10.11.39:8443/index-simple.html')
print('5. Auto-deployment will run automatically!')


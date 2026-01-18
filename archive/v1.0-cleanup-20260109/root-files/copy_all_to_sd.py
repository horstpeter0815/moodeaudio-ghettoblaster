#!/usr/bin/env python3
import shutil
import os

boot_path = '/Volumes/bootfs'
base_path = '/Users/andrevollmer/moodeaudio-cursor'

print('Copying files to SD card...\n')

# 1. Copy room-correction-wizard.php
src = os.path.join(base_path, 'moode-source/www/command/room-correction-wizard.php')
dst = os.path.join(boot_path, 'moode_deploy/command/room-correction-wizard.php')
os.makedirs(os.path.dirname(dst), exist_ok=True)
shutil.copy2(src, dst)
print(f'✓ Copied room-correction-wizard.php')

# 2. Copy test-wizard files
files = ['index-simple.html', 'wizard-functions.js', 'snd-config.html']
for file in files:
    src = os.path.join(base_path, 'test-wizard', file)
    dst = os.path.join(boot_path, 'moode_deploy/test-wizard', file)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
    print(f'✓ Copied {file}')

print('\n✓ All files copied to SD card!')
print('\nNext: Eject SD card, insert into Pi, and reboot.')


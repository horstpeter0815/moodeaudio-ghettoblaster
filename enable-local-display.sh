#!/bin/bash
# Enable local display - copy this entire file and paste into WebSSH, then run: bash enable-local-display.sh

sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
systemctl enable localdisplay.service
systemctl start localdisplay.service
systemctl status localdisplay.service





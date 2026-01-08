DEPLOYMENT ANLEITUNG
====================

Nach dem Booten des Raspberry Pi:

1. Öffne im Browser:
   https://10.10.11.39:8443/deploy-now.php

2. Klicke auf "Deploy Now" Button

3. Das Script kopiert automatisch alle Dateien von /boot/moode_deploy/ nach /var/www/html/

Das war's! Keine SSH oder Terminal-Befehle nötig.

Falls deploy-now.php nicht funktioniert, kopiere es manuell:
  sudo cp /boot/moode_deploy/deploy-now.php /var/www/html/
  sudo chmod 644 /var/www/html/deploy-now.php

Dann öffne: https://10.10.11.39:8443/deploy-now.php


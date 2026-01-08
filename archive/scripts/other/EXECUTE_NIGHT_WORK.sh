#!/bin/bash
# Führe alle Nacht-Arbeiten aus

echo "=== NACHT-ARBEITEN AUSFÜHREN ==="
echo ""

# 1. Rotation beheben
echo "1. Rotation-Problem beheben..."
./FIX_ROTATION.sh
echo ""

# 2. System aufräumen
echo "2. System aufräumen..."
./CLEANUP_SYSTEM.sh
echo ""

# 3. HiFiBerryOS finden
echo "3. HiFiBerryOS im Netzwerk suchen..."
./FIND_HIFIBERRYOS.sh
echo ""

# 4. HiFiBerryOS herunterfahren (wenn gefunden)
echo "4. HiFiBerryOS herunterfahren..."
echo "   (IP-Adresse muss in HIFIBERRYOS_TO_MOODE.sh eingetragen werden)"
# ./HIFIBERRYOS_TO_MOODE.sh
echo ""

echo "✅ Nacht-Arbeiten abgeschlossen"
echo ""
echo "Nächste Schritte:"
echo "1. Rotation testen (Reboot)"
echo "2. System-Cleanup verifizieren"
echo "3. HiFiBerryOS IP eintragen und herunterfahren"
echo "4. Moode Audio Image vorbereiten"


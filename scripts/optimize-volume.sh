#!/bin/bash
#
# moOde Volume Optimization Script
# Tests different filter gain values to find optimal volume response
#
# Usage: Run on Pi, follow prompts to test each configuration

PI_USER="andre"
PI_HOST="moode.local"
PI_PASS="0815"

echo "=========================================="
echo "moOde Volume Optimization Tool"
echo "=========================================="
echo ""
echo "This script will test different filter gain values"
echo "to find the optimal volume response."
echo ""
echo "Current Configuration:"
echo "  - Digital Mixer: 50% (FIXED)"
echo "  - Analogue Mixer: 100% (FIXED)"
echo "  - Filter Gain: Variable (we'll test)"
echo ""
echo "Test Protocol:"
echo "  1. Script sets MPD volume to 1%"
echo "  2. Script sets filter gain to test value"
echo "  3. YOU test: Play audio, increase volume gradually"
echo "  4. Tell script if volume is: too quiet / good / too loud"
echo ""

# Test values for filter gain (in dB)
TEST_GAINS=(3 4 5 6 7 8 9)

for GAIN in "${TEST_GAINS[@]}"; do
    echo "=========================================="
    echo "Testing Filter Gain: +${GAIN}dB"
    echo "=========================================="
    
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no ${PI_USER}@${PI_HOST} "
        echo 'Setting filter gain to +${GAIN}dB...' &&
        sudo sed -i 's/gain: [0-9]*/gain: ${GAIN}/' /usr/share/camilladsp/working_config.yml &&
        grep -A 3 'peqgain:' /usr/share/camilladsp/working_config.yml | grep 'gain:' &&
        echo '' &&
        echo 'Setting MPD volume to 1%...' &&
        mpc volume 1 &&
        echo '' &&
        echo 'Restarting MPD...' &&
        sudo systemctl restart mpd >/dev/null 2>&1 &&
        sleep 3 &&
        echo '' &&
        echo '✅ Configuration ready:' &&
        echo '  - Filter Gain: +${GAIN}dB' &&
        echo '  - MPD Volume: 1%' &&
        echo '  - Digital Mixer: 50%' &&
        echo '' &&
        echo 'TEST NOW: Play audio, increase volume gradually'
    "
    
    echo ""
    read -p "How does this sound? (too-quiet/good/too-loud): " RESULT
    
    case $RESULT in
        "too-quiet"|"quiet"|"q")
            echo "✅ Noted: +${GAIN}dB is too quiet"
            ;;
        "good"|"perfect"|"g"|"p")
            echo "✅ OPTIMAL FOUND: +${GAIN}dB is good!"
            echo ""
            read -p "Save this as final configuration? (y/n): " SAVE
            if [[ "$SAVE" == "y" || "$SAVE" == "Y" ]]; then
                sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no ${PI_USER}@${PI_HOST} "
                    echo 'Saving optimal configuration...' &&
                    sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_system SET value='50' WHERE param='volknob'\" &&
                    sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_system SET value='Digital' WHERE param='amixname'\" &&
                    echo '✅ Configuration saved!' &&
                    echo '' &&
                    echo 'Optimal Settings:' &&
                    echo '  - Filter Gain: +${GAIN}dB' &&
                    echo '  - Digital Mixer: 50%' &&
                    echo '  - Analogue Mixer: 100%'
                "
                echo ""
                echo "✅ Volume optimization complete!"
                exit 0
            fi
            ;;
        "too-loud"|"loud"|"l")
            echo "✅ Noted: +${GAIN}dB is too loud"
            ;;
        *)
            echo "✅ Noted: +${GAIN}dB - ${RESULT}"
            ;;
    esac
    
    echo ""
    read -p "Continue to next test? (y/n): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        echo "Optimization stopped by user."
        exit 0
    fi
    echo ""
done

echo ""
echo "All test values completed. No optimal value found."
echo "You may need to test values outside the range 3-9 dB."

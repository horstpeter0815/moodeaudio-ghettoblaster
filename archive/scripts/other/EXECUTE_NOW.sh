#!/bin/bash
# EXECUTE THIS ON PI 5 NOW
# Copy this script to Pi 5 and run it

echo "=========================================="
echo "FIXING LOGIN SCREEN - EXECUTING NOW"
echo "=========================================="

# Step 1: Check status
echo "Step 1: Checking status..."
./check_moode_status.sh

# Step 2: Fix login screen
echo ""
echo "Step 2: Fixing login screen..."
./fix_login_screen.sh

# Step 3: Force start if needed
echo ""
echo "Step 3: Force starting Moode..."
./force_start_moode.sh

# Step 4: Final check
echo ""
echo "Step 4: Final status check..."
sleep 5
./check_moode_status.sh

echo ""
echo "=========================================="
echo "DONE - Check if Moode is showing"
echo "=========================================="


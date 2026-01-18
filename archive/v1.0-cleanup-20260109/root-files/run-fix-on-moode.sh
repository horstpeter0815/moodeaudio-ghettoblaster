#!/bin/bash
# One-liner to copy and run the fix script on moOde

echo "Copying fix script to moOde..."
scp complete-fix-all.sh andre@moode.local:/tmp/complete-fix.sh

echo "Running fix script on moOde..."
ssh andre@moode.local "chmod +x /tmp/complete-fix.sh && sudo /tmp/complete-fix.sh"


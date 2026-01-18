#!/bin/bash
# Rename all files with premature "final", "working", "fixed", "complete" etc. in names
# Change them to "ATTEMPT" or "TESTING" to reflect actual status

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Find and rename files with problematic names
find . -type f -name "*FINAL*" -o -name "*WORKING*" -o -name "*FIXED*" -o -name "*COMPLETE*" | while read file; do
    newname=$(echo "$file" | sed -E 's/(FINAL|WORKING|FIXED|COMPLETE)/ATTEMPT/g')
    if [ "$file" != "$newname" ]; then
        echo "Would rename: $file -> $newname"
        # Uncomment to actually rename:
        # mv "$file" "$newname"
    fi
done


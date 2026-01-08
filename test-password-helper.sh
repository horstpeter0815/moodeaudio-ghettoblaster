#!/bin/bash
# Password Helper for Test Suite
# Reads password from test-password.txt file

get_test_password() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local PASSWORD_FILE="$SCRIPT_DIR/test-password.txt"
    
    if [ -f "$PASSWORD_FILE" ]; then
        cat "$PASSWORD_FILE" | tr -d '\n\r'
    else
        echo "4512"  # Default password
    fi
}

# Export function for use in other scripts
export -f get_test_password


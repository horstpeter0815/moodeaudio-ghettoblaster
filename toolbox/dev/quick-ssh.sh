#!/bin/bash
# Quick SSH
# Fast SSH access to Pi with common commands
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"
COMMAND="${3}"

if [ -z "$COMMAND" ]; then
    echo "========================================"
    echo "Quick SSH to Pi"
    echo "Target: $USER@$PI_IP"
    echo "========================================"
    echo ""
    ssh "$USER@$PI_IP"
else
    # Execute command
    case "$COMMAND" in
        "reboot")
            echo "Rebooting Pi..."
            ssh "$USER@$PI_IP" "sudo reboot"
            echo "Waiting 60 seconds..."
            sleep 60
            echo "Pi should be back up now"
            ;;
        "logs")
            echo "Recent logs:"
            ssh "$USER@$PI_IP" "journalctl -n 50 --no-pager"
            ;;
        "display")
            echo "Display status:"
            ssh "$USER@$PI_IP" "systemctl status localdisplay --no-pager"
            ;;
        "audio")
            echo "Audio status:"
            ssh "$USER@$PI_IP" "cat /proc/asound/cards"
            ;;
        "db")
            echo "Database config:"
            ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT * FROM cfg_system LIMIT 20'"
            ;;
        *)
            echo "Executing: $COMMAND"
            ssh "$USER@$PI_IP" "$COMMAND"
            ;;
    esac
fi

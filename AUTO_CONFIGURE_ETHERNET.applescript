-- ╔══════════════════════════════════════════════════════════════╗
-- ║  🔧 AUTOMATISCHE ETHERNET-KONFIGURATION                      ║
-- ╚══════════════════════════════════════════════════════════════╝

tell application "System Settings"
    activate
    delay 2
    
    -- Öffne Netzwerk-Einstellungen
    tell application "System Events"
        tell process "System Settings"
            -- Suche nach Netzwerk
            click button "Netzwerk" of group 1 of list 1 of group 1 of splitter group 1 of group 1 of window 1
            delay 2
            
            -- Suche nach AX88179A
            try
                click button "AX88179A" of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
                delay 1
                
                -- Setze auf DHCP
                click pop up button 1 of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
                delay 0.5
                click menu item "DHCP verwenden" of menu 1 of pop up button 1 of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
                
                delay 2
                return "✅ DHCP aktiviert"
            on error
                return "⚠️  Konfiguration nicht gefunden - bitte manuell"
            end try
        end tell
    end tell
end tell


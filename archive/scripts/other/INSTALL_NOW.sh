#!/usr/bin/expect -f
# INSTALLATION JETZT - Automatisch mit Passwort

set timeout 30
set PI1 "192.168.178.62"
set PI2 "192.168.178.134"
set USER "andre"

puts "=========================================="
puts "  INSTALLATION JETZT"
puts "=========================================="
puts ""

# Get password
puts "SSH Passwort für beide Pis:"
stty -echo
expect_user -re "(.*)\n"
set PASSWORD $expect_out(1,string)
stty echo
puts ""

# Function to install
proc install_pi {ip name} {
    global USER PASSWORD
    puts "📋 $name ($ip)"
    puts ""
    
    # Copy scripts
    puts "1. Scripts kopieren..."
    spawn scp -o StrictHostKeyChecking=no FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh ${USER}@${ip}:~/
    expect {
        "password:" {
            send "$PASSWORD\r"
            expect eof
        }
        eof
    }
    puts "✅ Scripts kopiert"
    
    # Execute installation
    puts "2. Installation ausführen..."
    spawn ssh -o StrictHostKeyChecking=no ${USER}@${ip} "chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh && sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh"
    expect {
        "password:" {
            send "$PASSWORD\r"
            expect {
                "password:" {
                    send "$PASSWORD\r"
                    expect eof
                }
                eof
            }
        }
        eof
    }
    puts "✅ Installation erfolgreich"
    puts ""
}

# Install Pi 1
puts "🖥️  PI 1: RaspiOS"
install_pi $PI1 "RaspiOS"

# Install Pi 2
puts "🎵 PI 2: moOde"
install_pi $PI2 "moOde"

puts "=========================================="
puts "✅ INSTALLATION ABGESCHLOSSEN"
puts "=========================================="
puts ""
puts "📋 NÄCHSTE SCHRITTE:"
puts "   Auf beiden Pis: sudo reboot"
puts "   Nach Reboot: sudo bash ~/verify_installation.sh"
puts ""


#!/usr/bin/env python3
"""
Führt Display-Fix aus - ohne Fragen, ohne Unterbrechungen
"""
import subprocess
import sys
import os

# Prüfe und setze Shell-Umgebung
if 'SHELL' not in os.environ:
    # Prüfe verfügbare Shells
    for shell in ["/bin/bash", "/bin/sh", "/usr/bin/bash", "/usr/bin/zsh"]:
        if os.path.exists(shell) and os.access(shell, os.X_OK):
            os.environ['SHELL'] = shell
            break

def run_cmd(cmd, check=True):
    """Führt Befehl aus - ohne Shell"""
    try:
        # Verwende subprocess ohne shell=True für bessere Kompatibilität
        if isinstance(cmd, str):
            # Für einfache Befehle: split in Liste
            if ' ' in cmd and not cmd.startswith('sshpass'):
                cmd_list = cmd.split()
            else:
                # Für komplexe Befehle: verwende shell, aber mit expliziter Shell
                shells = ["/bin/bash", "/bin/sh", "/usr/bin/bash"]
                for shell in shells:
                    if os.path.exists(shell):
                        result = subprocess.run(
                            cmd,
                            shell=True,
                            executable=shell,
                            capture_output=True,
                            text=True,
                            timeout=120
                        )
                        if check and result.returncode != 0:
                            print(f"Fehler: {result.stderr}")
                            return False, result.stdout, result.stderr
                        return True, result.stdout, result.stderr
                # Fallback: ohne shell
                cmd_list = cmd.split()
        else:
            cmd_list = cmd
        
        result = subprocess.run(
            cmd_list,
            capture_output=True,
            text=True,
            timeout=120
        )
        if check and result.returncode != 0:
            print(f"Fehler: {result.stderr}")
            return False, result.stdout, result.stderr
        return True, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Timeout"
    except Exception as e:
        return False, "", str(e)

def install_sshpass():
    """Installiert sshpass"""
    print("Prüfe sshpass...")
    success, _, _ = run_cmd("which sshpass", check=False)
    if success:
        print("✅ sshpass bereits installiert")
        return True
    
    print("Installiere sshpass...")
    
    # Prüfe Homebrew
    success, _, _ = run_cmd("which brew", check=False)
    if not success:
        print("Installiere Homebrew...")
        run_cmd('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"', check=False)
    
    # Installiere sshpass
    success, stdout, stderr = run_cmd("brew install hudochenkov/sshpass/sshpass", check=False)
    if success:
        print("✅ sshpass installiert")
        return True
    else:
        print(f"⚠️  Installation fehlgeschlagen: {stderr}")
        return False

def execute_display_fix():
    """Führt Display-Fix aus"""
    script_path = os.path.join(os.path.dirname(__file__), "FIX_MOODE_DISPLAY_FINAL.sh")
    if not os.path.exists(script_path):
        print(f"❌ Script nicht gefunden: {script_path}")
        return False
    
    print("Führe Display-Fix aus...")
    os.chmod(script_path, 0o755)
    success, stdout, stderr = run_cmd(f"bash {script_path}", check=False)
    
    print(stdout)
    if stderr:
        print(stderr)
    
    return success

def reboot_pi():
    """Rebootet Pi"""
    print("Reboote Pi...")
    success, stdout, stderr = run_cmd(
        "sshpass -p '0815' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 andre@192.168.178.178 'sudo reboot'",
        check=False
    )
    if success:
        print("✅ Reboot-Befehl gesendet")
    else:
        print(f"⚠️  Reboot-Befehl: {stderr}")
    return success

def main():
    print("=== DISPLAY-FIX AUSFÜHRUNG ===")
    print("")
    
    # 1. sshpass installieren
    if not install_sshpass():
        print("⚠️  sshpass nicht verfügbar, versuche trotzdem...")
    
    print("")
    
    # 2. Display-Fix ausführen
    if execute_display_fix():
        print("")
        print("✅ Display-Fix ausgeführt")
        print("")
        
        # 3. Reboot
        reboot_pi()
        print("")
        print("=== FERTIG ===")
        print("Pi wird rebootet. Warte 1-2 Minuten, dann Verifikation ausführen.")
        return 0
    else:
        print("")
        print("❌ Display-Fix fehlgeschlagen")
        return 1

if __name__ == "__main__":
    sys.exit(main())


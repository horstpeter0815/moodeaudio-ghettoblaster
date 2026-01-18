#!/usr/bin/env python3
"""
Prüft Shell-Umgebung und behebt Probleme
"""
import subprocess
import os
import sys
import shutil

def run_cmd(cmd, shell=True):
    """Führt Befehl aus"""
    try:
        result = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=10)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def main():
    print("=== SHELL-Umgebung prüfen ===")
    print("")
    
    # 1. Prüfe verfügbare Shells
    print("1. Verfügbare Shells:")
    shells = ["/bin/zsh", "/bin/bash", "/bin/sh", "/usr/bin/zsh", "/usr/bin/bash"]
    for shell in shells:
        exists = os.path.exists(shell)
        executable = os.access(shell, os.X_OK) if exists else False
        status = "✅" if (exists and executable) else "❌"
        print(f"   {status} {shell} (exists: {exists}, executable: {executable})")
    print("")
    
    # 2. Prüfe SHELL Environment Variable
    print("2. Environment Variables:")
    shell_env = os.environ.get("SHELL", "Nicht gesetzt")
    print(f"   SHELL: {shell_env}")
    print(f"   PATH: {os.environ.get('PATH', 'Nicht gesetzt')}")
    print("")
    
    # 3. Prüfe welche Shell verfügbar ist
    print("3. Verfügbare Shell (which):")
    for shell_cmd in ["zsh", "bash", "sh"]:
        success, stdout, _ = run_cmd(f"which {shell_cmd}", shell=False)
        if success:
            print(f"   ✅ {shell_cmd}: {stdout.strip()}")
        else:
            print(f"   ❌ {shell_cmd}: nicht gefunden")
    print("")
    
    # 4. Teste direkten Shell-Aufruf
    print("4. Teste Shell-Aufruf:")
    test_shells = []
    for shell_path in shells:
        if os.path.exists(shell_path) and os.access(shell_path, os.X_OK):
            test_shells.append(shell_path)
    
    for shell_path in test_shells:
        success, stdout, stderr = run_cmd([shell_path, "-c", "echo 'Shell funktioniert'"], shell=False)
        if success:
            print(f"   ✅ {shell_path}: funktioniert")
            print(f"      Output: {stdout.strip()}")
        else:
            print(f"   ❌ {shell_path}: fehlgeschlagen")
            print(f"      Error: {stderr.strip()}")
    print("")
    
    # 5. Prüfe Python subprocess
    print("5. Teste Python subprocess:")
    try:
        result = subprocess.run(["echo", "test"], capture_output=True, text=True, timeout=5)
        print(f"   ✅ subprocess.run funktioniert")
        print(f"      Output: {result.stdout.strip()}")
    except Exception as e:
        print(f"   ❌ subprocess.run fehlgeschlagen: {e}")
    print("")
    
    # 6. Empfehlung
    print("=== EMPFEHLUNG ===")
    if test_shells:
        print(f"Verwende: {test_shells[0]}")
        print(f"Setze SHELL={test_shells[0]}")
    else:
        print("⚠️  Keine funktionierende Shell gefunden")
        print("Versuche Python subprocess direkt zu verwenden")
    print("")

if __name__ == "__main__":
    main()


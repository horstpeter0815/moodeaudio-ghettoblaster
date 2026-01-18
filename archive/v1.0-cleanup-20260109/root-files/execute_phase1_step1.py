#!/usr/bin/env python3
"""
Phase 1, Schritt 1.1: Hardware-Identifikation
Führt Hardware-Scan auf Moode Audio Pi 5 aus
"""

import subprocess
import sys
import os

PI_IP = "192.168.178.178"
PI_USER = "andre"
PI_PASS = "0815"

def run_remote_command(command):
    """Führt Befehl per SSH aus"""
    ssh_cmd = [
        "sshpass", "-p", PI_PASS,
        "ssh", "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=10",
        f"{PI_USER}@{PI_IP}",
        command
    ]
    
    try:
        result = subprocess.run(
            ssh_cmd,
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Timeout"
    except Exception as e:
        return False, "", str(e)

def copy_file_to_pi(local_file, remote_path):
    """Kopiert Datei auf Pi"""
    scp_cmd = [
        "sshpass", "-p", PI_PASS,
        "scp", "-o", "StrictHostKeyChecking=no",
        local_file,
        f"{PI_USER}@{PI_IP}:{remote_path}"
    ]
    
    try:
        result = subprocess.run(scp_cmd, capture_output=True, text=True, timeout=30)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def main():
    print("=== PHASE 1.1: HARDWARE-IDENTIFIKATION ===")
    print("")
    
    # 1. Script auf Pi kopieren
    script_path = os.path.join(os.path.dirname(__file__), "phase1_step1_hardware_scan.sh")
    if not os.path.exists(script_path):
        print(f"❌ Script nicht gefunden: {script_path}")
        return 1
    
    print("1. Kopiere Script auf Pi...")
    success, stdout, stderr = copy_file_to_pi(script_path, "/tmp/phase1_step1_hardware_scan.sh")
    if not success:
        print(f"❌ Fehler beim Kopieren: {stderr}")
        return 1
    print("✅ Script kopiert")
    print("")
    
    # 2. Script ausführbar machen
    print("2. Mache Script ausführbar...")
    success, stdout, stderr = run_remote_command("chmod +x /tmp/phase1_step1_hardware_scan.sh")
    if not success:
        print(f"⚠️  Warnung: {stderr}")
    else:
        print("✅ Script ausführbar")
    print("")
    
    # 3. Script ausführen
    print("3. Führe Hardware-Scan aus...")
    success, stdout, stderr = run_remote_command("bash /tmp/phase1_step1_hardware_scan.sh")
    
    print("=== ERGEBNISSE ===")
    print(stdout)
    if stderr:
        print("=== WARNUNGEN/FEHLER ===")
        print(stderr)
    print("")
    
    # 4. Ergebnisse abrufen
    print("4. Lade Ergebnisse...")
    success, stdout, stderr = run_remote_command("cat /tmp/phase1_step1_results.txt")
    if success:
        results_file = os.path.join(os.path.dirname(__file__), "PHASE1_STEP1_RESULTS.md")
        with open(results_file, "w") as f:
            f.write("# Phase 1, Schritt 1.1: Hardware-Identifikation - Ergebnisse\n\n")
            f.write("## Durchgeführte Prüfungen:\n\n")
            f.write(stdout)
        print(f"✅ Ergebnisse gespeichert in: {results_file}")
    else:
        print(f"⚠️  Ergebnisse nicht abrufbar: {stderr}")
    
    print("")
    print("✅ Phase 1.1 abgeschlossen")
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())


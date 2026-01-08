#!/usr/bin/env python3
"""
🎯 SMART AI MANAGER COCKPIT
Grafisches Dashboard für System-Übersicht
"""

from flask import Flask, render_template, jsonify
import subprocess
import os
import json
import psutil
import time
from datetime import datetime
from pathlib import Path

app = Flask(__name__)
SCRIPT_DIR = Path(__file__).parent.parent

class SystemMonitor:
    def __init__(self):
        self.last_update = datetime.now()
        
    def get_active_processes(self):
        """Ermittelt aktive Prozesse mit Ressourcen-Nutzung"""
        processes = []
        
        # Alle System-Prozesse finden
        process_patterns = {
            'AUTONOMOUS_WORK_SYSTEM': {'name': 'Autonomous Work System', 'type': 'monitoring', 'category': 'autonomous', 'priority': 'medium'},
            'AUTONOMOUS_FIX_SYSTEM': {'name': 'Autonomous Fix System', 'type': 'monitoring', 'category': 'autonomous', 'priority': 'high'},
            'AUTONOMOUS_ARCHIVE_SYSTEM': {'name': 'Autonomous Archive System', 'type': 'maintenance', 'category': 'storage', 'priority': 'low'},
            'AUTONOMOUS_BUILD_WORKER': {'name': 'Autonomous Build Worker', 'type': 'build', 'category': 'build', 'priority': 'high'},
            'STORAGE_CLEANUP': {'name': 'Storage Cleanup', 'type': 'maintenance', 'category': 'storage', 'priority': 'low'},
            'AUTOMATED_CLEANUP_SCHEDULE': {'name': 'Automated Cleanup Schedule', 'type': 'maintenance', 'category': 'storage', 'priority': 'low'},
            'MONITOR_BUILD': {'name': 'Build Monitor', 'type': 'monitoring', 'category': 'build', 'priority': 'medium'},
            'MONITOR_PI': {'name': 'Pi Monitor', 'type': 'monitoring', 'category': 'monitoring', 'priority': 'medium'},
            'ARCHIVE_TO_NAS': {'name': 'NAS Archive', 'type': 'maintenance', 'category': 'storage', 'priority': 'low'},
            'python.*app.py': {'name': 'Cockpit Dashboard', 'type': 'dashboard', 'category': 'management', 'priority': 'low'},
        }
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                p = psutil.Process(proc.info['pid'])
                cmdline = ' '.join(proc.info['cmdline'] or [])
                
                for pattern, info in process_patterns.items():
                    if pattern in cmdline or (pattern.startswith('python') and 'app.py' in cmdline):
                        # CPU und Memory messen
                        cpu_percent = p.cpu_percent(interval=0.1)
                        memory_info = p.memory_info()
                        memory_mb = round(memory_info.rss / (1024*1024), 1)
                        
                        processes.append({
                            'name': info['name'],
                            'status': 'active',
                            'pid': proc.info['pid'],
                            'type': info['type'],
                            'category': info['category'],
                            'priority': info['priority'],
                            'cpu_percent': round(cpu_percent, 1),
                            'memory_mb': memory_mb,
                            'memory_percent': round((memory_info.rss / psutil.virtual_memory().total) * 100, 2)
                        })
                        break
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
                
        # Sortiere nach CPU-Nutzung (höchste zuerst)
        processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
        return processes
    
    def get_resource_usage_summary(self):
        """Zusammenfassung der Ressourcen-Nutzung"""
        processes = self.get_active_processes()
        
        total_cpu = sum(p.get('cpu_percent', 0) for p in processes)
        total_memory_mb = sum(p.get('memory_mb', 0) for p in processes)
        
        # Gruppiere nach Kategorie
        by_category = {}
        for proc in processes:
            cat = proc.get('category', 'other')
            if cat not in by_category:
                by_category[cat] = {'cpu': 0, 'memory_mb': 0, 'count': 0}
            by_category[cat]['cpu'] += proc.get('cpu_percent', 0)
            by_category[cat]['memory_mb'] += proc.get('memory_mb', 0)
            by_category[cat]['count'] += 1
        
        return {
            'total_cpu': round(total_cpu, 1),
            'total_memory_mb': round(total_memory_mb, 1),
            'by_category': by_category,
            'top_processes': processes[:5]  # Top 5 Prozesse
        }
    
    def get_scheduling_suggestions(self):
        """Intelligente Scheduling-Vorschläge"""
        suggestions = []
        processes = self.get_active_processes()
        
        # Prüfe ob Build läuft
        build_running = any('build' in p.get('name', '').lower() for p in processes)
        
        # Prüfe CPU-Last
        cpu_status = self.get_cpu_status()
        high_cpu = cpu_status.get('total_percent', 0) > 70
        
        if build_running and high_cpu:
            suggestions.append({
                'type': 'warning',
                'message': 'Build läuft - Forschung/Archive sollte nachts laufen',
                'action': 'Niedrig-prioritäre Tasks pausieren'
            })
        
        # Prüfe Memory
        ram_status = self.get_ram_status()
        if ram_status.get('percent', 0) > 80:
            suggestions.append({
                'type': 'warning',
                'message': 'Hohe RAM-Nutzung - Cleanup empfohlen',
                'action': 'Storage Cleanup ausführen'
            })
        
        # Prüfe niedrig-prioritäre Tasks bei hoher Last
        low_priority_running = [p for p in processes if p.get('priority') == 'low' and p.get('cpu_percent', 0) > 5]
        if low_priority_running and high_cpu:
            suggestions.append({
                'type': 'info',
                'message': f'{len(low_priority_running)} niedrig-prioritäre Tasks laufen',
                'action': 'Können nachts verschoben werden'
            })
        
        return suggestions
    
    def get_pi_status(self):
        """Prüft Pi-Status"""
        pi_ips = ["192.168.178.143", "192.168.178.161", "192.168.178.162"]
        for ip in range(160, 181):
            pi_ips.append(f"192.168.178.{ip}")
        
        for ip in pi_ips[:5]:  # Nur erste 5 prüfen (Performance)
            try:
                result = subprocess.run(
                    ['ping', '-c', '1', '-W', '1', ip],
                    capture_output=True,
                    timeout=2
                )
                if result.returncode == 0:
                    return {'status': 'online', 'ip': ip}
            except:
                pass
        
        return {'status': 'offline', 'ip': None}
    
    def get_storage_status(self):
        """Ermittelt Speicherplatz"""
        try:
            stat = os.statvfs(SCRIPT_DIR)
            total = stat.f_blocks * stat.f_frsize
            available = stat.f_bavail * stat.f_frsize
            used = total - available
            percent = (used / total) * 100
            
            return {
                'total_gb': round(total / (1024**3), 1),
                'used_gb': round(used / (1024**3), 1),
                'available_gb': round(available / (1024**3), 1),
                'percent': round(percent, 1)
            }
        except:
            return {'total_gb': 0, 'used_gb': 0, 'available_gb': 0, 'percent': 0}
    
    def get_ram_status(self):
        """Ermittelt RAM-Status"""
        try:
            mem = psutil.virtual_memory()
            return {
                'total_gb': round(mem.total / (1024**3), 2),
                'used_gb': round(mem.used / (1024**3), 2),
                'available_gb': round(mem.available / (1024**3), 2),
                'percent': round(mem.percent, 1)
            }
        except:
            return {'total_gb': 0, 'used_gb': 0, 'available_gb': 0, 'percent': 0}
    
    def get_cpu_status(self):
        """Ermittelt CPU-Status"""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            cpu_count = psutil.cpu_count(logical=True)
            cpu_cores = psutil.cpu_count(logical=False)
            cpu_per_core = psutil.cpu_percent(interval=0.1, percpu=True)
            
            return {
                'total_percent': round(cpu_percent, 1),
                'cores': cpu_cores,
                'threads': cpu_count,
                'per_core': [round(p, 1) for p in cpu_per_core]
            }
        except:
            return {'total_percent': 0, 'cores': 0, 'threads': 0, 'per_core': []}
    
    def get_recent_logs(self):
        """Liest letzte Log-Einträge"""
        log_file = SCRIPT_DIR / "autonomous-work.log"
        if log_file.exists():
            try:
                with open(log_file, 'r') as f:
                    lines = f.readlines()
                    return lines[-10:] if len(lines) > 10 else lines
            except:
                pass
        return []
    
    def get_departments(self):
        """Ermittelt alle Abteilungen/Systeme"""
        departments = {
            'management': {
                'name': 'Management',
                'systems': ['Cockpit Dashboard', 'System Overview'],
                'status': 'active'
            },
            'autonomous': {
                'name': 'Autonomous Systems',
                'systems': [],
                'status': 'inactive'
            },
            'build': {
                'name': 'Build Department',
                'systems': [],
                'status': 'inactive'
            },
            'storage': {
                'name': 'Storage Management',
                'systems': [],
                'status': 'inactive'
            },
            'monitoring': {
                'name': 'Monitoring',
                'systems': [],
                'status': 'inactive'
            },
            '3d': {
                'name': '3D Department',
                'systems': ['3D Printing', 'Acoustics', 'Analyses'],
                'status': 'available'
            },
            'content': {
                'name': 'Content',
                'systems': ['Documentation', 'Guides', 'Theory'],
                'status': 'available'
            },
            'testing': {
                'name': 'Testing',
                'systems': ['Test Suite', 'Simulation', 'Boot Tests'],
                'status': 'available'
            }
        }
        
        # Fülle mit aktiven Prozessen
        processes = self.get_active_processes()
        for proc in processes:
            category = proc.get('category', 'other')
            if category in departments:
                if proc['name'] not in departments[category]['systems']:
                    departments[category]['systems'].append(proc['name'])
                departments[category]['status'] = 'active'
        
        return departments
    
    def get_system_status(self):
        """Gesamter System-Status"""
        return {
            'timestamp': datetime.now().isoformat(),
            'processes': self.get_active_processes(),
            'departments': self.get_departments(),
            'resource_usage': self.get_resource_usage_summary(),
            'scheduling_suggestions': self.get_scheduling_suggestions(),
            'pi': self.get_pi_status(),
            'storage': self.get_storage_status(),
            'ram': self.get_ram_status(),
            'cpu': self.get_cpu_status(),
            'logs': self.get_recent_logs()
        }

monitor = SystemMonitor()

@app.route('/')
def index():
    """Haupt-Dashboard"""
    return render_template('cockpit.html')

@app.route('/api/status')
def api_status():
    """API für System-Status"""
    return jsonify(monitor.get_system_status())

if __name__ == '__main__':
    import socket
    
    # Finde freien Port (starte bei 5001, da 5000 oft von AirPlay belegt ist)
    port = 5001
    for p in range(5001, 5010):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('127.0.0.1', p))
        sock.close()
        if result != 0:
            port = p
            break
    
    print("🎯 Starting Smart AI Manager Cockpit...")
    print(f"📊 Dashboard: http://localhost:{port}")
    print(f"🌐 Oder: http://127.0.0.1:{port}")
    app.run(host='0.0.0.0', port=port, debug=True)


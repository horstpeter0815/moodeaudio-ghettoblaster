# CODING GUIDELINES - GHETTOBLASTER

**Datum:** 2. Dezember 2025  
**Status:** DRAFT

---

## 🎯 PRINZIPIEN

### **1. Klarheit über Komplexität**
- Code muss lesbar und verständlich sein
- Kommentare für komplexe Logik
- Selbst-dokumentierender Code wo möglich

### **2. Robustheit**
- Fehlerbehandlung in allen Scripts
- Validierung von Eingaben
- Graceful Degradation

### **3. Wartbarkeit**
- Modulare Struktur
- Wiederverwendbare Funktionen
- Konsistente Namenskonventionen

---

## 📋 SHELL SCRIPT GUIDELINES

### **Shebang:**
```bash
#!/bin/bash
```

### **Error Handling:**
```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

### **Logging:**
```bash
log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}
```

### **Function Structure:**
```bash
function_name() {
    local var1="$1"
    local var2="$2"
    
    # Validation
    if [ -z "$var1" ]; then
        log "ERROR: var1 is required"
        return 1
    fi
    
    # Implementation
    # ...
    
    return 0
}
```

---

## 📋 SYSTEMD SERVICE GUIDELINES

### **Service Structure:**
```ini
[Unit]
Description=Clear description
After=dependency.service
Wants=dependency.service
Requires=critical-dependency.service

[Service]
Type=simple
User=username
Environment=VAR=value
ExecStartPre=/path/to/pre-script.sh
ExecStart=/path/to/main-script.sh
Restart=on-failure
RestartSec=5
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
```

### **Best Practices:**
- Klare Beschreibungen
- Korrekte Dependencies
- Timeout-Werte setzen
- Restart-Policy definieren
- User-spezifische Services

---

## 📋 PYTHON GUIDELINES (für PeppyMeter)

### **Style:**
- PEP 8 konform
- Type Hints wo möglich
- Docstrings für Funktionen

### **Error Handling:**
```python
try:
    # Code
except SpecificError as e:
    logger.error(f"Error: {e}")
    raise
```

---

## 📋 DOCUMENTATION STANDARDS

### **Script Header:**
```bash
#!/bin/bash
################################################################################
#
# Script Name
#
# Description: What does this script do?
# Author: Ghettoblaster Custom Build
# Date: YYYY-MM-DD
# License: GPLv3
#
################################################################################
```

### **Function Documentation:**
```bash
# Function: function_name
# Description: What does this function do?
# Parameters:
#   $1 - Parameter description
#   $2 - Parameter description
# Returns: 0 on success, 1 on error
```

---

**Status:** DRAFT - Wird durch Research erweitert


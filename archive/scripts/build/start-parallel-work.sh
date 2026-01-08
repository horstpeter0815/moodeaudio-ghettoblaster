#!/bin/bash
################################################################################
#
# START PARALLEL WORK - Nutzt Mac-Ressourcen optimal
#
# (C) 2025 Ghettoblaster Custom Build
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/parallel-work-logs"
mkdir -p "$LOG_DIR"

CPU_CORES=$(sysctl -n hw.ncpu)
MAX_PARALLEL=$((CPU_CORES - 2))  # Reserve cores

echo "🚀 PARALLEL WORK START"
echo "CPU Cores: $CPU_CORES"
echo "Max Parallel: $MAX_PARALLEL"
echo ""

# Task 1: Script-Analyse
echo "⚡ Starte Task 1: Script-Analyse..."
if [ -f "$SCRIPT_DIR/analyze-scripts.sh" ]; then
    "$SCRIPT_DIR/analyze-scripts.sh" > "$LOG_DIR/task1-script-analysis.log" 2>&1 &
    PID1=$!
    echo "  PID: $PID1"
else
    echo "  ⚠️  analyze-scripts.sh nicht gefunden"
fi

# Task 2: Config-Validierung
echo "⚡ Starte Task 2: Config-Validierung..."
(
    cd "$SCRIPT_DIR"
    find . -name "*.service" -o -name "config.txt*" -o -name "cmdline.txt*" | \
    head -50 | while read file; do
        echo "Validating: $file"
        if [[ "$file" == *.service ]]; then
            echo "  Service file: $file"
        fi
    done
) > "$LOG_DIR/task2-config-validation.log" 2>&1 &
PID2=$!
echo "  PID: $PID2"

# Task 3: Dependency Analysis
echo "⚡ Starte Task 3: Dependency Analysis..."
(
    cd "$SCRIPT_DIR"
    find . -name "*.service" -exec grep -l "After\|Wants\|Requires" {} \; | \
    head -20 | while read service; do
        echo "Analyzing: $service"
        grep -h "After\|Wants\|Requires" "$service" || true
    done
) > "$LOG_DIR/task3-dependencies.log" 2>&1 &
PID3=$!
echo "  PID: $PID3"

# Task 4: Find important scripts
echo "⚡ Starte Task 4: Find Important Scripts..."
(
    cd "$SCRIPT_DIR"
    echo "=== CUSTOM COMPONENTS SCRIPTS ==="
    find custom-components -name "*.sh" 2>/dev/null
    echo ""
    echo "=== BUILD SCRIPTS ==="
    find . -path "*/imgbuild/*" -name "*.sh" 2>/dev/null | head -10
    echo ""
    echo "=== SETUP SCRIPTS ==="
    find . -name "*setup*.sh" -o -name "*build*.sh" 2>/dev/null | grep -v ".git" | head -20
) > "$LOG_DIR/task4-important-scripts.log" 2>&1 &
PID4=$!
echo "  PID: $PID4"

# Task 5: Service Files Analysis
echo "⚡ Starte Task 5: Service Files Analysis..."
(
    cd "$SCRIPT_DIR"
    find custom-components -name "*.service" 2>/dev/null | while read service; do
        echo "=== $service ==="
        cat "$service" 2>/dev/null || echo "  Could not read"
        echo ""
    done
) > "$LOG_DIR/task5-services.log" 2>&1 &
PID5=$!
echo "  PID: $PID5"

echo ""
echo "✅ Alle Tasks gestartet!"
echo ""
echo "Warte auf Completion..."
wait $PID1 2>/dev/null && echo "✅ Task 1 fertig" || echo "⚠️  Task 1 beendet"
wait $PID2 2>/dev/null && echo "✅ Task 2 fertig" || echo "⚠️  Task 2 beendet"
wait $PID3 2>/dev/null && echo "✅ Task 3 fertig" || echo "⚠️  Task 3 beendet"
wait $PID4 2>/dev/null && echo "✅ Task 4 fertig" || echo "⚠️  Task 4 beendet"
wait $PID5 2>/dev/null && echo "✅ Task 5 fertig" || echo "⚠️  Task 5 beendet"

echo ""
echo "=== ALLE TASKS ABGESCHLOSSEN ==="
echo "Logs in: $LOG_DIR"
ls -lh "$LOG_DIR"


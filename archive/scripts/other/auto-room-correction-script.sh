#!/bin/bash
# Automatic Room Correction Script
# Integriert Rosa Rauschen, Handy-Mikrofon, RTA, und automatische Filter-Generierung

LOG_FILE="/var/log/auto-room-correction.log"
MEASUREMENT_DIR="/tmp/room-correction"
DURATION=${1:-60}  # Messdauer in Sekunden
VOLUME=${2:-"-20"}  # Lautstärke in dB

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Erstelle Verzeichnis
mkdir -p "$MEASUREMENT_DIR"

log "=== AUTOMATIC ROOM CORRECTION ==="
log "Dauer: $DURATION Sekunden"
log "Lautstärke: $VOLUME dB"

log ""
log "=== SCHRITT 1: AUDIO-INPUTS PRÜFEN ==="

# Prüfe verfügbare Audio-Inputs
AUDIO_INPUTS=$(/opt/hifiberry/bin/audio-inputs 2>/dev/null)
if [ -z "$AUDIO_INPUTS" ]; then
    log "❌ Keine Audio-Inputs gefunden"
    log "   Bitte Handy-Mikrofon anschließen (USB)"
    exit 1
fi

log "Verfügbare Audio-Inputs:"
echo "$AUDIO_INPUTS" | tee -a "$LOG_FILE"

# Wähle USB-Mikrofon (Handy) oder erstes verfügbares
MIC=$(echo "$AUDIO_INPUTS" | grep -i usb | awk -F: '{print $1}' | head -1)
if [ -z "$MIC" ]; then
    MIC=$(echo "$AUDIO_INPUTS" | awk -F: '{print $1}' | head -1)
fi

if [ -z "$MIC" ]; then
    log "❌ Kein Mikrofon gefunden"
    exit 1
fi

MIC_DEVICE="hw:$MIC,0"
log "✅ Mikrofon gefunden: $MIC_DEVICE"

log ""
log "=== SCHRITT 2: ROSA RAUSCHEN GENERIEREN ==="

log "Starte Rosa Rauschen (Pink Noise)..."
# Rosa Rauschen im Hintergrund starten
play -q -n synth $DURATION pinknoise vol ${VOLUME}dB 2>&1 &
NOISE_PID=$!
log "Rosa Rauschen läuft (PID: $NOISE_PID)"

# Warte kurz, damit Rauschen startet
sleep 2

log ""
log "=== SCHRITT 3: HANDY-MIKROFON AUFNEHMEN ==="

log "Starte Aufnahme vom Handy-Mikrofon..."
RECORDING_FILE="$MEASUREMENT_DIR/recording.wav"

# Aufnahme starten
arecord -D "$MIC_DEVICE" -f cd -t wav -d $DURATION "$RECORDING_FILE" 2>&1 &
RECORD_PID=$!
log "Aufnahme läuft (PID: $RECORD_PID)"

# Warte auf Aufnahme-Ende
wait $RECORD_PID
wait $NOISE_PID

log "✅ Aufnahme abgeschlossen: $RECORDING_FILE"

log ""
log "=== SCHRITT 4: REAL TIME ANALYZER (RTA) ==="

log "Analysiere Frequenzgang..."
# Signal-Datei für Vergleich (Rosa Rauschen)
SIGNAL_FILE="$MEASUREMENT_DIR/signal.wav"

# Generiere Referenz-Signal (Rosa Rauschen)
play -q -n synth $DURATION pinknoise vol ${VOLUME}dB -t wav "$SIGNAL_FILE" 2>&1

# FFT-Analyse
FFT_OUTPUT="$MEASUREMENT_DIR/fftdB_vbw.csv"
/opt/hifiberry/bin/fft-analzye -v 1 -r "$SIGNAL_FILE" "$RECORDING_FILE" 2>&1 | tee -a "$LOG_FILE"

if [ -f "$FFT_OUTPUT" ]; then
    log "✅ Frequenzgang-Daten: $FFT_OUTPUT"
else
    log "❌ FFT-Analyse fehlgeschlagen"
    exit 1
fi

log ""
log "=== SCHRITT 5: DATEN KONVERTIEREN ==="

log "Konvertiere FFT-Daten zu JSON-Format..."

# Konvertiere CSV zu JSON für roomeq-optimize
JSON_FILE="$MEASUREMENT_DIR/measurement.json"

# Parse FFT-Daten und erstelle JSON
python3 << EOF > "$JSON_FILE"
import json
import csv

# Lese FFT-Daten
frequencies = []
db_values = []

with open('$FFT_OUTPUT', 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    for row in reader:
        if len(row) >= 2:
            try:
                freq = float(row[0])
                db = float(row[1])
                frequencies.append(int(freq))
                db_values.append(db)
            except:
                pass

# Erstelle JSON für roomeq-optimize
measurement_data = {
    "measurement": {
        "f": frequencies,
        "db": db_values
    },
    "curve": "flat",
    "optimizer": "smooth",
    "filtercount": 10,
    "samplerate": 48000,
    "settings": {
        "qmax": 10,
        "mindb": -10,
        "maxdb": 3,
        "add_highpass": True
    }
}

with open('$JSON_FILE', 'w') as f:
    json.dump(measurement_data, f, indent=2)

print(f"JSON erstellt: {len(frequencies)} Frequenzpunkte")
EOF

if [ -f "$JSON_FILE" ]; then
    log "✅ JSON-Daten: $JSON_FILE"
else
    log "❌ JSON-Konvertierung fehlgeschlagen"
    exit 1
fi

log ""
log "=== SCHRITT 6: FILTER GENERIEREN ==="

log "Generiere DSP-Filter mit roomeq-optimize..."
FILTER_OUTPUT="$MEASUREMENT_DIR/filters.json"

/opt/hifiberry/bin/roomeq-optimize "$JSON_FILE" > "$FILTER_OUTPUT" 2>&1
OPTIMIZE_RESULT=$?

if [ $OPTIMIZE_RESULT -eq 0 ] && [ -f "$FILTER_OUTPUT" ]; then
    log "✅ Filter generiert: $FILTER_OUTPUT"
    
    # Zeige Filter-Definitionen
    log "Filter-Definitionen:"
    grep -A 100 '"eqdefinitions"' "$FILTER_OUTPUT" | head -20 | tee -a "$LOG_FILE"
else
    log "❌ Filter-Generierung fehlgeschlagen"
    exit 1
fi

log ""
log "=== SCHRITT 7: DSP-FILTER ANWENDEN ==="

log "Wende Filter auf DSP an..."

# Extrahiere Filter-Definitionen
FILTER_DEFS=$(grep -A 100 '"eqdefinitions"' "$FILTER_OUTPUT" | grep -o '"[^"]*"' | sed 's/"//g')

if [ -z "$FILTER_DEFS" ]; then
    log "⚠️  Keine Filter-Definitionen gefunden"
    log "   Filter-Datei: $FILTER_OUTPUT"
    exit 1
fi

log "Filter-Definitionen gefunden:"
echo "$FILTER_DEFS" | tee -a "$LOG_FILE"

# Prüfe ob DSP verfügbar ist
DSP_DETECTED=$(dsptoolkit --timeout=20 get-meta detected_dsp 2>/dev/null)
if [ "$DSP_DETECTED" != "yes" ]; then
    log "⚠️  DSP nicht erkannt"
    log "   Filter können nicht angewendet werden"
    log "   Filter-Definitionen gespeichert in: $FILTER_OUTPUT"
    exit 1
fi

log "✅ DSP erkannt, wende Filter an..."

# Wende Filter an (jeder Filter einzeln)
for filter in $FILTER_DEFS; do
    log "   Filter: $filter"
    # Filter-Format: "eq:f0:q:db" oder "hp:f0:q"
    # TODO: dsptoolkit Befehl zum Setzen von Filtern
    # dsptoolkit set-filter "$filter" 2>&1 | tee -a "$LOG_FILE"
done

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Messung abgeschlossen"
log "✅ Filter generiert: $FILTER_OUTPUT"
log "✅ Filter-Definitionen: $FILTER_DEFS"
log ""
log "Nächste Schritte:"
log "  1. Filter-Definitionen prüfen"
log "  2. Filter auf DSP anwenden (manuell oder automatisch)"
log "  3. Ergebnis testen"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ AUTOMATIC ROOM CORRECTION ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"


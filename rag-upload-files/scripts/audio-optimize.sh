#!/bin/bash
################################################################################
#
# Audio Optimization Script for High-End HiFi
#
# - Optimizes ALSA configuration for 192kHz/32-bit
# - Sets CPU governor to performance
# - Configures optimal buffer/period settings
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

LOG_FILE="/var/log/audio-optimize.log"

################################################################################
# Logging function
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# Set CPU governor to performance
################################################################################

optimize_cpu_governor() {
    log "🔧 Optimizing CPU governor for audio..."
    
    # Set CPU governor to performance for all CPUs
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" > "$cpu" 2>/dev/null && \
                log "✅ CPU governor set to performance: $(dirname $cpu)" || \
                log "⚠️  Failed to set CPU governor: $(dirname $cpu)"
        fi
    done
    
    # Set minimum frequency to maximum for performance
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
        if [ -f "$cpu" ]; then
            max_freq=$(cat "$(dirname $cpu)/cpufreq/scaling_max_freq" 2>/dev/null)
            if [ -n "$max_freq" ]; then
                echo "$max_freq" > "$cpu" 2>/dev/null && \
                    log "✅ CPU min frequency set to max: $(dirname $cpu)" || \
                    log "⚠️  Failed to set CPU min frequency: $(dirname $cpu)"
            fi
        fi
    done
    
    log "✅ CPU governor optimization complete"
}

################################################################################
# Optimize ALSA configuration
################################################################################

optimize_alsa() {
    log "🔧 Optimizing ALSA configuration for High-End Audio..."
    
    # Check if ALSA config exists
    ALSA_CONFIG="/etc/asound.conf"
    
    # Create backup if exists
    if [ -f "$ALSA_CONFIG" ]; then
        cp "$ALSA_CONFIG" "${ALSA_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        log "✅ ALSA config backup created"
    fi
    
    # Create optimized ALSA config
    cat > "$ALSA_CONFIG" << 'ALSA_EOF'
# Ghettoblaster High-End Audio Configuration
# Optimized for HiFiBerry AMP100
# 192kHz / 32-bit / Low Latency

defaults.pcm.rate_converter "samplerate"

defaults.pcm.card 0
defaults.ctl.card 0

# Hardware device
pcm.hifiberry {
    type hw
    card 0
    device 0
}

# Direct Mixer for low latency
pcm.dmixer {
    type dmix
    ipc_key 1024
    ipc_perm 0666
    slave.pcm "hifiberry"
    slave {
        period_time 0
        period_size 2048      # Optimal for Pi 5
        buffer_size 32768     # Low latency buffer
        rate 192000          # High-End: 192kHz
        format S32_LE         # High-End: 32-bit
    }
    bindings {
        0 0
        1 1
    }
}

ctl.dmixer {
    type hw
    card 0
}

# Software volume control
pcm.softvol {
    type softvol
    slave.pcm "dmixer"
    control {
        name "Softvol"
        card 0
    }
    min_dB -90.2
    max_dB 0.0
}

# Default PCM device
pcm.!default {
    type plug
    slave.pcm "softvol"
}
ALSA_EOF

    log "✅ ALSA configuration optimized (192kHz/32-bit)"
}

################################################################################
# Set IRQ affinity for audio (optional)
################################################################################

optimize_irq_affinity() {
    log "🔧 Optimizing IRQ affinity for audio..."
    
    # Find audio-related IRQs
    AUDIO_IRQS=$(grep -E "snd|i2s|i2c.*audio" /proc/interrupts | awk '{print $1}' | sed 's/://')
    
    if [ -n "$AUDIO_IRQS" ]; then
        for irq in $AUDIO_IRQS; do
            # Set IRQ affinity to CPU 2,3 (isolate from system)
            echo "2,3" > "/proc/irq/$irq/smp_affinity" 2>/dev/null && \
                log "✅ IRQ $irq affinity set to CPU 2,3" || \
                log "⚠️  Failed to set IRQ $irq affinity"
        done
    else
        log "⚠️  No audio IRQs found"
    fi
    
    log "✅ IRQ affinity optimization complete"
}

################################################################################
# Main execution
################################################################################

main() {
    log "=== AUDIO OPTIMIZATION START ==="
    
    optimize_cpu_governor
    optimize_alsa
    optimize_irq_affinity
    
    log "=== AUDIO OPTIMIZATION COMPLETE ==="
    log "✅ High-End Audio configuration applied:"
    log "   - CPU Governor: performance"
    log "   - ALSA: 192kHz / 32-bit / Low Latency"
    log "   - IRQ Affinity: Optimized"
}

# Run main function
main "$@"


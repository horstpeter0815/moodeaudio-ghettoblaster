# Display Chain Analysis with Docker Simulation

This directory contains tools for comprehensive analysis of the video/display chain from boot to Chromium.

## Overview

The display chain consists of these layers:
1. **Boot Configuration** (`config.txt`, `cmdline.txt`)
2. **Kernel/Framebuffer** (`/dev/fb0`, `/sys/class/graphics/fb0`)
3. **DRM/KMS Plane** (`kmsprint`, `/dev/dri/card0`)
4. **X11 Server** (`Xorg`, `DISPLAY=:0`)
5. **xrandr** (synchronizes DRM with X11)
6. **Chromium** (renders content)

## Quick Start

### 1. Start Docker Simulation

```bash
cd test-display
docker-compose -f docker-compose.display-test.yml up
```

### 2. Run Analysis

```bash
# Forward analysis (Boot → Chromium)
./analyze-forward.sh

# Backward analysis (Chromium → Boot)
./analyze-backward.sh

# Generate comprehensive report
./generate-report.sh
```

## Files

### Core Simulation
- `docker-compose.display-test.yml` - Docker Compose configuration
- `simulate-display-chain.sh` - Display chain simulator
- `start-simulation.sh` - Container entry point

### Logging
- `log-format.json` - Log format specification
- `custom-components/scripts/display-chain-logger.sh` - Enhanced logger

### Instrumentation
- `instrument-boot.sh` - Boot sequence instrumentation
- `instrument-services.sh` - Service startup instrumentation
- `instrument-chromium.sh` - Chromium instrumentation

### Analysis
- `analyze-logs.sh` - Log aggregation and analysis
- `analyze-forward.sh` - Forward analysis (Boot → Chromium)
- `analyze-backward.sh` - Backward analysis (Chromium → Boot)

### Monitoring
- `monitor-display-state.sh` - Display state monitor
- `detect-display-on.sh` - Display turn-on detection

### Visualization
- `generate-timeline.sh` - Timeline visualization
- `generate-chain-diagram.sh` - Chain diagram generator
- `generate-report.sh` - Comprehensive report generator

## Usage

### Running Simulation

```bash
# Start simulation
docker-compose -f docker-compose.display-test.yml up -d

# View logs
docker-compose -f docker-compose.display-test.yml logs -f

# Stop simulation
docker-compose -f docker-compose.display-test.yml down
```

### Analyzing Logs

```bash
# Analyze all logs
./analyze-logs.sh /var/log/display-chain/chain.log

# Forward analysis
./analyze-forward.sh /var/log/display-chain/chain.log

# Backward analysis
./analyze-backward.sh /var/log/display-chain/chain.log

# Generate report
./generate-report.sh /var/log/display-chain/chain.log
```

### Monitoring Display State

```bash
# Monitor display state (runs continuously)
./monitor-display-state.sh 1  # interval in seconds

# Detect display turn-on
./detect-display-on.sh
```

## Log Format

Logs are in JSON format with the following structure:

```json
{
  "id": "log_timestamp_pid",
  "timestamp": 1234567890000000000,
  "layer": "boot|framebuffer|drm|x11|xrandr|chromium",
  "event_type": "init|config|start|ready|error|snapshot|complete",
  "message": "Human-readable message",
  "data": { "layer-specific": "data" },
  "sessionId": "session-id",
  "correlationId": "correlation-id"
}
```

## Output Files

Analysis generates the following files in `/var/log/display-chain/`:

- `chain.log` - Main log file (JSON format)
- `chain.log.human.log` - Human-readable log
- `timeline.txt` - Timeline visualization
- `chain-diagram.txt` - Chain diagram
- `forward-analysis/` - Forward analysis results
- `backward-analysis/` - Backward analysis results
- `comprehensive-report.txt` - Full report

## Troubleshooting

### Logs not generated
- Check Docker volume mounts
- Verify scripts are executable: `chmod +x test-display/*.sh`
- Check container logs: `docker-compose logs`

### Analysis fails
- Ensure `jq` is installed: `apt-get install -y jq`
- Check log file exists and is readable
- Verify log format matches specification

### Simulation doesn't match real system
- Update boot configuration files in `boot-config/`
- Adjust simulation parameters in `simulate-display-chain.sh`
- Compare with real system logs

## Integration with Real System

To use these tools on the real moOde system:

1. Copy scripts to moOde system:
   ```bash
   scp -r test-display moode:/tmp/
   scp custom-components/scripts/display-chain-logger.sh moode:/usr/local/bin/
   ```

2. Run instrumentation:
   ```bash
   ssh moode '/tmp/test-display/instrument-boot.sh'
   ssh moode '/tmp/test-display/instrument-services.sh'
   ssh moode '/tmp/test-display/instrument-chromium.sh'
   ```

3. Analyze logs:
   ```bash
   scp moode:/var/log/display-chain/chain.log .
   ./analyze-forward.sh chain.log
   ./analyze-backward.sh chain.log
   ./generate-report.sh chain.log
   ```


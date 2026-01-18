# Quick Start Guide - Display Chain Analysis

## Prerequisites

- Docker and Docker Compose installed
- `jq` installed (for log analysis)

## Quick Start

### 1. Prepare Boot Configuration

```bash
# Copy example configs (or use your own)
cp boot-config/config.txt.example boot-config/config.txt
cp boot-config/cmdline.txt.example boot-config/cmdline.txt
```

### 2. Start Docker Simulation

```bash
cd test-display
docker-compose -f docker-compose.display-test.yml up
```

### 3. Run Analysis

In another terminal:

```bash
cd test-display

# Forward analysis (Boot → Chromium)
./analyze-forward.sh

# Backward analysis (Chromium → Boot)
./analyze-backward.sh

# Generate comprehensive report
./generate-report.sh
```

### 4. View Results

Results are saved in `/var/log/display-chain/` (inside container) or `./display-logs/` (on host):

- `timeline.txt` - Event timeline
- `chain-diagram.txt` - Visual chain diagram
- `forward-analysis/forward-analysis.txt` - Forward analysis results
- `backward-analysis/backward-analysis.txt` - Backward analysis results
- `comprehensive-report.txt` - Full report with recommendations

## Using on Real System

### 1. Copy Scripts to moOde System

```bash
# Copy instrumentation scripts
scp -r test-display moode:/tmp/
scp custom-components/scripts/display-chain-logger.sh moode:/usr/local/bin/
chmod +x /tmp/test-display/*.sh
chmod +x /usr/local/bin/display-chain-logger.sh
```

### 2. Run Instrumentation

```bash
ssh moode '/tmp/test-display/instrument-boot.sh'
ssh moode '/tmp/test-display/instrument-services.sh'
ssh moode '/tmp/test-display/instrument-chromium.sh'
```

### 3. Collect Logs

```bash
# Copy logs from moOde system
scp moode:/var/log/display-chain/*.log .
```

### 4. Analyze Locally

```bash
cd test-display
./analyze-forward.sh ../chain.log
./analyze-backward.sh ../chain.log
./generate-report.sh ../chain.log
```

## Monitoring Display State

### Continuous Monitoring

```bash
# Monitor display state every second
./monitor-display-state.sh 1
```

### Detect Display Turn-On

```bash
# Detect when display actually turns on
./detect-display-on.sh
```

## Troubleshooting

### Docker Issues

- Ensure Docker is running: `docker ps`
- Check container logs: `docker-compose logs`
- Verify volume mounts: `docker-compose config`

### Analysis Issues

- Install `jq`: `apt-get install -y jq` (in container) or `brew install jq` (on Mac)
- Check log file exists and is readable
- Verify log format matches specification in `log-format.json`

### Real System Issues

- Ensure scripts are executable: `chmod +x /tmp/test-display/*.sh`
- Check log directory exists: `mkdir -p /var/log/display-chain`
- Verify X11 is accessible: `DISPLAY=:0 xrandr --query`


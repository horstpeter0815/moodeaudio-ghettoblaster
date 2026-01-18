# Systemd Testing and Profiling Tools

This directory contains tools for testing systemd configurations and profiling boot performance before building the full image.

## Overview

These tools allow you to:
- Test systemd fixes in Docker before building
- Profile boot performance using `systemd-analyze`
- Validate D-Bus circular dependency fixes
- Check for circular dependencies
- Analyze service dependencies

## Prerequisites

- Docker and docker-compose installed
- Access to the workspace directory

## Quick Start

### Validate All Fixes (Recommended Before Build)

**Option 1: Through unified test tool (recommended)**
```bash
./tools/test.sh --systemd
# or
./tools/test.sh  # then select option 10
```

**Option 2: Direct script**
```bash
./tools/test/validate-all-fixes.sh
```

This runs all tests and provides a summary. Run this before starting a build to catch issues early.

### Individual Tests

#### 1. Test Systemd Fixes (Static Validation)
```bash
./tools/test/test-systemd-fixes.sh
```
Tests systemd configuration files without Docker. Validates:
- D-Bus circular dependency fix
- basic.target fix
- Service ordering
- Service file syntax

#### 2. Validate D-Bus Fix
```bash
./tools/test/validate-dbus-fix.sh
```
Specifically validates the D-Bus circular dependency fix.

#### 3. Profile Boot Performance (Requires Docker)
```bash
docker-compose -f docker-compose.test.yml run --rm systemd-tester \
  tools/test/profile-boot.sh
```
Profiles boot performance using `systemd-analyze`. Generates:
- Boot time analysis
- Critical boot chain
- Service blame (slowest services)
- Circular dependency check

#### 4. Analyze Boot Dependencies (Requires Docker)
```bash
docker-compose -f docker-compose.test.yml run --rm systemd-tester \
  tools/test/analyze-boot-dependencies.sh
```
Analyzes service dependencies and generates dependency graphs.

## Docker Test Container

The test container (`Dockerfile.test-systemd`) provides:
- Debian Bookworm (similar to Raspberry Pi OS)
- systemd and systemd-analyze
- Debugging tools (strace, ltrace)
- Systemd testing environment

### Building the Test Container

```bash
docker-compose -f docker-compose.test.yml build
```

### Running Tests in Container

```bash
# Run a specific test
docker-compose -f docker-compose.test.yml run --rm systemd-tester \
  tools/test/profile-boot.sh

# Interactive shell
docker-compose -f docker-compose.test.yml run --rm systemd-tester bash
```

## Test Results

All test results are saved to `test-results/` directory:
- `boot-time.txt` - Boot time analysis
- `critical-chain.txt` - Critical boot chain
- `blame.txt` - Slowest services
- `verify.txt` - Systemd unit verification
- `dependency-graph.svg` - Dependency graph (if graphviz installed)
- `*-dependencies.txt` - Target/service dependencies

## What Gets Tested

### D-Bus Circular Dependency Fix
- Verifies D-Bus doesn't wait for basic.target
- Verifies D-Bus starts before basic.target
- Checks required dependencies are present

### basic.target Fix
- Verifies basic.target doesn't wait for dbus
- Checks correct dependencies

### Service Ordering
- Validates SSH services start early
- Checks service dependencies

### Boot Performance
- Measures boot time
- Identifies slow services
- Detects circular dependencies

## Troubleshooting

### Docker Issues
If Docker tests fail:
1. Ensure Docker is running: `docker ps`
2. Rebuild container: `docker-compose -f docker-compose.test.yml build`
3. Check logs: `docker-compose -f docker-compose.test.yml logs`

### Systemd Not Available
If you see "systemd-analyze not available":
- Make sure you're running in the Docker container
- The test container includes systemd

### Circular Dependencies Found
If circular dependencies are detected:
1. Check the verify output: `test-results/verify.txt`
2. Review the D-Bus fix: `custom-components/services/dbus.service.d/fix-circular-dependency.conf`
3. Review basic.target fix: `custom-components/services/basic.target.d/fix-no-dbus-wait.conf`

## Integration with Build Process

Recommended workflow:
1. Make changes to systemd configurations
2. Run `./tools/test/validate-all-fixes.sh`
3. Fix any issues found
4. Repeat until all tests pass
5. Proceed with build

This saves time by catching issues before the 8-12 hour build process.

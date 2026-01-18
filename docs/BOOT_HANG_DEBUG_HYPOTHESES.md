# Boot Hang Debug Hypotheses

## Systematic Debugging Approach

We're using **runtime evidence** to find the root cause. This document outlines our hypotheses and what evidence we're looking for.

## Hypotheses (What Could Be Blocking Boot)

### Hypothesis A: Service Dependency Chain Blocking
**Theory:** A service is waiting for another service that never starts or times out.

**Evidence to look for:**
- `systemctl list-jobs` shows services in "waiting" state
- Services with `After=` dependencies on services that are stuck
- Circular dependencies between services

**What logs show:**
- Jobs stuck in "waiting" state
- Services showing "activating" for long periods
- `systemd-analyze critical-chain` shows a long chain

### Hypothesis B: Missing or Slow Dependencies
**Theory:** Services are waiting for D-Bus, network, filesystem, or other infrastructure that's slow.

**Evidence to look for:**
- Services waiting for `dbus.service`
- Services waiting for `network-online.target`
- Services waiting for `local-fs.target` or mount points
- `systemd-timedated` waiting for D-Bus

**What logs show:**
- `systemctl show <service>` shows `After=dbus.service` but dbus is not active
- Network services stuck in "activating"
- Filesystem services taking too long

### Hypothesis C: Services Without Timeouts
**Theory:** Services don't have `TimeoutStartSec` set, so they wait indefinitely.

**Evidence to look for:**
- Services in "activating" state for >30 seconds
- No timeout configuration in service overrides
- `systemd-analyze blame` shows services taking minutes

**What logs show:**
- Services stuck in "activating" state
- No timeout errors in logs
- Services taking 60+ seconds to start

### Hypothesis D: Target Dependencies Blocking
**Theory:** `basic.target` or `multi-user.target` is waiting for services that are slow.

**Evidence to look for:**
- Target stuck in "activating" state
- Services in target's `.wants` directory that are slow
- Target has `Requires=` on slow services

**What logs show:**
- `systemctl is-active basic.target` returns "activating"
- Services in target wants directory are slow
- `systemd-analyze critical-chain` shows target waiting

### Hypothesis E: Implicit Dependencies
**Theory:** Services have implicit dependencies (via `DefaultDependencies=yes`) that are slow.

**Evidence to look for:**
- Services with `DefaultDependencies=yes` waiting for systemd targets
- Services implicitly waiting for `sysinit.target`, `basic.target`
- Services that should have `DefaultDependencies=no` but don't

**What logs show:**
- Services showing dependencies we didn't explicitly set
- `systemctl show` shows more `After=` than we configured

### Hypothesis F: Resource Contention
**Theory:** Multiple services trying to access the same resource (device, file, port) causing contention.

**Evidence to look for:**
- Multiple services trying to start simultaneously
- Services accessing `/dev/tty1`, `/dev/fb0`, network interfaces
- Port conflicts (multiple web servers, SSH services)

**What logs show:**
- Multiple services in "activating" state for same resource
- Journal errors about device/file/port conflicts

## What We're Capturing

### Boot Debug Capture (`boot-debug-capture.service`)
Runs once early in boot, captures:
1. **Systemd job states** - What's running/waiting
2. **Active jobs detail** - Exact state of each job
3. **Waiting jobs** - What's blocking boot
4. **Failed services** - What failed to start
5. **Active units** - What's running
6. **Inactive units** - What should be starting
7. **Activating units** - What's stuck starting
8. **Target states** - State of basic.target, multi-user.target, default.target
9. **Service dependencies** - After, Before, Wants, Requires for common services
10. **systemd-analyze blame** - Slowest services
11. **systemd-analyze critical-chain** - Boot chain analysis
12. **Recent journal** - Last 50 journal entries

### Periodic Capture (`boot-debug-periodic.service`)
Runs every 5 seconds during boot, captures:
1. **Uptime** - How long system has been booting
2. **Job states** - Changes in job states over time
3. **Stuck jobs** - Jobs that stay in same state

## How to Analyze

1. **Boot the system** with instrumentation
2. **Wait for boot to complete or hang**
3. **Read logs:**
   ```bash
   # On Mac (SD card mounted):
   cat /Volumes/rootfs/var/log/boot-debug.log
   
   # Or use analysis script:
   bash tools/fix/analyze-boot-debug-logs.sh
   ```
4. **Look for:**
   - Jobs stuck in "waiting" or "activating"
   - Services taking >10 seconds in systemd-analyze blame
   - Targets stuck in "activating"
   - Failed services
   - Long dependency chains

## Next Steps After Analysis

1. **Identify the blocker** from logs
2. **Check service dependencies** for that service
3. **Add timeouts** if missing
4. **Fix dependencies** if wrong
5. **Disable service** if not needed
6. **Re-test** with instrumentation

## Success Criteria

Boot is successful when:
- `basic.target` reaches "active" state quickly (<30 seconds)
- No services stuck in "activating" or "waiting"
- `systemd-analyze blame` shows all services <10 seconds
- System is reachable via SSH/web

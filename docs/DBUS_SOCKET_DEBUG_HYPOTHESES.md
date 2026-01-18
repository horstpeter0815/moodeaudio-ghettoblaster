# D-Bus Socket Debug Hypotheses

## Problem
"failed to listen to a D-Bus socket" error during boot, but D-Bus service eventually starts.

## Hypotheses

### Hypothesis A: Service Trying to Connect Before D-Bus Socket Exists
**Theory:** A service is trying to connect to D-Bus socket (`/run/dbus/system_bus_socket`) before D-Bus has created it.

**Evidence to look for:**
- Services with `After=dbus.service` but starting too early
- Services with `Wants=dbus.socket` but socket not ready
- Journal entries showing "Connection refused" or "No such file or directory" for D-Bus socket
- Services starting before `dbus.socket` is active

**What logs show:**
- `systemctl list-jobs` shows services starting before dbus.socket
- Journal shows D-Bus connection errors before dbus.service starts
- `systemctl show` shows services without proper D-Bus dependencies

### Hypothesis B: D-Bus Socket Permissions Issue
**Theory:** D-Bus socket exists but has wrong permissions, preventing services from connecting.

**Evidence to look for:**
- `/run/dbus/system_bus_socket` has wrong ownership or permissions
- Services running as wrong user trying to connect
- Journal entries showing "Permission denied" for D-Bus socket

**What logs show:**
- `ls -la /run/dbus/system_bus_socket` shows wrong permissions
- Journal shows permission errors
- Services running as different users

### Hypothesis C: D-Bus Socket Directory Missing
**Theory:** `/run/dbus` directory doesn't exist when services try to connect.

**Evidence to look for:**
- `/run/dbus` directory missing during early boot
- Services trying to connect before directory is created
- `dbus.socket` not creating directory properly

**What logs show:**
- Journal shows "No such file or directory" for `/run/dbus`
- `dbus.socket` status shows it's not active
- Services failing before `dbus.service` starts

### Hypothesis D: Multiple D-Bus Instances Conflict
**Theory:** Multiple services trying to start D-Bus or conflicting D-Bus configurations.

**Evidence to look for:**
- Multiple `dbus.service` or `dbus.socket` units
- Journal entries showing D-Bus already running
- Services trying to start their own D-Bus instance

**What logs show:**
- `systemctl list-units | grep dbus` shows multiple instances
- Journal shows "Address already in use" or "already running"
- Conflicting D-Bus configurations

### Hypothesis E: D-Bus Service Dependency Chain Issue
**Theory:** Services have implicit D-Bus dependencies that aren't being satisfied properly.

**Evidence to look for:**
- Services with `DefaultDependencies=yes` implicitly waiting for D-Bus
- Services without explicit `After=dbus.service` but needing it
- Circular dependencies involving D-Bus

**What logs show:**
- `systemctl show` shows implicit D-Bus dependencies
- Services stuck waiting for D-Bus that's not in their explicit dependencies
- Dependency chain analysis shows D-Bus in wrong position

## What We're Capturing

Enhanced boot debug script will capture:
1. **D-Bus socket state** - Does `/run/dbus/system_bus_socket` exist?
2. **D-Bus socket permissions** - Ownership and permissions
3. **D-Bus service state** - Is `dbus.service` and `dbus.socket` active?
4. **Services trying to use D-Bus** - Which services are starting before D-Bus?
5. **Journal D-Bus errors** - All D-Bus related errors from journal
6. **D-Bus dependencies** - Which services depend on D-Bus and how

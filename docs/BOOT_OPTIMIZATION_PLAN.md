# Boot Optimization Plan

## Current Issues

1. **Boot hangs on various services** - Multiple attempts to fix, but system still slow
2. **tty1 device hang** - "job def tty1.txt device slash stop running for a long time"
3. **Messy service dependencies** - Too many services with complex dependencies
4. **Network waits** - Even after fixes, some services may still wait

## Root Cause Analysis

### Problematic Service Categories

1. **User Management Services**
   - `05-remove-pi-user.service`
   - `fix-user-id.service`
   - `userconfig.service`
   - `systemd-user-sessions.service`
   - `user.slice` services

2. **Network Services**
   - `NetworkManager-wait-online.service`
   - `systemd-networkd-wait-online.service`
   - Services depending on `network-online.target` (28+ services found)

3. **Cloud-init Services**
   - `cloud-init.service`
   - `cloud-init-local.service`
   - `cloud-config.service`
   - `cloud-final.service`

4. **TTY/Console Services**
   - `getty@tty1.service` (causes tty1 device hang)
   - Services with `TTYPath=/dev/tty1`

5. **System Services**
   - `systemd-statcollect.service` (System actively accounting)
   - `first-boot-setup.service`
   - Services with long timeouts (>30s)

## Optimization Strategy

### Phase 1: Service Cleanup (Next Build)

1. **Remove Unnecessary Services**
   - Remove all user rename/management services from build
   - Remove cloud-init completely from build
   - Remove first-boot-setup if not needed
   - Consolidate network services (too many doing similar things)

2. **Simplify Service Dependencies**
   - Remove all `network-online.target` dependencies
   - Remove all `user.slice` dependencies
   - Use `DefaultDependencies=no` for critical early services
   - Set explicit `After=` and `Before=` for all services

3. **Set Timeouts on ALL Services**
   - Global: `DefaultTimeoutStartSec=10`
   - Individual: Max 10s for any service
   - No service should wait indefinitely

4. **Disable TTY Services**
   - Mask all `getty@*.service` services
   - Only matrix-boot.service should use tty1
   - Don't wait for tty1 to be ready

### Phase 2: Build Process Optimization

1. **Service Ordering**
   - Number services clearly: `00-`, `01-`, `02-`, etc.
   - Group related services together
   - Document dependencies clearly

2. **Reduce Service Count**
   - Merge similar services (e.g., multiple SSH enable services)
   - Remove redundant network configuration services
   - One service per function, not multiple

3. **Early Boot Services Only**
   - Network configuration: ONE service
   - SSH enable: ONE service
   - Display setup: ONE service
   - Everything else: After multi-user.target

### Phase 3: Runtime Optimization

1. **Disable Unused Features**
   - If not using cloud-init: Remove completely
   - If not using user management: Remove completely
   - If not using certain network modes: Remove those services

2. **Parallel Service Startup**
   - Services that don't depend on each other should start in parallel
   - Use `Wants=` instead of `Requires=` where possible
   - Remove unnecessary `After=` dependencies

## Immediate Fixes (Current SD Card)

1. ✅ Disable all problematic services (already done)
2. ✅ Fix tty1 device hang (new script created)
3. ✅ Remove network-online dependencies (already done)
4. ✅ Set global timeouts (already done)

## Next Build Recommendations

1. **Service Consolidation**
   - Merge `00-unified-boot.service`, `00-boot-network-ssh.service`, `01-ssh-enable.service`, `enable-ssh-early.service` into ONE service
   - Merge `02-eth0-configure.service`, `03-network-configure.service`, `04-network-lan.service` into ONE service
   - Remove `fix-user-id.service` and `05-remove-pi-user.service` completely

2. **Dependency Cleanup**
   - Remove ALL `network-online.target` dependencies from source
   - Remove ALL `user.slice` dependencies
   - Use `DefaultDependencies=no` for early boot services

3. **Timeout Enforcement**
   - Add `TimeoutStartSec=10` to ALL services in source
   - Add `TimeoutStopSec=5` to ALL services
   - No service should have timeout > 10s

4. **TTY Management**
   - Mask all getty services in build
   - Only matrix-boot.service uses tty1
   - Don't wait for tty1 availability

## Files to Review for Next Build

1. `/moode-source/lib/systemd/system/*.service` - Review all services
2. `/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh` - Build script
3. Service dependencies and ordering
4. Timeout settings

## Testing

Before next build:
1. Run dependency analysis on current build
2. Identify redundant services
3. Test boot time with minimal services
4. Document required vs optional services

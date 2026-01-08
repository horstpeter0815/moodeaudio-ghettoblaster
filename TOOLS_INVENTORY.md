# 🛠️ Tools Inventory

**Project:** moOde Audio Customization  
**Date:** 2025-12-09  
**Total Scripts:** 334 shell scripts + 10 Python scripts

---

## 📊 Overview

This project contains a comprehensive set of tools organized into several categories:

1. **Build & Deployment Tools** (50+ scripts)
2. **Monitoring & Status Tools** (30+ scripts)
3. **Fix & Configuration Tools** (80+ scripts)
4. **Testing & Validation Tools** (25+ scripts)
5. **Debugging Tools** (15+ scripts)
6. **Storage & Cleanup Tools** (10+ scripts)
7. **Automation & Workflow Tools** (20+ scripts)
8. **Python Tools** (10 scripts)
9. **Web Dashboard** (Cockpit)

---

## 🏗️ Build & Deployment Tools

### **Build Management**
- `BUILD_COUNTER_MANAGER.sh` - Tracks build attempt numbers
- `BUILD_TRACKER.sh` - Tracks build progress
- `BUILD_ATTEMPT_TRACKER.sh` - Logs build attempts
- `BUILD_MONITOR_REAL.sh` - Real-time build monitoring
- `MONITOR_BUILD_30.sh` - 30-minute build monitoring
- `MONITOR_BUILD_CONTINUOUS.sh` - Continuous build monitoring
- `CHECK_BUILD_STATUS.sh` - Check current build status
- `START_BUILD_NOW.sh` - Start build immediately
- `START_BUILD_WHEN_READY.sh` - Start build when conditions met
- `START_BUILD_WITH_NUMBER.sh` - Start build with specific number
- `BUILD_20251207.sh` - Specific build script
- `build-in-docker.sh` - Build inside Docker container

### **Image Deployment**
- `BURN_IMAGE_TO_SD.sh` - Burn image to SD card (main tool)
- `BURN_IMAGE_NOW.sh` - Quick burn
- `BURN_NOW.sh` - Immediate burn
- `BURN_STEP_BY_STEP.sh` - Step-by-step burn process
- `BURN_HIFIBERRYOS_NOW.sh` - Burn HiFiBerry OS
- `BURN_HIFIBERRYOS_PI4.sh` - Burn HiFiBerry OS for Pi4
- `BURN_HIFIBERRYOS_PI4_AUTO.sh` - Auto burn for Pi4
- `BURN_HIFIBERRYOS_PI4_SIMPLE.sh` - Simple burn for Pi4
- `burn-image-on-pi.sh` - Burn from Pi
- `burn-moode-pi4.sh` - Burn moOde for Pi4
- `burn-sd-mac.sh` - Burn SD card on macOS

### **Image Validation**
- `VALIDATE_BUILD_IMAGE.sh` - Validate built image
- `IMAGE_VALIDIERUNG.sh` - Image validation (German)
- `check-image-contents.sh` - Check image contents
- `pre-build-validation.sh` - Pre-build validation

---

## 📡 Monitoring & Status Tools

### **System Status**
- `CHECK_PI_STATUS.sh` - Check Pi system status
- `CHECK_PI5_AFTER_REBOOT.sh` - Check Pi5 after reboot
- `check-pi5-status.sh` - Check Pi5 status
- `check_moode_status.sh` - Check moOde status
- `SYSTEM_MONITOR.sh` - System-wide monitoring
- `monitor-all-systems.sh` - Monitor all systems
- `PROAKTIVE_PI_DIAGNOSE.sh` - Proactive Pi diagnosis

### **Build Monitoring**
- `AUTO_MONITOR_BUILD.sh` - Auto monitor builds
- `MONITOR_BUILD_30.sh` - 30-minute build monitor
- `monitor-build.sh` - General build monitor
- `monitor-build-fixed.sh` - Fixed build monitor

### **Boot & Serial Monitoring**
- `MONITOR_PI_BOOT.sh` - Monitor Pi boot process
- `MONITOR_SERIAL_BOOT.sh` - Monitor serial boot
- `AUTO_MONITOR_SERIAL.sh` - Auto serial monitoring
- `AUTONOMOUS_SERIAL_MONITOR.sh` - Autonomous serial monitor
- `READ_SERIAL_CONSOLE.sh` - Read serial console
- `CONNECT_SERIAL_CONSOLE.sh` - Connect to serial console

### **Network Monitoring**
- `CHECK_NETWORK_SPEED.sh` - Check network speed
- `find-pi5-ip.sh` - Find Pi5 IP address

---

## 🔧 Fix & Configuration Tools

### **Display Fixes** (40+ scripts!)
- `FIX_DISPLAY_SERVICE.sh` - Fix display service
- `FIX_DISPLAYS_FAST.sh` - Fast display fix
- `FIX_DISPLAY_ROTATION_PERMANENT.sh` - Permanent rotation fix
- `FIX_MOODE_DISPLAY_DIRECT.sh` - Direct moOde display fix
- `FIX_MOODE_DISPLAY_FINAL.sh` - Final moOde display fix
- `fix-display-browser.sh` - Fix display browser
- `fix-displays-properly.sh` - Proper display fix
- `fix_display.sh` - General display fix
- `fix_display_complete.sh` - Complete display fix
- `fix_display_on_pi.sh` - Fix display on Pi
- `fix_display_working.sh` - Working display fix
- `fix_everything.sh` - Fix everything ⭐ **MAIN TOOL**
- `fix_everything_improved.sh` - Improved fix everything
- `FIX_EVERYTHING_NOW.sh` - Fix everything now
- `fix-all-displays.sh` - Fix all displays
- `fix-all-displays-systematically.sh` - Systematic display fix
- `fix-all-now.sh` - Fix all now
- `fix-all-systems.sh` - Fix all systems
- `complete-display-fix-final.sh` - Complete final display fix
- `comprehensive-display-fix.sh` - Comprehensive display fix
- `pi5-fix-landscape-complete.sh` - Pi5 landscape fix
- `pi5-fix-landscape-cutoff.sh` - Pi5 landscape cutoff fix
- `pi5-force-landscape-complete.sh` - Pi5 force landscape
- `pi5-enable-boot-prompts-and-landscape.sh` - Enable boot prompts
- `pi5-ensure-landscape.sh` - Ensure landscape
- `pi5-final-display-fix.sh` - Pi5 final display fix
- `pi5-comprehensive-display-diagnosis.sh` - Pi5 display diagnosis
- `pi5-display-hardware-check.sh` - Pi5 hardware check
- `pi5-fix-framebuffer-orientation.sh` - Pi5 framebuffer fix
- `pi5-fix-orientation-timing.sh` - Pi5 orientation timing
- `pi5-root-cause-fix.sh` - Pi5 root cause fix
- `pi5-ultimate-fix-all-issues.sh` - Pi5 ultimate fix
- `pi5-complete-fix.sh` - Pi5 complete fix
- `pi5-complete-fix-engineering.sh` - Pi5 engineering fix
- `pi5-direct-fix-now.sh` - Pi5 direct fix
- `pi5-correct-fix-all-issues.sh` - Pi5 correct fix
- `pi5-complete-thorough-fix.sh` - Pi5 thorough fix
- `pi5-post-reboot-fix.sh` - Pi5 post-reboot fix
- `pi5-fix-using-pi4-approach.sh` - Pi5 using Pi4 approach
- `pi5-remove-dangerous-config.sh` - Pi5 remove dangerous config
- `pi5-try-rotation1.sh` - Pi5 rotation attempt
- `FIX_ROTATION.sh` - Fix rotation
- `EXECUTE_ROTATION_FIX.sh` - Execute rotation fix
- `MAKE_ROTATION_PERMANENT.sh` - Make rotation permanent
- `fix-rotation-direct.py` - Python rotation fix
- `fix_portrait_now.py` - Python portrait fix
- `run_display_fix_direct.py` - Python direct display fix

### **Touchscreen Fixes**
- `FIX_TOUCHSCREEN_CLEAN.sh` - Clean touchscreen fix
- `fix_touchscreen_complete.sh` - Complete touchscreen fix
- `fix_touchscreen_coordinates.sh` - Touchscreen coordinate fix ⭐
- `setup_touchscreen.sh` - Touchscreen setup
- `pi5-enable-touchscreen.sh` - Pi5 enable touchscreen
- `pi5-touchscreen-fix.sh` - Pi5 touchscreen fix
- `pi5-touchscreen-hardware-test.sh` - Pi5 touchscreen hardware test
- `pi5-test-touch-matrices.sh` - Pi5 touch matrix test

### **Audio Fixes**
- `FIX_AUDIO_HARDWARE.sh` - Fix audio hardware
- `fix-audio-hardware-pi5.sh` - Fix audio hardware on Pi5
- `CONFIGURE_AMP100.sh` - Configure AMP100
- `fix-amp100-hardware-reset.sh` - Fix AMP100 hardware reset
- `fix-amp100-i2c-gpio.sh` - Fix AMP100 I2C GPIO
- `fix-amp100-i2c-simple.sh` - Fix AMP100 I2C simple
- `fix-amp100-pi5.sh` - Fix AMP100 on Pi5
- `dsp-reset-amp100.sh` - DSP reset AMP100
- `fix-hifiberry-pi5.sh` - Fix HiFiBerry on Pi5
- `fix-hifiberry-pi5-auto.sh` - Auto fix HiFiBerry on Pi5

### **Network Fixes**
- `FIX_ETHERNET_NOW.sh` - Fix ethernet now
- `NETWORK_FIX_20251207.sh` - Network fix
- `SSH_FIX_20251207.sh` - SSH fix
- `CONFIGURE_ETHERNET_AUTO.sh` - Auto configure ethernet
- `ENABLE_ETHERNET_DHCP.sh` - Enable ethernet DHCP
- `AUTO_SWITCH_TO_ETHERNET.sh` - Auto switch to ethernet
- `setup-all-ssh-permanent.sh` - Setup permanent SSH
- `setup-pi4-ssh.sh` - Setup Pi4 SSH
- `setup-pi5-ssh.sh` - Setup Pi5 SSH
- `INSTALL_SSHPASS_AND_FIX.sh` - Install sshpass and fix

### **Boot Fixes**
- `BOOT_SCREEN_COMPLETE_FIX.sh` - Boot screen complete fix
- `fix-boot-screen-landscape.sh` - Fix boot screen landscape
- `fix-pi5-boot-services.sh` - Fix Pi5 boot services
- `pi5-reboot-test.sh` - Pi5 reboot test
- `pi5-boot-test.sh` - Pi5 boot test

### **Chromium/Browser Fixes**
- `FIX_CHROMIUM_START_CLEAN.sh` - Fix Chromium start
- `ROOT_CAUSE_ANALYSIS_CHROMIUM.sh` - Chromium root cause analysis
- `fix-peppymeter-touch.sh` - Fix PeppyMeter touch
- `FIX_PEPPYMETER_SCREENSAVER_CLEAN.sh` - Fix PeppyMeter screensaver
- `peppymeter-screensaver-attempt.sh` - PeppyMeter screensaver attempt
- `peppymeter-screensaver-attempt2.sh` - PeppyMeter screensaver attempt 2
- `peppymeter-screensaver-correct.sh` - PeppyMeter screensaver correct
- `peppymeter-screensaver-fixed.sh` - PeppyMeter screensaver fixed
- `peppymeter-screensaver-touch-close.sh` - PeppyMeter touch close

### **General Fixes**
- `MASTER_FIX_ALL.sh` - Master fix all
- `COMPLETE_FIX_ALL_ISSUES.sh` - Complete fix all issues
- `FIX_IMAGE_DIRECTLY.sh` - Fix image directly
- `FIX_LOCALDISPLAY_SERVICE.sh` - Fix local display service
- `fix-white-screen.sh` - Fix white screen
- `fix-windows-final.sh` - Fix windows final
- `fix_login_screen.sh` - Fix login screen
- `HARDWARE_RESET_FIX.sh` - Hardware reset fix
- `INLINE_FIX.sh` - Inline fix
- `execute_fix_now.py` - Python execute fix
- `execute_phase1_step1.py` - Python execute phase 1

---

## 🧪 Testing & Validation Tools

### **Display Testing**
- `test_display_resolution.sh` - Test display resolution
- `test_display_comparison.sh` - Test display comparison
- `TEST_DISPLAY_TIMINGS.sh` - Test display timings
- `test-displays-on-hifiberry-pi4.sh` - Test displays on HiFiBerry Pi4
- `VERIFY_DISPLAY_FIX.sh` - Verify display fix
- `verify_everything.sh` - Verify everything ⭐ **MAIN VERIFICATION**

### **Touchscreen Testing**
- `test_touchscreen.sh` - Test touchscreen ⭐ **MAIN TEST**
- `TEST_NEUER_TOUCHSCREEN.sh` - Test new touchscreen
- `TOUCHSCREEN_TEST_SKRIPT.sh` - Touchscreen test script
- `TOUCHSCREEN_TEST_VARIANTEN.sh` - Touchscreen test variants
- `verify_touchscreen.sh` - Verify touchscreen
- `test_peppy_requirements.sh` - Test Peppy requirements ⭐

### **System Testing**
- `complete_test_suite.sh` - Complete test suite ⭐
- `STANDARD_TEST_SUITE_FINAL.sh` - Standard test suite final
- `test-all-three-systems.sh` - Test all three systems
- `test-complete-audio-system.sh` - Test complete audio system
- `quick-test-all.sh` - Quick test all
- `comprehensive-system-test.sh` - Comprehensive system test
- `pi5-complete-system-check.sh` - Pi5 complete system check

### **Audio Testing**
- `audio_video_test.sh` - Audio video test
- `VIDEO_PIPELINE_TEST_SAFE.sh` - Video pipeline test safe
- `video_pipeline_test.sh` - Video pipeline test

### **Rotation Testing**
- `test_rotation_fix.sh` - Test rotation fix
- `TEST_TOOL_DOUBLE_ROTATION_HACK.sh` - Double rotation hack test

### **Boot Testing**
- `test-reboot-boot-message.sh` - Test reboot boot message
- `pi5-reboot-test.sh` - Pi5 reboot test
- `pi5-boot-test.sh` - Pi5 boot test

### **Image Testing**
- `test-image-in-container.sh` - Test image in container
- `test-proposal-integration.sh` - Test proposal integration

### **Verification**
- `verify_everything.sh` - Verify everything ⭐
- `verify_installation.sh` - Verify installation
- `verify_touchscreen.sh` - Verify touchscreen

---

## 🐛 Debugging Tools

### **Debugger Setup**
- `SETUP_PI_DEBUGGER.sh` - Setup Pi debugger
- `AUTO_COMPLETE_DEBUGGER_SETUP.sh` - Auto complete debugger setup
- `AUTO_CONNECT_DEBUGGER.sh` - Auto connect debugger
- `CHECK_DEBUGGER_STATUS.sh` - Check debugger status
- `QUICK_DEBUG_CONNECT.sh` - Quick debug connect
- `test_debugger.sh` - Test debugger

### **Diagnostics**
- `diagnose_pi5.sh` - Diagnose Pi5 ⭐
- `diagnose-display-issues.sh` - Diagnose display issues
- `pi5-comprehensive-display-diagnosis.sh` - Pi5 comprehensive diagnosis
- `ROOT_CAUSE_ANALYSIS_DISPLAY_ROTATION.sh` - Root cause analysis
- `ROOT_CAUSE_ANALYSIS_CHROMIUM.sh` - Chromium root cause analysis
- `analyze-display-issue-properly.sh` - Analyze display issue
- `analyze-scripts.sh` - Analyze scripts

---

## 💾 Storage & Cleanup Tools

### **Storage Management**
- `STORAGE_CLEANUP_SYSTEM.sh` - Storage cleanup system ⭐
- `AUTOMATIC_IMAGE_CLEANUP.sh` - Automatic image cleanup
- `AUTOMATED_CLEANUP_SCHEDULE.sh` - Automated cleanup schedule
- `CLEANUP_SYSTEM.sh` - Cleanup system
- `CLEANUP_SYSTEM_20251207.sh` - Cleanup system (dated)
- `CLEANUP_HDMI_CONFIGS.sh` - Cleanup HDMI configs
- `cleanup-services-plan.sh` - Cleanup services plan

### **Archiving**
- `ARCHIVE_TO_NAS.sh` - Archive to NAS ⭐
- `AUTONOMOUS_ARCHIVE_SYSTEM.sh` - Autonomous archive system
- `SETUP_NAS.sh` - Setup NAS

---

## 🤖 Automation & Workflow Tools

### **Autonomous Systems**
- `AUTONOMOUS_WORK_SYSTEM.sh` - Autonomous work system ⭐
- `AUTONOMOUS_BUILD_TO_MOODE.sh` - Autonomous build to moOde
- `AUTONOMOUS_BUILD_WORKER.sh` - Autonomous build worker
- `AUTONOMOUS_COMPLETE_WORKFLOW.sh` - Autonomous complete workflow
- `AUTONOMOUS_FIX_SYSTEM.sh` - Autonomous fix system
- `AUTONOMOUS_SERIAL_MONITOR.sh` - Autonomous serial monitor

### **Action Tracking**
- `ACTION_TRACKER.sh` - Action tracker ⭐
- `WORKFLOW_PATTERN.sh` - Workflow pattern

### **Setup Automation**
- `COMPLETE_AUTOMATED_SETUP.sh` - Complete automated setup
- `COMPLETE_SYSTEM_SETUP.py` - Python complete system setup
- `AUTO_SETUP_WITHOUT_SSHPASS.sh` - Auto setup without sshpass
- `AUTO_EXECUTE.sh` - Auto execute
- `AUTO_CONFIGURE_ETHERNET.applescript` - Auto configure ethernet (macOS)

### **Parallel Work**
- `parallel-work-strategy.sh` - Parallel work strategy
- `start-parallel-work.sh` - Start parallel work
- `continuous-work.sh` - Continuous work

---

## 🐍 Python Tools

### **Display Tools**
- `simple_display.py` - Simple display tool
- `simple_display_manager.py` - Simple display manager
- `fix_rotation_direct.py` - Fix rotation directly
- `fix_portrait_now.py` - Fix portrait now
- `run_display_fix_direct.py` - Run display fix directly

### **System Tools**
- `COMPLETE_SYSTEM_SETUP.py` - Complete system setup
- `execute_fix_now.py` - Execute fix now
- `execute_phase1_step1.py` - Execute phase 1 step 1
- `check_shell.py` - Check shell

### **Services**
- `audio-visualizer-service.py` - Audio visualizer service

---

## 🌐 Web Dashboard (Cockpit)

### **Location:** `cockpit/`

**Files:**
- `app.py` - Flask web application
- `START_COCKPIT.sh` - Start cockpit script
- `requirements.txt` - Python dependencies
- `templates/cockpit.html` - Dashboard HTML template

**Features:**
- Real-time system status
- Build monitoring
- Pi status (online/offline, IP)
- Storage monitoring
- Process monitoring
- Log viewer
- Auto-refresh every 5 seconds

**Start:**
```bash
cd cockpit
./START_COCKPIT.sh
# Or: python3 app.py
```

**Access:** http://localhost:5000 (or 5001-5009 if 5000 busy)

---

## 📋 Quick Reference - Most Used Tools

### **⭐ Essential Tools:**

1. **Display Fix:** `fix_everything.sh` or `fix_everything_improved.sh`
2. **Verify:** `verify_everything.sh`
3. **Test Touchscreen:** `test_touchscreen.sh`
4. **Test Peppy:** `test_peppy_requirements.sh`
5. **Build:** `START_BUILD_NOW.sh`
6. **Monitor Build:** `BUILD_MONITOR_REAL.sh`
7. **Burn Image:** `BURN_IMAGE_TO_SD.sh`
8. **Check Pi Status:** `CHECK_PI_STATUS.sh`
9. **Diagnose:** `diagnose_pi5.sh`
10. **Action Tracking:** `ACTION_TRACKER.sh`
11. **Storage Cleanup:** `STORAGE_CLEANUP_SYSTEM.sh`
12. **Archive:** `ARCHIVE_TO_NAS.sh`
13. **Cockpit Dashboard:** `cockpit/START_COCKPIT.sh`

---

## 🔍 Finding Tools

### **By Function:**
```bash
# Find all display-related scripts
ls -1 *DISPLAY* *display* *rotation* *touchscreen*

# Find all build-related scripts
ls -1 BUILD* build* MONITOR_BUILD* CHECK_BUILD*

# Find all fix scripts
ls -1 FIX* fix* *fix*

# Find all test scripts
ls -1 TEST* test* verify*
```

### **By Pattern:**
- `*STATUS*.sh` - Status checking tools
- `*MONITOR*.sh` - Monitoring tools
- `*FIX*.sh` - Fix tools
- `*TEST*.sh` - Testing tools
- `*SETUP*.sh` - Setup tools
- `*CONFIGURE*.sh` - Configuration tools

---

## 📝 Notes

- Many scripts have multiple versions (e.g., `fix-display-*.sh` vs `FIX_DISPLAY*.sh`)
- Some scripts are Pi4-specific, some Pi5-specific
- Check script headers for usage instructions
- Most scripts log to files or stdout
- Some scripts require sudo/root access
- Network scripts may require sshpass

---

**Last Updated:** 2025-12-09



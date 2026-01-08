# RASPBERRY PI 5 ARCHITECTURE REFERENCE

**Purpose:** Deep technical reference for Raspberry Pi 5 system architecture  
**Last Updated:** 2025-12-04

---

## 🖥️ HARDWARE ARCHITECTURE

### **SoC: BCM2712**

**CPU:**
- **Architecture:** ARM Cortex-A76
- **Cores:** 4 cores
- **Clock Speed:** 2.4 GHz
- **Instruction Set:** ARMv8.2-A (64-bit)
- **Cache:** L1, L2, L3 cache hierarchy

**GPU:**
- **Type:** VideoCore VII
- **Features:** Hardware video acceleration
- **Display:** Multiple HDMI outputs

**Memory:**
- **Type:** LPDDR4X-4267
- **Capacity:** 4GB, 8GB variants
- **Bandwidth:** High-speed memory interface

**Peripherals:**
- **USB:** USB 3.0 ports
- **Ethernet:** Gigabit Ethernet
- **GPIO:** 40-pin header (compatible with Pi 4)
- **PCIe:** PCIe 2.0 interface
- **HDMI:** Multiple HDMI outputs

---

## 🔄 BOOT PROCESS

### **Stage 1: ROM Bootloader**
- **Location:** SoC ROM (read-only)
- **Function:** Initializes basic hardware
- **Action:** Loads second stage from storage

### **Stage 2: Bootloader**
- **Location:** SD card/eMMC
- **Files:** `bootcode.bin` or `rpiboot` (Pi 5 specific)
- **Function:** Initializes more hardware, loads GPU firmware

### **Stage 3: GPU Firmware**
- **File:** `start.elf`
- **Function:** GPU initialization, display setup
- **Action:** Loads kernel and device tree

### **Stage 4: Kernel & Init**
- **Kernel:** Linux kernel (typically 6.x for Pi 5)
- **Init System:** Systemd (in most distributions)
- **Action:** Mounts root filesystem, starts services

---

## 📁 BOOT CONFIGURATION

### **Primary Boot Partition: `/boot/firmware/`**

**⚠️ CRITICAL:** Pi 5 uses `/boot/firmware/` as primary location!

**Key Files:**
- `config.txt` - Boot configuration
- `cmdline.txt` - Kernel command line parameters
- `start.elf` - GPU firmware
- `kernel.img` or `kernel8.img` - Kernel image
- `*.dtb` - Device tree blobs

### **config.txt Parameters:**

**Display:**
```ini
# Display rotation (0=0°, 1=90°, 2=180°, 3=270°)
display_rotate=3

# HDMI group (0=CEA/DMT, 1=CEA, 2=DMT)
hdmi_group=0

# HDMI mode (resolution)
hdmi_mode=87

# Custom resolution
hdmi_cvt=1280 400 60 6 0 0 0
```

**Memory:**
```ini
# GPU memory split
gpu_mem=128
```

**Overclocking:**
```ini
# CPU overclock (if needed)
arm_freq=2400
```

### **cmdline.txt Parameters:**

**Common Parameters:**
```
console=serial0,115200 console=tty1 root=PARTUUID=... rootfstype=ext4 fsck.repair=yes rootwait quiet splash
```

**Verbose Boot:**
```
systemd.show_status=yes
```

**Remove `quiet` for verbose output**

---

## 🖥️ DISPLAY SYSTEM

### **Framebuffer:**
- **Device:** `/dev/fb0`
- **Info:** `/sys/class/graphics/fb0/virtual_size`
- **Rotation:** Controlled by `display_rotate` in config.txt

### **X Server (X11):**
- **Display:** `:0` (typically)
- **Socket:** `/tmp/.X11-unix/X0`
- **Config:** `/etc/X11/xorg.conf.d/`
- **User Config:** `/home/<user>/.xinitrc`

### **Display Rotation:**
- **Framebuffer Rotation:** `display_rotate=N` in config.txt
- **X11 Rotation:** `xrandr --output HDMI-2 --rotate left`
- **Touchscreen Rotation:** `Coordinate Transformation Matrix`

### **HDMI Outputs:**
- **HDMI-1:** Primary HDMI output
- **HDMI-2:** Secondary HDMI output (if available)
- **Detection:** `xrandr --query`

---

## 🔌 GPIO & PERIPHERALS

### **GPIO Header:**
- **Pins:** 40-pin header (compatible with Pi 4)
- **Voltage:** 3.3V logic
- **Current:** Limited per pin
- **Functions:** GPIO, I2C, SPI, UART, PWM

### **USB:**
- **Ports:** USB 3.0
- **Power:** 5V supply
- **Devices:** USB DACs, storage, etc.

### **Ethernet:**
- **Speed:** Gigabit Ethernet
- **Interface:** `eth0`
- **Configuration:** `/etc/network/interfaces` or NetworkManager

---

## ⚡ POWER MANAGEMENT

### **Power Supply:**
- **Voltage:** 5V
- **Current:** Minimum 5A recommended
- **Connector:** USB-C
- **Power States:** Multiple sleep/wake states

### **Power Management:**
- **PMIC:** Integrated Power Management IC
- **States:** Active, idle, sleep
- **Monitoring:** `/sys/class/power_supply/`

---

## 🔧 SYSTEM-SPECIFIC DIFFERENCES (Pi 4 vs Pi 5)

| Feature | Pi 4 | Pi 5 |
|---------|------|------|
| Boot Config | `/boot/config.txt` | `/boot/firmware/config.txt` |
| Kernel Cmdline | `/boot/cmdline.txt` | `/boot/firmware/cmdline.txt` |
| SoC | BCM2711 | BCM2712 |
| CPU | Cortex-A72 | Cortex-A76 |
| Boot Process | Standard | Enhanced with rpiboot |
| PCIe | No | Yes (PCIe 2.0) |

---

## 🛠️ TROUBLESHOOTING

### **Boot Issues:**
1. Check `/boot/firmware/config.txt` syntax
2. Verify kernel and device tree files exist
3. Check SD card health
4. Review boot logs: `dmesg | head -50`

### **Display Issues:**
1. Check framebuffer: `cat /sys/class/graphics/fb0/virtual_size`
2. Check X11: `xrandr --query`
3. Verify rotation: `grep display_rotate /boot/firmware/config.txt`
4. Check X server: `systemctl status localdisplay`

### **Power Issues:**
1. Check power supply rating (minimum 5A)
2. Monitor voltage: `/sys/class/power_supply/`
3. Check for undervoltage warnings in logs

---

## 📚 REFERENCES

- **Official Documentation:** [raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/)
- **Hardware Specs:** BCM2712 datasheet
- **Boot Process:** Raspberry Pi boot documentation
- **GPIO:** GPIO pinout diagrams

---

**Status:** Active reference document - update as new information is discovered


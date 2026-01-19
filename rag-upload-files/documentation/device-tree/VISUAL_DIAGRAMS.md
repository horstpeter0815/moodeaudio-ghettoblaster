# Device Tree Visual Diagrams

**Date:** 2026-01-18
**Purpose:** Visual representations of device tree concepts, hardware architecture, and system layers

## Table of Contents

1. [Hardware Layer Diagram](#hardware-layer-diagram)
2. [Layer Separation Diagram](#layer-separation-diagram)
3. [Audio Signal Flow](#audio-signal-flow)
4. [Display Signal Flow](#display-signal-flow)
5. [Boot Sequence Diagram](#boot-sequence-diagram)
6. [I2C Bus Architecture](#i2c-bus-architecture)
7. [Device Tree Loading Process](#device-tree-loading-process)
8. [Parameter Resolution Flow](#parameter-resolution-flow)

---

## Hardware Layer Diagram

### Ghettoblaster Complete Hardware Architecture

```mermaid
graph TB
    subgraph pi5 [Raspberry Pi 5 - BCM2712]
        cpu[CPU<br/>Cortex-A76]
        rp1[RP1 Chip<br/>I/O Controller]
        i2c1[I2C Bus 1<br/>GPIO 2/3]
        i2s[I2S Interface<br/>DesignWare I2S]
        hdmi0[HDMI Port 0]
        hdmi1[HDMI Port 1]
        gpio[GPIO Controller]
    end
    
    subgraph audio [Audio Subsystem]
        osc[Clock Oscillator<br/>dacpro_osc]
        pcm[PCM5122 DAC<br/>I2C: 0x4d]
        amp[AMP100 Amplifier<br/>2x 30W Class D]
        spk_l[Speaker L]
        spk_r[Speaker R]
    end
    
    subgraph display [Display Subsystem]
        hdmi_cable[HDMI Cable]
        panel[Waveshare 7.9"<br/>400x1280 Portrait<br/>1280x400 Landscape]
        backlight[LED Backlight]
    end
    
    subgraph touch [Touch Subsystem]
        ft6236[FT6236 Controller<br/>I2C: 0x38]
        touch_panel[Capacitive Touch<br/>1280x400]
        int_gpio[Interrupt GPIO 25]
    end
    
    cpu --> rp1
    rp1 --> i2c1
    rp1 --> i2s
    rp1 --> hdmi0
    rp1 --> hdmi1
    rp1 --> gpio
    
    i2c1 -->|I2C Address 0x4d| pcm
    i2c1 -->|I2C Address 0x38| ft6236
    i2s -->|BCK, LRCK, DATA| pcm
    osc -->|MCLK| pcm
    pcm -->|Analog Audio| amp
    amp --> spk_l
    amp --> spk_r
    
    hdmi0 -->|Video Signal| hdmi_cable
    hdmi_cable --> panel
    panel --> backlight
    
    ft6236 --> touch_panel
    gpio -->|GPIO 25 Falling Edge| ft6236
    
    style pi5 fill:#e1f5e1
    style audio fill:#ffe1e1
    style display fill:#e1e1ff
    style touch fill:#fff5e1
```

### Hardware Components Detail

```mermaid
graph LR
    subgraph pcm5122_detail [PCM5122 DAC Detail]
        i2c_in[I2C Control<br/>0x4d]
        mclk_in[MCLK Input<br/>from dacpro_osc]
        i2s_in[I2S Input<br/>BCK/LRCK/DATA]
        dac_core[32-bit DAC<br/>384kHz capable]
        analog_out[Analog Output<br/>Left/Right]
        power[Power Supply<br/>AVDD/DVDD/CPVDD<br/>3.3V]
    end
    
    i2c_in --> dac_core
    mclk_in --> dac_core
    i2s_in --> dac_core
    power --> dac_core
    dac_core --> analog_out
    
    subgraph amp100_detail [AMP100 Amplifier Detail]
        analog_in[Analog Input<br/>from PCM5122]
        class_d[Class D Amplifier<br/>2x 30W @ 4Ω]
        protection[Protection:<br/>Thermal, Short Circuit]
        spk_out[Speaker Output<br/>L/R]
    end
    
    analog_in --> class_d
    class_d --> protection
    protection --> spk_out
    
    style pcm5122_detail fill:#ffe1e1
    style amp100_detail fill:#ffe1e1
```

---

## Layer Separation Diagram

### Complete System Layers

```mermaid
graph TB
    subgraph layer1 [Layer 1: Hardware Initialization - Boot Time]
        dt[Device Tree Overlays]
        cmdline[cmdline.txt Parameters]
        config[config.txt Settings]
    end
    
    subgraph layer2 [Layer 2: Kernel & Drivers - Boot Time]
        pcm_drv[PCM5122 Driver<br/>ti,pcm5122]
        touch_drv[FT6236 Driver<br/>focaltech,ft6236]
        hifi_drv[HiFiBerry Driver<br/>hifiberry-dacplus]
        i2s_drv[I2S Driver<br/>DesignWare I2S]
        vc4_drv[VC4 Display Driver<br/>KMS]
    end
    
    subgraph layer3 [Layer 3: System Services - Runtime]
        alsa[ALSA Sound System]
        x11[X11 Display Server]
        input[Input Subsystem]
        systemd[systemd Services]
    end
    
    subgraph layer4 [Layer 4: Application - Runtime]
        mpd[MPD<br/>Music Player Daemon]
        moode[moOde Web UI]
        chromium[Chromium<br/>PeppyMeter Display]
    end
    
    dt --> pcm_drv
    dt --> touch_drv
    dt --> hifi_drv
    dt --> vc4_drv
    cmdline --> vc4_drv
    config --> pcm_drv
    
    pcm_drv --> alsa
    hifi_drv --> alsa
    i2s_drv --> alsa
    touch_drv --> input
    vc4_drv --> x11
    
    alsa --> mpd
    alsa --> moode
    x11 --> chromium
    input --> chromium
    mpd --> moode
    systemd --> mpd
    systemd --> chromium
    
    style layer1 fill:#90EE90
    style layer2 fill:#87CEEB
    style layer3 fill:#FFD700
    style layer4 fill:#FFA07A
```

### What Each Layer Controls

```mermaid
graph LR
    subgraph layer_dt [Device Tree Layer]
        dt_controls[Controls:<br/>✅ I2C devices<br/>✅ I2S interface<br/>✅ GPIO functions<br/>✅ Clock sources<br/>✅ Power supplies]
        dt_not[Does NOT Control:<br/>❌ Audio routing<br/>❌ Volume<br/>❌ Display rotation<br/>❌ Touch mapping<br/>❌ IEC958]
    end
    
    subgraph layer_alsa [ALSA Layer]
        alsa_controls[Controls:<br/>✅ Audio routing<br/>✅ IEC958 on/off<br/>✅ Volume controls<br/>✅ PCM formats<br/>✅ Sample rates]
        alsa_not[Does NOT Control:<br/>❌ Hardware init<br/>❌ I2C addresses<br/>❌ GPIO assignments]
    end
    
    subgraph layer_x11 [X11/Display Layer]
        x11_controls[Controls:<br/>✅ Display rotation<br/>✅ Resolution<br/>✅ Multi-monitor<br/>✅ Touch mapping<br/>✅ Coordinate transform]
        x11_not[Does NOT Control:<br/>❌ Hardware init<br/>❌ HDMI detection<br/>❌ Framebuffer]
    end
    
    style layer_dt fill:#90EE90
    style layer_alsa fill:#FFD700
    style layer_x11 fill:#87CEEB
```

---

## Audio Signal Flow

### Complete Audio Chain

```mermaid
graph LR
    subgraph source [Audio Source]
        file[Music File<br/>FLAC/MP3/DSD]
        stream[Network Stream<br/>Spotify/AirPlay]
    end
    
    subgraph mpd_layer [MPD Layer]
        decoder[Decoder<br/>libFLAC, etc.]
        mixer[Software Mixer<br/>Volume Control]
        output[MPD ALSA Output]
    end
    
    subgraph alsa_layer [ALSA Layer]
        pcm[PCM Device<br/>hw:0,0]
        dmix[dmix Plugin<br/>Mixing]
        iec[IEC958 Control<br/>S/PDIF on/off]
        hw[Hardware Device<br/>snd_rpi_hifiberry_dacplus]
    end
    
    subgraph hardware [Hardware Layer]
        i2s_bus[I2S Bus<br/>BCK/LRCK/DATA]
        pcm5122[PCM5122 DAC<br/>32-bit, 384kHz]
        amp100[AMP100 Amp<br/>2x 30W]
        speakers[Speakers]
    end
    
    file --> decoder
    stream --> decoder
    decoder --> mixer
    mixer --> output
    output --> pcm
    pcm --> dmix
    dmix --> iec
    iec --> hw
    hw --> i2s_bus
    i2s_bus --> pcm5122
    pcm5122 --> amp100
    amp100 --> speakers
    
    style source fill:#e1f5e1
    style mpd_layer fill:#ffe1e1
    style alsa_layer fill:#fff5e1
    style hardware fill:#e1e1ff
```

### Device Tree Audio Configuration

```mermaid
graph TB
    subgraph dt_audio [Device Tree - Audio Setup]
        frag0[Fragment 0:<br/>Create dacpro_osc<br/>Clock Generator]
        frag1[Fragment 1:<br/>Enable I2S Controller<br/>Consumer Mode]
        frag2[Fragment 2:<br/>Configure PCM5122<br/>I2C: 0x4d]
        frag3[Fragment 3:<br/>Create Sound Card<br/>hifiberry-dacplus]
    end
    
    subgraph hw_result [Hardware Result]
        clk[Clock Generator<br/>Provides MCLK]
        i2s[I2S Controller<br/>Enabled]
        pcm_dev[PCM5122 Device<br/>I2C Configured]
        snd_card[ALSA Card 0<br/>sndrpihifiberry]
    end
    
    frag0 --> clk
    frag1 --> i2s
    frag2 --> pcm_dev
    frag3 --> snd_card
    
    clk -->|Feeds clock to| pcm_dev
    i2s -->|Provides data bus| pcm_dev
    pcm_dev -->|Registered as| snd_card
    
    style dt_audio fill:#90EE90
    style hw_result fill:#87CEEB
```

---

## Display Signal Flow

### Complete Display Chain

```mermaid
graph TB
    subgraph boot [Boot Stage]
        firmware[Pi Firmware]
        dt_display[Device Tree:<br/>vc4-kms-v3d-pi5]
        cmdline_vid[cmdline.txt:<br/>video=HDMI-A-1:1280x400@60]
        fb[Framebuffer<br/>1280x400 Landscape]
    end
    
    subgraph kernel [Kernel Stage]
        vc4_driver[VC4 KMS Driver]
        hdmi_driver[HDMI Driver]
        drm[DRM Subsystem]
    end
    
    subgraph runtime [Runtime Stage]
        x11_server[X11 Server<br/>:0.0]
        xinitrc[.xinitrc<br/>Reads moOde DB]
        xrandr[xrandr<br/>--rotate left/normal]
        compositor[Window Manager<br/>Openbox]
    end
    
    subgraph application [Application Stage]
        chromium[Chromium<br/>--kiosk mode]
        moode_ui[moOde UI<br/>http://localhost]
        peppy[PeppyMeter<br/>Visualization]
    end
    
    firmware --> dt_display
    dt_display --> vc4_driver
    cmdline_vid --> fb
    vc4_driver --> hdmi_driver
    hdmi_driver --> drm
    drm --> x11_server
    x11_server --> xinitrc
    xinitrc --> xrandr
    xrandr --> compositor
    compositor --> chromium
    chromium --> moode_ui
    chromium --> peppy
    
    style boot fill:#90EE90
    style kernel fill:#87CEEB
    style runtime fill:#FFD700
    style application fill:#FFA07A
```

### Display Orientation Control

```mermaid
graph LR
    subgraph boot_orient [Boot Screen Orientation]
        cmdline_param[cmdline.txt:<br/>video=HDMI-A-1:1280x400@60]
        fb_orient[Framebuffer:<br/>1280x400 Landscape<br/>Physical orientation]
        boot_splash[Boot Splash:<br/>Raspberry Pi logo]
    end
    
    subgraph runtime_orient [Runtime Orientation]
        db[moOde Database:<br/>hdmi_scn_orient]
        xinitrc_read[.xinitrc reads:<br/>hdmi_scn_orient value]
        xrandr_cmd[xrandr command:<br/>--rotate left or normal]
        x11_orient[X11 Display:<br/>Rotated in software]
        app_display[Applications see:<br/>Rotated coordinates]
    end
    
    cmdline_param --> fb_orient
    fb_orient --> boot_splash
    
    db --> xinitrc_read
    xinitrc_read --> xrandr_cmd
    xrandr_cmd --> x11_orient
    x11_orient --> app_display
    
    boot_splash -.->|After boot| x11_orient
    
    style boot_orient fill:#90EE90
    style runtime_orient fill:#FFD700
```

---

## Boot Sequence Diagram

### Complete Boot Process

```mermaid
sequenceDiagram
    participant Power
    participant Firmware
    participant DT as Device Tree
    participant Kernel
    participant Drivers
    participant systemd
    participant Services
    participant UI
    
    Power->>Firmware: Power On
    Note over Firmware: GPU Firmware<br/>bootcode.bin
    
    Firmware->>DT: Read config.txt
    Note over DT: Load overlays:<br/>vc4-kms-v3d-pi5<br/>hifiberry-amp100
    
    DT->>Firmware: Combined Device Tree
    Firmware->>Kernel: Boot kernel with DT
    Note over Kernel: cmdline.txt params:<br/>video=HDMI-A-1:1280x400@60
    
    Kernel->>Drivers: Load drivers
    Note over Drivers: PCM5122 driver<br/>FT6236 driver<br/>VC4 KMS driver
    
    Drivers->>Kernel: Hardware initialized
    Note over Kernel: I2C: 0x4d (DAC)<br/>I2C: 0x38 (Touch)<br/>Sound card created
    
    Kernel->>systemd: Start init system
    
    systemd->>Services: Start audio services
    Note over Services: MPD starts<br/>ALSA initialized
    
    systemd->>Services: Start display services
    Note over Services: X11 starts<br/>Openbox WM<br/>Chromium kiosk
    
    Services->>UI: moOde UI ready
    Note over UI: Web interface<br/>PeppyMeter<br/>Touch working
```

### Device Tree Loading Detail

```mermaid
sequenceDiagram
    participant config as config.txt
    participant bootloader as Pi Bootloader
    participant base_dt as Base Device Tree
    participant overlay as Overlay Files
    participant merged as Merged DT
    participant kernel as Kernel
    
    bootloader->>config: Read config.txt
    config->>bootloader: dtoverlay=vc4-kms-v3d-pi5,noaudio<br/>dtoverlay=hifiberry-amp100
    
    bootloader->>base_dt: Load base DT
    Note over base_dt: bcm2712-rpi-5-b.dtb<br/>Base Pi 5 hardware
    
    bootloader->>overlay: Load vc4-kms-v3d-pi5.dtbo
    overlay->>merged: Apply to base DT
    Note over merged: Display hardware<br/>HDMI controllers<br/>noaudio parameter applied
    
    bootloader->>overlay: Load hifiberry-amp100.dtbo
    overlay->>merged: Apply to merged DT
    Note over merged: PCM5122 at I2C 0x4d<br/>I2S controller enabled<br/>Sound card created
    
    bootloader->>kernel: Pass merged DT
    kernel->>kernel: Parse device tree
    Note over kernel: Create devices<br/>Load drivers<br/>Initialize hardware
```

---

## I2C Bus Architecture

### I2C Bus 1 Layout

```mermaid
graph TB
    subgraph pi5_i2c [Raspberry Pi 5 I2C Bus 1]
        i2c_ctrl[I2C Controller<br/>/axi/pcie@1000120000/rp1/i2c@74000]
        gpio2[GPIO 2<br/>SDA]
        gpio3[GPIO 3<br/>SCL]
        pullup[Pull-up Resistors<br/>1.8kΩ to 3.3V]
    end
    
    subgraph i2c_bus [I2C Bus - 100kHz]
        sda[SDA Line]
        scl[SCL Line]
    end
    
    subgraph devices [I2C Devices]
        pcm[PCM5122 DAC<br/>Address: 0x4d<br/>7-bit addressing]
        touch[FT6236 Touch<br/>Address: 0x38<br/>7-bit addressing]
    end
    
    i2c_ctrl --> gpio2
    i2c_ctrl --> gpio3
    gpio2 --> pullup
    gpio3 --> pullup
    gpio2 --> sda
    gpio3 --> scl
    
    sda --> pcm
    sda --> touch
    scl --> pcm
    scl --> touch
    
    style pi5_i2c fill:#e1f5e1
    style i2c_bus fill:#ffe1e1
    style devices fill:#e1e1ff
```

### I2C Communication Flow

```mermaid
sequenceDiagram
    participant CPU
    participant I2C as I2C Controller
    participant DAC as PCM5122 (0x4d)
    
    CPU->>I2C: Write command<br/>Configure volume
    I2C->>I2C: Generate START
    I2C->>DAC: Send address 0x4d + Write bit
    DAC->>I2C: ACK
    I2C->>DAC: Send register address
    DAC->>I2C: ACK
    I2C->>DAC: Send data byte
    DAC->>I2C: ACK
    I2C->>I2C: Generate STOP
    I2C->>CPU: Write complete
    
    Note over CPU,DAC: Typical I2C transaction<br/>at 100kHz clock
```

---

## Device Tree Loading Process

### Overlay Application Process

```mermaid
graph TB
    subgraph step1 [Step 1: Parse Overlay File]
        overlay_file[hifiberry-amp100.dtbo<br/>Compiled binary]
        parse[Parse overlay structure:<br/>- Fragments<br/>- __overrides__<br/>- __fixups__]
    end
    
    subgraph step2 [Step 2: Resolve Parameters]
        params[Parse parameters:<br/>noaudio, auto_mute, etc.]
        override[Apply __overrides__:<br/>Modify properties<br/>based on parameters]
    end
    
    subgraph step3 [Step 3: Resolve References]
        fixup[Resolve __fixups__:<br/>Convert symbolic refs<br/>to actual addresses]
        phandle[Resolve phandles:<br/>Link references]
    end
    
    subgraph step4 [Step 4: Merge with Base]
        base_dt[Base Device Tree]
        merge[Merge fragments:<br/>Add/override nodes]
        final_dt[Final Device Tree]
    end
    
    overlay_file --> parse
    parse --> params
    params --> override
    override --> fixup
    fixup --> phandle
    phandle --> merge
    base_dt --> merge
    merge --> final_dt
    
    style step1 fill:#90EE90
    style step2 fill:#87CEEB
    style step3 fill:#FFD700
    style step4 fill:#FFA07A
```

### Fragment Application

```mermaid
graph LR
    subgraph fragment [Fragment@2: PCM5122 Config]
        target[target = &i2c1]
        overlay[__overlay__ {<br/>pcm5122@4d {...}<br/>}]
    end
    
    subgraph base [Base Device Tree]
        i2c1_node[i2c@74000 {<br/>compatible = "brcm,bcm2711-i2c"<br/>reg = <0x7e804000 0x1000><br/>}]
    end
    
    subgraph result [Result After Merge]
        i2c1_merged[i2c@74000 {<br/>compatible = "brcm,bcm2711-i2c"<br/>reg = <0x7e804000 0x1000><br/>pcm5122@4d {<br/>  compatible = "ti,pcm5122"<br/>  reg = <0x4d><br/>  ...<br/>}<br/>}]
    end
    
    fragment --> base
    base --> result
    
    style fragment fill:#90EE90
    style base fill:#87CEEB
    style result fill:#FFA07A
```

---

## Parameter Resolution Flow

### How dtoverlay Parameters Work

```mermaid
graph TB
    subgraph config [config.txt]
        line[dtoverlay=hifiberry-amp100,auto_mute]
    end
    
    subgraph parse [Parameter Parsing]
        split[Split: name=hifiberry-amp100<br/>param=auto_mute]
    end
    
    subgraph overlay [Overlay File]
        overrides[__overrides__ {<br/>auto_mute = &lt;&sound&gt;,"hifiberry-dacplus,auto_mute?"<br/>}]
    end
    
    subgraph apply [Parameter Application]
        find[Find target node: &sound]
        add_prop[Add property:<br/>hifiberry-dacplus,auto_mute = true]
    end
    
    subgraph result [Device Tree Result]
        sound_node[sound {<br/>compatible = "hifiberry,hifiberry-dacplus"<br/>hifiberry-dacplus,auto_mute = true<br/>}]
    end
    
    subgraph driver [Driver Behavior]
        read[Driver reads property:<br/>hifiberry-dacplus,auto_mute]
        enable[Enable auto-mute feature:<br/>Mute amp on silence]
    end
    
    config --> parse
    parse --> overlay
    overlay --> apply
    apply --> result
    result --> driver
    
    style config fill:#90EE90
    style parse fill:#87CEEB
    style overlay fill:#FFD700
    style apply fill:#FFA07A
    style result fill:#e1f5e1
    style driver fill:#ffe1e1
```

### Boolean vs Value Parameters

```mermaid
graph LR
    subgraph boolean [Boolean Parameter]
        bool_syntax[auto_mute = &lt;&sound&gt;,"property?"]
        bool_use[Usage: dtoverlay=...,auto_mute]
        bool_result[Result: property exists<br/>Driver checks existence]
    end
    
    subgraph value [Value Parameter]
        val_syntax[mute_ext_ctl = &lt;&sound&gt;,"property:0"]
        val_use[Usage: dtoverlay=...,mute_ext_ctl=4]
        val_result[Result: property = 4<br/>Driver reads value]
    end
    
    bool_syntax --> bool_use
    bool_use --> bool_result
    
    val_syntax --> val_use
    val_use --> val_result
    
    style boolean fill:#90EE90
    style value fill:#87CEEB
```

---

## Summary

These visual diagrams illustrate:

1. **Hardware Architecture** - Complete component layout and connections
2. **Layer Separation** - What each software layer controls
3. **Signal Flows** - Audio and display data paths
4. **Boot Sequence** - How system initializes from power-on
5. **I2C Architecture** - Device addressing and communication
6. **Device Tree Process** - How overlays are loaded and applied
7. **Parameter Resolution** - How dtoverlay parameters work

### Using These Diagrams

- **For understanding** - See how components interact
- **For troubleshooting** - Identify where in the chain problems occur
- **For documentation** - Include in presentations and guides
- **For teaching** - Explain concepts visually

### Diagram Formats

All diagrams are in **Mermaid** format, which renders in:
- GitHub/GitLab markdown
- Many documentation tools
- Can be exported to PNG/SVG

**Status:** Phase 5 Diagrams Complete

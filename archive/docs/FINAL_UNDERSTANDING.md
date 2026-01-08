# Final Understanding: What Actually Works

## Key Discovery
**You were right to question my intelligence!**

### The Truth
- **`hdmi_timings` works WITH `disable_fw_kms_setup=1`** (on RaspiOS Full)
- It was NOT about removing `disable_fw_kms_setup=1`
- It was about using `hdmi_timings` instead of `hdmi_cvt`

### Why I Was Wrong
I incorrectly concluded that removing `disable_fw_kms_setup=1` was necessary, when in fact:
- RaspiOS Full has `disable_fw_kms_setup=1` AND `hdmi_timings` works
- The mode appears in KMS even though firmware says `hdmi_timings is unknown`
- KMS reads the mode from somewhere (maybe kernel parameter or different mechanism)

### Current Test
- Applied `hdmi_timings` to Moode Audio
- Added `disable_fw_kms_setup=1` to match RaspiOS Full
- Testing if this makes 1280x400 available on Moode Audio

## Working Configuration (RaspiOS Full)
```ini
disable_fw_kms_setup=1

[pi5]
hdmi_timings=1280 32 48 80 400 10 3 2 60 35860 0 0 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
display_rotate=0
```

## What We Learned
1. `hdmi_timings` syntax works (with or without `=`)
2. `disable_fw_kms_setup=1` doesn't prevent `hdmi_timings` from working
3. Firmware may not recognize it, but KMS still gets the mode
4. Need to test if Moode Audio behaves the same way


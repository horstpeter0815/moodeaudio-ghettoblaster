# Forum Lösung - Exakt nachvollzogen

## Forum-Lösung (popeye65) für HDMI Display:

### Schritt 1: cmdline.txt
- ✅ `video=HDMI-A-1:400x1280M@60,rotate=90`
- ✅ Display startet im Portrait (400x1280)

### Schritt 2: Moode Web-UI
- ✅ `hdmi_scn_orient='portrait'`
- ✅ xinitrc führt dann xrandr Rotation aus

### Schritt 3: config.txt
- ✅ **KEINE hdmi_cvt, hdmi_timings, hdmi_group, hdmi_mode**
- ✅ Nur `hdmi_force_hotplug=1`
- ✅ Forum verwendet diese Parameter NICHT!

### Schritt 4: xinitrc
- ✅ Moode xinitrc rotiert automatisch bei `portrait`
- ✅ `xrandr --output HDMI-1 --rotate left`

## Unterschied zu meinen Versuchen:

- ❌ Ich habe hdmi_cvt/timings verwendet - Forum macht das NICHT!
- ❌ Ich habe hdmi_group/mode verwendet - Forum macht das NICHT!
- ✅ Forum verwendet NUR: video Parameter + Moode portrait + xinitrc

## Erwartetes Ergebnis:

- ✅ Display startet mit 400x1280 (Portrait)
- ✅ xinitrc rotiert dann zu Landscape
- ✅ Exakt wie im Forum beschrieben

---

**Status:** ✅ Exakt wie Forum implementiert! Reboot durchgeführt!


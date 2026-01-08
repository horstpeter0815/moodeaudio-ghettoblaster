# Smooth Audio Konfiguration - Befehle

## IP: 192.168.178.178
## User: andre
## Pass: 0815

## 1. STATUS PRÜFEN:
```bash
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "hostname && uname -a"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "grep dtoverlay /boot/firmware/config.txt | grep -v '^#'"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "cat /proc/asound/cards"
```

## 2. DISPLAY KONFIGURIEREN (Landscape):
```bash
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "sudo moodeutl -w hdmi_scn_orient landscape"
```

## 3. TOUCHSCREEN KONFIGURIEREN:
```bash
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "echo 'xinput set-prop \"FT6236\" \"Coordinate Transformation Matrix\" 0 -1 1 1 0 0 0 0 1' >> /home/andre/.xinitrc"
```

## 4. AUDIO PRÜFEN:
```bash
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "i2cdetect -y 13"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "dmesg | grep -i pcm5122"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "aplay -l"
```

## 5. REBOOT:
```bash
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@192.168.178.178 "sudo reboot"
```


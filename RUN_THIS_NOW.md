# 🎯 RUN THIS NOW

## ✅ Image is Mounted!

**Image:** `/Volumes/rootfs 1` (has moOde files)  
**SD card:** `/Volumes/rootfs` (needs moOde files)

## Copy moOde Files:

```bash
cd ~/moodeaudio-cursor
sudo ./MOUNT_AND_COPY.sh
```

**OR manually:**

```bash
sudo rsync -av --progress '/Volumes/rootfs 1/var/www/' '/Volumes/rootfs/var/www/html/'
sudo mkdir -p '/Volumes/rootfs/var/local/www'
sudo rsync -av --progress '/Volumes/rootfs 1/var/local/www/' '/Volumes/rootfs/var/local/www/'
```

**Then install fixes:**

```bash
sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

**Then eject and boot!**

---

**Run the copy command now!**


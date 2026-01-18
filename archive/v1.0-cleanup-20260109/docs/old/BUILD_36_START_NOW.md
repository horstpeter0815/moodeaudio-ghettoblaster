# 🚀 Start Build 36 - Copy-Paste Ready

## ⚠️ Important: Docker Required on macOS

**Before starting:** Make sure Docker Desktop is running!

## ✅ Correct Command (From Home Directory)

```bash
sudo ~/moodeaudio-cursor/START_BUILD_36.sh
```

**The script will automatically:**
- Detect macOS
- Use Docker for the build
- Build Docker image if needed
- Run build in container

## Or (If Already in Project Directory)

```bash
sudo ./START_BUILD_36.sh
```

## Or Via Toolbox

```bash
cd ~/moodeaudio-cursor
sudo ./tools/build.sh --build
```

---

## ⚠️ Important Notes

1. **Requires sudo** - Build system needs root privileges
2. **Docker should be running** - Script will warn if not
3. **Build takes 30-60 minutes** - Be patient
4. **Monitor progress** - Use another terminal: `~/moodeaudio-cursor/tools/build.sh --monitor`

---

## 📋 What Build 36 Includes

- ✅ SSH guaranteed (multiple layers)
- ✅ User fix (andre, UID 1000)
- ✅ Network fix (eth0 static IP 192.168.10.2)
- ✅ Early boot services

---

## 🎯 After Build Completes

```bash
# Validate build
sudo ~/moodeaudio-cursor/tools/build.sh --validate

# Test in Docker
~/moodeaudio-cursor/tools/test.sh --image

# Deploy to SD card
sudo ~/moodeaudio-cursor/tools/build.sh --deploy
```

---

**Ready to build! Just copy-paste the command above. 🚀**


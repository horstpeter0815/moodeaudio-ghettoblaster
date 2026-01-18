# 🐳 Build 36 - Docker Instructions (macOS)

## ⚠️ Important: Build Must Run in Docker on macOS

The build system requires Linux dependencies that aren't available on macOS. **Docker is required.**

---

## ✅ Step-by-Step Instructions

### Step 1: Start Docker Desktop
1. Open Docker Desktop application
2. Wait for Docker to start (whale icon in menu bar)
3. Verify Docker is running:
   ```bash
   docker info
   ```

### Step 2: Start Build
```bash
sudo ~/moodeaudio-cursor/START_BUILD_36.sh
```

**What happens:**
- Script detects macOS
- Checks Docker is running
- Builds Docker image (first time only, ~5 minutes)
- Runs build in Docker container (30-60 minutes)

---

## 🔍 Troubleshooting

### Docker Not Running
```bash
# Check Docker status
docker info

# If error: Start Docker Desktop first
```

### Docker Image Build Fails
```bash
# Manually build Docker image
cd ~/moodeaudio-cursor
docker-compose -f docker-compose.build.yml build
```

### Build Fails in Container
```bash
# Check container logs
docker-compose -f docker-compose.build.yml logs moode-builder

# Or enter container manually
docker-compose -f docker-compose.build.yml run --rm moode-builder bash
```

---

## 📋 Alternative: Manual Docker Build

If the script doesn't work, build manually:

```bash
# 1. Build Docker image
cd ~/moodeaudio-cursor
docker-compose -f docker-compose.build.yml build

# 2. Run build in container
docker-compose -f docker-compose.build.yml run --rm moode-builder bash -c "cd /workspace/imgbuild && ./build.sh"
```

---

## ⏱️ Build Time

- **Docker image build:** ~5 minutes (first time only)
- **Actual build:** 30-60 minutes
- **Total:** ~35-65 minutes

---

## ✅ After Build Completes

The image will be in:
```
~/moodeaudio-cursor/imgbuild/deploy/
```

Then:
```bash
# Validate
~/moodeaudio-cursor/tools/build.sh --validate

# Test in Docker
~/moodeaudio-cursor/tools/test.sh --image

# Deploy to SD card
sudo ~/moodeaudio-cursor/tools/build.sh --deploy
```

---

**Start Docker Desktop, then run the build! 🚀**


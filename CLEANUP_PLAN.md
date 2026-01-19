# Workspace Cleanup Plan
**Date:** 2026-01-19  
**Goal:** Clean, organized, production-ready workspace

---

## Phase 1: Archive Old Trial Scripts ✅

### Move to Archive:
- [ ] Old display fix attempts (50+ scripts)
- [ ] Audio debug scripts (replaced by working config)
- [ ] Network troubleshooting (one-time fixes)
- [ ] Failed build attempts documentation

### Keep Active:
- [x] Working build scripts (imgbuild/)
- [x] Current custom components (moode-source/)
- [x] Integration plans (WISSENSBASIS/141_*.md)

---

## Phase 2: Clean Build Artifacts ✅

### Remove:
- [ ] Old build logs (keep latest only)
- [ ] Failed build work directories
- [ ] Temporary build files
- [ ] Docker build cache

### Keep:
- [x] Current build configuration
- [x] Latest successful build log
- [x] Deploy scripts

---

## Phase 3: Consolidate Documentation ✅

### Merge/Archive:
- [ ] Redundant display configuration docs (5+ versions)
- [ ] Old troubleshooting guides (solved issues)
- [ ] Interim build status docs
- [ ] Duplicate device tree docs

### Organize:
- [ ] Create index of active docs
- [ ] Tag docs: [ACTIVE] [REFERENCE] [ARCHIVED]
- [ ] Remove duplicate information

---

## Phase 4: Organize Scripts ✅

### scripts/ Directory:
```
scripts/
├── deployment/     (SD card burning, imaging)
├── audio/          (Audio setup, CamillaDSP)
├── display/        (Display config helpers)
├── network/        (Network tools)
├── system/         (System maintenance)
└── README.md       (What each script does)
```

### tools/ Directory:
```
tools/
├── build/          (Build helpers)
├── debug/          (Debugging tools)
├── config/         (Configuration helpers)
└── README.md       (Tool descriptions)
```

---

## Phase 5: Clean Config Files ✅

### Remove:
- [ ] *.bak files (43 files)
- [ ] *.old files
- [ ] *.orig files
- [ ] Duplicate working configs

### Consolidate:
- [ ] Keep v1.0 working config (reference)
- [ ] Keep current build config (active)
- [ ] Archive all experiments

---

## Phase 6: GitHub Maintenance ✅

### Commit Structure:
```
git add -A
git commit -m "Major cleanup: Production-ready v1.1
- Archived trial-and-error scripts
- Organized scripts/ and tools/ directories
- Consolidated documentation
- Removed duplicate configs
- Added IR/DAB+ integration plan
- Build ready with Bose Wave True Stereo"

git tag v1.1-cleanup-production
git push origin main --tags
```

---

## Final Structure

```
moodeaudio-cursor/
├── .archive/                    # All old attempts
├── imgbuild/                    # BUILD SYSTEM (clean)
│   ├── moode-cfg/              # Active build config
│   ├── build-macos.sh          # Main build script
│   └── deploy/                 # Build output
├── moode-source/               # CUSTOM COMPONENTS (clean)
│   ├── boot/
│   ├── usr/
│   └── lib/
├── scripts/                    # ORGANIZED BY CATEGORY
│   ├── deployment/
│   ├── audio/
│   ├── display/
│   └── README.md
├── tools/                      # ORGANIZED TOOLBOX
│   ├── build/
│   ├── debug/
│   └── README.md
├── WISSENSBASIS/               # CONSOLIDATED DOCS
│   ├── 000_INDEX.md           # Master index
│   ├── [ACTIVE] docs          # Current system
│   ├── [REFERENCE] docs       # Keep for info
│   └── [ARCHIVED] tag         # Moved to .archive/
├── docs/                       # OFFICIAL DOCS
└── README.md                   # Project overview

REMOVED:
- 43 duplicate configs
- 80+ trial scripts
- 10+ old build logs
- Redundant documentation
```

---

## Success Criteria

- ✅ No duplicate files
- ✅ Clear directory structure
- ✅ Every script has purpose
- ✅ Documentation is current
- ✅ GitHub is organized
- ✅ Build system is clean
- ✅ Toolbox is maintained
- ✅ Ready for v1.1 release

---

**Estimated Time:** 30-45 minutes (while build runs)

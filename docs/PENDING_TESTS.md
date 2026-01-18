# ⏳ Pending Tests & Setup

**Date:** 2025-01-12  
**Status:** Tests ready, pending execution

---

## 🧙 Wizard + PeppyMeter Test

**Status:** ⏳ **READY TO TEST**

### What's Ready:
- ✅ Test script created: `scripts/wizard/TEST_PEPPYMETER_WIZARD.sh`
- ✅ Test plan documented: `docs/PEPPYMETER_WIZARD_TEST.md`
- ✅ PeppyMeter configuration script: `scripts/wizard/set-peppymeter-blue.sh`

### What Needs Testing:
1. PeppyMeter shows audio levels during wizard measurements
2. Pink noise levels visible on PeppyMeter
3. Corrected audio levels after filter application
4. Tap-to-switch functionality during wizard

### How to Test:
```bash
# From Mac (tests via SSH)
bash ~/moodeaudio-cursor/scripts/wizard/TEST_PEPPYMETER_WIZARD.sh

# Then manually:
# 1. Open: http://192.168.1.159/snd-config.php
# 2. Run wizard
# 3. Watch PeppyMeter during measurements
```

---

## 🔍 BIS - Status Unknown

**Status:** ❓ **NEEDS IDENTIFICATION**

### What is BIS?
- Not found in codebase
- May be:
  - Bluetooth-related (BIS = Broadcast Isochronous Stream?)
  - A component name or abbreviation
  - A feature that needs to be implemented

### Action Needed:
- [ ] Identify what BIS refers to
- [ ] Determine if it's a feature or component
- [ ] Create test plan if applicable

---

## 🔍 PAPI - Status Unknown

**Status:** ❓ **NEEDS IDENTIFICATION**

### What is PAPI?
- Not found in codebase
- May be:
  - Performance API (PAPI)?
  - A component name or abbreviation
  - A feature that needs to be implemented

### Action Needed:
- [ ] Identify what PAPI refers to
- [ ] Determine if it's a feature or component
- [ ] Create test plan if applicable

---

## 📋 Test Checklist

### Ready to Test:
- [x] PeppyMeter + Wizard integration
- [ ] **BIS** (needs identification first)
- [ ] **PAPI** (needs identification first)

### Test Scripts Available:
- ✅ `scripts/wizard/TEST_PEPPYMETER_WIZARD.sh`
- ✅ `scripts/wizard/set-peppymeter-blue.sh`

### Documentation:
- ✅ `docs/PEPPYMETER_WIZARD_TEST.md`
- ✅ `docs/WIZARD_ACCESS.md`

---

## 🚀 Next Steps

1. **Test PeppyMeter + Wizard:**
   ```bash
   bash ~/moodeaudio-cursor/scripts/wizard/TEST_PEPPYMETER_WIZARD.sh
   ```

2. **Identify BIS:**
   - Check with user what BIS refers to
   - Search project documentation
   - Create test plan once identified

3. **Identify PAPI:**
   - Check with user what PAPI refers to
   - Search project documentation
   - Create test plan once identified

---

**Last Updated:** 2025-01-12

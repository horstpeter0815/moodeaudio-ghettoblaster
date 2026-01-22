# Volume Optimization Wizard Integration - Changes Made

## Files Modified

### 1. Backend: `moode-source/www/command/room-correction-wizard.php`

**Added Commands:**
- `start_volume_optimization` - Initialize volume optimization wizard
- `test_volume_gain` - Test specific filter gain value (sets MPD to 1% for safe testing)
- `set_volume_gain` - Save optimal filter gain
- `get_volume_status` - Get current volume configuration

**Location:** Lines 21-25 (allowed_commands array) and lines 798-900+ (switch cases)

### 2. Frontend: `moode-source/www/templates/snd-config.html`

**Added Step 7: Volume Optimization**
- HTML: Lines 726-760 (wizard-step-7 div)
- JavaScript Functions: 
  - `startVolumeOptimization()` - Start volume optimization
  - `testVolumeGain()` - Test specific gain value
  - `reportVolumeResult()` - User feedback (too quiet/good/too loud)
  - `saveOptimalVolume()` - Save final configuration
- Updated `showWizardStep()` to handle step 7

**Location:** 
- HTML: After wizard-step-6, before closing modal-body div
- JavaScript: Before closeRoomCorrectionWizard() function

## How It Works

1. **User completes room correction** (Steps 1-6)
2. **Clicks "Continue to Volume Optimization"** button in Step 6
3. **Step 7 opens** with volume optimization interface
4. **User selects gain value** (4-8 dB dropdown)
5. **Clicks "Test This Gain Value"**
6. **System sets:**
   - Filter gain to selected value
   - MPD volume to 1% (safe for testing)
7. **User tests** with their protocol:
   - Volume at 1%
   - Press play
   - Increase gradually
8. **User provides feedback:**
   - "Too Quiet" → Try next higher gain
   - "Good!" → Save this configuration
   - "Too Loud" → Try next lower gain
9. **System saves optimal gain** when "Good!" is selected

## Integration Points

- **Backend:** `/command/room-correction-wizard.php` handles all volume optimization commands
- **Frontend:** Modal wizard in `snd-config.html` with Step 7 UI
- **Safety Protocol:** Always sets MPD to 1% before testing
- **User Control:** User decides when volume is optimal

## Testing

To test the wizard:
1. Access moOde web UI
2. Go to Audio Settings
3. Click "Run Wizard" (Room Correction)
4. Complete Steps 1-6 (room correction)
5. Click "Continue to Volume Optimization"
6. Test different gain values
7. Save optimal configuration

---

**Status:** ✅ Integrated and ready for testing

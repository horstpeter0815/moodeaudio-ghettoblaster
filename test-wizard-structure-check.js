const fs = require('fs');

console.log('🔍 Checking Wizard Structure...\n');

// Read the wizard HTML
const html = fs.readFileSync('moode-source/www/templates/snd-config.html', 'utf8');

let errors = [];
let warnings = [];

// Check 1: Modal exists
if (!html.includes('id="room-correction-wizard-modal"')) {
    errors.push('✗ Wizard modal element not found');
} else {
    console.log('✓ Wizard modal element found');
}

// Check 2: All 6 steps exist
for (let i = 1; i <= 6; i++) {
    if (!html.includes(`id="wizard-step-${i}"`)) {
        errors.push(`✗ Wizard step ${i} not found`);
    } else {
        console.log(`✓ Wizard step ${i} found`);
    }
}

// Check 3: Required functions
const requiredFunctions = {
    'startRoomCorrectionWizard': 'Main entry point',
    'wizardNextStep': 'Step navigation',
    'showWizardStep': 'Show step function',
    'startNoiseMeasurement': 'Ambient noise measurement',
    'finishNoiseMeasurement': 'Finish noise measurement',
    'startNoiseWebAudioMeasurement': 'Noise Web Audio setup',
    'startContinuousMeasurement': 'Pink noise measurement',
    'startWebAudioMeasurement': 'Web Audio setup',
    'stopMeasurement': 'Stop measurement',
    'updateNoiseMeasurement': 'Update noise measurement',
    'drawAmbientNoiseCanvas': 'Draw noise canvas',
    'drawFrequencyResponseCanvas': 'Draw frequency canvas'
};

console.log('\n📋 Checking Functions:');
Object.keys(requiredFunctions).forEach(func => {
    const regex = new RegExp(`function\\s+${func}\\s*\\(|const\\s+${func}\\s*=|let\\s+${func}\\s*=|var\\s+${func}\\s*=`);
    if (regex.test(html)) {
        console.log(`✓ ${func} - ${requiredFunctions[func]}`);
    } else {
        errors.push(`✗ ${func} - ${requiredFunctions[func]} - NOT FOUND`);
    }
});

// Check 4: Canvas elements
console.log('\n🎨 Checking Canvas Elements:');
const canvases = {
    'ambient-noise-canvas': 'Ambient noise visualization',
    'frequency-response-canvas': 'Frequency response visualization',
    'analysis-canvas': 'Analysis visualization',
    'before-after-canvas': 'Before/after comparison'
};

Object.keys(canvases).forEach(canvas => {
    if (html.includes(`id="${canvas}"`)) {
        console.log(`✓ ${canvas} - ${canvases[canvas]}`);
    } else {
        warnings.push(`⚠ ${canvas} - ${canvases[canvas]} - NOT FOUND (might be optional)`);
    }
});

// Check 5: Button handlers
console.log('\n🔘 Checking Button Handlers:');
const buttons = [
    {selector: 'onclick="wizardNextStep()"', name: 'Start Measurement button'},
    {selector: 'onclick="finishNoiseMeasurement()"', name: 'Finish Noise Measurement button'},
    {selector: 'onclick="applyCorrection()"', name: 'Apply Correction button'},
    {selector: 'onclick="stopMeasurement()"', name: 'Stop Measurement button'}
];

buttons.forEach(button => {
    if (html.includes(button.selector)) {
        console.log(`✓ ${button.name} found`);
    } else {
        warnings.push(`⚠ ${button.name} not found`);
    }
});

// Check 6: jQuery/Bootstrap dependencies
console.log('\n📚 Checking Dependencies:');
if (html.includes('jquery') || html.includes('jQuery')) {
    console.log('✓ jQuery reference found');
} else {
    warnings.push('⚠ jQuery reference not found in HTML (might be loaded elsewhere)');
}

// Summary
console.log('\n' + '='.repeat(50));
console.log('📊 Summary:');
console.log(`Errors: ${errors.length}`);
console.log(`Warnings: ${warnings.length}`);

if (errors.length > 0) {
    console.log('\n❌ ERRORS:');
    errors.forEach(e => console.log('  ' + e));
}

if (warnings.length > 0) {
    console.log('\n⚠️  WARNINGS:');
    warnings.forEach(w => console.log('  ' + w));
}

if (errors.length === 0) {
    console.log('\n✅ Structure check passed! All critical elements found.');
} else {
    console.log('\n❌ Structure check failed! Please fix errors above.');
    process.exit(1);
}

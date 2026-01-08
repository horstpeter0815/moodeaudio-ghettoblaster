const fs = require('fs');
const html = fs.readFileSync('moode-source/www/templates/snd-config.html', 'utf8');

console.log('🧪 Testing Wizard Logic Flow...\n');

// Extract wizardNextStep function to analyze logic
const wizardNextStepMatch = html.match(/function wizardNextStep\(\)\s*{[\s\S]*?}(?=\n\s*function|\n\s*<\/script>|$)/);
if (wizardNextStepMatch) {
    const funcCode = wizardNextStepMatch[0];
    console.log('✅ wizardNextStep function found');
    
    // Check step flow
    if (funcCode.includes('wizardStep === 2')) {
        console.log('✅ Step 2 logic found');
    }
    if (funcCode.includes('wizardStep === 3')) {
        console.log('✅ Step 3 logic found');
    }
    if (funcCode.includes('wizardStep === 4')) {
        console.log('✅ Step 4 logic found');
    }
    
    // Check if startNoiseMeasurement is called
    if (funcCode.includes('startNoiseMeasurement()')) {
        console.log('✅ Calls startNoiseMeasurement() for step 2');
    }
    
    // Check if startContinuousMeasurement is called
    if (funcCode.includes('startContinuousMeasurement()')) {
        console.log('✅ Calls startContinuousMeasurement() for step 3');
    }
} else {
    console.log('❌ wizardNextStep function not found');
}

// Check finishNoiseMeasurement calls wizardNextStep
if (html.includes('finishNoiseMeasurement')) {
    const finishMatch = html.match(/function finishNoiseMeasurement\(\)\s*{[\s\S]*?}(?=\n\s*function|\n\s*<\/script>|$)/);
    if (finishMatch && finishMatch[0].includes('wizardNextStep()')) {
        console.log('✅ finishNoiseMeasurement() calls wizardNextStep() - correct flow');
    } else {
        console.log('⚠️  finishNoiseMeasurement() may not call wizardNextStep()');
    }
}

// Check showWizardStep function
if (html.includes('function showWizardStep')) {
    const showMatch = html.match(/function showWizardStep\([^)]*\)\s*{[\s\S]*?}(?=\n\s*function|\n\s*<\/script>|$)/);
    if (showMatch) {
        const showCode = showMatch[0];
        // Check if it hides all steps
        if (showCode.includes('wizard-step-1') && showCode.includes('wizard-step-6')) {
            console.log('✅ showWizardStep hides all steps (1-6)');
        }
        // Check if it shows the requested step
        if (showCode.includes('.show()')) {
            console.log('✅ showWizardStep shows the requested step');
        }
    }
}

// Check step visibility initialization
if (html.includes('wizard-step-1') && html.includes('wizard-step-2')) {
    // Check if step 1 is visible by default
    const step1Match = html.match(/id="wizard-step-1"[^>]*>/);
    if (step1Match && !step1Match[0].includes('display: none')) {
        console.log('✅ Step 1 is visible by default');
    }
    
    // Check if other steps are hidden by default
    for (let i = 2; i <= 6; i++) {
        const stepMatch = html.match(new RegExp(`id="wizard-step-${i}"[^>]*>`));
        if (stepMatch && stepMatch[0].includes('display: none')) {
            console.log(`✅ Step ${i} is hidden by default`);
        }
    }
}

console.log('\n✅ Logic flow check complete!');

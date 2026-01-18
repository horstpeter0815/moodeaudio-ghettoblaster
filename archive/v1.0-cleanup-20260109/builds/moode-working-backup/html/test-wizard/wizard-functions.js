/**
 * Room Correction Wizard Functions
 * Extracted minimal set of functions needed for wizard to work
 * Based on snd-config.html but without the problematic parts that cause hanging
 */

// Log helper function (defined early so it can be used throughout)
function wizardLog(msg, type) {
    console.log(msg);
    if (typeof window !== 'undefined' && typeof window.log === 'function') {
        try {
            window.log(msg, type || 'info');
        } catch(e) {
            // Ignore errors if log fails
        }
    }
}

wizardLog('=== wizard-functions.js: Script file STARTED loading ===', 'info');
console.log('=== wizard-functions.js: Script file STARTED loading ===');

// Wizard state
let wizardStep = 1;
let measurementData = null;
let frequencyResponse = null;
let frequencyDataBuffer = [];
let currentFrequencyResponse = null;
let currentMicrophoneStream = null; // Store stream to reuse between steps

// Web Audio API variables
let audioContext = null;
let analyser = null;
let microphone = null;
let measurementInterval = null;
let isMeasuring = false;

// Constants
const SAMPLE_RATE = 44100;
const FFT_SIZE = 8192;
const AVERAGE_WINDOW_SECONDS = 2.5;
const NOISE_MEASUREMENT_SECONDS = 5;
const UPDATE_INTERVAL_MS = 100;

// Ambient noise measurement
let ambientNoiseMeasurement = null;
let noiseMeasurementStartTime = null;
let noiseMeasurementInterval = null;
let isMeasuringNoise = false;

/**
 * Start the room correction wizard
 */
function startRoomCorrectionWizard() {
    wizardStep = 1;
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:38',message:'startRoomCorrectionWizard called',data:{wizardStep:wizardStep},timestamp:Date.now(),sessionId:'wizard-debug',runId:'start-wizard',hypothesisId:'H1'})}).catch(()=>{});
    // #endregion
    
    // Show modal
    var modal = $('#room-correction-wizard-modal');
    if (modal.length) {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:45',message:'Modal element found',data:{modalLength:modal.length},timestamp:Date.now(),sessionId:'wizard-debug',runId:'start-wizard',hypothesisId:'H2'})}).catch(()=>{});
        // #endregion
        
        if (typeof $.fn.modal !== 'undefined') {
            modal.modal('show');
        } else {
            modal.css('display', 'block');
            modal.addClass('show');
            if (!$('#modal-backdrop').length) {
                $('body').append('<div id="modal-backdrop" class="modal-backdrop fade show"></div>');
            }
        }
    } else {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:53',message:'Modal element NOT found',data:{},timestamp:Date.now(),sessionId:'wizard-debug',runId:'start-wizard',hypothesisId:'H3'})}).catch(()=>{});
        // #endregion
    }
    
    showWizardStep(1);
    stopMeasurement();
}

/**
 * Show specific wizard step
 */
function showWizardStep(step) {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:62',message:'showWizardStep called',data:{step:step,oldStep:wizardStep},timestamp:Date.now(),sessionId:'wizard-debug',runId:'show-step',hypothesisId:'H4'})}).catch(()=>{});
    // #endregion
    
    for (let i = 1; i <= 6; i++) {
        $('#wizard-step-' + i).hide();
    }
    const targetStep = $('#wizard-step-' + step);
    targetStep.show();
    wizardStep = step;
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:70',message:'Step shown',data:{step:step,targetStepLength:targetStep.length,isVisible:targetStep.is(':visible')},timestamp:Date.now(),sessionId:'wizard-debug',runId:'show-step',hypothesisId:'H5'})}).catch(()=>{});
    // #endregion
    
    // Update Step 6 status when shown
    if (step === 6) {
        wizardLog('Step 6 shown - updating filter status indicator', 'info');
        // Check if we're in simulation mode (mock backend)
        // Detect simulation: localhost or port 8080 = Docker test
        const isSimulation = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' || window.location.port === '8080';
        
        setTimeout(() => {
            if (isSimulation) {
                // Show simulation warning
                if ($('#simulation-warning-step6').length) {
                    $('#simulation-warning-step6').show();
                }
                if ($('#filter-status-text').length) {
                    $('#filter-status-text').text('SIMULATED (Not Active)');
                }
                if ($('#filter-status-details').length) {
                    $('#filter-status-details').html('<strong>⚠️ SIMULATION MODE:</strong> Filter is NOT actually applied. This is a test environment with mock backend.');
                }
                wizardLog('Filter status: SIMULATED (not actually active)', 'warning');
            } else {
                // Real system - filter should be active
                if ($('#simulation-warning-step6').length) {
                    $('#simulation-warning-step6').hide();
                }
                if ($('#filter-status-text').length) {
                    $('#filter-status-text').text('Active');
                }
                if ($('#filter-status-details').length) {
                    $('#filter-status-details').text('Filter has been generated and applied. Pink noise continues with correction active - you should hear the difference!');
                }
                wizardLog('Filter status: Active (REAL SYSTEM)', 'success');
            }
        }, 100);
    }
    
    // Wire up buttons in the newly shown step (especially for Step 5)
    if (step === 5) {
        setTimeout(() => {
            const generateBtn = $('#wizard-step-5 button');
            generateBtn.each(function() {
                const btn = $(this);
                const text = btn.text().trim();
                if (text.includes('Generate Filter')) {
                    console.log('Generate Filter button in Step 5, window.generateFilter:', typeof window.generateFilter);
                    // DON'T wire up - let onclick attribute work naturally
                    // The onclick='generateFilter()' should work if window.generateFilter exists
                    // #region agent log
                    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:82',message:'Step 5 Generate Filter button - leaving onclick attribute',data:{windowGenerateFilter:typeof window.generateFilter},timestamp:Date.now(),sessionId:'wizard-debug',runId:'show-step',hypothesisId:'H10'})}).catch(()=>{});
                    // #endregion
                }
            });
        }, 100);
    }
}

/**
 * Go to next wizard step
 */
function wizardNextStep() {
    wizardLog('=== wizardNextStep() called ===', 'success');
    wizardLog('Current wizardStep: ' + wizardStep, 'info');
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:73',message:'wizardNextStep called',data:{currentStep:wizardStep},timestamp:Date.now(),sessionId:'wizard-debug',runId:'next-step',hypothesisId:'H6'})}).catch(()=>{});
    // #endregion
    
    wizardStep++;
    wizardLog('wizardStep incremented to: ' + wizardStep, 'info');
    
    if (wizardStep === 2) {
        wizardLog('wizardStep is 2 - starting ambient noise measurement', 'info');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:80',message:'Starting Step 2 - Ambient Noise Measurement',data:{},timestamp:Date.now(),sessionId:'wizard-debug',runId:'next-step',hypothesisId:'H7'})}).catch(()=>{});
        // #endregion
        // Re-enabled: Show Step 2 and start ambient noise measurement
        showWizardStep(2);
        startNoiseMeasurement();
    } else if (wizardStep === 3) {
        wizardLog('wizardStep is 3 - calling startContinuousMeasurement()', 'info');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:86',message:'Step 3, calling startContinuousMeasurement',data:{},timestamp:Date.now(),sessionId:'wizard-debug',runId:'next-step',hypothesisId:'H8'})}).catch(()=>{});
        // #endregion
        startContinuousMeasurement();
    } else if (wizardStep === 4) {
        wizardLog('wizardStep is 4 - showing Step 4', 'info');
        showWizardStep(4);
    } else if (wizardStep === 5) {
        wizardLog('wizardStep is 5 - showing Step 5', 'info');
        showWizardStep(5);
    } else if (wizardStep === 6) {
        wizardLog('wizardStep is 6 - showing Step 6', 'info');
        showWizardStep(6);
    } else {
        wizardLog('wizardStep is ' + wizardStep + ' - no handler for this step', 'warning');
    }
    wizardLog('wizardNextStep() completed', 'success');
}

/**
 * Start ambient noise measurement
 */
function startNoiseMeasurement() {
    console.log('startNoiseMeasurement called, showing step 2');
    showWizardStep(2);
    
    // Wait a bit for step 2 to be visible before requesting mic
    setTimeout(() => {
        if ($('#noise-measurement-status-text').length) {
            $('#noise-measurement-status-text').text('Requesting microphone access for ambient noise measurement...');
        }
        console.log('Starting noise web audio measurement...');
        startNoiseWebAudioMeasurement();
    }, 300);
}

/**
 * Start noise measurement using Web Audio API
 */
function startNoiseWebAudioMeasurement() {
    console.log('startNoiseWebAudioMeasurement called');
    
    // Check if getUserMedia is available
    if (!navigator.mediaDevices) {
        const errorMsg = 'navigator.mediaDevices not available. This requires HTTPS or localhost.';
        console.error(errorMsg);
        alert(errorMsg + '\n\nOn iPhone Safari, getUserMedia only works with HTTPS or localhost.');
        if ($('#noise-measurement-status-text').length) {
            $('#noise-measurement-status-text').html('❌ ' + errorMsg);
        }
        return;
    }
    
    if (!navigator.mediaDevices.getUserMedia) {
        const errorMsg = 'getUserMedia not available. This may require HTTPS.';
        console.error(errorMsg);
        alert(errorMsg + '\n\niPhone Safari requires HTTPS for getUserMedia on non-localhost URLs.');
        if ($('#noise-measurement-status-text').length) {
            $('#noise-measurement-status-text').html('❌ ' + errorMsg);
        }
        return;
    }
    
    // Check if we're on HTTPS
    const isHttps = window.location.protocol === 'https:';
    const isLocalhost = window.location.hostname.match(/^localhost$|^127\.0\.0\.1$/);
    const isHttp = window.location.protocol === 'http:' && !isLocalhost;
    
    if (isHttp) {
        console.warn('HTTP detected - iPhone Safari requires HTTPS for getUserMedia');
        const errorMsg = 'HTTPS required: iPhone Safari needs HTTPS for microphone access';
        alert(errorMsg + '\n\nCurrent URL: ' + window.location.href + '\n\nPlease use HTTPS URL.');
        if ($('#noise-measurement-status-text').length) {
            $('#noise-measurement-status-text').html('❌ ' + errorMsg);
        }
        return;
    }
    
    console.log('Protocol check: HTTPS=' + isHttps + ', Protocol=' + window.location.protocol);
    
    // Add timeout for getUserMedia call (15 seconds for iPhone Safari - it can be slow)
    let timeoutFired = false;
    const timeout = setTimeout(() => {
        timeoutFired = true;
        console.error('getUserMedia timeout after 15 seconds');
        const currentProtocol = window.location.protocol;
        console.log('Timeout - Current protocol:', currentProtocol, 'isHttps:', isHttps);
        
        let errorMsg = 'Microphone access timeout after 15 seconds.\n\nPlease check:\n';
        errorMsg += '1. Microphone permissions in Safari settings:\n   Settings → Safari → Microphone\n';
        errorMsg += '2. Safari may be asking for permission - check for a prompt\n';
        errorMsg += '3. Try refreshing the page\n';
        errorMsg += '4. Make sure no other app is using the microphone\n';
        
        if ($('#noise-measurement-status-text').length) {
            $('#noise-measurement-status-text').html('❌ Microphone access timeout<br><small>Check Safari microphone permissions</small>');
        }
        alert(errorMsg);
    }, 15000); // Increased to 15 seconds for iPhone Safari
    
    console.log('Requesting microphone access...', {
        protocol: window.location.protocol,
        hostname: window.location.hostname,
        hasMediaDevices: !!navigator.mediaDevices,
        hasGetUserMedia: !!navigator.mediaDevices?.getUserMedia
    });
    
    navigator.mediaDevices.getUserMedia({ audio: true })
        .then(stream => {
            if (timeoutFired) {
                console.log('getUserMedia succeeded after timeout warning');
                // Stream was granted, but timeout already fired - still continue
            } else {
                clearTimeout(timeout);
            }
            console.log('Microphone access granted, stream:', stream);
            
            try {
                // Create AudioContext
                const AudioContextClass = window.AudioContext || window.webkitAudioContext;
                if (!AudioContextClass) {
                    throw new Error('Web Audio API not supported');
                }
                
                audioContext = new AudioContextClass({
                    sampleRate: SAMPLE_RATE
                });
                console.log('AudioContext created:', audioContext.state);
                
                // Create analyser node
                analyser = audioContext.createAnalyser();
                analyser.fftSize = FFT_SIZE;
                analyser.smoothingTimeConstant = 0.3;
                console.log('Analyser created, fftSize:', FFT_SIZE);
                
                // Connect microphone to analyser
                microphone = audioContext.createMediaStreamSource(stream);
                microphone.connect(analyser);
                currentMicrophoneStream = stream; // Store stream for reuse
                console.log('Microphone connected to analyser');
                
                // Initialize noise measurement
                ambientNoiseMeasurement = null;
                noiseMeasurementStartTime = Date.now();
                isMeasuringNoise = true;
                
                // Show measurement UI
                if ($('#noise-measurement-recording').length) {
                    $('#noise-measurement-recording').show();
                }
                if ($('#noise-measurement-status-text').length) {
                    $('#noise-measurement-status-text').text('✅ Measuring ambient noise...');
                }
                console.log('Measurement started');
                
                // Start measurement loop
                noiseMeasurementInterval = setInterval(updateNoiseMeasurement, UPDATE_INTERVAL_MS);
                
                // Auto-finish after timeout
                setTimeout(function() {
                    if (isMeasuringNoise) {
                        console.log('Auto-finishing noise measurement');
                        finishNoiseMeasurement();
                    }
                }, NOISE_MEASUREMENT_SECONDS * 1000);
                
                // Initial update
                updateNoiseMeasurement();
            } catch (err) {
                clearTimeout(timeout);
                console.error('Error setting up Web Audio API:', err);
                const errorMsg = 'Error setting up audio measurement: ' + err.message;
                alert(errorMsg);
                if ($('#noise-measurement-status-text').length) {
                    $('#noise-measurement-status-text').html('❌ ' + errorMsg);
                }
            }
        })
        .catch(err => {
            if (!timeoutFired) {
                clearTimeout(timeout);
            }
            console.error('Error accessing microphone:', err);
            console.error('Error name:', err.name);
            console.error('Error message:', err.message);
            console.error('Protocol:', window.location.protocol);
            
            let errorMsg = 'Microphone access error: ' + err.name;
            if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
                errorMsg = 'Microphone access denied.\n\nPlease check Safari settings:\nSettings → Safari → Microphone\n\nOr allow microphone access when Safari asks for permission.';
            } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
                errorMsg = 'No microphone found. Please connect a microphone.';
            } else if (err.name === 'NotSupportedError' || err.name === 'ConstraintNotSatisfiedError') {
                errorMsg = 'Microphone not supported or constraints not satisfied.';
            } else {
                errorMsg = 'Microphone error: ' + err.message;
            }
            
            // Only mention HTTP if actually on HTTP (not HTTPS)
            const currentProtocol = window.location.protocol;
            if (currentProtocol === 'http:' && !window.location.hostname.match(/^localhost$|^127\.0\.0\.1$/)) {
                errorMsg += '\n\n⚠️ You are using HTTP. iPhone Safari requires HTTPS for microphone access.';
                console.warn('HTTP detected but getUserMedia failed');
            } else {
                console.log('Error on HTTPS - not an HTTP issue, protocol:', currentProtocol);
            }
            
            alert(errorMsg);
            if ($('#noise-measurement-status-text').length) {
                $('#noise-measurement-status-text').html('❌ ' + errorMsg.replace(/\n/g, '<br>'));
            }
        });
}

/**
 * Update noise measurement display
 */
function updateNoiseMeasurement() {
    if (!analyser || !isMeasuringNoise) return;
    
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    analyser.getByteFrequencyData(dataArray);
    
    const frequencies = [];
    const magnitudes = [];
    const nyquist = SAMPLE_RATE / 2;
    
    for (let i = 0; i < bufferLength; i++) {
        const freq = (i * nyquist) / bufferLength;
        if (freq >= 20 && freq <= 20000) {
            const magnitude = dataArray[i];
            const db = magnitude > 0 ? (magnitude / 255) * 96 - 96 : -96;
            frequencies.push(freq);
            magnitudes.push(db);
        }
    }
    
    if (!ambientNoiseMeasurement) {
        ambientNoiseMeasurement = {
            frequencies: frequencies,
            magnitude: new Array(frequencies.length).fill(0),
            count: 0
        };
    }
    
    if (ambientNoiseMeasurement.frequencies.length === frequencies.length) {
        for (let i = 0; i < frequencies.length; i++) {
            ambientNoiseMeasurement.magnitude[i] += magnitudes[i];
        }
        ambientNoiseMeasurement.count++;
    }
    
    // Update timer
    const elapsed = (Date.now() - noiseMeasurementStartTime) / 1000;
    const remaining = Math.max(0, NOISE_MEASUREMENT_SECONDS - elapsed);
    $('#noise-measurement-time').text(Math.ceil(remaining));
    if (remaining <= 0 && $('#finish-noise-btn').length) {
        $('#finish-noise-btn').show();
    }
}

/**
 * Finish noise measurement
 */
function finishNoiseMeasurement() {
    isMeasuringNoise = false;
    
    if (noiseMeasurementInterval) {
        clearInterval(noiseMeasurementInterval);
        noiseMeasurementInterval = null;
    }
    
    if (ambientNoiseMeasurement && ambientNoiseMeasurement.count > 0) {
        // Calculate average
        for (let i = 0; i < ambientNoiseMeasurement.magnitude.length; i++) {
            ambientNoiseMeasurement.magnitude[i] /= ambientNoiseMeasurement.count;
        }
    }
    
    // DON'T close audioContext or stop microphone stream - we'll reuse it in Step 3
    // Just disconnect the microphone from analyser (we'll reconnect in Step 3)
    if (microphone && analyser) {
        microphone.disconnect(analyser);
        console.log('Disconnected microphone from analyser (will reconnect in Step 3)');
    }
    
    wizardNextStep();
}

/**
 * Start continuous pink noise measurement
 */
function startContinuousMeasurement() {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:362',message:'startContinuousMeasurement called',data:{wizardStep:wizardStep,audioContextState:audioContext?audioContext.state:'null',microphoneExists:!!microphone,streamExists:!!currentMicrophoneStream},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H1'})}).catch(()=>{});
    // #endregion
    
    showWizardStep(3);
    if ($('#measurement-status-text').length) {
        $('#measurement-status-text').text('Starting pink noise playback...');
    }
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:369',message:'Before pink noise POST request',data:{step3Visible:$('#wizard-step-3').is(':visible'),statusTextExists:$('#measurement-status-text').length>0},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H2'})}).catch(()=>{});
    // #endregion
    
    // Start pink noise playback
    wizardLog('Sending start_pink_noise command to backend...', 'info');
    $.post('/command/room-correction-wizard.php', {
        cmd: 'start_pink_noise'
    }, function(data) {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:374',message:'Pink noise POST response',data:{status:data.status,message:data.message,hasData:!!data},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H3'})}).catch(()=>{});
        // #endregion
        
        wizardLog('Pink noise response: ' + JSON.stringify(data), 'info');
        
        // Check if this is a simulation (mock backend)
        const isSimulation = data.message && data.message.includes('simulated');
        const hasPid = data.pid && data.pid !== 'unknown' && data.pid !== null && data.pid !== undefined;
        const statusOk = data.status === 'ok';
        
        wizardLog('Pink noise check - isSimulation: ' + isSimulation + ', hasPid: ' + hasPid + ', status: ' + data.status, 'info');
        
        // Real system has PID and status='ok', simulation doesn't
        if (isSimulation || !hasPid || !statusOk) {
            wizardLog('⚠️ WARNING: Pink noise may not be playing!', 'error');
            wizardLog('Response: ' + JSON.stringify(data), 'error');
            if ($('#measurement-status-text').length) {
                if (isSimulation) {
                    $('#measurement-status-text').html('⚠️ <strong>SIMULATION MODE:</strong> Pink noise is NOT actually playing. This is a test environment with mock backend.');
                } else {
                    $('#measurement-status-text').html('⚠️ <strong>WARNING:</strong> Pink noise may not have started. Response: ' + (data.message || 'Unknown error') + '. Check volume and audio device.');
                }
            }
        } else {
            wizardLog('✅ Pink noise started on REAL system - you should hear it!', 'success');
            wizardLog('Pink noise PID: ' + data.pid, 'info');
            if ($('#measurement-status-text').length) {
                $('#measurement-status-text').html('✅ <strong>Pink noise started!</strong> PID: ' + data.pid + '<br>You should hear pink noise from your speakers now. Requesting microphone access...');
            }
        }
        
        if (data.status === 'ok') {
            startContinuousWebAudioMeasurement();
        } else {
            alert('Error starting pink noise: ' + (data.message || 'Unknown error'));
        }
    }).fail(function(xhr, status, error) {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:382',message:'Pink noise POST failed',data:{status:status,error:error,xhrStatus:xhr.status,xhrStatusText:xhr.statusText},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H4'})}).catch(()=>{});
        // #endregion
    });
}

/**
 * Start continuous measurement using Web Audio API
 */
function startContinuousWebAudioMeasurement() {
    console.log('startContinuousWebAudioMeasurement called');
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:383',message:'startContinuousWebAudioMeasurement called',data:{audioContextState:audioContext?audioContext.state:'null',microphoneExists:!!microphone,streamExists:!!currentMicrophoneStream,analyserExists:!!analyser},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H5'})}).catch(()=>{});
    // #endregion
    
    // Check if we already have an active microphone stream from Step 2
    // If so, reuse it; otherwise request a new one
    if (audioContext && audioContext.state !== 'closed' && microphone) {
        console.log('Reusing existing audioContext and microphone stream');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:390',message:'Reusing existing audio context and microphone',data:{audioContextState:audioContext.state,analyserExists:!!analyser},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H6'})}).catch(()=>{});
        // #endregion
        
        // Reconnect microphone to analyser
        if (!analyser) {
            analyser = audioContext.createAnalyser();
            analyser.fftSize = FFT_SIZE;
            analyser.smoothingTimeConstant = 0.3;
        }
        microphone.connect(analyser);
    } else {
        // Request new microphone access
        console.log('Requesting new microphone access for continuous measurement');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:399',message:'Requesting new microphone access',data:{mediaDevicesExists:!!navigator.mediaDevices},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H7'})}).catch(()=>{});
        // #endregion
        
        navigator.mediaDevices.getUserMedia({ audio: true })
            .then(stream => {
                // #region agent log
                fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:402',message:'Microphone access granted',data:{streamActive:stream.active,streamId:stream.id,audioTracks:stream.getAudioTracks().length},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H8'})}).catch(()=>{});
                // #endregion
                setupAudioMeasurement(stream);
            })
            .catch(err => {
                console.error('Error accessing microphone:', err);
                // #region agent log
                fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:410',message:'Microphone access error',data:{errorName:err.name,errorMessage:err.message},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H9'})}).catch(()=>{});
                // #endregion
                
                let errorMsg = 'Microphone access error: ' + err.name;
                if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
                    errorMsg = 'Microphone access denied.\n\nPlease check Safari settings:\nSettings → Safari → Microphone\n\nOr allow microphone access when Safari asks for permission.';
                } else {
                    errorMsg = 'Microphone error: ' + err.message;
                }
                alert(errorMsg);
                if ($('#measurement-status-text').length) {
                    $('#measurement-status-text').html('❌ ' + errorMsg.replace(/\n/g, '<br>'));
                }
            });
        return; // Exit early, setupAudioMeasurement will be called from the promise
    }
    
    // If we got here, we're reusing existing stream - continue with setup
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:425',message:'Reusing stream path - calling setupAudioMeasurement',data:{},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H10'})}).catch(()=>{});
    // #endregion
    setupAudioMeasurement(null);
}

/**
 * Setup audio measurement (reused by both paths above)
 */
function setupAudioMeasurement(stream) {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:427',message:'setupAudioMeasurement called',data:{streamProvided:!!stream,audioContextExists:!!audioContext,audioContextState:audioContext?audioContext.state:'null'},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H11'})}).catch(()=>{});
    // #endregion
    
    try {
        // Create AudioContext if needed
        if (!audioContext || audioContext.state === 'closed') {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            if (!AudioContextClass) {
                throw new Error('Web Audio API not supported');
            }
            audioContext = new AudioContextClass({
                sampleRate: SAMPLE_RATE
            });
            console.log('AudioContext created:', audioContext.state);
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:438',message:'AudioContext created',data:{state:audioContext.state,sampleRate:audioContext.sampleRate},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H12'})}).catch(()=>{});
            // #endregion
        }
        
        // Create analyser if needed
        if (!analyser) {
            analyser = audioContext.createAnalyser();
            analyser.fftSize = FFT_SIZE;
            analyser.smoothingTimeConstant = 0.3; // Less smoothing for real-time
            console.log('Analyser created, fftSize:', FFT_SIZE);
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:446',message:'Analyser created',data:{fftSize:FFT_SIZE},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H13'})}).catch(()=>{});
            // #endregion
        }
        
        // Connect microphone - either use new stream or reuse existing
        if (stream) {
            // New stream - create new MediaStreamSource
            microphone = audioContext.createMediaStreamSource(stream);
            microphone.connect(analyser);
            currentMicrophoneStream = stream; // Store stream
            console.log('Microphone connected to analyser (new stream)');
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:450',message:'Microphone connected (new stream)',data:{streamActive:stream.active},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H14'})}).catch(()=>{});
            // #endregion
        } else if (currentMicrophoneStream) {
            // Reuse existing stream - create new MediaStreamSource from stored stream
            microphone = audioContext.createMediaStreamSource(currentMicrophoneStream);
            microphone.connect(analyser);
            console.log('Microphone reconnected to analyser (reusing existing stream)');
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:456',message:'Microphone reconnected (reusing stream)',data:{streamActive:currentMicrophoneStream.active},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H15'})}).catch(()=>{});
            // #endregion
        } else if (microphone) {
            // Fallback: try to reconnect existing microphone node
            microphone.connect(analyser);
            console.log('Microphone reconnected to analyser (fallback)');
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:461',message:'Microphone reconnected (fallback)',data:{},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H16'})}).catch(()=>{});
            // #endregion
        } else {
            throw new Error('No microphone stream available and no new stream provided');
        }
        
        // Initialize frequency data buffer
        frequencyDataBuffer = [];
        
        // Show measurement UI
        if ($('#measurement-recording').length) {
            $('#measurement-recording').show();
        }
        if ($('#measurement-status-text').length) {
            $('#measurement-status-text').text('✅ Measurement active');
        }
        console.log('Measurement started');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:478',message:'Measurement UI shown and started',data:{recordingVisible:$('#measurement-recording').is(':visible'),statusTextExists:$('#measurement-status-text').length>0},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H17'})}).catch(()=>{});
        // #endregion
        
        isMeasuring = true;
        
        // Start continuous measurement loop
        measurementInterval = setInterval(updateMeasurement, UPDATE_INTERVAL_MS);
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:484',message:'Measurement interval started',data:{intervalMs:UPDATE_INTERVAL_MS,isMeasuring:isMeasuring},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H18'})}).catch(()=>{});
        // #endregion
        
        // Initial update
        updateMeasurement();
    } catch (err) {
        console.error('Error setting up Web Audio API:', err);
        const errorMsg = 'Error setting up audio measurement: ' + err.message;
        alert(errorMsg);
        if ($('#measurement-status-text').length) {
            $('#measurement-status-text').html('❌ ' + errorMsg);
        }
    }
}

/**
 * Update continuous measurement display
 */
function updateMeasurement() {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:564',message:'updateMeasurement called',data:{analyserExists:!!analyser,isMeasuring:isMeasuring},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H19'})}).catch(()=>{});
    // #endregion
    
    if (!analyser || !isMeasuring) {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:567',message:'updateMeasurement early return',data:{analyserExists:!!analyser,isMeasuring:isMeasuring},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H20'})}).catch(()=>{});
        // #endregion
        return;
    }
    
    // Get frequency data
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    analyser.getByteFrequencyData(dataArray);
    
    // #region agent log
    const maxValue = Math.max(...dataArray);
    const sum = dataArray.reduce((a, b) => a + b, 0);
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:575',message:'Frequency data retrieved',data:{bufferLength:bufferLength,maxValue:maxValue,sum:sum,hasData:maxValue>0},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H21'})}).catch(()=>{});
    // #endregion
    
    // Convert to dB and map to frequencies
    const frequencies = [];
    const magnitudes = [];
    const nyquist = SAMPLE_RATE / 2;
    
    for (let i = 0; i < bufferLength; i++) {
        const freq = (i * nyquist) / bufferLength;
        // Only use 20-20000 Hz range
        if (freq >= 20 && freq <= 20000) {
            // Convert to dB (dataArray is 0-255, representing 0 to -96 dB)
            const magnitude = dataArray[i];
            const db = magnitude > 0 ? (magnitude / 255) * 96 - 96 : -96;
            
            frequencies.push(freq);
            magnitudes.push(db);
        }
    }
    
    // Add to rolling average buffer
    const timestamp = Date.now();
    frequencyDataBuffer.push({
        timestamp: timestamp,
        frequencies: frequencies,
        magnitudes: magnitudes
    });
    
    // Remove old data (keep only last 2-3 seconds)
    const cutoffTime = timestamp - (AVERAGE_WINDOW_SECONDS * 1000);
    frequencyDataBuffer = frequencyDataBuffer.filter(item => item.timestamp > cutoffTime);
    
    // Calculate rolling average
    if (frequencyDataBuffer.length > 0) {
        const avgMagnitudes = new Array(frequencies.length).fill(0);
        
        // Average across all samples in buffer
        frequencyDataBuffer.forEach(sample => {
            // Interpolate sample magnitudes to match frequency array
            for (let i = 0; i < frequencies.length; i++) {
                const targetFreq = frequencies[i];
                // Find closest frequency in sample
                let closestIdx = 0;
                let minDist = Math.abs(sample.frequencies[0] - targetFreq);
                for (let j = 1; j < sample.frequencies.length; j++) {
                    const dist = Math.abs(sample.frequencies[j] - targetFreq);
                    if (dist < minDist) {
                        minDist = dist;
                        closestIdx = j;
                    }
                }
                avgMagnitudes[i] += sample.magnitudes[closestIdx];
            }
        });
        
        // Divide by number of samples
        for (let i = 0; i < avgMagnitudes.length; i++) {
            avgMagnitudes[i] /= frequencyDataBuffer.length;
        }
        
        // TEMPORARILY DISABLED: Subtract ambient noise if available
        // TODO: Re-enable ambient noise correction later
        let correctedMagnitudes = avgMagnitudes;
        // if (ambientNoiseMeasurement && ambientNoiseMeasurement.frequencies.length === frequencies.length) {
        //     // Subtract noise floor from measurement
        //     // Use power subtraction: 10*log10(10^(signal/10) - 10^(noise/10))
        //     correctedMagnitudes = new Array(frequencies.length);
        //     for (let i = 0; i < frequencies.length; i++) {
        //         const signalPower = Math.pow(10, avgMagnitudes[i] / 10);
        //         const noisePower = Math.pow(10, ambientNoiseMeasurement.magnitude[i] / 10);
        //         const correctedPower = Math.max(0.000001, signalPower - noisePower); // Prevent negative/zero
        //         correctedMagnitudes[i] = 10 * Math.log10(correctedPower);
        //     }
        // }
        
        // Store current averaged frequency response (without ambient noise correction for now)
        currentFrequencyResponse = {
            frequencies: frequencies,
            magnitude: correctedMagnitudes, // Using raw magnitudes without noise subtraction
            ambient_noise: null // Disabled for now
        };
        
        // Update display (show both original and corrected)
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:667',message:'Before drawFrequencyResponseCanvas',data:{hasFreqResponse:!!currentFrequencyResponse,hasFrequencies:currentFrequencyResponse?.frequencies?.length>0,hasMagnitude:currentFrequencyResponse?.magnitude?.length>0},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H22'})}).catch(()=>{});
        // #endregion
        drawFrequencyResponseCanvas(currentFrequencyResponse);
    }
}

/**
 * Draw frequency response canvas
 * Supports both 'frequency-response-canvas' (Step 3) and 'analysis-canvas' (Step 5)
 */
function drawFrequencyResponseCanvas(freqResponse) {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:674',message:'drawFrequencyResponseCanvas called',data:{canvasExists:!!document.getElementById('frequency-response-canvas'),analysisCanvasExists:!!document.getElementById('analysis-canvas'),hasFreqResponse:!!freqResponse},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H23'})}).catch(()=>{});
    // #endregion
    
    // Try to find canvas - check both possible IDs (Step 3 uses 'frequency-response-canvas', Step 5 uses 'analysis-canvas')
    let canvas = document.getElementById('frequency-response-canvas');
    if (!canvas) {
        canvas = document.getElementById('analysis-canvas');
    }
    
    if (!canvas || !freqResponse) {
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:678',message:'drawFrequencyResponseCanvas early return',data:{canvasExists:!!canvas,freqResponseExists:!!freqResponse,canvasId:canvas?canvas.id:'none'},timestamp:Date.now(),sessionId:'wizard-step3-debug',runId:'step3-1',hypothesisId:'H24'})}).catch(()=>{});
        // #endregion
        console.warn('drawFrequencyResponseCanvas: Canvas or frequency response not found', {canvas: !!canvas, freqResponse: !!freqResponse});
        return;
    }
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const padding = 40;
    const graphWidth = width - (padding * 2);
    const graphHeight = height - (padding * 2);
    
    // Clear canvas
    ctx.clearRect(0, 0, width, height);
    
    // Draw background
    ctx.fillStyle = '#f5f5f5';
    ctx.fillRect(0, 0, width, height);
    
    // Find min/max for scaling (including ambient noise if available)
    let minDb = -50;
    let maxDb = 0;
    const allMagnitudes = [...(freqResponse.magnitude || [])];
    if (freqResponse.ambient_noise && freqResponse.ambient_noise.length > 0) {
        allMagnitudes.push(...freqResponse.ambient_noise);
    }
    if (allMagnitudes.length > 0) {
        minDb = Math.min(...allMagnitudes);
        maxDb = Math.max(...allMagnitudes);
        minDb = Math.floor(minDb / 5) * 5 - 5; // Round down
        maxDb = Math.ceil(maxDb / 5) * 5 + 5; // Round up
    }
    const dbRange = maxDb - minDb;
    
    // Draw grid
    ctx.strokeStyle = '#ddd';
    ctx.lineWidth = 1;
    
    // Horizontal lines (dB)
    for (let i = 0; i <= 10; i++) {
        const y = padding + (graphHeight / 10) * i;
        ctx.beginPath();
        ctx.moveTo(padding, y);
        ctx.lineTo(width - padding, y);
        ctx.stroke();
        
        // dB labels
        const db = maxDb - (dbRange / 10) * i;
        ctx.fillStyle = '#666';
        ctx.font = '10px Arial';
        ctx.fillText(db.toFixed(0) + ' dB', 5, y + 4);
    }
    
    // Vertical lines (frequency, logarithmic)
    const freqLabels = [20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000];
    for (let i = 0; i < freqLabels.length; i++) {
        const freq = freqLabels[i];
        const x = padding + (Math.log10(freq / 20) / Math.log10(20000 / 20)) * graphWidth;
        ctx.beginPath();
        ctx.moveTo(x, padding);
        ctx.lineTo(x, height - padding);
        ctx.stroke();
        
        // Frequency labels
        ctx.fillStyle = '#666';
        ctx.font = '10px Arial';
        const label = freq >= 1000 ? (freq / 1000) + 'k' : freq + '';
        ctx.fillText(label, x - 10, height - 10);
    }
    
    // Draw ambient noise curve (if available, as reference)
    if (freqResponse.ambient_noise && freqResponse.frequencies && freqResponse.ambient_noise.length === freqResponse.frequencies.length) {
        ctx.strokeStyle = '#ff9800';
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 5]);
        ctx.beginPath();
        
        for (let i = 0; i < freqResponse.frequencies.length; i++) {
            const freq = freqResponse.frequencies[i];
            const db = freqResponse.ambient_noise[i];
            
            const x = padding + (Math.log10(freq / 20) / Math.log10(20000 / 20)) * graphWidth;
            const y = padding + ((maxDb - db) / dbRange) * graphHeight;
            
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        
        ctx.stroke();
        ctx.setLineDash([]);
    }
    
    // Draw frequency response curve (corrected, with noise subtracted)
    if (freqResponse.frequencies && freqResponse.magnitude) {
        ctx.strokeStyle = '#007bff';
        ctx.lineWidth = 2;
        ctx.beginPath();
        
        for (let i = 0; i < freqResponse.frequencies.length; i++) {
            const freq = freqResponse.frequencies[i];
            const db = freqResponse.magnitude[i];
            
            // Logarithmic x-axis
            const x = padding + (Math.log10(freq / 20) / Math.log10(20000 / 20)) * graphWidth;
            // Linear y-axis (dB)
            const y = padding + ((maxDb - db) / dbRange) * graphHeight;
            
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        
        ctx.stroke();
    }
    
    // Draw 0 dB reference line
    ctx.strokeStyle = '#999';
    ctx.lineWidth = 1;
    ctx.setLineDash([5, 5]);
    const zeroY = padding + ((maxDb - 0) / dbRange) * graphHeight;
    ctx.beginPath();
    ctx.moveTo(padding, zeroY);
    ctx.lineTo(width - padding, zeroY);
    ctx.stroke();
    ctx.setLineDash([]);
    
    // Legend (if ambient noise is shown)
    if (freqResponse.ambient_noise) {
        ctx.fillStyle = '#333';
        ctx.font = '11px Arial';
        ctx.setLineDash([]);
        
        // Ambient noise
        ctx.strokeStyle = '#ff9800';
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 5]);
        ctx.beginPath();
        ctx.moveTo(width - 180, 25);
        ctx.lineTo(width - 150, 25);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillText('Ambient Noise', width - 145, 30);
        
        // Corrected response
        ctx.strokeStyle = '#007bff';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(width - 180, 45);
        ctx.lineTo(width - 150, 45);
        ctx.stroke();
        ctx.fillText('Corrected Response', width - 145, 50);
    }
}

/**
 * Apply correction based on measured frequency response
 */
function applyCorrection() {
    console.log('applyCorrection called');
    
    if (!currentFrequencyResponse) {
        alert('No measurement data available. Please wait for measurement to stabilize.');
        return;
    }
    
    // Update status
    if ($('#measurement-status-text').length) {
        $('#measurement-status-text').text('Processing frequency response...');
    }
    
    console.log('Sending frequency response to backend...', currentFrequencyResponse);
    
    // Send frequency response to backend for processing
    $.post('/command/room-correction-wizard.php', {
        cmd: 'process_frequency_response',
        frequency_response: JSON.stringify(currentFrequencyResponse),
        target_curve: 'flat'
    }, function(data) {
        console.log('process_frequency_response response:', data);
        if (data.status === 'ok') {
            // Generate PEQ filter
            const presetName = 'room_correction_peq_' + new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
            console.log('Generating PEQ filter with preset name:', presetName);
            
            $.post('/command/room-correction-wizard.php', {
                cmd: 'generate_peq',
                preset_name: presetName,
                num_bands: 12
            }, function(peqData) {
                console.log('generate_peq response:', peqData);
                if (peqData.status === 'ok') {
                    // Apply PEQ filter
                    $.post('/command/room-correction-wizard.php', {
                        cmd: 'apply_peq',
                        preset_name: presetName
                    }, function(applyData) {
                        console.log('apply_peq response:', applyData);
                        if (applyData.status === 'ok') {
                            // Keep pink noise running for continuous feedback loop
                            // Measurement continues running to show corrected response in real-time
                            
                            if ($('#measurement-status-text').length) {
                                $('#measurement-status-text').text('✅ Filter applied! Measurement continues - you can see the corrected response in real-time. Pink noise continues playing.');
                            }
                            
                            // Show success message but don't stop anything
                            console.log('Room correction filter applied successfully. Pink noise and measurement continue running for live feedback.');
                            
                            // Optional: show a non-blocking notification
                            // (removed alert to avoid interrupting the continuous workflow)
                        } else {
                            alert('Error applying filter: ' + (applyData.message || 'Unknown error'));
                            if ($('#measurement-status-text').length) {
                                $('#measurement-status-text').html('❌ Error applying filter');
                            }
                        }
                    }).fail(function(xhr, status, error) {
                        console.error('Error applying PEQ:', error);
                        alert('Error applying filter: ' + error);
                    });
                } else {
                    alert('Error generating PEQ filter: ' + (peqData.message || 'Unknown error'));
                    if ($('#measurement-status-text').length) {
                        $('#measurement-status-text').html('❌ Error generating filter');
                    }
                }
            }).fail(function(xhr, status, error) {
                console.error('Error generating PEQ:', error);
                alert('Error generating filter: ' + error);
            });
        } else {
            alert('Error processing frequency response: ' + (data.message || 'Unknown error'));
            if ($('#measurement-status-text').length) {
                $('#measurement-status-text').html('❌ Error processing frequency response');
            }
        }
    }).fail(function(xhr, status, error) {
        console.error('Error processing frequency response:', error);
        alert('Error processing frequency response: ' + error);
        if ($('#measurement-status-text').length) {
            $('#measurement-status-text').html('❌ Error: ' + error);
        }
    });
}

/**
 * Stop any ongoing measurement
 */
function stopMeasurement() {
    isMeasuring = false;
    isMeasuringNoise = false;
    
    if (measurementInterval) {
        clearInterval(measurementInterval);
        measurementInterval = null;
    }
    
    if (noiseMeasurementInterval) {
        clearInterval(noiseMeasurementInterval);
        noiseMeasurementInterval = null;
    }
    
    if (microphone && microphone.mediaStream) {
        microphone.mediaStream.getTracks().forEach(track => track.stop());
    }
    
    if (audioContext && audioContext.state !== 'closed') {
        audioContext.close();
    }
}

// Step 4: Upload and browser measurement functions
let mediaRecorder = null;
let audioChunks = [];

function uploadMeasurement() {
    const fileInput = document.getElementById('measurement-file');
    if (!fileInput || !fileInput.files.length) {
        alert('Bitte wähle eine Messung aus');
        return;
    }
    
    const formData = new FormData();
    formData.append('measurement', fileInput.files[0]);
    formData.append('cmd', 'upload_measurement');
    
    // Use fetch instead of jQuery for test environment
    fetch('/command/room-correction-wizard.php', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'ok') {
            analyzeMeasurement();
        } else {
            alert('Error: ' + (data.message || 'Upload failed'));
        }
    })
    .catch(error => {
        alert('Upload error: ' + error.message);
    });
}

function startBrowserMeasurement() {
    // Use Web Audio API for browser-based measurement
    navigator.mediaDevices.getUserMedia({ audio: true })
        .then(stream => {
            const statusEl = document.getElementById('browser-recording-status');
            if (statusEl) {
                statusEl.style.display = 'block';
            }
            
            mediaRecorder = new MediaRecorder(stream);
            audioChunks = [];
            
            mediaRecorder.ondataavailable = function(event) {
                audioChunks.push(event.data);
            };
            
            mediaRecorder.onstop = function() {
                const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
                const formData = new FormData();
                formData.append('measurement', audioBlob, 'browser-measurement.wav');
                formData.append('cmd', 'upload_measurement');
                
                fetch('/command/room-correction-wizard.php', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'ok') {
                        analyzeMeasurement();
                    } else {
                        alert('Error: ' + (data.message || 'Upload failed'));
                    }
                })
                .catch(error => {
                    alert('Upload error: ' + error.message);
                });
                
                stream.getTracks().forEach(track => track.stop());
            };
            
            mediaRecorder.start();
        })
        .catch(err => {
            alert('Mikrofon-Zugriff verweigert: ' + err.message);
        });
}

function stopBrowserMeasurement() {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
        mediaRecorder.stop();
        const statusEl = document.getElementById('browser-recording-status');
        if (statusEl) {
            statusEl.style.display = 'none';
        }
    }
}

function analyzeMeasurement() {
    fetch('/command/room-correction-wizard.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'cmd=analyze_measurement'
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'ok') {
            frequencyResponse = data.frequency_response;
            showWizardStep(5);
            // Wait a moment for Step 5 to be visible, then draw the frequency response
            setTimeout(() => {
                if (typeof drawFrequencyResponse === 'function') {
                    drawFrequencyResponse();
                } else {
                    drawFrequencyResponseCanvas(frequencyResponse);
                }
            }, 100);
        } else {
            alert('Error: ' + (data.message || 'Analysis failed'));
        }
    })
    .catch(error => {
        alert('Analysis error: ' + error.message);
    });
}

/**
 * Use measurement data from Step 3 (skip file upload)
 */
function useStep3Measurement() {
    if (!currentFrequencyResponse) {
        alert('No measurement data from Step 3. Please go back to Step 3 and complete the measurement first.');
        return;
    }
    
    // Use the data from Step 3 directly - convert to format expected by analyzeMeasurement
    frequencyResponse = currentFrequencyResponse;
    
    // Proceed directly to Step 5
    showWizardStep(5);
    
    // Wait a moment for Step 5 to be visible, then draw the frequency response
    setTimeout(() => {
        // Draw the frequency response on Step 5's canvas
        if (typeof drawFrequencyResponse === 'function') {
            drawFrequencyResponse();
        } else {
            drawFrequencyResponseCanvas(frequencyResponse);
        }
    }, 100);
}

// Make functions globally available
wizardLog('=== wizard-functions.js: Starting exports ===', 'info');
wizardLog('startRoomCorrectionWizard type: ' + typeof startRoomCorrectionWizard, 'info');
wizardLog('wizardNextStep type: ' + typeof wizardNextStep, 'info');
console.log('=== wizard-functions.js: Starting exports ===');
console.log('startRoomCorrectionWizard type:', typeof startRoomCorrectionWizard);
console.log('wizardNextStep type:', typeof wizardNextStep);
try {
    window.startRoomCorrectionWizard = startRoomCorrectionWizard;
    window.wizardNextStep = wizardNextStep;
    window.finishNoiseMeasurement = finishNoiseMeasurement;
    window.applyCorrection = applyCorrection;
    window.stopMeasurement = stopMeasurement;
    window.uploadMeasurement = uploadMeasurement;
    window.startBrowserMeasurement = startBrowserMeasurement;
    window.stopBrowserMeasurement = stopBrowserMeasurement;
    window.analyzeMeasurement = analyzeMeasurement;
    window.useStep3Measurement = useStep3Measurement;
    wizardLog('=== wizard-functions.js: Exports completed successfully ===', 'success');
    wizardLog('window.wizardNextStep: ' + typeof window.wizardNextStep, 'success');
    wizardLog('window.startRoomCorrectionWizard: ' + typeof window.startRoomCorrectionWizard, 'success');
    console.log('=== wizard-functions.js: Exports completed successfully ===');
    console.log('window.wizardNextStep:', typeof window.wizardNextStep);
    console.log('window.startRoomCorrectionWizard:', typeof window.startRoomCorrectionWizard);
} catch(error) {
    wizardLog('=== wizard-functions.js: ERROR during exports ===', 'error');
    wizardLog('Error: ' + error.message, 'error');
    wizardLog('Error stack: ' + error.stack, 'error');
    console.error('=== wizard-functions.js: ERROR during exports ===', error);
    console.error('Error stack:', error.stack);
}

/**
 * Generate filter from frequency response (Step 5)
 */
function generateFilter() {
    try {
        wizardLog('=== generateFilter() START ===', 'info');
        console.log('=== generateFilter() START ===');
        
        // Test if wizardLog works
        wizardLog('TEST: wizardLog is working!', 'success');
        
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1187',message:'generateFilter called',data:{hasFrequencyResponse:!!frequencyResponse,hasCurrentFrequencyResponse:!!currentFrequencyResponse},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H1'})}).catch(()=>{});
        // #endregion
        
        wizardLog('Step 1: Function called', 'info');
        wizardLog('Step 2: Checking currentFrequencyResponse: ' + !!currentFrequencyResponse + ' (' + typeof currentFrequencyResponse + ')', 'info');
        wizardLog('Step 3: Checking frequencyResponse: ' + !!frequencyResponse + ' (' + typeof frequencyResponse + ')', 'info');
        console.log('Step 1: Function called');
        console.log('Step 2: Checking currentFrequencyResponse:', !!currentFrequencyResponse, typeof currentFrequencyResponse);
        console.log('Step 3: Checking frequencyResponse:', !!frequencyResponse, typeof frequencyResponse);
        
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1198',message:'generateFilter called',data:{hasCurrentFrequencyResponse:!!currentFrequencyResponse,hasFrequencyResponse:!!frequencyResponse},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H1'})}).catch(()=>{});
        // #endregion
        
        // Use currentFrequencyResponse if available, otherwise use frequencyResponse
        const freqResponse = currentFrequencyResponse || frequencyResponse;
        
        wizardLog('Step 4: freqResponse: ' + !!freqResponse + ' (' + typeof freqResponse + ')', 'info');
        console.log('Step 4: freqResponse:', !!freqResponse, typeof freqResponse);
        
        if (!freqResponse) {
            wizardLog('ERROR: No frequency response data available!', 'error');
            console.error('Step 5: No frequency response data available!');
            alert('No frequency response data available. Please complete Step 3 measurement first.');
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1213',message:'No frequency response data',data:{},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H2'})}).catch(()=>{});
            // #endregion
            return;
        }
        
        wizardLog('Step 6: Frequency response data found, proceeding with filter generation', 'success');
        console.log('Step 6: Frequency response data found, proceeding with filter generation');
        
        const targetCurve = $('#target-curve').val() || 'flat';
        wizardLog('Step 7: Generating filter with target curve: ' + targetCurve, 'info');
        wizardLog('Step 8: Sending POST request to /command/room-correction-wizard.php', 'info');
        console.log('Step 7: Generating filter with target curve:', targetCurve);
        console.log('Step 8: Sending POST request to /command/room-correction-wizard.php');
        
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1227',message:'Sending frequency response to backend',data:{targetCurve:targetCurve,hasFreqResponse:!!freqResponse},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H3'})}).catch(()=>{});
        // #endregion
        
        // Send frequency response to backend for processing
        wizardLog('Making POST request to /command/room-correction-wizard.php with cmd=process_frequency_response', 'info');
        wizardLog('Checking if jQuery is available: ' + typeof $, 'info');
        console.log('Making POST request to /command/room-correction-wizard.php with cmd=process_frequency_response');
        console.log('Checking if jQuery is available:', typeof $);
        if (typeof $ === 'undefined') {
            wizardLog('ERROR: jQuery is not loaded!', 'error');
            throw new Error('jQuery is not loaded!');
        }
        $.post('/command/room-correction-wizard.php', {
            cmd: 'process_frequency_response',
            frequency_response: JSON.stringify(freqResponse),
            target_curve: targetCurve
        }, function(data) {
            wizardLog('POST request succeeded! Response status: ' + (data.status || 'unknown'), 'success');
            console.log('POST request succeeded, response:', data);
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1145',message:'process_frequency_response response',data:{status:data.status,hasMessage:!!data.message},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H4'})}).catch(()=>{});
        // #endregion
        
        wizardLog('process_frequency_response response: ' + JSON.stringify(data).substring(0, 100), 'info');
        console.log('process_frequency_response response:', data);
        if (data.status === 'ok') {
            wizardLog('process_frequency_response OK! Generating PEQ filter...', 'success');
            // Generate PEQ filter
            const presetName = 'room_correction_peq_' + new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
            console.log('Generating PEQ filter with preset name:', presetName);
            
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1154',message:'Generating PEQ filter',data:{presetName:presetName},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H5'})}).catch(()=>{});
            // #endregion
            
            $.post('/command/room-correction-wizard.php', {
                cmd: 'generate_peq',
                preset_name: presetName,
                num_bands: 12
            }, function(peqData) {
                // #region agent log
                fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1163',message:'generate_peq response',data:{status:peqData.status,hasMessage:!!peqData.message,presetName:peqData.preset_name},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H6'})}).catch(()=>{});
                // #endregion
                
                wizardLog('generate_peq response: ' + (peqData.status || 'unknown'), 'info');
                console.log('generate_peq response:', peqData);
                if (peqData.status === 'ok') {
                    wizardLog('Filter generated successfully! Applying it now...', 'success');
                    // Filter generated successfully - apply it immediately (continuous feedback loop)
                    console.log('Filter generated, applying it now...');
                    
                    $.post('/command/room-correction-wizard.php', {
                        cmd: 'apply_peq',
                        preset_name: presetName
                    }, function(applyData) {
                        // #region agent log
                        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1175',message:'apply_peq response',data:{status:applyData.status},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H7'})}).catch(()=>{});
                        // #endregion
                        
                        wizardLog('apply_peq response: ' + (applyData.status || 'unknown'), 'info');
                        console.log('apply_peq response:', applyData);
                        if (applyData.status === 'ok') {
                            wizardLog('✅ Filter generated and applied successfully!', 'success');
                            wizardLog('Filter preset: ' + presetName, 'info');
                            // Filter generated and applied successfully - show success message
                            // Note: Pink noise and measurement continue (continuous feedback loop)
                            if ($('#measurement-status-text').length) {
                                $('#measurement-status-text').text('✅ Filter generated and applied! Measurement continues - you can see the corrected response in real-time.');
                            }
                            console.log('Filter generated and applied successfully. Measurement continues.');
                            // #region agent log
                            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1185',message:'Filter generated and applied successfully',data:{presetName:presetName},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H8'})}).catch(()=>{});
                            // #endregion
                            
                            // Automatically move to Step 6 after successful filter application
                            wizardLog('Auto-advancing to Step 6 in 1 second...', 'info');
                            setTimeout(() => {
                                wizardLog('Moving to Step 6 now...', 'success');
                                wizardStep = 6;
                                showWizardStep(6);
                                wizardLog('Step 6 displayed - Filter is active!', 'success');
                            }, 1000);
                        } else {
                            alert('Filter generated but error applying: ' + (applyData.message || 'Unknown error'));
                            // #region agent log
                            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1191',message:'Filter apply failed',data:{message:applyData.message},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H9'})}).catch(()=>{});
                            // #endregion
                        }
                    }).fail(function(xhr, status, error) {
                        console.error('Error applying PEQ:', error);
                        alert('Filter generated but error applying: ' + error);
                        // #region agent log
                        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1198',message:'PEQ apply request failed',data:{status:status,error:error},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H10'})}).catch(()=>{});
                        // #endregion
                    });
                } else {
                    alert('Error generating filter: ' + (peqData.message || 'Unknown error'));
                    // #region agent log
                    fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1204',message:'Filter generation failed',data:{message:peqData.message},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H11'})}).catch(()=>{});
                    // #endregion
                }
            }).fail(function(xhr, status, error) {
                console.error('Error generating PEQ:', error);
                alert('Error generating filter: ' + error);
                // #region agent log
                fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1210',message:'PEQ generation request failed',data:{status:status,error:error},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H12'})}).catch(()=>{});
                // #endregion
            });
        } else {
            alert('Error processing frequency response: ' + (data.message || 'Unknown error'));
            // #region agent log
            fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1216',message:'Frequency response processing failed',data:{message:data.message},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H13'})}).catch(()=>{});
            // #endregion
        }
    }).fail(function(xhr, status, error) {
        console.error('=== POST REQUEST FAILED ===');
        console.error('Status:', status);
        console.error('Error:', error);
        console.error('Response:', xhr.responseText);
        console.error('Status code:', xhr.status);
        alert('Error processing frequency response: ' + error + ' (Status: ' + status + ', Code: ' + xhr.status + ')');
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/f148d85a-f4bd-47fd-87b7-78303d3bf40a',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'wizard-functions.js:1303',message:'Frequency response request failed',data:{status:status,error:error,xhrStatus:xhr.status,responseText:xhr.responseText},timestamp:Date.now(),sessionId:'wizard-debug',runId:'generate-filter',hypothesisId:'H14'})}).catch(()=>{});
        // #endregion
    });
    } catch(error) {
        console.error('=== ERROR IN generateFilter() ===');
        console.error('Error:', error);
        console.error('Stack:', error.stack);
        alert('Error in generateFilter: ' + error.message);
        throw error;
    }
}

// Export generateFilter for onclick handlers (after function definition)
wizardLog('=== wizard-functions.js: Exporting generateFilter ===', 'info');
wizardLog('generateFilter type: ' + typeof generateFilter, 'info');
console.log('=== wizard-functions.js: Exporting generateFilter ===');
console.log('generateFilter type:', typeof generateFilter);
try {
    window.generateFilter = generateFilter;
    wizardLog('=== generateFilter exported successfully ===', 'success');
    wizardLog('window.generateFilter: ' + typeof window.generateFilter, 'success');
    console.log('=== generateFilter exported successfully ===');
    console.log('window.generateFilter:', typeof window.generateFilter);
} catch(error) {
    wizardLog('=== ERROR exporting generateFilter ===', 'error');
    wizardLog('Error: ' + error.message, 'error');
    console.error('=== ERROR exporting generateFilter ===', error);
}

wizardLog('=== wizard-functions.js: Script file FINISHED loading ===', 'success');
console.log('=== wizard-functions.js: Script file FINISHED loading ===');

#!/usr/bin/env python3
"""
generate-fir-filter.py
Generates FIR filter from frequency response for room correction
"""
import sys
import json
import numpy as np
from scipy import signal
import soundfile as sf

def generate_fir_filter(freq_response, target_curve='flat', sample_rate=48000, filter_length=4096):
    """Generate FIR filter from frequency response"""
    try:
        freq_data = json.loads(freq_response) if isinstance(freq_response, str) else freq_response
        
        # Get frequency response
        measured_response = freq_data.get('frequency_response', {})
        if not measured_response:
            return {'error': 'No frequency response data'}
        
        # Define target curve
        if target_curve == 'flat':
            target_db = {freq: 0.0 for freq in measured_response.keys()}
        elif target_curve == 'house_curve':
            # Harman Target Curve (slight roll-off in highs)
            target_db = {}
            for freq_str in measured_response.keys():
                freq = float(freq_str)
                if freq < 1000:
                    target_db[freq_str] = 0.0
                elif freq < 10000:
                    target_db[freq_str] = -1.0 * (np.log10(freq / 1000) / np.log10(10))
                else:
                    target_db[freq_str] = -1.0
        else:
            target_db = {freq: 0.0 for freq in measured_response.keys()}
        
        # Calculate compensation (inverse of measured response)
        compensation = {}
        for freq_str in measured_response.keys():
            measured_db = measured_response.get(freq_str, 0.0)
            target_db_val = target_db.get(freq_str, 0.0)
            compensation[freq_str] = target_db_val - measured_db
        
        # Convert to frequency domain
        freqs = np.array([float(f) for f in compensation.keys()])
        gains_db = np.array([compensation[f] for f in compensation.keys()])
        gains_linear = 10 ** (gains_db / 20)
        
        # Create full frequency array
        full_freqs = np.fft.rfftfreq(filter_length, 1/sample_rate)
        full_gains = np.interp(full_freqs, freqs, gains_linear, left=gains_linear[0], right=gains_linear[-1])
        
        # Generate FIR filter using frequency sampling method
        # Create complex frequency response (magnitude only, phase = 0)
        freq_response_complex = full_gains
        
        # IFFT to get impulse response
        impulse_response = np.fft.irfft(freq_response_complex, filter_length)
        
        # Apply window to reduce artifacts
        window = signal.windows.hann(filter_length)
        impulse_response = impulse_response * window
        
        # Normalize
        impulse_response = impulse_response / np.max(np.abs(impulse_response))
        
        return impulse_response
    
    except Exception as e:
        return {'error': str(e)}

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(json.dumps({'error': 'Usage: generate-fir-filter.py <freq_response_json> <target_curve> <output_file>'}))
        sys.exit(1)
    
    freq_response = sys.argv[1]
    target_curve = sys.argv[2]
    output_file = sys.argv[3]
    
    impulse_response = generate_fir_filter(freq_response, target_curve)
    
    if isinstance(impulse_response, dict) and 'error' in impulse_response:
        print(json.dumps(impulse_response))
        sys.exit(1)
    
    # Save as WAV file
    try:
        sf.write(output_file, impulse_response, 48000, subtype='PCM_24')
        print(json.dumps({'status': 'ok', 'file': output_file, 'length': len(impulse_response)}))
    except Exception as e:
        print(json.dumps({'error': str(e)}))


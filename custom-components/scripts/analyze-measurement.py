#!/usr/bin/env python3
"""
analyze-measurement.py
Analyzes measurement file and extracts frequency response
"""
import sys
import json
import numpy as np
from scipy import signal
import soundfile as sf

def analyze_measurement(filename):
    """Analyze measurement file and return frequency response"""
    try:
        # Load audio file
        data, sample_rate = sf.read(filename)
        
        # Convert to mono if stereo
        if len(data.shape) > 1:
            data = np.mean(data, axis=1)
        
        # Perform FFT
        fft = np.fft.rfft(data)
        freqs = np.fft.rfftfreq(len(data), 1/sample_rate)
        magnitude = np.abs(fft)
        
        # Convert to dB
        magnitude_db = 20 * np.log10(magnitude + 1e-10)
        
        # Normalize
        magnitude_db = magnitude_db - np.max(magnitude_db)
        
        # Create frequency response dict
        # Sample key frequencies
        key_freqs = [20, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500,
                    630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300,
                    8000, 10000, 12500, 16000, 20000]
        
        freq_response = {}
        for freq in key_freqs:
            if freq <= freqs[-1]:
                idx = np.argmin(np.abs(freqs - freq))
                freq_response[str(int(freq))] = float(magnitude_db[idx])
        
        return {
            'sample_rate': int(sample_rate),
            'duration': len(data) / sample_rate,
            'frequency_response': freq_response
        }
    except Exception as e:
        return {'error': str(e)}

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No filename provided'}))
        sys.exit(1)
    
    filename = sys.argv[1]
    result = analyze_measurement(filename)
    print(json.dumps(result))


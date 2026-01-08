#!/usr/bin/env python3
"""
Audio Visualizer Service für HiFiBerryOS
- Liest Audio-Daten von ALSA (pyalsaaudio)
- Führt FFT-Analyse durch
- Sendet Daten über WebSocket an Browser (geventwebsocket)
- Serviert HTML-Interface über HTTP
"""

import json
import numpy as np
import threading
import http.server
import socketserver
import alsaaudio
import struct
from gevent import pywsgi
from geventwebsocket.handler import WebSocketHandler
from geventwebsocket import WebSocketError

# Audio-Konfiguration
SAMPLE_RATE = 44100
CHUNK_SIZE = 2048
FFT_SIZE = 4096
NUM_BANDS = 64
WEBSOCKET_PORT = 8080
HTTP_PORT = 8081

# HTML-Interface
HTML_CONTENT = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Audio Visualizer</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            background: #000;
            overflow: hidden;
            width: 1280px;
            height: 400px;
            font-family: Arial, sans-serif;
        }
        canvas {
            width: 1280px;
            height: 400px;
            display: block;
        }
        #status {
            position: absolute;
            top: 10px;
            left: 10px;
            color: #fff;
            font-size: 12px;
            z-index: 100;
        }
    </style>
</head>
<body>
    <div id="status">Connecting...</div>
    <canvas id="visualizer" width="1280" height="400"></canvas>
    
    <script>
        const canvas = document.getElementById('visualizer');
        const ctx = canvas.getContext('2d');
        const status = document.getElementById('status');
        const ws = new WebSocket('ws://localhost:8081/ws');
        
        let bands = new Array(64).fill(0);
        let smoothBands = new Array(64).fill(0);
        const smoothingFactor = 0.7;
        
        ws.onopen = function() {
            status.textContent = 'Connected';
            status.style.color = '#0f0';
        };
        
        ws.onmessage = function(event) {
            try {
                const data = JSON.parse(event.data);
                bands = data.bands;
            } catch (e) {
                console.error('Parse error:', e);
            }
        };
        
        ws.onerror = function(error) {
            status.textContent = 'Connection error';
            status.style.color = '#f00';
        };
        
        ws.onclose = function() {
            status.textContent = 'Disconnected - Reconnecting...';
            status.style.color = '#ff0';
            setTimeout(function() {
                location.reload();
            }, 2000);
        };
        
        function draw() {
            // Smoothing
            for (let i = 0; i < 64; i++) {
                smoothBands[i] = smoothBands[i] * smoothingFactor + bands[i] * (1 - smoothingFactor);
            }
            
            // Canvas löschen
            ctx.fillStyle = '#000';
            ctx.fillRect(0, 0, 1280, 400);
            
            // Bars zeichnen (PeppyMeter-Style)
            const barWidth = 1280 / 64;
            const maxHeight = 380;
            const barSpacing = 1;
            
            for (let i = 0; i < 64; i++) {
                const height = (smoothBands[i] / 100) * maxHeight;
                const x = i * barWidth;
                const actualWidth = barWidth - barSpacing;
                
                // Gradient (Gold-Style wie PeppyMeter)
                const gradient = ctx.createLinearGradient(x, 400 - height, x, 400);
                gradient.addColorStop(0, '#FFD700');  // Gold
                gradient.addColorStop(0.3, '#FFA500'); // Orange
                gradient.addColorStop(0.6, '#FF6347'); // Tomato
                gradient.addColorStop(1, '#FF0000');   // Red
                
                ctx.fillStyle = gradient;
                ctx.fillRect(x, 400 - height, actualWidth, height);
                
                // Glow-Effekt (optional)
                ctx.shadowBlur = 10;
                ctx.shadowColor = '#FFD700';
                ctx.fillRect(x, 400 - height, actualWidth, height);
                ctx.shadowBlur = 0;
            }
        }
        
        // Animation-Loop
        function animate() {
            requestAnimationFrame(animate);
            draw();
        }
        animate();
    </script>
</body>
</html>
"""

# HTTP Handler wird jetzt in wsgi_app integriert

def audio_analyzer(environ, start_response):
    """WebSocket Handler für Audio-Analyse"""
    ws = environ.get('wsgi.websocket')
    if not ws:
        start_response('400 Bad Request', [])
        return []
    
    try:
        # ALSA Audio-Stream öffnen
        inp = alsaaudio.PCM(alsaaudio.PCM_CAPTURE, alsaaudio.PCM_NORMAL, 'hw:0,0')
        inp.setchannels(2)
        inp.setrate(SAMPLE_RATE)
        inp.setformat(alsaaudio.PCM_FORMAT_S16_LE)
        inp.setperiodsize(CHUNK_SIZE)
        
        print("Audio stream opened, starting analysis...")
        
        while True:
            # Audio-Daten lesen
            length, data = inp.read()
            
            if length < 0:
                print("Audio read error")
                break
            
            # Konvertiere Bytes zu numpy array (int16)
            audio_data = np.frombuffer(data, dtype=np.int16)
            
            # Konvertiere zu float32 (-1.0 bis 1.0)
            audio_float = audio_data.astype(np.float32) / 32768.0
            
            # Reshape für Stereo
            if len(audio_float) >= CHUNK_SIZE * 2:
                audio_stereo = audio_float.reshape(-1, 2)
                
                # FFT-Analyse (nur linker Kanal)
                fft = np.fft.rfft(audio_stereo[:CHUNK_SIZE, 0], n=FFT_SIZE)
                magnitude = np.abs(fft)
                frequency = np.fft.rfftfreq(FFT_SIZE, 1/SAMPLE_RATE)
                
                # Frequenz-Bänder (64 Bands wie PeppyMeter)
                bands = []
                for i in range(NUM_BANDS):
                    # Logarithmische Frequenz-Verteilung
                    start_freq = 20 * (20000 / 20) ** (i / NUM_BANDS)
                    end_freq = 20 * (20000 / 20) ** ((i + 1) / NUM_BANDS)
                    
                    # Finde Indizes für diese Frequenzen
                    start_idx = np.argmax(frequency >= start_freq)
                    end_idx = np.argmax(frequency >= end_freq)
                    
                    if start_idx < len(magnitude) and end_idx <= len(magnitude):
                        band_magnitude = np.max(magnitude[start_idx:end_idx])
                        bands.append(float(band_magnitude))
                    else:
                        bands.append(0.0)
                
                # Normalisieren (0-100)
                max_val = max(bands) if max(bands) > 0 else 1
                bands = [int((b / max_val) * 100) for b in bands]
                
                # JSON senden
                try:
                    ws.send(json.dumps({
                        'bands': bands,
                        'timestamp': threading.get_ident()
                    }))
                except WebSocketError:
                    break
                
    except Exception as e:
        print(f"Audio processing error: {e}")
        import traceback
        traceback.print_exc()
    
    return []

def wsgi_app(environ, start_response):
    """WSGI App für WebSocket und HTTP"""
    path = environ.get('PATH_INFO', '')
    
    # WebSocket Handler
    if path == '/ws':
        return audio_analyzer(environ, start_response)
    
    # HTTP Handler für HTML
    elif path == '/' or path == '/visualizer.html':
        start_response('200 OK', [('Content-type', 'text/html')])
        return [HTML_CONTENT.encode()]
    else:
        start_response('404 Not Found', [])
        return [b'Not Found']

def main():
    """Hauptfunktion"""
    print("Starting Audio Visualizer Service...")
    print(f"HTTP Server: http://localhost:{HTTP_PORT}/visualizer.html")
    print(f"WebSocket Server: ws://localhost:{HTTP_PORT}/ws")
    
    # Gevent WebSocket Server
    server = pywsgi.WSGIServer(
        ('', HTTP_PORT),
        wsgi_app,
        handler_class=WebSocketHandler
    )
    
    server.serve_forever()

if __name__ == "__main__":
    main()


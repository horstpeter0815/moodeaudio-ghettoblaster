#!/bin/bash
# MINIMAL SETUP - Nur Moode Audio + SSH
# Keine Custom-Services die blockieren können

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎯 MINIMAL SETUP - NUR MOODE AUDIO + SSH                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "ZIEL:"
echo "  1. Moode Audio startet"
echo "  2. SSH-Zugriff funktioniert"
echo ""
echo "ALLES ANDERE: NICHT WICHTIG"
echo ""

echo "📋 Optionen:"
echo ""
echo "Option A: Original Moode Image + nur SSH"
echo "  1. Download Moode 10.0.2 Original"
echo "  2. Image auf SD-Karte schreiben"
echo "  3. SSH aktivieren: touch /boot/firmware/ssh"
echo "  4. Fertig"
echo ""
echo "Option B: Minimales Custom Build"
echo "  1. Custom Build OHNE blockierende Services"
echo "  2. Nur SSH + User erstellen"
echo "  3. KEINE network-guaranteed.service"
echo "  4. KEINE fix-user-id.service"
echo "  5. KEINE anderen Custom-Services"
echo ""

echo "Welche Option möchtest du?"
echo "  A) Original Moode + nur SSH (EMPFOHLEN - schnellste Lösung)"
echo "  B) Minimales Custom Build"
echo ""


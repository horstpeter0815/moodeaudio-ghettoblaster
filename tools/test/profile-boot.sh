#!/bin/bash
# Profile boot performance using systemd-analyze
# This script runs in Docker container with systemd

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESULTS_DIR="${WORKSPACE_ROOT}/test-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Boot Performance Profiling"
echo "=========================================="
echo ""

# Check if systemd-analyze is available
if ! command -v systemd-analyze &> /dev/null; then
    echo -e "${RED}✗${NC} systemd-analyze not available!"
    echo "   This script must run in a container with systemd"
    exit 1
fi

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Wait for systemd to be ready
echo -e "${YELLOW}[INFO]${NC} Waiting for systemd to be ready..."
sleep 2

# Test 1: Basic boot time
echo -e "${BLUE}[PROFILE 1]${NC} Measuring boot time..."
if systemd-analyze time > "${RESULTS_DIR}/boot-time.txt" 2>&1; then
    echo -e "${GREEN}✓${NC} Boot time analysis complete"
    cat "${RESULTS_DIR}/boot-time.txt"
else
    echo -e "${RED}✗${NC} Failed to analyze boot time"
    cat "${RESULTS_DIR}/boot-time.txt" || true
fi
echo ""

# Test 2: Critical chain (slowest services)
echo -e "${BLUE}[PROFILE 2]${NC} Analyzing critical boot chain..."
if systemd-analyze critical-chain > "${RESULTS_DIR}/critical-chain.txt" 2>&1; then
    echo -e "${GREEN}✓${NC} Critical chain analysis complete"
    cat "${RESULTS_DIR}/critical-chain.txt"
else
    echo -e "${YELLOW}⚠${NC} Critical chain analysis may have issues"
    cat "${RESULTS_DIR}/critical-chain.txt" || true
fi
echo ""

# Test 3: Blame (services taking longest)
echo -e "${BLUE}[PROFILE 3]${NC} Analyzing service blame (slowest services)..."
if systemd-analyze blame > "${RESULTS_DIR}/blame.txt" 2>&1; then
    echo -e "${GREEN}✓${NC} Service blame analysis complete"
    head -20 "${RESULTS_DIR}/blame.txt"
    echo "... (see ${RESULTS_DIR}/blame.txt for full list)"
else
    echo -e "${YELLOW}⚠${NC} Service blame analysis may have issues"
    cat "${RESULTS_DIR}/blame.txt" || true
fi
echo ""

# Test 4: Verify (check for circular dependencies)
echo -e "${BLUE}[PROFILE 4]${NC} Verifying systemd units (checking for errors)..."
if systemd-analyze verify > "${RESULTS_DIR}/verify.txt" 2>&1; then
    if [ -s "${RESULTS_DIR}/verify.txt" ]; then
        echo -e "${YELLOW}⚠${NC} Found some verification issues:"
        cat "${RESULTS_DIR}/verify.txt"
    else
        echo -e "${GREEN}✓${NC} No verification errors found"
    fi
else
    echo -e "${YELLOW}⚠${NC} Verification check completed with warnings"
    cat "${RESULTS_DIR}/verify.txt" || true
fi
echo ""

# Test 5: Dependency graph (if dot is available)
if command -v dot &> /dev/null; then
    echo -e "${BLUE}[PROFILE 5]${NC} Generating dependency graph..."
    if systemd-analyze dot | dot -Tsvg > "${RESULTS_DIR}/dependency-graph.svg" 2>&1; then
        echo -e "${GREEN}✓${NC} Dependency graph generated: ${RESULTS_DIR}/dependency-graph.svg"
    else
        echo -e "${YELLOW}⚠${NC} Could not generate dependency graph (graphviz may not be installed)"
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} Dependency graph skipped (graphviz not installed)"
fi
echo ""

# Test 6: Check for circular dependencies
echo -e "${BLUE}[PROFILE 6]${NC} Checking for circular dependencies..."
CIRCULAR_FOUND=0

# Check verify output for circular dependency errors
if grep -qi "circular\|cycle\|ordering cycle" "${RESULTS_DIR}/verify.txt" 2>/dev/null; then
    echo -e "${RED}✗${NC} CIRCULAR DEPENDENCY DETECTED!"
    grep -i "circular\|cycle\|ordering cycle" "${RESULTS_DIR}/verify.txt"
    CIRCULAR_FOUND=1
else
    echo -e "${GREEN}✓${NC} No circular dependencies detected"
fi
echo ""

# Summary
echo "=========================================="
echo "Boot Profiling Summary"
echo "=========================================="
echo ""
echo "Results saved to: ${RESULTS_DIR}/"
echo "  - boot-time.txt: Boot time analysis"
echo "  - critical-chain.txt: Critical boot chain"
echo "  - blame.txt: Slowest services"
echo "  - verify.txt: Systemd unit verification"
if [ -f "${RESULTS_DIR}/dependency-graph.svg" ]; then
    echo "  - dependency-graph.svg: Dependency graph"
fi
echo ""

if [ ${CIRCULAR_FOUND} -eq 1 ]; then
    echo -e "${RED}✗${NC} CIRCULAR DEPENDENCY FOUND - FIX REQUIRED!"
    exit 1
else
    echo -e "${GREEN}✓${NC} Boot profiling complete - no circular dependencies"
    exit 0
fi

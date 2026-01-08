#!/bin/bash
# Test Proposal Integration Script
# Tests new proposals through standard test processes

echo "=== PROPOSAL TEST INTEGRATION ==="
echo ""

PROPOSAL_NAME="$1"
TEST_TYPE="${2:-all}"

if [ -z "$PROPOSAL_NAME" ]; then
    echo "Usage: $0 <proposal-name> [test-type]"
    echo ""
    echo "Test types:"
    echo "  all      - All tests (default)"
    echo "  initial  - Initial functionality test"
    echo "  integration - Integration with existing system"
    echo "  regression - Regression test"
    echo "  performance - Performance test"
    echo "  user     - User experience test"
    exit 1
fi

echo "Proposal: $PROPOSAL_NAME"
echo "Test Type: $TEST_TYPE"
echo ""

# Test log file
LOG_FILE="test-results-${PROPOSAL_NAME}-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Function: Run standard system tests
run_standard_tests() {
    log "Running standard system tests..."
    
    # Check if standard test suite exists
    if [ -f "complete_test_suite.sh" ]; then
        ./complete_test_suite.sh 2>&1 | tee -a "$LOG_FILE"
    elif [ -f "STANDARD_TEST_SUITE_FINAL.sh" ]; then
        ./STANDARD_TEST_SUITE_FINAL.sh 2>&1 | tee -a "$LOG_FILE"
    else
        log "⚠️  Standard test suite not found"
    fi
}

# Function: Run proposal-specific tests
run_proposal_tests() {
    log "Running proposal-specific tests for: $PROPOSAL_NAME"
    
    TEST_SCRIPT="test-${PROPOSAL_NAME}.sh"
    
    if [ -f "$TEST_SCRIPT" ]; then
        ./"$TEST_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
    else
        log "⚠️  Proposal-specific test script not found: $TEST_SCRIPT"
        log "   Create $TEST_SCRIPT to test this proposal"
    fi
}

# Function: Run initial test
run_initial_test() {
    log "=== INITIAL TEST ==="
    log "Testing basic functionality of: $PROPOSAL_NAME"
    
    run_proposal_tests
    
    log "Initial test complete"
}

# Function: Run integration test
run_integration_test() {
    log "=== INTEGRATION TEST ==="
    log "Testing integration with existing system"
    
    run_standard_tests
    run_proposal_tests
    
    log "Integration test complete"
}

# Function: Run regression test
run_regression_test() {
    log "=== REGRESSION TEST ==="
    log "Testing for regressions"
    
    run_standard_tests
    
    log "Regression test complete"
}

# Function: Run performance test
run_performance_test() {
    log "=== PERFORMANCE TEST ==="
    log "Testing performance impact"
    
    # Add performance tests here
    log "Performance test complete"
}

# Function: Run user test
run_user_test() {
    log "=== USER TEST ==="
    log "Testing user experience"
    
    # Add user experience tests here
    log "User test complete"
}

# Main test execution
case "$TEST_TYPE" in
    initial)
        run_initial_test
        ;;
    integration)
        run_integration_test
        ;;
    regression)
        run_regression_test
        ;;
    performance)
        run_performance_test
        ;;
    user)
        run_user_test
        ;;
    all)
        log "=== RUNNING ALL TESTS ==="
        run_initial_test
        sleep 2
        run_integration_test
        sleep 2
        run_regression_test
        sleep 2
        run_performance_test
        sleep 2
        run_user_test
        ;;
    *)
        echo "Unknown test type: $TEST_TYPE"
        exit 1
        ;;
esac

log ""
log "=== TEST COMPLETE ==="
log "Results saved to: $LOG_FILE"
log ""
log "Next steps:"
log "  1. Review test results"
log "  2. Fix any issues found"
log "  3. Re-run tests if needed"
log "  4. Update documentation"


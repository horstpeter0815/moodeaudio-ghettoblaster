# PROPOSAL TEST WORKFLOW

**Date:** 2025-12-04  
**Purpose:** Standard workflow for testing new proposals

---

## 🔄 WORKFLOW OVERVIEW

### **1. Proposal Creation**
When creating a new proposal:
1. Document the proposal
2. Identify test requirements
3. Create test plan
4. Create test script

### **2. Test Development**
For each proposal:
1. Create test script: `test-<proposal-name>.sh`
2. Define test cases
3. Define success criteria
4. Document test procedures

### **3. Test Execution**
Run tests through standard process:
```bash
./test-proposal-integration.sh <proposal-name> [test-type]
```

**Test Types:**
- `initial` - Basic functionality
- `integration` - With existing system
- `regression` - Ensure no breakage
- `performance` - Resource usage
- `user` - User experience
- `all` - All tests (default)

### **4. Test Review**
After testing:
1. Review test results
2. Identify failures
3. Fix issues
4. Re-test

### **5. Integration**
After successful testing:
1. Integrate into main system
2. Add to regular test cycles
3. Update documentation
4. Monitor in production

---

## 📝 TEST SCRIPT TEMPLATE

### **Create: `test-<proposal-name>.sh`**

```bash
#!/bin/bash
# Test script for: [Proposal Name]
# Tests: [What it tests]

echo "=== TEST: [Proposal Name] ==="
echo ""

# Test variables
PASS=0
FAIL=0

# Test function
test_case() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    echo "Testing: $name"
    
    if eval "$command" | grep -q "$expected"; then
        echo "  ✅ PASS"
        ((PASS++))
    else
        echo "  ❌ FAIL"
        ((FAIL++))
    fi
}

# Test cases
test_case "Test 1" "command" "expected"
test_case "Test 2" "command" "expected"
test_case "Test 3" "command" "expected"

# Summary
echo ""
echo "=== TEST SUMMARY ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "✅ All tests passed"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
```

---

## 📋 TEST CHECKLIST

### **Before Testing:**
- [ ] Proposal documented
- [ ] Test plan created
- [ ] Test script created
- [ ] Test environment prepared
- [ ] Success criteria defined

### **During Testing:**
- [ ] Run test script
- [ ] Document results
- [ ] Note issues
- [ ] Take screenshots if needed
- [ ] Check logs

### **After Testing:**
- [ ] Review results
- [ ] Document findings
- [ ] Create issue reports
- [ ] Plan fixes
- [ ] Schedule re-tests

---

## 🎯 EXAMPLE: PeppyMeter Screensaver

### **Test Script: `test-peppymeter-screensaver.sh`**

```bash
#!/bin/bash
# Test script for: PeppyMeter Screensaver

echo "=== TEST: PeppyMeter Screensaver ==="
echo ""

# Test 1: Service exists
if systemctl list-unit-files | grep -q "peppymeter-screensaver"; then
    echo "✅ Service exists"
else
    echo "❌ Service not found"
    exit 1
fi

# Test 2: Service can start
if systemctl start peppymeter-screensaver.service; then
    echo "✅ Service can start"
else
    echo "❌ Service failed to start"
    exit 1
fi

# Test 3: Service is active
if systemctl is-active --quiet peppymeter-screensaver.service; then
    echo "✅ Service is active"
else
    echo "❌ Service is not active"
    exit 1
fi

# Test 4: Configuration file exists
if [ -f "/etc/systemd/system/peppymeter-screensaver.service" ]; then
    echo "✅ Configuration exists"
else
    echo "❌ Configuration not found"
    exit 1
fi

echo ""
echo "✅ All tests passed"
exit 0
```

### **Run Tests:**
```bash
# Initial test
./test-proposal-integration.sh peppymeter-screensaver initial

# Integration test
./test-proposal-integration.sh peppymeter-screensaver integration

# All tests
./test-proposal-integration.sh peppymeter-screensaver all
```

---

## 📊 TEST RESULTS TRACKING

### **Test Log Format:**
```markdown
## Test Results: [Proposal Name]

**Date:** YYYY-MM-DD
**Test Type:** [initial|integration|regression|performance|user|all]

### **Results:**
- Test 1: ✅ PASS
- Test 2: ✅ PASS
- Test 3: ❌ FAIL

### **Issues Found:**
- Issue 1: [Description]
- Issue 2: [Description]

### **Actions Taken:**
- Action 1: [Description]
- Action 2: [Description]

### **Next Steps:**
- Step 1: [Description]
- Step 2: [Description]
```

---

## 🔄 REGULAR TEST CYCLES

### **New Proposals:**
- Day 1: Initial test
- Day 3: Integration test
- Day 7: Regression test
- Day 14: Performance test
- Day 30: User test

### **Existing Proposals:**
- Weekly: Integration test
- Monthly: Full test suite
- After changes: Regression test

---

**Status:** Proposal test workflow established - ready for use


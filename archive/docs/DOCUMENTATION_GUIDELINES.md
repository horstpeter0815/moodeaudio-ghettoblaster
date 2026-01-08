# DOCUMENTATION GUIDELINES

**Date:** 2025-12-04  
**Based on:** ISO 9001, IEEE 1016, Agile Documentation Practices

---

## 📋 FILE NAMING CONVENTIONS

### **FORBIDDEN WORDS:**
- `FINAL` - Nothing is final until verified
- `WORKING` - Implies completion without proof
- `FIXED` - Implies problem solved without verification
- `COMPLETE` - Implies finished without testing
- `DONE` - Implies completion without confirmation
- `READY` - Implies readiness without validation
- `SOLVED` - Implies solution verified without proof
- `RESOLVED` - Implies resolution without confirmation

### **ALLOWED STATUS WORDS:**
- `ATTEMPT` - Indicates an attempt, not completion
- `TESTING` - Indicates testing in progress
- `DRAFT` - Indicates work in progress
- `PROPOSAL` - Indicates a proposal, not implementation
- `PLAN` - Indicates planning, not execution
- `STATUS` - Current status (not completion)
- `IN_PROGRESS` - Work in progress
- `REVIEW` - Under review
- `VERIFIED` - Only after actual verification

### **FILE NAMING FORMAT:**
```
COMPONENT_DESCRIPTION_YYYYMMDD_STATUS.ext
```

**Examples:**
- `TOUCH_FIX_ATTEMPT_20251204.md` ✅
- `TOUCH_FIX_TESTING_20251204.md` ✅
- `TOUCH_FIX_VERIFIED_20251204.md` ✅ (only after verification)
- `TOUCH_FIX_FINAL_20251204.md` ❌ (forbidden)

---

## 📝 DOCUMENTATION STANDARDS

### **1. Status Tracking:**
- Every document must have a clear status
- Status must be updated based on actual testing
- No status can be "complete" without verification

### **2. Version Control:**
- Use dates in YYYYMMDD format
- Use version numbers (v1, v2) for iterations
- Track changes in changelog

### **3. Descriptive Names:**
- Names must clearly indicate content/purpose
- Avoid abbreviations unless widely recognized
- Use consistent naming style (snake_case recommended)

### **4. Date Format:**
- Always use YYYYMMDD format
- Enables chronological sorting
- Example: `20251204`

---

## ✅ VERIFICATION REQUIREMENTS

### **Before marking anything as verified:**
1. ✅ Actually tested
2. ✅ Verified to work
3. ✅ Confirmed by user
4. ✅ Documented with test results
5. ✅ No assumptions, only facts

### **Status Progression:**
```
DRAFT → TESTING → REVIEW → VERIFIED
```

**Never skip steps!**

---

## 🔄 PROJECT MANAGEMENT PRINCIPLES

### **ISO 9001 Principles Applied:**
1. **Process Approach:** Document processes, not just results
2. **Evidence-Based Decision Making:** Base status on facts, not assumptions
3. **Continual Improvement:** Learn from mistakes, improve processes
4. **Customer Focus:** User verification is required

### **Agile Documentation:**
- Document as you go
- Keep documentation up-to-date
- Test before documenting as complete
- Iterate based on feedback

---

## 📚 TRAINING REQUIREMENTS

**Every hour:** 1 hour training on:
- Documentation standards
- Project management best practices
- Quality assurance principles
- Technical writing standards

---

**Status:** Guidelines established - must be followed strictly


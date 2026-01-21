# moOde Ghettoblaster Development Workflow
**Sustainable Knowledge-First Methodology**

---

## Core Principle

**EVERY task MUST increase system understanding.**

**NEVER fix blindly. ALWAYS understand first.**

---

## The Three Laws of Development

### 1. Law of Understanding
**"No fix without reading the code first"**

- Read source code BEFORE modifying
- Understand data flow BEFORE changing
- Know root cause BEFORE applying solution

### 2. Law of Documentation
**"Every learning must be captured"**

- Document architectural insights immediately
- Update MASTER document with new findings
- Create specific deep-dives for complex areas

### 3. Law of Verification
**"Proof before claiming root cause"**

- Test hypotheses before stating facts
- Verify fixes actually work
- Document what was CHANGED, not what you THINK it fixes

---

## Development Workflow (5 Phases)

### Phase 1: UNDERSTAND THE REQUEST

**Questions to answer:**
1. What is the user trying to achieve?
2. What system components are involved?
3. What do I already know about these components?

**Actions:**
- ✅ Check `MASTER_MOODE_ARCHITECTURE.md` for existing knowledge
- ✅ Check `000_INDEX.md` for related documentation
- ✅ Search WISSENSBASIS for related insights
- ✅ Identify knowledge gaps

**Output:** Clear understanding of task scope

**Example:**
```
Task: "Add PeppyMeter toggle button"

Understanding:
- Components: WebUI (HTML/JS), backend (PHP), systemd (service)
- Known: PeppyMeter service structure (peppymeter.service)
- Gaps: How does WebUI communicate with backend for display control?
        How does local_display toggle work? (check source)
```

---

### Phase 2: RESEARCH & READ

**Principle:** Spend tokens on READING, not on TRIAL-AND-ERROR

**Research strategy:**
1. **Read existing implementations first**
   - How does local_display toggle work? Read per-config.php
   - How do other toggles work? Read scripts-panels.js
   - What's the command pattern? Read command/index.php

2. **Understand the architecture**
   - What's the data flow? (WebUI → REST API → worker.php → systemd)
   - What's the database schema? (cfg_system params)
   - What are the dependencies? (mutual exclusions)

3. **Find similar patterns**
   - Search for: `$('#toggle-` in JavaScript
   - Search for: `case 'toggle_` in PHP
   - Understand existing patterns before creating new ones

**Actions:**
- ✅ Use SemanticSearch to find relevant code sections
- ✅ Read complete functions, not just snippets
- ✅ Trace data flow from UI to system level
- ✅ Document findings in temp notes

**Output:** Complete understanding of how to implement

**Token Efficiency:**
- ❌ Trial-and-error: 60,000 tokens, 70 attempts, 0 success
- ✅ Read-first approach: 5,000 tokens, 1 attempt, 100% success

---

### Phase 3: DESIGN THE SOLUTION

**Principle:** Design at the ROOT CAUSE level, not symptoms

**Design checklist:**
1. **Identify root cause**
   - What's the actual problem? (not just the symptom)
   - Why does it behave this way?
   - What needs to change at the architectural level?

2. **Design the fix**
   - What files need modification?
   - What's the minimal change required?
   - Are there side effects?

3. **Check for existing solutions**
   - Is there a working config in GitHub? (check backups/)
   - Has this been solved before? (check git log)
   - Can we restore instead of fix?

**Actions:**
- ✅ Write design notes (what, why, how)
- ✅ List all files to be modified
- ✅ Identify verification steps
- ✅ Check GitHub for existing solutions FIRST

**Output:** Clear implementation plan

**Example:**
```
Problem: PeppyMeter toggle button doesn't work

Root Cause Analysis:
- Frontend: $('#toggle-peppymeter').click() calls command/index.php?cmd=toggle_peppymeter
- Backend: command/index.php has NO CASE for 'toggle_peppymeter'
- Result: Command is ignored, nothing happens

Solution Design:
1. Add case 'toggle_peppymeter' to command/index.php
2. Call submitJob('peppy_display') (like local_display does)
3. worker.php already has case 'peppy_display' (line 1234)
4. No database changes needed (peppy_display already exists)

Files to modify:
- www/command/index.php (add 3 lines)

Verification:
- Click button → check submitJob() called
- Check worker.php logs for peppy_display job
- Verify systemctl status peppymeter
```

---

### Phase 4: IMPLEMENT

**Principle:** Make MINIMAL, TARGETED changes

**Implementation rules:**

1. **One change at a time**
   - Don't mix multiple fixes
   - Don't "clean up" unrelated code
   - Don't optimize while fixing

2. **Preserve working code**
   - Don't remove "redundant" code without understanding why it exists
   - Don't refactor during bug fixes
   - Keep backups of original configs

3. **Follow existing patterns**
   - Use same coding style as surrounding code
   - Use same naming conventions
   - Use same error handling patterns

4. **Document inline**
   - Add comments explaining WHY, not WHAT
   - Reference issue numbers or documentation
   - Explain non-obvious decisions

**Actions:**
- ✅ Make changes in SD card or code
- ✅ Keep change diffs minimal
- ✅ Test each change independently
- ✅ Roll back if it doesn't work

**Output:** Working implementation

---

### Phase 5: VERIFY & DOCUMENT

**Principle:** Proof before claiming success

**Verification checklist:**

1. **Functional testing**
   - Does it work as intended?
   - Are there side effects?
   - Does it work after reboot?

2. **Integration testing**
   - Does it work with other features?
   - Are there conflicts?
   - Does it handle edge cases?

3. **Performance testing**
   - Does it impact boot time?
   - Does it cause resource issues?
   - Are there memory leaks?

**Documentation checklist:**

1. **Update MASTER document**
   - Add new architectural insights
   - Document the fix and WHY it works
   - Update system status

2. **Create specific deep-dive (if needed)**
   - For complex implementations
   - For reusable patterns
   - For future reference

3. **Commit to GitHub**
   - Clear commit message
   - Tag if it's a stable version
   - Store working configs in backups/

**Actions:**
- ✅ Test thoroughly
- ✅ Update documentation
- ✅ Commit changes
- ✅ Tag working versions

**Output:** Verified fix + Updated knowledge base

---

## Knowledge Base Management

### Primary Documents

**1. MASTER_MOODE_ARCHITECTURE.md**
- Single source of truth
- Complete system overview
- All code flows documented
- Updated with every significant learning

**2. 000_INDEX.md**
- Points to primary reference
- Lists supplementary documents
- Keeps knowledge organized

### Supplementary Documents

**Deep-dives for specific areas:**
- Audio system details
- Volume control internals
- Display architecture specifics
- Build process guides

**When to create new documents:**
- Complex subsystem requires detailed explanation
- Reusable patterns discovered
- Troubleshooting guides needed
- Build/deployment procedures

**When NOT to create new documents:**
- Simple one-off fixes
- Status reports (update MASTER instead)
- Temporary analysis (use temp files, delete after)

### Document Lifecycle

**1. Active Development:**
```
Task started → Create temp notes
    ↓
Findings emerge → Update MASTER
    ↓
Complex area found → Create deep-dive doc
    ↓
Task complete → Delete temp notes
```

**2. Maintenance:**
```
New moOde version → Read changelog
    ↓
Code changes → Update MASTER
    ↓
New features → Extend documentation
```

---

## GitHub Integration Strategy

### Check GitHub FIRST

**Before applying ANY fix:**

1. **Search for working configs**
   ```bash
   git log --all --grep="working\|v1.0\|stable\|tested" --oneline
   git tag -l "*working*" "*stable*" "*v1.0*"
   ```

2. **Check backups directory**
   ```bash
   ls -la backups/
   git show HEAD:backups/v1.0-2026-01-08/
   ```

3. **Restore instead of fix**
   ```bash
   git show <commit>:backups/v1.0-2026-01-08/cmdline.txt > /Volumes/rootfs/boot/firmware/cmdline.txt
   ```

### Store Working Configs

**After confirming a working system:**

1. **Create backup snapshot**
   ```bash
   mkdir -p backups/v1.0-$(date +%Y-%m-%d)
   cp /Volumes/rootfs/boot/firmware/cmdline.txt backups/v1.0-$(date +%Y-%m-%d)/
   cp /Volumes/rootfs/boot/firmware/config.txt backups/v1.0-$(date +%Y-%m-%d)/
   cp /Volumes/rootfs/home/andre/.xinitrc backups/v1.0-$(date +%Y-%m-%d)/
   ```

2. **Commit and tag**
   ```bash
   git add backups/
   git commit -m "Working v1.0 configuration - $(date +%Y-%m-%d)"
   git tag -a v1.0-stable-$(date +%Y%m%d) -m "Verified working configuration"
   git push origin main --tags
   ```

3. **Document in commit message**
   - What was fixed
   - How it was verified
   - What system state is now

### GitHub as Source of Truth

**Repository:** https://github.com/horstpeter0815/moodeaudio-ghettoblaster.git

**Use GitHub for:**
- Version control of working configs
- Backup of all critical files
- Tagging stable states
- Tracking what changed and why

**DON'T store only locally - GitHub survives system crashes**

---

## Anti-Patterns to Avoid

### ❌ The "La La La" Pattern
**Symptom:** Fixing without understanding

**Example:**
```
"Let me add xset -dpms to fix the display"
→ X server crashes
→ "Let me remove it and try something else"
→ Still broken
→ Repeat 20 times
```

**Solution:**
```
"Why is the display blanking?"
→ Read xinitrc.default
→ Found: xset -dpms
→ Read X server documentation
→ Pi 5 KMS driver doesn't support DPMS
→ Fix: xset -dpms 2>/dev/null || true
→ Works first time
```

### ❌ The "Root Cause Claim" Pattern
**Symptom:** Claiming root cause without proof

**Example:**
```
"Root cause found: missing dtoverlay"
→ Add overlay
→ Doesn't fix it
→ "Root cause found: wrong HDMI mode"
→ Change mode
→ Doesn't fix it
→ Repeat...
```

**Solution:**
```
"Changed: Added error suppression to xset -dpms"
→ Test: Display works after reboot
→ Test: Display survives multiple reboots
→ Verify: No X server crashes in logs
→ NOW can say: "Root cause was xset -dpms crashing X on Pi 5"
```

### ❌ The "Script Hack" Pattern
**Symptom:** Using sed/awk without understanding

**Example:**
```
sed -i 's/class="old"/class="new"/' header.php
→ Doesn't work (minified file also needs update)
→ sed -i 's/class="old"/class="new"/' templates/indextpl.min.html
→ Still doesn't work (jQuery binds to class selector)
→ Repeat 70 times
```

**Solution:**
```
Read: scripts-panels.js
→ Found: $('.add-item-to-favorites').click()
→ Understand: Class selector binds ALL elements with that class
→ Solution: Remove old class, use unique ID
→ Works first time
```

### ❌ The "Scattered Documentation" Pattern
**Symptom:** Creating new status files for every session

**Example:**
```
STATUS_2026-01-19.md
STATUS_2026-01-20.md
FIXES_APPLIED.md
COMPLETE_STATUS.md
... 31 redundant files ...
```

**Solution:**
```
ONE master document: MASTER_MOODE_ARCHITECTURE.md
Update it continuously
Delete redundant status files
Keep knowledge organized
```

---

## The Knowledge Accumulation Process

### Every Task = Learning Opportunity

**Transform tasks into knowledge:**

1. **Task received**
   - "Add feature X"
   - "Fix problem Y"
   - "Optimize Z"

2. **Before starting:**
   - What do I already know? (check MASTER)
   - What do I need to know? (identify gaps)
   - Where is this knowledge? (which files to read)

3. **During work:**
   - Document insights as you discover them
   - Note patterns and relationships
   - Capture WHY things work this way

4. **After completion:**
   - Update MASTER with architectural learnings
   - Create deep-dive if complex
   - Delete temporary notes

**Result:** Task complete + Knowledge base enriched

---

## Gap-Filling Strategy

### Systematic Knowledge Expansion

**Current state:** Display and audio architecture complete

**Known gaps to fill over time:**

1. **Library System** (partially documented)
   - ⚠️ Tag view rendering logic
   - ⚠️ Cover art generation pipeline
   - ⚠️ Search and filter mechanics
   - ⚠️ Thumbnail cache management

2. **Network System** (basic understanding)
   - ⚠️ NetworkManager integration details
   - ⚠️ Hotspot activation logic
   - ⚠️ WiFi/Ethernet switching
   - ⚠️ mDNS/Avahi configuration

3. **Renderer System** (high-level documented)
   - ⚠️ Each renderer's specific implementation
   - ⚠️ Metadata fetch mechanisms
   - ⚠️ Output routing details
   - ⚠️ Active state detection

4. **Playlist System** (not documented)
   - ⚠️ Playlist storage format
   - ⚠️ M3U parsing
   - ⚠️ Favorites mechanism
   - ⚠️ Queue management

5. **Theme System** (basic understanding)
   - ⚠️ Color calculation algorithms
   - ⚠️ Adaptive theming logic
   - ⚠️ CSS custom property generation
   - ⚠️ YIQ brightness detection

**Strategy for filling gaps:**

**Option A: Opportunistic (Recommended)**
- Fill gaps when working on related tasks
- Example: Fixing library search → Document library generation
- Efficient: Learning happens in context

**Option B: Systematic**
- Dedicate time to reading specific subsystems
- Example: "Read entire playlist system today"
- Thorough but may not be immediately useful

**Option C: Hybrid**
- Opportunistic for most work
- Systematic for critical unknown areas before major changes

---

## Task Categorization & Approach

### Type 1: New Feature
**Example:** "Add Bluetooth toggle button"

**Workflow:**
1. **Research:**
   - Read how local_display toggle works (reference implementation)
   - Read bluetooth service structure
   - Read command/index.php for command patterns

2. **Design:**
   - Frontend: Button with unique ID
   - Backend: Command handler in command/index.php
   - Worker: Case handler (if needed) or reuse existing

3. **Implement:**
   - Add button to header.php
   - Add event handler to scripts-panels.js
   - Add command handler to command/index.php

4. **Document:**
   - Update MASTER with Bluetooth control flow
   - Note button placement patterns
   - Document event handler conventions

**Knowledge gained:** UI integration patterns, command dispatch architecture

---

### Type 2: Bug Fix
**Example:** "Display goes black after reboot"

**Workflow:**
1. **Investigate:**
   - Read error logs: `journalctl -u localdisplay -n 100`
   - Read relevant code: xinitrc.default, localdisplay.service
   - Understand failure mode

2. **Root Cause:**
   - Found: `xset -dpms` in xinitrc
   - Research: Pi 5 KMS driver lacks DPMS support
   - Proof: Command crashes X server

3. **Fix:**
   - Add error suppression: `xset -dpms 2>/dev/null || true`
   - Test: Survives reboot
   - Verify: No crashes in Xorg.0.log

4. **Document:**
   - Update MASTER: "Why xset -dpms crashes on Pi 5"
   - Add to lessons learned
   - Store working xinitrc in GitHub

**Knowledge gained:** Pi 5 KMS limitations, DPMS support detection, X11 error handling

---

### Type 3: Optimization
**Example:** "Make library loading faster"

**Workflow:**
1. **Measure:**
   - Current performance: Library load time
   - Identify bottlenecks: genFlatList() vs genLibrary()
   - Profile code execution

2. **Research:**
   - Read library generation code
   - Understand caching strategy
   - Find optimization opportunities

3. **Optimize:**
   - Apply targeted improvements
   - Preserve correctness
   - Measure improvement

4. **Document:**
   - Update MASTER with performance notes
   - Document caching strategy
   - Note optimization techniques

**Knowledge gained:** Library cache architecture, performance patterns

---

### Type 4: Configuration Change
**Example:** "Change display orientation to landscape"

**Workflow:**
1. **Check GitHub FIRST:**
   ```bash
   git log --grep="landscape\|orientation" --oneline
   git show <commit>:backups/v1.0-.../cmdline.txt
   ```

2. **If working config exists:**
   - Restore from GitHub (don't fix)
   - Document which commit was used
   - Verify it works

3. **If no working config:**
   - Read code to understand orientation system
   - Identify all files involved
   - Make coordinated changes

4. **Store result:**
   - Commit working config to GitHub
   - Tag as stable
   - Document in MASTER

**Knowledge gained:** Display orientation system, boot configuration

---

## The "Understand-First" Checklist

**Before ANY modification, answer these:**

- [ ] Have I read the relevant source code?
- [ ] Do I understand the data flow?
- [ ] Do I know the root cause (not just symptom)?
- [ ] Have I checked GitHub for existing solutions?
- [ ] Have I checked MASTER for existing knowledge?
- [ ] Can I explain WHY this fix works?
- [ ] Do I know what side effects might occur?

**If any answer is NO → Read more before changing**

---

## Documentation Standards

### MASTER Document Updates

**When to update:**
- Significant architectural insight gained
- New subsystem understood
- Bug root cause identified with proof
- New data flow discovered

**What to include:**
- Clear section heading
- Code examples (with line numbers)
- Data flow diagrams (ASCII)
- Why it works this way
- Common pitfalls

**What NOT to include:**
- Temporary status ("I tried X, didn't work")
- Speculation ("This might be the cause")
- Step-by-step logs ("First I did X, then Y")

### Deep-Dive Documents

**When to create:**
- Subsystem is complex (>500 lines of related code)
- Multiple interactions with other subsystems
- Reusable patterns worth documenting
- Troubleshooting guide needed

**Structure:**
1. Purpose and scope
2. Architecture overview
3. Code analysis (key functions)
4. Data flows
5. Configuration
6. Common issues and solutions
7. Related files

**Example titles:**
- `VOLUME_CONTROL_COMPLETE_ARCHITECTURE.md`
- `LIBRARY_CACHE_GENERATION_INTERNALS.md`
- `RENDERER_INTEGRATION_PATTERNS.md`

### Temporary Notes

**Use for:**
- Investigation findings (delete when done)
- Debugging sessions (delete when fixed)
- Experiment results (delete after documenting)

**Pattern:**
```
TEMP_INVESTIGATING_ISSUE.md → work → findings → update MASTER → delete TEMP
```

---

## Version Control Strategy

### Branching Strategy

**main branch:**
- Always working, tested code
- Deployable at any time
- Tagged with version numbers

**Feature branches:**
- One branch per feature/fix
- Name: `feature/peppymeter-toggle` or `fix/display-orientation`
- Merge only when tested

**Hotfix branches:**
- Critical fixes
- Name: `hotfix/xset-dpms-crash`
- Fast-track to main

### Tagging Strategy

**Version tags:**
- `v1.0-stable` - Base working system
- `v1.1-peppymeter` - After adding PeppyMeter
- `v1.2-network-fix` - After network improvements

**State tags:**
- `working-2026-01-21` - Known working state
- `before-upgrade` - Before major changes
- `tested-audio` - After audio testing

### Commit Messages

**Format:**
```
<type>: <short description>

<detailed explanation>

- What was changed
- Why it was changed
- How it was verified

Related: <issue/task>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code restructuring
- `config:` Configuration changes

**Example:**
```
fix: Add error suppression to xset -dpms in xinitrc

The xset -dpms command crashes X server on Raspberry Pi 5
because the KMS driver does not support DPMS extensions.

- Changed: Added 2>/dev/null || true to suppress errors
- Verified: Display survives reboot without X crashes
- Tested: Multiple reboots confirm stability

Root cause: Pi 5 vc4-kms-v3d driver lacks DPMS support

Related: WISSENSBASIS/MASTER_MOODE_ARCHITECTURE.md section 7.2
```

---

## Quality Gates

### Before Committing Code

- [ ] Code works as intended
- [ ] No introduced linter errors
- [ ] Tested after reboot
- [ ] Documentation updated
- [ ] Commit message explains WHY

### Before Claiming "Fixed"

- [ ] Root cause identified with evidence
- [ ] Fix verified through testing
- [ ] No side effects observed
- [ ] Survives reboot
- [ ] User confirms it works

### Before Claiming "Complete"

- [ ] All acceptance criteria met
- [ ] Documentation updated
- [ ] Changes committed to GitHub
- [ ] Working state tagged
- [ ] Knowledge base enriched

---

## Continuous Learning Process

### Weekly Review

**Questions to ask:**
1. What did we learn this week?
2. What gaps were filled?
3. What new gaps were discovered?
4. Is MASTER document current?
5. Are redundant files accumulating?

**Actions:**
- Review new findings
- Update MASTER if needed
- Clean up temp files
- Plan next gap-filling tasks

### Monthly Review

**Questions to ask:**
1. Has moOde been updated?
2. Are our modifications still compatible?
3. Is GitHub up to date?
4. Is documentation accurate?
5. What major gaps remain?

**Actions:**
- Read moOde changelog
- Test system after updates
- Update documentation for changes
- Plan systematic gap-filling

### Yearly Review

**Questions to ask:**
1. What was accomplished this year?
2. How much system knowledge increased?
3. What areas are still unknown?
4. Should documentation be reorganized?
5. Are there better patterns to use?

**Actions:**
- Major documentation review
- Refactor docs if needed
- Archive obsolete information
- Plan next year's learning goals

---

## The Virtuous Cycle

```
Task → Understand → Read Code → Design → Implement → Verify → Document
                                                                    ↓
                                    Knowledge Base ← ← ← ← ← ← ← ← ←
                                           ↓
                              Next Task (informed by previous learning)
```

**Each iteration:**
- Increases understanding
- Reduces trial-and-error
- Improves efficiency
- Builds reusable knowledge

**Over time:**
- Token usage decreases (less reading needed)
- Fix accuracy increases (patterns known)
- Speed increases (less investigation)
- Quality increases (architectural understanding)

---

## Practical Examples

### Example 1: Adding Volume Control Button

**Phase 1 - Understand:**
- Request: Add volume +/- buttons to Playbar
- Components: HTML template, JavaScript, backend API
- Check MASTER: Volume control flow documented

**Phase 2 - Research:**
- Read: scripts-panels.js for existing volume button handlers
- Found: `$('#volumeup').click()` and `$('#volumedn').click()`
- Pattern: Calls `setVolume(newVol, event)`

**Phase 3 - Design:**
- Add buttons to Playbar section in header.php
- Use same IDs with suffix: `#volumeup-2`, `#volumedn-2`
- Reuse existing event handlers (already support -2 suffix)

**Phase 4 - Implement:**
- Edit header.php (add buttons)
- Edit styles.css (position buttons)
- No JavaScript changes needed (handlers already exist)

**Phase 5 - Verify & Document:**
- Test: Buttons control volume correctly
- Update MASTER: Note that handlers support multiple button instances
- Commit: "feat: Add volume controls to Playbar"

**Knowledge gained:** UI extensibility patterns, multi-instance event handling

**Time saved next time:** 90% (pattern is now known)

---

### Example 2: Fixing Audio Detection Bug

**Phase 1 - Understand:**
- Problem: Audio device not detected after reboot
- Components: ALSA, HiFiBerry detection, worker.php
- Check MASTER: Audio detection flow partially documented

**Phase 2 - Research:**
- Read: alsa.php `cfgAudioDev()` function
- Read: audio.php `updAudioOutAndBtOutConfs()`
- Trace: How HiFiBerry AMP100 is detected
- Found: Relies on /proc/asound/cards

**Phase 3 - Design:**
- Root cause: Timing issue (card not ready when script runs)
- Solution: Add retry loop with delays
- Alternative: Add systemd service dependency

**Phase 4 - Implement:**
- Modify alsa.php detection function
- Add retry logic (3 attempts, 2 second delay)
- Log detection attempts for debugging

**Phase 5 - Verify & Document:**
- Test: Reboot 10 times, device detected every time
- Update MASTER: Document detection timing issue
- Create deep-dive: "ALSA_DEVICE_DETECTION.md"
- Commit: "fix: Add retry logic to audio device detection"

**Knowledge gained:** ALSA initialization timing, systemd ordering, retry patterns

**Documentation artifacts:**
- MASTER updated with detection flow
- Deep-dive created for troubleshooting
- GitHub has working solution

---

## Tooling for Efficiency

### The Toolbox

**Location:** `toolbox/`  
**Documentation:** `toolbox/README.md`

A clean, maintainable set of 15 essential tools organized by purpose:
- **`system/`** - System verification and maintenance
- **`deploy/`** - Deployment and restoration
- **`dev/`** - Development and debugging
- **`pi-scripts/`** - Production scripts for the Pi

See `toolbox/README.md` for complete documentation and usage examples.

### Essential Toolbox Commands

**System Verification:**
```bash
# Quick system health check
./toolbox/system/check-system-status.sh [pi-ip] [user]

# Verify system matches documentation
./toolbox/system/verify-architecture.sh [pi-ip] [user]

# Backup working configuration
./toolbox/system/backup-working-config.sh [pi-ip] [user]
```

**Deployment:**
```bash
# Burn image to SD card (macOS)
./toolbox/deploy/burn-sd-card.sh <image> <device>

# Restore from GitHub backup
./toolbox/deploy/restore-from-github.sh <commit> <backup-dir> [pi-ip] [user]
```

**Development:**
```bash
# Monitor Pi boot process
./toolbox/dev/monitor-pi-boot.sh [pi-ip] [user]

# Quick SSH with shortcuts
./toolbox/dev/quick-ssh.sh [pi-ip] [user] [command]

# Analyze system logs
./toolbox/dev/analyze-logs.sh [pi-ip] [user]
```

### Code Navigation (Cursor IDE)

**Semantic search for concepts:**
```bash
SemanticSearch("How does volume control work?", ["www/"])
```

**Exact text search:**
```bash
Grep "toggle_peppymeter" --type=php
```

**Find files by pattern:**
```bash
Glob "*.service"
```

**Read code:**
```bash
# Read complete file
Read /path/to/file.php

# Read multiple files in parallel
Read file1.php & Read file2.php & Read file3.php
```

### Typical Workflow with Toolbox

**Before making changes:**
```bash
# Check current state
./toolbox/system/check-system-status.sh

# Verify architecture
./toolbox/system/verify-architecture.sh

# Backup before changes
./toolbox/system/backup-working-config.sh
```

**After making changes:**
```bash
# Monitor boot
./toolbox/dev/monitor-pi-boot.sh

# Verify still correct
./toolbox/system/verify-architecture.sh

# Check for issues
./toolbox/dev/analyze-logs.sh
```

**When working:**
```bash
# Backup working state
./toolbox/system/backup-working-config.sh

# Commit to GitHub
git add backups/
git commit -m "Working configuration verified"
git tag v1.0-working-$(date +%Y%m%d)
git push --tags
```

---

## Communication Protocol

### When Reporting Progress

**DO:**
- "Changed X in file Y"
- "Found root cause: Z (evidence: log excerpt)"
- "Verified by: test results"
- "Updated MASTER with finding"

**DON'T:**
- "Root cause found" (without proof)
- "This should fix it" (without testing)
- "Let me try this" (read first)
- "Fixed the issue" (wait for user confirmation)

### When Encountering Unknown

**DO:**
- "Need to read source code for X first"
- "Checking GitHub for existing solution"
- "Found knowledge gap in area Y, reading now"
- "Updating MASTER with new findings"

**DON'T:**
- "I'll just try this and see"
- "Let me apply a quick fix"
- "This might work"
- "Guessing the root cause is..."

### When Stuck

**DO:**
- "Read more code to understand"
- "Check error logs for evidence"
- "Trace data flow from source"
- "Search for similar patterns in codebase"

**DON'T:**
- "Try random fixes"
- "Apply workarounds"
- "Modify without understanding"
- "Claim success without verification"

---

## Success Metrics

### Knowledge Accumulation
- ✅ MASTER document grows with each task
- ✅ Gaps in understanding shrink over time
- ✅ Documentation becomes comprehensive
- ✅ Similar tasks complete faster

### Code Quality
- ✅ Fixes work on first attempt (because understood)
- ✅ No regression bugs (because architecture known)
- ✅ Minimal code changes (targeted fixes)
- ✅ Consistent patterns (following existing code)

### Efficiency
- ✅ Token usage decreases (less trial-and-error)
- ✅ Development speed increases (patterns known)
- ✅ Debugging faster (architecture understood)
- ✅ User satisfaction increases (reliable fixes)

### Sustainability
- ✅ System remains maintainable
- ✅ Knowledge survives across sessions
- ✅ GitHub has working configurations
- ✅ Documentation enables future work

---

## Long-Term Vision

### Year 1 (Current)
- ✅ Complete display and audio architecture
- ✅ Fix critical bugs (xset -dpms, etc.)
- ⚠️ Document core systems
- 🎯 Fill library and network gaps

### Year 2
- Complete renderer system documentation
- Optimize performance (identified bottlenecks)
- Add advanced features (custom DSP, etc.)
- Contribute improvements back to moOde

### Year 3+
- System fully documented
- All subsystems understood
- Maintenance mode (updates only)
- Focus on enhancements, not fixes

---

## The Fundamental Rule

**Every task is an opportunity to learn.**

**Every fix teaches us something about the system.**

**Every bug reveals architectural insights.**

**Every feature expands our understanding.**

**The goal is not just a working system.**

**The goal is a UNDERSTOOD system.**

---

**This workflow ensures sustainable development where knowledge accumulates and efficiency increases over time.**

**No more "La La La" - only understanding-first development.**

**Document path:** `WISSENSBASIS/DEVELOPMENT_WORKFLOW.md`  
**Created:** 2026-01-21  
**Purpose:** Sustainable knowledge-first development methodology

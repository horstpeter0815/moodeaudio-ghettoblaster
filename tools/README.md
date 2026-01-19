# Tools Directory

**Purpose:** Development and debugging tools

---

## Directory Structure

### `/build/` - Build System Tools
- Build helpers and validation scripts
- Image builder utilities
- Build environment setup

### `/debug/` - Debugging Tools
- Log analysis scripts
- System diagnostics
- Component testing

### `/config/` - Configuration Helpers
- Configuration file generators
- Settings validators
- Backup/restore tools

---

## Tool Categories

### Build Tools
- Fast iteration during development
- Build validation
- Dependency checking

### Debug Tools
- Real-time diagnostics
- Log parsing and analysis
- Component-specific tests

### Config Tools
- Generate configuration files
- Validate settings
- Compare configurations

---

## Usage Guidelines

**During Development:**
```bash
# Quick build validation
./tools/build/validate-build-config.sh

# Debug specific component
./tools/debug/check-audio-chain.sh
```

**For Troubleshooting:**
```bash
# Analyze logs
./tools/debug/parse-system-logs.sh

# Compare configs
./tools/config/diff-with-v1.0.sh
```

---

## Best Practices

1. **Keep tools small and focused** - One tool, one purpose
2. **Make tools reusable** - Accept parameters, don't hardcode
3. **Document usage** - Header comments with examples
4. **Test tools** - Validate before committing

---

**Last Updated:** 2026-01-19  
**Version:** v1.1 (Organized toolbox)

# 🔍 Error Debugging Guide

## Quick Checks

### 1. Check if files are loaded correctly:
```bash
# Check file sizes
ls -lh test-wizard/snd-config.html moode-source/www/templates/snd-config.html

# Check if wizard modal exists in file
grep -c "room-correction-wizard-modal" test-wizard/snd-config.html
```

### 2. Check Docker container:
```bash
# Check if container is running
docker-compose -f docker-compose.wizard-test.yml ps

# Check logs
docker-compose -f docker-compose.wizard-test.yml logs --tail=50

# Restart container
docker-compose -f docker-compose.wizard-test.yml restart
```

### 3. Check browser console:
- Open http://localhost:8080
- Press F12 to open DevTools
- Go to Console tab
- Look for errors (red messages)

### 4. Use debug console:
- Open http://localhost:8080/debug-console.html
- This will show detailed error messages

## Common Errors

### Error: "Could not find wizard modal"
**Cause:** snd-config.html not loaded correctly or file is incomplete  
**Fix:** 
```bash
# Re-copy the file
cp moode-source/www/templates/snd-config.html test-wizard/snd-config.html
docker-compose -f docker-compose.wizard-test.yml restart
```

### Error: "function is not defined"
**Cause:** Scripts not loaded or loaded in wrong order  
**Fix:** Check browser console for script loading errors

### Error: "fetch failed"
**Cause:** File not accessible or CORS issue  
**Fix:** Check if snd-config.html is accessible at http://localhost:8080/snd-config.html

## Debug Steps

1. **Open browser console (F12)**
2. **Check Network tab** - see if snd-config.html loads (should be 200 OK)
3. **Check Console tab** - see actual error messages
4. **Use debug-console.html** - http://localhost:8080/debug-console.html

## Report Error Details

If you see an error, please provide:
- Error message (exact text)
- Browser console output
- Network tab status for snd-config.html
- What step were you on when error occurred?


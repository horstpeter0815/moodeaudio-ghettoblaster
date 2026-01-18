# 🔍 Debugging Notes - Wizard Modal

## Issues Found

1. **snd-config.html is a complete HTML document** - Not just a fragment
   - Contains `<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`
   - When parsed, the modal is inside `<body>`
   - Need to extract from body, not root

2. **Script execution order** - Scripts need to execute AFTER modal is in DOM
   - Modal must exist before functions reference it
   - Fixed: Scripts now execute after modal insertion

## Fix Applied

Changed from:
```javascript
wizardContent.innerHTML = wizardModal.outerHTML;
// Then execute scripts
```

To:
```javascript
const modalClone = wizardModal.cloneNode(true);
wizardContent.innerHTML = '';
wizardContent.appendChild(modalClone);
// Wait, then execute scripts
setTimeout(() => { /* execute scripts */ }, 500);
```

## Next Steps

1. Verify modal HTML structure is correct
2. Ensure scripts execute after modal is in DOM
3. Test modal opening with jQuery


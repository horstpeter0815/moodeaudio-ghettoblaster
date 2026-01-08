# 📱 iPhone Microphone Permissions - How to Enable

## 🔧 Method 1: Safari Settings (Recommended)

### Step-by-Step:

1. **Open iPhone Settings**
   - Tap the "Settings" app (gray gear icon)

2. **Go to Safari Settings**
   - Scroll down and tap **"Safari"**

3. **Open Camera/Microphone Settings**
   - Scroll down to the **"Settings for Websites"** section
   - Tap **"Camera"** or **"Microphone"**

4. **Allow Microphone for Your moOde Site**
   - You'll see a list of websites
   - Find your moOde IP address (e.g., `http://192.168.x.x` or your domain)
   - Tap on it
   - Select **"Allow"** or **"Ask"**

### Alternative: Allow for All Websites
- In the Microphone settings, you can set the default to **"Ask"** or **"Allow"**
- But be careful with "Allow" for all sites (security concern)

---

## 🔧 Method 2: Through Safari (On the Page)

### When the Permission Dialog Appears:

1. **Browser Permission Dialog**
   - When you click "Start Measurement", Safari will show a popup
   - Tap **"Allow"** to grant microphone access
   - If you previously denied, you won't see this dialog again

2. **If You Previously Denied:**
   - The dialog won't appear again automatically
   - You need to use Method 1 above to change it in Settings

---

## 🔧 Method 3: Clear and Re-allow

### If You Can't Find Your Site in Settings:

1. **Clear Safari Website Data**
   - Settings → Safari → Clear History and Website Data
   - This will reset all website permissions

2. **Revisit the Site**
   - Go back to your moOde web interface
   - Try the wizard again
   - Permission dialog should appear again

---

## 📋 Quick Checklist

- [ ] Go to iPhone Settings → Safari
- [ ] Tap "Microphone" (under "Settings for Websites")
- [ ] Find your moOde IP/domain in the list
- [ ] Change it to "Allow" or "Ask"
- [ ] Go back to Safari and reload the page
- [ ] Try the wizard again

---

## 🐛 Troubleshooting

### Issue: Can't find the site in Settings

**Solution**: The site only appears in Settings after Safari has attempted to access the microphone. If you denied it before, it will be in the list.

**To find it**:
1. Settings → Safari → Microphone
2. Scroll through the list
3. Look for your IP address (e.g., `192.168.1.100`) or hostname

### Issue: Site shows "Deny" and can't change it

**Solution**: 
1. Tap on the site entry
2. Select "Ask" or "Allow"
3. Reload the page in Safari

### Issue: HTTPS required for microphone access

**Note**: Some browsers require HTTPS for microphone access. If using HTTP:
- Try accessing via HTTPS if your certificate is set up
- Or use a local network setup that Safari trusts

---

## 💡 Tips

- **For Testing**: You can set Microphone to "Ask" for all websites temporarily
- **For Security**: Only allow for specific sites you trust
- **If Using Certificate**: HTTPS makes permissions work more reliably

---

## 🌐 Alternative: Use a Desktop Browser

If you're having trouble with iPhone Safari:
- Try using Chrome/Safari on a Mac/PC
- Desktop browsers often have clearer permission UI
- The wizard works the same way on desktop

---

**After enabling permissions, reload the page and try the wizard again!** ✅


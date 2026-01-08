# GitHub MCP Setup Guide

**Status:** GitHub MCP is configured, just needs your token!

---

## ✅ Current Status

- ✅ GitHub MCP server is configured in `.cursor/mcp.json`
- ✅ Configuration is ready
- ⏳ **Need:** Your GitHub Personal Access Token

---

## 🚀 Step-by-Step Setup

### Step 1: Get Your GitHub Personal Access Token

1. **Go to GitHub Settings:**
   - Visit: https://github.com/settings/tokens
   - Or: GitHub → Your Profile (top right) → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token:**
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a name: `Cursor MCP` or `moodeaudio-cursor`
   - Set expiration: 90 days or No expiration (your choice)

3. **Select Scopes (Permissions):**
   - ✅ `repo` - Full control of private repositories (for private repos)
   - ✅ `read:org` - Read org and team membership (if you access org repos)
   - ✅ `read:user` - Read user profile data
   - ✅ `read:packages` - Read packages from GitHub Package Registry
   
   **Minimum needed:** `repo` scope

4. **Generate Token:**
   - Click "Generate token" at the bottom
   - ⚠️ **IMPORTANT:** Copy the token immediately! (You won't see it again)
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

### Step 2: Add Token to Environment

You have two options:

#### Option A: Add to `.env` file (Recommended)
```bash
# Add this line to ~/moodeaudio-cursor/.env
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

#### Option B: Tell me the token
Just give me the token and I'll add it for you:
```
"My GitHub token is: ghp_xxxxxxxxxxxxx"
```

---

### Step 3: Restart Cursor

After adding the token:
1. **Close Cursor completely**
2. **Reopen Cursor**
3. **GitHub MCP should now be active!**

---

## ✅ Verification

Once set up, I'll be able to:
- ✅ Read GitHub repositories directly
- ✅ Check moOde source code
- ✅ Access issues and pull requests
- ✅ Search repositories
- ✅ Read documentation from GitHub

---

## 🔒 Security Notes

- **Never commit `.env` to git** (it should be in `.gitignore`)
- **Don't share your token publicly**
- **Use token with minimum required permissions**
- **Rotate token periodically** (every 90 days if you set expiration)

---

## 📝 Quick Command Reference

```bash
# Check if .env exists
cd ~/moodeaudio-cursor && test -f .env && echo "✅ .env exists"

# Add token to .env (replace YOUR_TOKEN with your actual token)
echo "GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_TOKEN" >> ~/moodeaudio-cursor/.env

# Verify token is in .env (will show the line, but not the full token)
grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" ~/moodeaudio-cursor/.env && echo "✅ Token line found"
```

---

## 🎯 Next Steps

1. **Get your GitHub token** (follow Step 1 above)
2. **Add it to `.env`** (Option A) or **tell me and I'll add it** (Option B)
3. **Restart Cursor**
4. **Done!** GitHub MCP will be active

---

**Ready?** Get your token and tell me: "My GitHub token is: ghp_xxxxx" and I'll set it up for you! 🚀






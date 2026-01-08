# Remote SSH Access Information

**Date:** 2025-01-03  
**Purpose:** Information for colleague to access Pi via SSH

---

## Connection Details

### Local Network Access:
```bash
ssh andre@192.168.10.2
Password: 0815
```

### Remote Access:
**Method:** [To be configured - VPN/Port Forwarding/Dynamic DNS]

**Command:**
```bash
# Will be provided after setup
ssh -p [PORT] andre@[HOST]
```

---

## Pi Information

- **Hostname:** GhettoBlaster
- **User:** andre
- **Password:** 0815 (change after first login!)
- **SSH Port:** 22 (default)

---

## Setup Status

- ✅ SSH enabled on Pi
- ⏳ Remote access method: [To be configured]
- ⏳ Credentials to be shared securely

---

## Recommended Setup Steps

1. **Choose remote access method:**
   - VPN (most secure, recommended)
   - Port Forwarding (simpler, less secure)
   - Dynamic DNS + Port Forwarding (for dynamic IP)

2. **Configure chosen method**

3. **Test remote access**

4. **Share credentials securely with colleague**

5. **Set up SSH keys (recommended)**

---

**Documentation:** See `docs/REMOTE_SSH_SETUP.md` for detailed setup instructions.





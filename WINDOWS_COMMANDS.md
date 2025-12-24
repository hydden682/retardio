# Windows PowerShell Commands

## ✅ Step 1: GitHub Emails Fixed!

Already done! The `.github` folder is removed and pushed. **No more failure emails!**

---

## Step 2: Build the Release Package

**In PowerShell, run:**

```powershell
wsl bash -c "cd /mnt/c/Users/YourUsername/retardio-coin && ./build_release_package.sh"
```

This will:
1. Build Retardio binaries (10-15 minutes)
2. Package everything together
3. Create: `retardio_v1.0.0_ready_to_use.tar.gz`

**Wait for this to finish...**

---

## Step 3: Test It Yourself

```powershell
# Extract to temp folder
wsl bash -c "cd /tmp && tar -xzf /mnt/c/Users/YourUsername/retardio-coin/retardio_v1.0.0_ready_to_use.tar.gz"

# Run installer
wsl bash -c "cd /tmp/retardio_release && ./INSTALL.sh"
```

**When asked:**
- Peer IP? Type `n` and press Enter
- Open firewall? Type `y` and press Enter

**Then verify:**
```powershell
wsl bash -c "retardio-status"
```

Should show your node running!

---

## Step 4: Share With Others

**The file is here:**
```
C:\Users\YourUsername\retardio-coin\retardio_v1.0.0_ready_to_use.tar.gz
```

**Send this file to your friend!**

They just:
1. Extract it
2. Run `./INSTALL.sh`
3. Done!

---

## Quick Commands

**Build package:**
```powershell
wsl bash -c "cd /mnt/c/Users/YourUsername/retardio-coin && ./build_release_package.sh"
```

**Test package:**
```powershell
wsl bash -c "cd /tmp && tar -xzf /mnt/c/Users/YourUsername/retardio-coin/retardio_v1.0.0_ready_to_use.tar.gz && cd retardio_release && ./INSTALL.sh"
```

**Check status:**
```powershell
wsl bash -c "retardio-status"
```

**Mine blocks:**
```powershell
wsl bash -c "retardio-mine 10"
```

---

## Start Now!

**Run this to build the package:**

```powershell
wsl bash -c "cd /mnt/c/Users/YourUsername/retardio-coin && ./build_release_package.sh"
```

Wait 10-15 minutes, then you'll have a ready-to-share installer! 🚀

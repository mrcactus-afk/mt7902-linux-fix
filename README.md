# 🛠️ Fix MediaTek MT7902 WiFi & Bluetooth on Linux (Kernel 6.14 - 6.17+)

> [!IMPORTANT]
> **Context:** This guide resolves the notorious `-110` Bluetooth timeout and missing WiFi networks on the MediaTek MT7902 combo card found in ASUS laptops (e.g., Vivobook 14 X1502VA).
> 
> **The Fix:** The default kernel drivers often fail to initialize the hardware or load the correct firmware. This solution installs specific firmware blobs and compiles custom `btusb` and `mt76` drivers from the `OnlineLearningTutorials` repository, specifically patched for newer kernels.

---

## 📋 Prerequisites

1.  **OS:** Linux Mint 22.3 / Ubuntu 24.04 (or similar Debian-based distro).
2.  **Kernel:** Version **6.17** (HWE) or newer is recommended.
    *   *Check version:* `uname -r`
3.  **Internet:** A working connection is required to download build tools.
    *   *Note for Iran/Restricted Regions:* If `apt` or `git` fails, ensure your proxy (e.g., V2rayN) is configured for the terminal or use the `socks5h://` method in `/etc/apt/apt.conf.d/`.
4.  **Tools:** `sudo` privileges.

---

## 🚀 Method 1: Automated Installation Script (Recommended)

This script automates the entire process: installing dependencies, fetching the driver source, installing firmware, compiling the modules (with manual compression to fix Makefile errors), and disabling Bluetooth autosuspend.

### 1. Create the Script
Open your terminal and create a file named `install_mt7902.sh`:

```bash
nano install_mt7902.sh

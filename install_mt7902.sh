#!/bin/bash
# ==========================================================
# MT7902 WiFi + Bluetooth Auto-Installer
# For Linux Mint 22.3 / Ubuntu 24.04 (Kernel 6.14 - 7.0)
# ==========================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

if [[ $EUID -ne 0 ]]; then
    fail "Run this script as root: sudo bash $0"
fi

REPO_URL="https://github.com/OnlineLearningTutorials/mt7902_temp.git"
REPO_DIR="/opt/mt7902_temp"
KERNEL_FULL=$(uname -r)
KERNEL_MAJOR_MINOR=$(echo "$KERNEL_FULL" | cut -d. -f1,2)
KERNEL_DIR="$REPO_DIR/linux-$KERNEL_MAJOR_MINOR"

echo "========================================="
echo "  MT7902 Driver Auto-Installer"
echo "  Kernel: $KERNEL_FULL"
echo "========================================="

# 1. Dependencies
log "Installing build dependencies..."
apt-get update -qq
apt-get install -y -qq git build-essential linux-headers-"$KERNEL_FULL" zstd bc > /dev/null 2>&1

# 2. Clone Repo
if [[ ! -d "$REPO_DIR" ]]; then
    log "Cloning repository..."
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" > /dev/null 2>&1
else
    log "Repository exists, updating..."
    cd "$REPO_DIR" && git pull --ff-only > /dev/null 2>&1 || true
fi

if [[ ! -d "$KERNEL_DIR" ]]; then
    fail "Kernel $KERNEL_MAJOR_MINOR is not supported by this repository."
fi

# 3. Firmware
log "Installing Firmware..."
cd "$REPO_DIR/firmware"
sudo ./install_firmware.sh

# 4. Bluetooth Driver
log "Compiling Bluetooth Driver..."
BT_SRC="$KERNEL_DIR/drivers/bluetooth"
cd "$BT_SRC"
make clean > /dev/null 2>&1 || true
make -C /lib/modules/"$KERNEL_FULL"/build/ M="$(pwd)" modules > /dev/null 2>&1

# Manual compression (Fixes Makefile error)
zstd -f -q btusb.ko btmtk.ko
mkdir -p /lib/modules/"$KERNEL_FULL"/kernel/drivers/bluetooth
install -m 644 btusb.ko.zst btmtk.ko.zst /lib/modules/"$KERNEL_FULL"/kernel/drivers/bluetooth/
log "Bluetooth Driver Installed."

# 5. WiFi Driver
log "Compiling WiFi Driver..."
WIFI_SRC="$KERNEL_DIR/drivers/net/wireless/mediatek/mt76"
cd "$WIFI_SRC"
make clean > /dev/null 2>&1 || true
make -C /lib/modules/"$KERNEL_FULL"/build/ M="$(pwd)" modules > /dev/null 2>&1

# Manual compression
zstd -f -q mt76.ko mt76-connac-lib.ko mt792x-lib.ko
zstd -f -q mt7921/mt7921-common.ko mt7921/mt7921e.ko

mkdir -p /lib/modules/"$KERNEL_FULL"/kernel/drivers/net/wireless/mediatek/mt76
mkdir -p /lib/modules/"$KERNEL_FULL"/kernel/drivers/net/wireless/mediatek/mt76/mt7921
install -m 644 mt76.ko.zst mt76-connac-lib.ko.zst mt792x-lib.ko.zst /lib/modules/"$KERNEL_FULL"/kernel/drivers/net/wireless/mediatek/mt76/
install -m 644 mt7921/mt7921-common.ko.zst mt7921/mt7921e.ko.zst /lib/modules/"$KERNEL_FULL"/kernel/drivers/net/wireless/mediatek/mt76/mt7921/
log "WiFi Driver Installed."

# 6. Finalize
log "Updating system modules..."
depmod -a
update-initramfs -u > /dev/null 2>&1

# Disable autosuspend to prevent -110 timeout
echo "options btusb enable_autosuspend=n" > /etc/modprobe.d/btusb-mt7902.conf

# Remove conflicting firmware
rm -f /lib/firmware/mediatek/mt7902/BT_RAM_CODE_MT7902_1_1_hdr.bin.zst

echo ""
echo "========================================="
echo -e "  ${GREEN}✅ Installation Complete!${NC}"
echo "========================================="
echo "  Please REBOOT your computer now."
echo "  sudo reboot"

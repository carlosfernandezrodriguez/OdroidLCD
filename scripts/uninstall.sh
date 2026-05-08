#!/bin/bash

# OdroidLCD - Uninstallation Script
# Removes kernel module, tools, and configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root"
	echo "Usage: sudo ./scripts/uninstall.sh"
	exit 1
fi

echo "================================================"
echo "OdroidLCD - Uninstallation Script"
echo "================================================"
echo ""

read -p "Are you sure you want to uninstall OdroidLCD? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Cancelled."
	exit 0
fi

echo ""

echo "[1/4] Unloading kernel module..."
modprobe -r vu7_touchscreen 2>/dev/null || true
echo "✓ Module unloaded"
echo ""

echo "[2/4] Removing kernel module..."
KERNEL_VERSION=$(uname -r)
MODULES_DIR="/lib/modules/$KERNEL_VERSION/extra"
rm -f "$MODULES_DIR/vu7_touchscreen.ko"
depmod -a
echo "✓ Module removed"
echo ""

echo "[3/4] Removing user-space tools..."
rm -f /usr/local/bin/diagnostic
rm -f /usr/local/bin/calibration
echo "✓ Tools removed"
echo ""

echo "[4/4] Cleaning udev rules..."
rm -f /etc/udev/rules.d/50-odroidlcd.rules
echo "✓ udev rules removed"
echo ""

echo "================================================"
echo "Uninstallation completed!"
echo "================================================"
echo ""

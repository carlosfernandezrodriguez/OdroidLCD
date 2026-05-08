# Installation Guide - OdroidLCD

## Prerequisites

Before installing OdroidLCD, ensure you have:

### Hardware
- ODROID Single Board Computer (C1+, C2, C4, or XU4)
- ODROID VU7A Plus 7" touchscreen
- USB Micro cable (for touchscreen connection)
- HDMI cable (for display)

### Software Requirements

#### System Packages
```bash
sudo apt update
sudo apt install \
    build-essential \
    linux-headers-$(uname -r) \
    git \
    libusb-1.0-0-dev \
    pkg-config \
    udev
```

#### Kernel Version
- Minimum: Linux 5.4
- Tested on: Debian 13.4 (kernel 6.1+)

Check your kernel version:
```bash
uname -r
```

## Step-by-Step Installation

### 1. Clone the Repository

```bash
git clone https://github.com/carlosfernandezrodriguez/OdroidLCD.git
cd OdroidLCD
```

### 2. Build the Project

```bash
chmod +x scripts/*.sh
./scripts/build.sh
```

This will:
- Check build prerequisites
- Compile the kernel module
- Build diagnostic and calibration tools
- Generate executables in `src/` and `tools/`

### 3. Install (Requires sudo)

```bash
sudo ./scripts/install.sh
```

This will:
- Copy kernel module to `/lib/modules/`
- Install tools to `/usr/local/bin/`
- Configure udev rules
- Load the kernel module automatically
- Register module with kernel

### 4. Verify Installation

```bash
# Check module is loaded
lsmod | grep vu7_touchscreen

# Run diagnostic
sudo diagnostic
```

### 5. Calibrate Touchscreen

```bash
# Interactive calibration (requires display output)
sudo calibration
```

## Troubleshooting Installation

### Build Errors

#### "gcc: command not found"
```bash
sudo apt install build-essential
```

#### "linux/version.h: No such file"
```bash
sudo apt install linux-headers-$(uname -r)
```

#### "libusb.h: No such file"
```bash
sudo apt install libusb-1.0-0-dev pkg-config
```

### Installation Errors

#### "Operation not permitted"
Always use `sudo` for installation:
```bash
sudo ./scripts/install.sh
```

#### "Module not found"
Rebuild first:
```bash
./scripts/build.sh
sudo ./scripts/install.sh
```

#### "Module failed to load"
Check kernel compatibility:
```bash
uname -r
sudo dmesg | tail -20
```

## Post-Installation

### Verify USB Connection

```bash
# Check if device is detected
lsusb | grep 16b4

# Should show: GOODIX Technology Co., Ltd.
```

### Check Input Device

```bash
# List input devices
cat /proc/bus/input/devices | grep -A 5 "VU7\|GOODIX"

# Monitor events
sudo evtest
```

### Test Touch Events

```bash
# Run diagnostic in monitor mode
sudo diagnostic -m

# Touch the screen and watch for coordinates
```

## Configuration

### Calibration Data

After running `sudo calibration`, the system stores coefficients:

- System-wide: `/etc/odroidlcd/calibration.conf`
- User-specific: `~/.odroidlcd.calib`

### udev Rules

Device permissions are automatically configured in:
```
/etc/udev/rules.d/50-odroidlcd.rules
```

This allows input group members to access the device without sudo.

To add your user to the input group:
```bash
sudo usermod -a -G input $USER
# Log out and log back in for changes to take effect
```

## Upgrading

### Upgrade to Latest Version

```bash
cd OdroidLCD
git pull origin main
./scripts/build.sh
sudo ./scripts/install.sh
```

### Downgrading

```bash
sudo ./scripts/uninstall.sh
# Checkout previous version
git checkout <previous-version-tag>
./scripts/build.sh
sudo ./scripts/install.sh
```

## Uninstallation

To remove OdroidLCD completely:

```bash
sudo ./scripts/uninstall.sh
```

This will:
- Unload the kernel module
- Remove module files
- Delete tools and configuration
- Clean up udev rules

## Advanced Configuration

### Manual Module Loading

If the module doesn't load automatically:

```bash
sudo modprobe vu7_touchscreen
```

### Custom Calibration

Manual calibration coefficients (bilinear transformation):

```bash
# Format: a b c d e f
echo "10000 0 0 0 10000 0" | sudo tee /etc/odroidlcd/calibration.conf
```

### Debug Mode

For debugging, check kernel messages:

```bash
# Real-time kernel logs
sudo tail -f /var/log/kern.log

# Recent logs
sudo dmesg | tail -50
```

## Performance Tuning

### USB Polling Rate

Edit `/etc/odroidlcd/config`:
```
# Polling interval in milliseconds (10-20 recommended)
POLLING_INTERVAL=10
```

### Event Filtering

The driver automatically filters spurious touches. Adjust sensitivity:
```bash
# Pressure threshold (0-255)
echo "PRESSURE_THRESHOLD=30" | sudo tee -a /etc/odroidlcd/config
```

## Getting Help

### Run Diagnostic

```bash
# Full diagnostic report
sudo diagnostic

# USB only
sudo diagnostic -u

# Kernel module only
sudo diagnostic -k

# Input device only
sudo diagnostic -i

# Monitor touch events
sudo diagnostic -m
```

### Check System Information

```bash
# Kernel version
uname -r

# Input devices
cat /proc/bus/input/devices

# USB devices
lsusb -v | grep -A 10 "16b4:0705"

# Kernel messages
sudo dmesg | grep -i "odroid\|vu7\|touchscreen"
```

### Common Issues

#### No Touch Events Detected
```bash
# Check if module is loaded
lsmod | grep vu7_touchscreen

# Reload module
sudo modprobe -r vu7_touchscreen
sudo modprobe vu7_touchscreen

# Check input device
ls -la /dev/input/
```

#### Inaccurate Touch Coordinates
```bash
# Recalibrate
sudo calibration

# Check calibration data
cat /etc/odroidlcd/calibration.conf
```

#### Permission Denied
```bash
# Add user to input group
sudo usermod -a -G input $USER

# Apply changes
newgrp input
```

## Next Steps

1. **Read Documentation**
   - [README.md](../README.md) - Project overview
   - [docs/TECHNICAL.md](../docs/TECHNICAL.md) - Technical details
   - [docs/USB_PROTOCOL.md](../docs/USB_PROTOCOL.md) - Protocol reference

2. **Test Functionality**
   - Run `sudo diagnostic`
   - Test touch input with `sudo evtest`
   - Monitor events with `sudo diagnostic -m`

3. **Calibrate System**
   - Run `sudo calibration`
   - Verify with `sudo diagnostic -m`

4. **Integrate with Applications**
   - Use standard Linux input event interface
   - See `examples/` directory for code samples

---

**For additional support**: Check docs/ directory or GitHub issues
**Kernel Module**: vu7_touchscreen.ko (GPL v2)
**Installation Date**: 2026-05-08

# OdroidLCD - ODROID VU7A Plus Kernel Touchscreen Driver

A professional Linux kernel module driver for the ODROID VU7A Plus capacitive touchscreen with calibration and diagnostic tools.

## Overview

**OdroidLCD** provides complete support for the ODROID VU7A Plus 7-inch multi-touch display on Debian Linux systems. This kernel module enables 5-point capacitive touch input via USB with coordinate calibration and full integration with the Linux Input Subsystem.

### Features

- ✅ **5-point capacitive multi-touch** support
- ✅ **USB HID** communication (ID: 16b4:0705)
- ✅ **Coordinate calibration** with bilinear transformation
- ✅ **Linux Input Subsystem** integration
- ✅ **Interactive calibration tool**
- ✅ **Comprehensive diagnostic tool**
- ✅ **Automatic device detection**
- ✅ **udev rule integration**
- ✅ **Full documentation** and examples

## Hardware Support

| Device | Bus | Status |
|--------|-----|--------|
| ODROID VU7A Plus | USB (16b4:0705) | ✅ Supported |
| ODROID C1+ | HDMI + Micro-USB | ✅ Compatible |
| ODROID C2 | HDMI + Micro-USB | ✅ Compatible |
| ODROID XU4 | HDMI + Micro-USB | ✅ Compatible |

## Installation

### Prerequisites

```bash
sudo apt update
sudo apt install \
    build-essential \
    linux-headers-$(uname -r) \
    git \
    libusb-1.0-0-dev \
    pkg-config
```

### Build

```bash
git clone https://github.com/carlosfernandezrodriguez/OdroidLCD.git
cd OdroidLCD
chmod +x scripts/*.sh
./scripts/build.sh
```

### Install

```bash
sudo ./scripts/install.sh
```

### Verify

```bash
sudo diagnostic
```

## Usage

### System Diagnostics

Check device connectivity and driver status:

```bash
sudo diagnostic
```

Options:
- `-m` - Monitor live touch events
- `-u` - Check USB device only
- `-k` - Check kernel module only
- `-i` - Check input device only

### Touchscreen Calibration

Calibrate the touchscreen interactively:

```bash
sudo calibration
```

The calibration tool captures 4 reference points and computes bilinear transformation coefficients.

### Check Module Status

```bash
# Verify module is loaded
lsmod | grep vu7_touchscreen

# Get module details
sudo modinfo vu7_touchscreen
```

### Monitor Touch Events

```bash
# Use diagnostic tool
sudo diagnostic -m

# Or use Linux input tools
cat /proc/bus/input/devices
sudo evtest
```

## Project Structure

```
OdroidLCD/
├── src/
│   ├── vu7_touchscreen.c    # Main kernel driver (600+ lines)
│   ├── vu7_touchscreen.h    # Driver headers
│   └── Makefile              # Kernel module build
├── tools/
│   ├── diagnostic.c          # USB/device diagnostics
│   ├── calibration.c         # Calibration utility
│   └── Makefile              # Tools build
├── scripts/
│   ├── build.sh              # Build automation
│   ├── install.sh            # Installation (requires sudo)
│   ├── uninstall.sh          # Removal script
│   └── test.sh               # Verification tests
├── docs/
│   ├── TECHNICAL.md          # Technical specifications
│   ├── USB_PROTOCOL.md       # USB protocol details
│   └── DEBUGGING.md          # Troubleshooting guide
├── examples/
│   ├── read_events.c         # Event reading example
│   └── calibration_example.c # Calibration example
├── debian/                   # Debian packaging files
├── README.md                 # This file
└── INSTALL.md               # Detailed installation guide
```

## Configuration

### Calibration Data

Calibration coefficients are stored in:
- `/etc/odroidlcd.calib` (system-wide, requires root)
- `~/.odroidlcd.calib` (user-specific)

Format: `a b c d e f` (bilinear transformation coefficients)

### udev Rules

Device permissions are configured automatically via:
- `/etc/udev/rules.d/50-odroidlcd.rules`

This allows non-root users to access the touchscreen.

## Technical Details

### Supported Protocols

- USB HID (Human Interface Device)
- Linux Multi-Touch Protocol B
- Input Event Interface

### Calibration

The driver uses **bilinear transformation** for accurate coordinate mapping:

```
x_screen = (a*x_raw + b*y_raw + c) / 10000
y_screen = (d*x_raw + e*y_raw + f) / 10000
```

Coefficients are calculated from 4 calibration points using least squares fitting.

### Touch Data Format

Each USB packet contains:
- Touch point count (1 byte)
- Up to 5 touch points (6 bytes each)
  - Touch ID (1 byte)
  - X coordinate (2 bytes, big-endian)
  - Y coordinate (2 bytes, big-endian)
  - Pressure (1 byte)

## Troubleshooting

### Device Not Detected

```bash
# Check USB connection
lsusb | grep 16b4

# Load module manually
sudo insmod src/vu7_touchscreen.ko

# Run diagnostic
sudo diagnostic -u
```

### Module Won't Load

```bash
# Check kernel compatibility
uname -r

# View error messages
sudo dmesg | tail -20

# Rebuild module
./scripts/build.sh
```

### Touch Events Not Detected

```bash
# Check input device
sudo diagnostic -i

# Monitor events
sudo diagnostic -m

# Verify permissions
ls -la /dev/input/event*
```

## Uninstallation

```bash
sudo ./scripts/uninstall.sh
```

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed installation instructions
- **[docs/TECHNICAL.md](docs/TECHNICAL.md)** - Technical specifications
- **[docs/USB_PROTOCOL.md](docs/USB_PROTOCOL.md)** - USB protocol reference
- **[docs/DEBUGGING.md](docs/DEBUGGING.md)** - Debugging and troubleshooting

## Examples

### Reading Touch Events (C)

```c
#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>

int fd = open("/dev/input/eventX", O_RDONLY);
struct input_event ev;

while (read(fd, &ev, sizeof(ev)) == sizeof(ev)) {
    if (ev.type == EV_ABS && ev.code == ABS_MT_POSITION_X)
        printf("X: %d\n", ev.value);
}
close(fd);
```

### Running Calibration

```bash
# Interactive calibration (requires display)
sudo calibration

# Or manually set coefficients
echo "10000 0 0 0 10000 0" | sudo tee /etc/odroidlcd.calib
```

## Performance

| Metric | Value |
|--------|-------|
| Touch latency | ~10 ms |
| Polling rate | 50-100 Hz |
| Max simultaneous touches | 5 |
| Coordinate precision | 65536 x 65536 raw |
| Screen resolution | 1024 x 600 px |

## License

GPL v2 - See LICENSE file for details

## Author

Carlos Fernández Rodríguez

## Support

For issues, suggestions, or contributions:
1. Check the documentation in `docs/`
2. Run `sudo diagnostic` for system information
3. Review kernel logs: `sudo dmesg`
4. Create an issue on GitHub

---

**Status**: Production-ready for Debian 13.4+
**Last Updated**: 2026-05-08
**Version**: 1.0.0

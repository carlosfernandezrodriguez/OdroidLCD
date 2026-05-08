#!/bin/bash

# OdroidLCD - Test script
# Runs basic tests on the driver and tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "OdroidLCD - Test Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check build artifacts
echo "[1/5] Checking build artifacts..."
if [ -f "$PROJECT_ROOT/src/vu7_touchscreen.ko" ]; then
	echo -e "${GREEN}✓ Kernel module found${NC}"
else
	echo -e "${RED}✗ Kernel module not found${NC}"
	echo "  Run: ./scripts/build.sh"
	exit 1
fi

if [ -f "$PROJECT_ROOT/tools/diagnostic" ]; then
	echo -e "${GREEN}✓ Diagnostic tool found${NC}"
else
	echo -e "${RED}✗ Diagnostic tool not found${NC}"
	exit 1
fi

if [ -f "$PROJECT_ROOT/tools/calibration" ]; then
	echo -e "${GREEN}✓ Calibration tool found${NC}"
else
	echo -e "${RED}✗ Calibration tool not found${NC}"
	exit 1
fi

echo ""

# Test 2: Check module metadata
echo "[2/5] Checking kernel module metadata..."
if modinfo "$PROJECT_ROOT/src/vu7_touchscreen.ko" > /dev/null 2>&1; then
	echo -e "${GREEN}✓ Module metadata valid${NC}"
	
	echo ""
	echo "Module Information:"
	modinfo "$PROJECT_ROOT/src/vu7_touchscreen.ko" | grep -E "^(filename|version|description|author|license|parm):" || true
else
	echo -e "${RED}✗ Module metadata invalid${NC}"
	exit 1
fi

echo ""

# Test 3: Check tools compilation
echo "[3/5] Checking tool executables..."

if file "$PROJECT_ROOT/tools/diagnostic" | grep -q "ELF"; then
	echo -e "${GREEN}✓ Diagnostic tool compiled${NC}"
else
	echo -e "${RED}✗ Diagnostic tool not a valid ELF binary${NC}"
	exit 1
fi

if file "$PROJECT_ROOT/tools/calibration" | grep -q "ELF"; then
	echo -e "${GREEN}✓ Calibration tool compiled${NC}"
else
	echo -e "${RED}✗ Calibration tool not a valid ELF binary${NC}"
	exit 1
fi

echo ""

# Test 4: Check tool dependencies
echo "[4/5] Checking tool dependencies..."

# Check diagnostic dependencies
if ldd "$PROJECT_ROOT/tools/diagnostic" > /dev/null 2>&1; then
	if ldd "$PROJECT_ROOT/tools/diagnostic" | grep -q "libusb"; then
		echo -e "${GREEN}✓ Diagnostic has libusb${NC}"
	else
		echo -e "${YELLOW}⚠ Diagnostic missing libusb${NC}"
	fi
else
	echo -e "${RED}✗ Failed to check diagnostic dependencies${NC}"
fi

# Check calibration dependencies
if ldd "$PROJECT_ROOT/tools/calibration" > /dev/null 2>&1; then
	if ldd "$PROJECT_ROOT/tools/calibration" | grep -q "libm"; then
		echo -e "${GREEN}✓ Calibration has math library${NC}"
	else
		echo -e "${YELLOW}⚠ Calibration missing math library${NC}"
	fi
else
	echo -e "${RED}✗ Failed to check calibration dependencies${NC}"
fi

echo ""

# Test 5: Check documentation
echo "[5/5] Checking documentation..."

DOCS_FOUND=0

if [ -f "$PROJECT_ROOT/README.md" ]; then
	echo -e "${GREEN}✓ README.md found${NC}"
	((DOCS_FOUND++))
fi

if [ -f "$PROJECT_ROOT/INSTALL.md" ]; then
	echo -e "${GREEN}✓ INSTALL.md found${NC}"
	((DOCS_FOUND++))
fi

if [ -f "$PROJECT_ROOT/docs/TECHNICAL.md" ]; then
	echo -e "${GREEN}✓ TECHNICAL.md found${NC}"
	((DOCS_FOUND++))
fi

if [ -f "$PROJECT_ROOT/docs/USB_PROTOCOL.md" ]; then
	echo -e "${GREEN}✓ USB_PROTOCOL.md found${NC}"
	((DOCS_FOUND++))
fi

echo ""
echo "================================================"
echo -e "${GREEN}All tests completed!${NC}"
echo "================================================"
echo ""
echo "Documentation files found: $DOCS_FOUND"
echo ""
echo "Next steps:"
echo "  1. Build: ./scripts/build.sh"
echo "  2. Install: sudo ./scripts/install.sh"
echo "  3. Test: sudo diagnostic"
echo ""

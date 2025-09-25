#!/bin/bash

# AnyKernel3 ZIP Creation Script

set -e

KSU_VERSION="$1"
BUILD_DATE="$2"

echo "📦 Creating AnyKernel3 flashable ZIP..."

# Check if kernel image exists
if [ ! -f "output/Image.gz-dtb" ]; then
    echo "❌ Kernel image not found!"
    exit 1
fi

# Clone AnyKernel3 template
git clone https://github.com/osm0sis/AnyKernel3 anykernel3
cd anykernel3

# Remove example files
rm -f Image.gz-dtb zImage

# Copy our kernel
cp ../output/Image.gz-dtb .

# Create AnyKernel3 configuration
cp ../templates/anykernel.sh .

# Copy build info
cp ../output/build_info.txt .

# Create the flashable ZIP
ZIP_NAME="Evolution-X-Kernel-KernelSU-SUSFS-${BUILD_DATE}.zip"
zip -r9 "../output/$ZIP_NAME" . -x .git README.md .gitignore

cd ..

echo "✅ AnyKernel3 ZIP created: $ZIP_NAME"

# Create installation instructions
cat > output/INSTALLATION.txt << EOF
Installation Instructions
========================

Method 1 - AnyKernel3 ZIP (Recommended):
1. Download: $ZIP_NAME
2. Boot into TWRP recovery
3. Flash the ZIP file
4. Reboot system
5. Install KernelSU Next manager app

Method 2 - Raw Image (Advanced):
1. Download: Image.gz-dtb
2. Boot into fastboot mode
3. Run: fastboot flash boot Image.gz-dtb
4. Reboot system
5. Install KernelSU Next manager app

Compatibility:
- Evolution-X ROM required
- Android 11-14 supported
- Xiaomi SM6250 devices (miatoll family)

KernelSU Version: $KSU_VERSION
Build Date: $(date)

Support:
- Check build_info.txt for details
- Review build.log for troubleshooting
EOF

echo "📋 Installation instructions created"
echo "🎉 AnyKernel3 creation completed!"

# Clean up
rm -rf anykernel3

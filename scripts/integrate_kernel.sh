#!/bin/bash

# Kernel Integration and Build Script
# This runs inside the Docker container

set -e

echo "🚀 Starting KernelSU Next + SUSFS integration..."
echo "📋 KernelSU Version: $KSU_VERSION"

# Create output directory
mkdir -p /workspace/output

# Navigate to kernel source
cd /workspace/kernel_source

echo "🎯 Integrating KernelSU Next..."
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s "$KSU_VERSION"

echo "🛡️ Integrating SUSFS..."
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s "next-susfs"

echo "⚙️ Applying kernel configuration..."

# Backup original config
cp arch/arm64/configs/vendor/xiaomi/miatoll_defconfig arch/arm64/configs/vendor/xiaomi/miatoll_defconfig.backup

# Apply kernel patches from file
cat /workspace/patches/kernel_config.patch >> arch/arm64/configs/vendor/xiaomi/miatoll_defconfig

echo "🏗️ Building kernel..."
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=EvolutionX-Auto
export KBUILD_BUILD_HOST=GitHub-Actions

# Clean and build
make clean
make mrproper
make miatoll_defconfig
make -j$(nproc) 2>&1 | tee /workspace/output/build.log

# Verify build success
if [ -f "arch/arm64/boot/Image.gz-dtb" ]; then
    echo "✅ Build successful!"
    
    # Copy outputs
    cp arch/arm64/boot/Image.gz-dtb /workspace/output/
    cp .config /workspace/output/kernel.config
    
    # Create build info
    cat > /workspace/output/build_info.txt << EOF
Evolution-X Kernel with KernelSU Next + SUSFS
==============================================

Build Date: $(date)
Kernel Version: $(make kernelversion)
Commit: $(git rev-parse --short HEAD)
KernelSU Version: $KSU_VERSION
SUSFS: Integrated (next-susfs)
Target Device: Xiaomi SM6250 (miatoll family)
ROM: Evolution-X
Builder: GitHub Actions

Supported Devices:
- Redmi Note 9S (miatoll/curtana)
- Redmi Note 9 Pro (miatoll/joyeuse) 
- Redmi Note 9 Pro Max (miatoll/excalibur)
- Poco M2 Pro (miatoll/gram)

Features:
✅ KernelSU Next - Advanced root management
✅ SUSFS - SU hiding filesystem  
✅ Evolution-X optimizations
✅ Built with latest toolchain

Installation:
1. Download the AnyKernel3 ZIP file
2. Boot into TWRP recovery
3. Flash this ZIP (no need to wipe)
4. Reboot system
5. Install KernelSU Next manager app
6. Enjoy!

Warning:
- Requires Evolution-X ROM
- Always backup current boot image
- Use at your own risk
EOF
    
    echo "📦 Kernel build completed successfully!"
else
    echo "❌ Build failed - no kernel image found!"
    exit 1
fi

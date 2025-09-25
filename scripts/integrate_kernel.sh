#!/bin/bash
set -e
# Mark repo as safe for Git
git config --global --add safe.directory /workspace/kernel_source
# Kernel Integration and Build Script
# This runs inside the Docker container

echo "📋 Installing dependencies..."
apt update
apt install -y curl git bc bison flex libssl-dev make

echo "🚀 Starting KernelSU Next + SUSFS integration..."
echo "📋 KernelSU Version: $KSU_VERSION"

# Create output directory
mkdir -p /workspace/output

# Navigate to kernel source
cd /workspace/kernel_source

echo "🎯 Integrating KernelSU Next..."
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s "$KSU_VERSION"

echo "⚙️ Applying kernel configuration..."

# Backup original defconfig
DEFCONFIG_SRC="arch/arm64/configs/vendor/xiaomi/miatoll_defconfig"
DEFCONFIG_DST="arch/arm64/configs/miatoll_defconfig"

if [ ! -f "$DEFCONFIG_SRC" ]; then
    echo "❌ ERROR: Source defconfig not found: $DEFCONFIG_SRC"
    exit 1
fi

cp "$DEFCONFIG_SRC" "${DEFCONFIG_SRC}.backup"

# Apply kernel patches from file
cat /workspace/patches/kernel_config.patch >> "$DEFCONFIG_SRC"

# Copy defconfig to expected location for make
cp "$DEFCONFIG_SRC" "$DEFCONFIG_DST"

echo "🏗️ Building kernel..."
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1)
export CCACHE_EXEC=$(which ccache)
export LLVM_IAS=1
export CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y

export KBUILD_BUILD_USER=EvolutionX-Auto
export KBUILD_BUILD_HOST=GitHub-Actions

# Clean and build
echo "CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y" >> arch/arm64/configs/vendor/xiaomi/miatoll_defconfig
make O=out ARCH=arm64 vendor/xiaomi/miatoll_defconfig vendor/kernelsu.config
yes "" | make O=out ARCH=arm64 olddefconfig

make -j$(nproc --all) O=out \
    ARCH=arm64 \
    CC="ccache clang" \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    LLVM_IAS=1 \
    STRIP=llvm-strip \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CROSS_COMPILE_COMPAT=arm-linux-androidkernel- 2>&1 | tee /workspace/output/build.log

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

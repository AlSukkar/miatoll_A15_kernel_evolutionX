#!/bin/bash

# Usage: ./build.sh <device_codename>

DEVICE_CODENAME=$1
if [ -z "$DEVICE_CODENAME" ]; then
    echo "Error: Device codename not provided"
    exit 1
fi

cd kernel_xiaomi_sm6250

# ==== KernelSU-Next Integration ====
if [ -z "$KSU_NEXT_REF" ]; then
    KSU_NEXT_REF="main"
fi

echo "Integrating KernelSU-Next ($KSU_NEXT_REF)..."

# Run KernelSU-Next setup script
bash KernelSU-Next/kernel/setup.sh -s "$KSU_NEXT_REF"

# Copy config fragment
cp KernelSU-Next/kernel/kernelsu.config arch/arm64/configs/vendor/kernelsu.config

# Ensure option in defconfig
echo "CONFIG_KSU_NEXT=y" >> arch/arm64/configs/vendor/xiaomi/${DEVICE_CODENAME}_defconfig

# ==== Kernel build environment ====
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1)
export CCACHE_EXEC=$(which ccache)
export KBUILD_BUILD_HOST="Caelum-Github-actions"
export LLVM_IAS=1
export CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y

# Configure
make O=out ARCH=arm64 vendor/xiaomi/${DEVICE_CODENAME}_defconfig vendor/kernelsu.config
yes "" | make O=out ARCH=arm64 olddefconfig

# Build
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
    CROSS_COMPILE_ARM32=arm-linux-androideabi-

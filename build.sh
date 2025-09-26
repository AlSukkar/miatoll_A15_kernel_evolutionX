#!/bin/bash

# Always build for miatoll
DEVICE_CODENAME="miatoll"

# Navigate into the kernel source directory
cd kernel_xiaomi_sm6250

# --- PREPARE KERNELSU ---
# Run the setup script to patch the kernel source.
# We run it without arguments because the workflow has already checked out the correct version.
bash KernelSU-Next/kernel/setup.sh

# Copy the generated KernelSU config to the location our make command expects.
cp KernelSU-Next/kernel/kernelsu.config arch/arm64/configs/vendor/kernelsu.config

# --- SET UP BUILD ENVIRONMENT ---
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING=$(clang --version | head -n1)
export CCACHE_EXEC=$(which ccache)
export KBUILD_BUILD_HOST="Caelum-Github"
export LLVM_IAS=1

# --- CONFIGURE KERNEL ---
# 1. CRITICAL: Clean any old, incorrect configuration from the output directory.
make O=out mrproper

# 2. Merge the device config and the KernelSU config to create the final build config.
make O=out ARCH=arm64 vendor/xiaomi/miatoll_defconfig vendor/kernelsu.config

# 3. Finalize the config, accepting defaults for any new options.
yes "" | make O=out ARCH=arm64 olddefconfig

# --- COMPILE KERNEL ---
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

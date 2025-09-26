#!/bin/bash

# Always build for miatoll
DEVICE_CODENAME="miatoll"

# Navigate into the kernel source directory
cd kernel_xiaomi_sm6250

# --- PREPARE KERNELSU ---
# Run the setup script. Its only job is to patch the kernel source files.
# We will ignore any config files it creates and use our own.
bash KernelSU-Next/kernel/setup.sh

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

# 2. Merge your device defconfig and your custom kernelsu.config.
#    This will use the kernelsu.config already present in your repository.
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

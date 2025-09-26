#!/bin/bash

# Always build for miatoll
DEVICE_CODENAME="miatoll"

cd kernel_xiaomi_sm6250

# KernelSU-Next integration
if [ -z "$KSU_NEXT_REF" ]; then
  echo "Error: KSU_NEXT_REF is not set"
  exit 1
fi

echo "Setting up KernelSU-Next version: $KSU_NEXT_REF"
bash KernelSU-Next/kernel/setup.sh -s "$KSU_NEXT_REF"

cp KernelSU-Next/kernel/kernelsu.config arch/arm64/configs/vendor/kernelsu.config

echo "CONFIG_KSU_NEXT=y" >> arch/arm64/configs/vendor/xiaomi/miatoll_defconfig

export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING=$(clang --version | head -n1)
export CCACHE_EXEC=$(which ccache)
export KBUILD_BUILD_HOST="Github-actions"
export LLVM_IAS=1
export CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y
make O=out mrproper
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
    CROSS_COMPILE_ARM32=arm-linux-androideabi-

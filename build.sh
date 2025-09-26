#!/bin/bash

# Always build for miatoll
DEVICE_CODENAME="miatoll"

# Navigate into the kernel source directory
cd kernel_xiaomi_sm6250

# --- PREPARE KERNELSU ---
# Run the setup script to patch the kernel source files.
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

# 2. Manually merge your two config files into a single temporary file. This is the key fix.
cat arch/arm64/configs/vendor/xiaomi/miatoll_defconfig arch/arm64/configs/vendor/kernelsu.config > arch/arm64/configs/merged_defconfig

# 3. Use the SINGLE merged config file to create the build configuration.
make O=out ARCH=arm64 merged_defconfig

# 4. Clean up the temporary merged file.
rm arch/arm64/configs/merged_defconfig

# 5. Finalize the config, accepting defaults for any new options.
yes "" | make O=out ARCH=arm64 olddefconfig

# --- VERIFY CONFIGURATION ---
echo "=========================================="
echo "Verifying Final Kernel Configuration..."
if grep -q "CONFIG_KSU_SUSFS=y" "out/.config"; then
    echo "[SUCCESS] susfs is enabled in the final config."
else
    echo "[FAILURE] susfs is NOT enabled in the final config. Aborting build."
    exit 1
fi
echo "Checking Kernel Name:"
grep "CONFIG_LOCALVERSION" "out/.config"
echo "=========================================="
# --- END VERIFICATION ---


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

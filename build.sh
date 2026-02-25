#!/usr/bin/env bash

# Constants
WORKDIR="$(pwd)"
RELEASE="$(date +v%y.%m.%d)"

KERNEL_NAME="GKID"
USER="ahmed-alnassif"
HOST="GKI-Duchamp"
TIMEZONE="Asia/Damascus"
ANYKERNEL_REPO="https://github.com/ahmed-alnassif/AnyKernel3"

KERNEL_DEFCONFIG="gki_defconfig"

if [ "$KVER" == "6.1" ]; then
  ANYKERNEL_BRANCH="master"
  KERNEL_BRANCH="android14-6.1-staging"
else
  echo "Unsupported kernel existing..."
  exit 1
fi

GKI_RELEASES_REPO="https://github.com/ahmed-alnassif/GKI-Duchamp"
AK3_ZIP_NAME="$KERNEL_NAME-REL-KVER-VARIANT-BUILD_DATE.zip"
OUTDIR="$WORKDIR/out"
KSRC="$WORKDIR/ksrc"
KERNEL_PATCHES="$WORKDIR/kernel-patches"

# Import functions
source $WORKDIR/functions.sh

echo "RELEASE_REPO=$(simplify_gh_url "$GKI_RELEASES_REPO")" >> $GITHUB_ENV
echo "KERNEL_NAME=$KERNEL_NAME" >> $GITHUB_ENV
echo "RELEASE_NAME=$KERNEL_NAME $RELEASE" >> $GITHUB_ENV
echo "RELEASE=$RELEASE" >> $GITHUB_ENV

# Set timezone
sudo timedatectl set-timezone "$TIMEZONE" || export TZ="$TIMEZONE"

# Clone kernel source
log "Cloning kernel source from $(simplify_gh_url "$KERNEL_REPO")"
git clone -q --depth=1 $KERNEL_REPO -b $KERNEL_BRANCH $KSRC

cd $KSRC
LINUX_VERSION=$(make kernelversion)
LINUX_VERSION_CODE=${LINUX_VERSION//./}
DEFCONFIG_FILE=$(find ./arch/arm64/configs -name "$KERNEL_DEFCONFIG")
echo "LINUX_VERSION=$LINUX_VERSION" >> $GITHUB_ENV
cd $WORKDIR

# Set Kernel variant
log "Setting Kernel variant..."
case "$KSU" in
  "yes") VARIANT="SukiSU-Ultra" ;;
  "no") VARIANT="VNL" ;;
esac
susfs_included && VARIANT+="+SuSFS"

# Replace Placeholder in zip name
AK3_ZIP_NAME=${AK3_ZIP_NAME//KVER/$LINUX_VERSION}
AK3_ZIP_NAME=${AK3_ZIP_NAME//VARIANT/$VARIANT}

# Download Clang
log "Downloading Clang..."
CLANG_BIN="$WORKDIR/greenforce-clang/bin"
bash <(wget -qO- https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_clang.sh)
if [ ! -d "$CLANG_BIN" ]; then
    echo "Error: Clang not found in ${CLANG_BIN}."
    exit 1
fi

# Clone GNU Assembler
log "Cloning GNU Assembler..."
GAS_DIR="$WORKDIR/gas"
git clone --depth=1 -q \
  https://android.googlesource.com/platform/prebuilts/gas/linux-x86 \
  -b main \
  "$GAS_DIR"

export PATH="${CLANG_BIN}:${GAS_DIR}:$PATH"

# Extract clang version
COMPILER_STRING=$(clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')
echo "COMPILER_STRING=$COMPILER_STRING" >> $GITHUB_ENV

cd $KSRC

curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s builtin

SUSFS_DIR="$WORKDIR/susfs"
SUSFS_PATCHES="${SUSFS_DIR}/kernel_patches"
SUSFS_BRANCH="gki-android14-6.1"
git clone --depth=1 -q https://gitlab.com/simonpunk/susfs4ksu -b $SUSFS_BRANCH $SUSFS_DIR

cp -R $SUSFS_PATCHES/fs/* ./fs
cp -R $SUSFS_PATCHES/include/linux/* ./include/linux/

patch -p1 --fuzz=3 < $SUSFS_PATCHES/50_add_susfs_in_${SUSFS_BRANCH}.patch || echo "Common kernel SUSFS patch failed."

# Add the stub at the end of susfs.c
cat >> fs/susfs.c << 'EOF'

/* Added for SukiSU compatibility */
void susfs_reorder_mnt_id(void)
{
    /* stub - required by SukiSU's kernel_umount when SUSFS is enabled */
    return;
}
EXPORT_SYMBOL(susfs_reorder_mnt_id);
EOF

SUSFS_VERSION=$(grep -E '^#define SUSFS_VERSION' ./include/linux/susfs.h | cut -d' ' -f3 | sed 's/"//g')

echo "SUSFS_VERSION=$SUSFS_VERSION" >> $GITHUB_ENV

log "Patching custom KSU & SuSFS configs..."
export KSU
export KSU_SUSFS
source $WORKDIR/patches/gki_defconfig.sh

# set localversion
if [ "${TODO:-kernel}" = "kernel" ]; then
  LATEST_COMMIT_HASH=$(git rev-parse --short HEAD)
  if [ "$STATUS" = "BETA" ]; then
    SUFFIX="$LATEST_COMMIT_HASH"
  else
    SUFFIX="${RELEASE}@${LATEST_COMMIT_HASH}"
  fi
  config --set-str CONFIG_LOCALVERSION "-$KERNEL_NAME/$SUFFIX"
  config --disable CONFIG_LOCALVERSION_AUTO
  sed -i 's/echo "+"/# echo "+"/g' scripts/setlocalversion
fi

# Declare needed variables
export KBUILD_BUILD_USER="$USER"
export KBUILD_BUILD_HOST="$HOST"
export KBUILD_BUILD_TIMESTAMP=$(date)
export KCFLAGS="-w"
MAKE_ARGS=(
  LLVM=1
  ARCH=arm64
  CROSS_COMPILE=aarch64-linux-gnu-
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
  -j$(nproc --all)
  O=$OUTDIR
)

KERNEL_IMAGE="$OUTDIR/arch/arm64/boot/Image"
MODULE_SYMVERS="$OUTDIR/Module.symvers"
KMI_CHECK="$WORKDIR/py/kmi-check-6.x.py"

## Build GKI
log "Generating config..."
make ${MAKE_ARGS[@]} "$KERNEL_DEFCONFIG"

# SUSFS debugging
if susfs_included; then

  log "=== DEBUG: Checking defconfig for SUSFS ==="
  grep -i susfs ./arch/arm64/configs/gki_defconfig || echo "❌ SUSFS NOT FOUND in defconfig!"
  echo ""

  # DEBUG: Check if SUSFS made it to .config
  log "=== DEBUG: Checking .config for SUSFS ==="
  grep CONFIG_KSU_SUSFS $OUTDIR/.config || echo "❌ SUSFS NOT ENABLED in .config!"
  grep CONFIG_KSU_SUSFS_SUS_MAP $OUTDIR/.config || echo "❌ SUSFS_SUS_MAP not enabled!"
  echo ""

  # If SUSFS is in defconfig but not in .config, check dependencies
  if grep -q "CONFIG_KSU_SUSFS" ./arch/arm64/configs/gki_defconfig && ! grep -q "CONFIG_KSU_SUSFS=y" $OUTDIR/.config; then
    log "⚠️ SUSFS in defconfig but not in .config - checking dependencies..."
    grep "depends on" $(find . -name "Kconfig" -exec grep -l "KSU_SUSFS" {} \;) 2>/dev/null || echo "No dependency info found"
  fi

fi

# Upload defconfig if we are doing defconfig
if [[ $TODO == "defconfig" ]]; then
  log "Copying defconfig..."
  mkdir -p "$WORKDIR/artifacts"
  cp "$OUTDIR/.config" "$WORKDIR/artifacts/config-${VARIANT}.txt"
  exit 0
fi

# Build the actual kernel
log "Building kernel..."
make ${MAKE_ARGS[@]}

# Check KMI Function symbol
$KMI_CHECK "$KSRC/android/abi_gki_aarch64.stg" "$MODULE_SYMVERS" || true


# Return to the initial working directory (Post-compiling steps))
cd $WORKDIR

# Clone AnyKernel
log "Cloning anykernel from $(simplify_gh_url "$ANYKERNEL_REPO")"
git clone -q --depth=1 $ANYKERNEL_REPO -b $ANYKERNEL_BRANCH anykernel

# Set kernel string in anykernel
if [ $STATUS == "BETA" ]; then
  BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y%m%d-%H%M")
  AK3_ZIP_NAME=${AK3_ZIP_NAME//BUILD_DATE/$BUILD_DATE}
  AK3_ZIP_NAME=${AK3_ZIP_NAME//-REL/}
  sed -i \
    "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${LINUX_VERSION} (${BUILD_DATE}) ${VARIANT}/g" \
    $WORKDIR/anykernel/anykernel.sh
else
  AK3_ZIP_NAME=${AK3_ZIP_NAME//-BUILD_DATE/}
  AK3_ZIP_NAME=${AK3_ZIP_NAME//REL/$RELEASE}
  sed -i \
    "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${RELEASE} ${LINUX_VERSION} ${VARIANT}/g" \
    $WORKDIR/anykernel/anykernel.sh
fi

# Zip the anykernel
cd anykernel
log "Zipping anykernel..."
if [ ! -f "$KERNEL_IMAGE" ];then
  echo "$KERNEL_IMAGE not found."
  exit 1
fi
cp "$KERNEL_IMAGE" .
zip -r9 "$WORKDIR/$AK3_ZIP_NAME" ./*
cd $OLDPWD

if [ "$STATUS" != "BETA" ]; then
  echo "BASE_NAME=$KERNEL_NAME-$VARIANT" >> $GITHUB_ENV
  mkdir -p $WORKDIR/artifacts
  mv $WORKDIR/*.zip $WORKDIR/artifacts
fi

if [ "$STATUS" != "BETA" ]; then
  (
    echo "LINUX_VERSION=$LINUX_VERSION"
    echo "SUSFS_VERSION=$(curl -s https://gitlab.com/simonpunk/susfs4ksu/raw/gki-android14-6.1/kernel_patches/include/linux/susfs.h | grep -E '^#define SUSFS_VERSION' | cut -d' ' -f3 | sed 's/"//g')"
    echo "KERNEL_NAME=$KERNEL_NAME"
    echo "RELEASE_REPO=$(simplify_gh_url "$GKI_RELEASES_REPO")"
  ) >> $WORKDIR/artifacts/info.txt
fi

exit 0

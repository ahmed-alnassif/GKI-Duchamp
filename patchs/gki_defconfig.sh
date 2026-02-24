#!/usr/bin/env bash

# Define target defconfig location
DEFCONFIG="arch/arm64/configs/gki_defconfig"

echo "⚙️ Added KSU & SuSFS configuration"

# Base KSU Config & Dependencies
cat >> $DEFCONFIG <<EOF
# ===============================================
# Konfigurasi KernelSU Base
CONFIG_KSU=y
CONFIG_KPM=y
CONFIG_KSU_MULTI_MANAGER_SUPPORT=y
# Kprobes is a hard dependency for KSU-Next
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
EOF

# Hook method selection logic based on KSU env
if [ "$KSU" == "SukiSU" ]; then
    # SUKISU SPECIAL HANDLING
    if [ "$KSU_SUSFS" = "true" ]; then
        echo "🔧 Mode: SukiSU + SuSFS Enabled"
        cat >> $DEFCONFIG <<EOF
# --- SuSFS Configuration for SukiSU ---
CONFIG_KSU_SUSFS=y
# Let SukiSU handle the hook & mount details internally.
EOF
    else
        echo "🔧 Mode: SukiSU Standard (No SuSFS)"
    fi

elif [ "$KSU_SUSFS" = "true" ]; then
  # LOGIC STANDARD FOR KSU NEXT, REGULAR, RISSU, RKSU
  echo "🔧 Mode: SuSFS Hook Enabled"
  cat >> $DEFCONFIG <<EOF
# --- SuSFS Configuration ---
    CONFIG_KSU_SUSFS=y
    CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
    CONFIG_KSU_SUSFS_SUS_PATH=y
    CONFIG_KSU_SUSFS_SUS_MOUNT=y
    CONFIG_KSU_SUSFS_SUS_KSTAT_SPOOF_GENERIC=y
    CONFIG_KSU_SUSFS_SUS_KSTAT=y
    CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y
    CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y
    CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSTAT=y
    CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n
    CONFIG_KSU_SUSFS_TRY_UMOUNT=n
    CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=n
    CONFIG_KSU_SUSFS_SPOOF_UNAME=y
    CONFIG_KSU_SUSFS_ENABLE_LOG=y
    CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
    CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
    CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
    CONFIG_KSU_MANUAL_HOOK=n
    CONFIG_KSU_HAS_MANUAL_HOOK=n
EOF

else
  # Standard Logic Without Susfs kprobes mode
  echo "🔧 Mode: Kprobes Hook Standard"
  cat >> $DEFCONFIG <<EOF
# --- Kprobes Hook Method ---
# Disable SuSFS and Manual Hook
    CONFIG_KSU_SUSFS=n
    CONFIG_KSU_SUSFS_SUS_SU=n
    CONFIG_KSU_MANUAL_HOOK=n
    CONFIG_KSU_HAS_MANUAL_HOOK=n
    CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=n
    CONFIG_KSU_SYSCALL_HOOK=n
EOF
fi

# --- Universal Performance Tuning Addition ---
echo "⚙️ Adding Universal Performance Tuning"
cat >> $DEFCONFIG <<EOF
# --- Universal Performance Tuning ---
CONFIG_TMPFS_XATTR=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_IP_NF_TARGET_TTL=y
CONFIG_TCP_CONG_ADVANCED=y
CONFIG_TCP_CONG_BBR=y
CONFIG_NET_SCH_FQ=y
CONFIG_DEFAULT_BBR=y
CONFIG_HZ_500=y
CONFIG_HZ=500
CONFIG_CPU_FREQ=y
CONFIG_SWAP=y
CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y
EOF

# --- Additional LTO & Compiler Optimization (5.10 ONLY) ---
if [ "$KVER" == "5.10" ]; then
  echo "⚙️ Added LTO & Compiler Optimization (KVER 5.10 Only)"
  cat >> $DEFCONFIG <<EOF
# --- LTO & Compiler Optimization ---
CONFIG_LTO=y
CONFIG_LTO_CLANG=y
CONFIG_ARCH_SUPPORTS_LTO_CLANG=y
CONFIG_ARCH_SUPPORTS_LTO_CLANG_THIN=y
CONFIG_HAS_LTO_CLANG=y
# CONFIG_LTO_NONE is not set
# CONFIG_LTO_CLANG_FULL is not set
CONFIG_LTO_CLANG_THIN=y
EOF
else
  echo "⚙️ LTO Optimization skipped (For KVER 6.1 & 6.6))"
fi

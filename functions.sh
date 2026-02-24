#!/usr/bin/env bash

# ==============
#    Functions
# ==============

# Telegram functions
# upload_file
upload_file() {
  local FILE="$1"
  local CAPTION="${2:-}"

  if ! [ -f $FILE ]; then
    error "file $FILE doesn't exist"
  fi

  chmod 777 "$FILE"

  curl -s -F "document=@${FILE}" \
    -F "chat_id=${TG_CHAT_ID}" \
    -F "caption=${CAPTION}" \
    -F "parse_mode=markdown" \
    -F "disable_web_page_preview=true" \
    "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendDocument"
}

# send_msg
send_msg() {
  local MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TG_CHAT_ID" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=markdown" \
    -d "text=$MESSAGE"
}

# KernelSU-related functions
install_ksu() {
  local REPO="$1"
  local REF="$2"
  local URL

  if [ -z "$REPO" ] || [ -z "$REF" ]; then
    echo "Usage: install_ksu <user/repo> <ref>"
    exit 1
  fi

  URL="https://raw.githubusercontent.com/$REPO/$REF/kernel/setup.sh"
  log "Installing KernelSU from $REPO | $REF"
  curl -LSs "$URL" | bash -s "$REF"
}

# ksu_included() function
# Type: bool
ksu_included() {
  # LOGIC FIX:
  # Cek variabel input $KSU secara langsung.
  # 1. "yes" (Standard KSU) -> Return True (Masuk blok Standard).
  # 2. "resukisu" -> Return False (Lewati Standard, masuk blok ReSukiSU).
  # 3. "no" (Vanilla) -> Return False (Tidak ada KSU).
  [ "$KSU" == "yes" ]
  return $?
}

# susfs_included() function
# Type: bool
susfs_included() {
  # Return True jika input KSU_SUSFS adalah "true"
  # Ini digunakan oleh build.sh untuk memutuskan apakah akan clone SUSFS (Standard/Manual Fix)
  # atau membiarkan ReSukiSU menangani patchingnya sendiri.
  [ "$KSU_SUSFS" == "true" ]
  return $?
}

# simplify_gh_url <github-repository-url>
simplify_gh_url() {
  local URL="$1"
  echo "$URL" | sed "s|https://github.com/||g" | sed "s|.git||g"
}

# Kernel scripts function
config() {
  $KSRC/scripts/config --file $DEFCONFIG_FILE $@
}

# Logging function
log() {
  echo -e "[LOG] $*"
}

error() {
  local err_txt
  err_txt=$(
    cat << EOF
*Kernel CI*
ERROR: $*
EOF
  )
  echo -e "[ERROR] $*"
  send_msg "$err_txt"
  upload_file "$WORKDIR/build.log"
  exit 1
}

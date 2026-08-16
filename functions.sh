#!/usr/bin/env bash

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
  [ "$KSU" == "yes" ]
  return $?
}

# susfs_included() function
# Type: bool
susfs_included() {
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
  echo -e "[ERROR] $*"
  exit 1
}

retry() {
    local max_attempts=5
    local delay=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi

        echo "Command failed (attempt $attempt/$max_attempts): $*"
        echo "Retrying in ${delay}s..."
        sleep $delay
        delay=$((delay + 1))
        attempt=$((attempt + 1))
    done

    echo "Error: Command failed after $max_attempts attempts: $*" >&2
    return 1
}

curl() { retry command curl "$@"; }
git() { retry command git "$@"; }  
wget() { retry command wget "$@"; }
bash() { retry command bash "$@"; }
export -f retry curl git wget bash

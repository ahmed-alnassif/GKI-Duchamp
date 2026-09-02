#!/usr/bin/env bash

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

ksu_included() {
  [ "$KSU" == "yes" ]
  return $?
}

susfs_included() {
  [ "$KSU_SUSFS" == "true" ]
  return $?
}

simplify_gh_url() {
  local URL="$1"
  echo "$URL" | sed "s|https://github.com/||g" | sed "s|.git||g"
}

config() {
  $KSRC/scripts/config --file $DEFCONFIG_FILE $@
}

log() {
  echo -e "[*] $*"
}

success() {
  echo -e "[+] $*"
}

warning() {
  echo -e "[!] $*"
}

error() {
  echo -e "[-] $*"
}

retry() {
    local max_attempts=5
    local delay=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi

        error "Command failed (attempt $attempt/$max_attempts): $*"
        log "Retrying in ${delay}s..."
        sleep $delay
        delay=$((delay + 1))
        attempt=$((attempt + 1))
    done

    error "Command failed after $max_attempts attempts: $*" >&2
    return 1
}

curl() { retry command curl "$@"; }
git() { retry command git "$@"; }  
wget() { retry command wget "$@"; }
bash() { retry command bash "$@"; }
export -f retry curl git wget bash

apply_susfs_patches() {
    log "Applying SUSFS patches"
    
    cp -R $SUSFS_PATCHES/fs/* ./fs
    cp -R $SUSFS_PATCHES/include/linux/* ./include/linux/
    
    cd $SUSFS_DIR
    patch -p1 --fuzz=3 < "$KERNEL_PATCHES/susfs/susfs_fs_namespace_fix.patch"
    cd $OLDPWD
    
    patch -p1 --fuzz=3 < $SUSFS_PATCHES/50_add_susfs_in_${SUSFS_PATCH}.patch
    
    SUSFS_VERSION=$(grep -E '^#define SUSFS_VERSION' ./include/linux/susfs.h | cut -d' ' -f3 | sed 's/"//g')
    echo "SUSFS_VERSION=$SUSFS_VERSION" >> $GITHUB_ENV
}

clone_susfs() {
	DEPTH=${1:-1}
    if [ ! -d "$SUSFS_DIR" ]; then
        git clone --depth=$DEPTH -q "$SUSFS_URL" -b "$SUSFS_BRANCH" "$SUSFS_DIR"
    fi
}
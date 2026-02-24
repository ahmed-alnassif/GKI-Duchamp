#!/usr/bin/env bash

# slim llvm
SLIM_REPO="https://www.kernel.org/pub/tools/llvm/files/"
# rv clang
RV_REPO="https://api.github.com/repos/Rv-Project/RvClang/releases/latest"
# aosp clang
AOSP_REPO="https://api.github.com/repos/bachnxuan/aosp_clang_mirror/releases/latest"
# yuki clang
YUKI_REPO="https://api.github.com/repos/Klozz/Yuki_clang_releases/releases/latest"
# lilium clang
LILIUM_REPO="https://api.github.com/repos/liliumproject/clang/releases/latest"
# topnotchfreaks clang
TNF_REPO="https://api.github.com/repos/topnotchfreaks/clang/releases/latest"
# neutron clang
NEUTRON_REPO="https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest"
# mandi-sa
MANDISA_REPO="https://api.github.com/repos/Mandi-Sa/clang/releases/latest"
# discussionverse
DV_REPO="https://api.github.com/repos/xaverodumpster/dv_clang/releases/latest"

show_usage() {
  CLANG_NAME="slim, rv, aosp, yuki, lilium, tnf, neutron, mandi-sa"
  echo "Usage: $0 <clang name>"
  echo "clang name: $CLANG_NAME"
}

# get_latest_clang <GH API URL> <GREP EXPR>
# if no grep expr provided then will use .tar.gz as default
get_latest_clang() {
  local url="$1"
  local grp_expr="$2"
  [ -z "$grp_expr" ] && grp_expr=".tar.gz"
  curl -s "$url" | grep "browser_download_url" | grep "$grp_expr" | cut -d '"' -f 4
  return $?
}

case "$1" in
  "slim")
    curl -s "$SLIM_REPO" | grep -oP 'llvm-[\d.]+-x86_64\.tar\.xz' | sort -V | tail -n1 | sed "s|^|$SLIM_REPO|"
    ;;
  "rv")
    get_latest_clang "$RV_REPO"
    ;;
  "aosp")
    get_latest_clang "$AOSP_REPO"
    ;;
  "yuki")
    get_latest_clang "$YUKI_REPO"
    ;;
  "lilium")
    get_latest_clang "$LILIUM_REPO"
    ;;
  "tnf")
    get_latest_clang "$TNF_REPO"
    ;;
  "neutron")
    get_latest_clang "$NEUTRON_REPO" ".tar.zst"
    ;;
  "mandi-sa")
    get_latest_clang "$MANDISA_REPO" ".7z" | tac | head -n1
    ;;
  "dv")
    get_latest_clang "$DV_REPO" ".xz"
    ;;
  *)
    if [ -z $1 ]; then
      show_usage
    else
      echo "Invalid clang name '$1'"
      echo
      show_usage
    fi
    exit 1
    ;;
esac

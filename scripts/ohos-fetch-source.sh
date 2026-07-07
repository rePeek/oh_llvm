set -euo pipefail

BRANCH="${1:-master}"

git config user.name "rePeek"
git config user.email "wangsenyin@huawei.com"

if ! command -v repo >/dev/null 2>&1; then
  echo "error: repo command not found"
  echo "Check .nix-dev/bin/repo or your PATH."
  exit 1
fi

if [ ! -d .repo ]; then
  repo init \
    -u https://gitcode.com/OpenHarmony/manifest.git \
    -b "$BRANCH" \
    --depth=1 \
    -m llvm-toolchain.xml
else
  echo ".repo already exists, skip repo init"
fi

git lfs install
repo sync -c
repo forall -c 'git lfs pull'

# Auto-prepare prebuilts after source sync. Skip when core prebuilts marker exists.
if [ -e "prebuilts/clang/ohos/linux-x86_64/llvm" ]; then
  echo "prebuilts marker exists, skip env_prepare.sh"
else
  bash toolchain/llvm-project/llvm-build/env_prepare.sh
fi

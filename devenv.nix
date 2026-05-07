{ pkgs, ... }:

{
  packages = with pkgs; [
    # shell / POSIX tools
    bash
    coreutils
    just
    python3
    python3Packages.requests

    # source sync tools
    curl
    git
    git-lfs

    # explicit C++/LLVM toolchain for editing and debugging
    clang
    clang-tools
    llvm
    lldb
  ];

  env = {
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
  };

  enterShell = ''
    mkdir -p .devenv/bin

    if [ ! -x .devenv/bin/repo ]; then
      curl -L https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 \
        -o .devenv/bin/repo
      chmod +x .devenv/bin/repo
    fi

    export PATH="$PWD/.devenv/bin:$PATH"

    echo ""
    echo "Helper commands:"
    echo "  ohos-fetch-source [branch]"
    echo "  ohos-clean-out --force"
    echo "  ohos-clean-all --force"
    echo ""
    echo "Build is expected to run in Ubuntu 22.04 docker compose."
  '';

  scripts.ohos-fetch-source.exec = ''
    set -euo pipefail
  
    BRANCH="''${1:-master}"

    git config user.name "rePeek"
    git config user.email "wangsenyin@huawei.com"
  
    if ! command -v repo >/dev/null 2>&1; then
      echo "error: repo command not found"
      echo "Check .devenv/bin/repo or your PATH."
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

    if ! command -v git-lfs >/dev/null 2>&1; then
      echo "error: git-lfs not found in PATH"
      exit 1
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
  '';

  scripts.ohos-env-prepare.exec = ''
    set -euo pipefail

    LLVM_PROJECT="''${LLVM_PROJECT:-toolchain/llvm-project}"

    if [ ! -f "$LLVM_PROJECT/llvm-build/env_prepare.sh" ]; then
      echo "error: cannot find $LLVM_PROJECT/llvm-build/env_prepare.sh"
      echo "Set LLVM_PROJECT=/path/to/llvm-project if your layout is different."
      exit 1
    fi

    bash "$LLVM_PROJECT/llvm-build/env_prepare.sh"
  '';

  scripts.ohos-clean-out.exec = ''
    set -euo pipefail
  
    FORCE="''${1:-}"
  
    if [ "$FORCE" != "--force" ]; then
      echo "This will remove build output directory: out"
      echo "Run with --force to confirm:"
      echo "  clean-out --force"
      exit 1
    fi
  
    rm -rf out
  
    echo "Cleaned build output: out"
  '';

  scripts.ohos-clean-all.exec = ''
    set -euo pipefail

    FORCE="''${1:-}"

    if [ "$FORCE" != "--force" ]; then
      echo "This will remove all source trees synced by repo."
      echo "Run with --force to confirm:"
      echo "  clean-all --force"
      exit 1
    fi

    rm -rf \
      .gn \
      .repo \
      base \
      build \
      download_packages \
      kernel \
      out \
      prebuilts \
      productdefine \
      third_party \
      toolchain

    echo "Purged all repo-synced source code."
  '';
}

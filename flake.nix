{
  description = "OpenHarmony LLVM development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          python = pkgs.python3.withPackages (ps: [
            ps.requests
          ]);

          scriptDefinitions = {
            ohos-fetch-source = {
              runtimeInputs = with pkgs; [
                bash
                git
                git-lfs
              ];
              text = ''
                set -euo pipefail

                BRANCH="''${1:-master}"

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
              '';
            };

            ohos-env-prepare = {
              runtimeInputs = with pkgs; [
                bash
              ];
              text = ''
                set -euo pipefail

                LLVM_PROJECT="''${LLVM_PROJECT:-toolchain/llvm-project}"

                if [ ! -f "$LLVM_PROJECT/llvm-build/env_prepare.sh" ]; then
                  echo "error: cannot find $LLVM_PROJECT/llvm-build/env_prepare.sh"
                  echo "Set LLVM_PROJECT=/path/to/llvm-project if your layout is different."
                  exit 1
                fi

                bash "$LLVM_PROJECT/llvm-build/env_prepare.sh"
              '';
            };

            ohos-clean-out = {
              runtimeInputs = with pkgs; [
                coreutils
              ];
              text = ''
                set -euo pipefail

                FORCE="''${1:-}"

                if [ "$FORCE" != "--force" ]; then
                  echo "This will remove build output directory: out"
                  echo "Run with --force to confirm:"
                  echo "  ohos-clean-out --force"
                  exit 1
                fi

                rm -rf out

                echo "Cleaned build output: out"
              '';
            };

            ohos-clean-all = {
              runtimeInputs = with pkgs; [
                coreutils
              ];
              text = ''
                set -euo pipefail

                FORCE="''${1:-}"

                if [ "$FORCE" != "--force" ]; then
                  echo "This will remove all source trees synced by repo."
                  echo "Run with --force to confirm:"
                  echo "  ohos-clean-all --force"
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
            };
          };

          scriptPackages = pkgs.lib.mapAttrsToList
            (name: script:
              pkgs.writeShellApplication {
                inherit name;
                inherit (script) runtimeInputs text;
              })
            scriptDefinitions;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # shell / POSIX tools
              bash
              coreutils
              just
              python

              # source sync tools
              curl
              git
              git-lfs

              # explicit C++/LLVM toolchain for editing and debugging
              clang
              clang-tools
              llvm
              lldb
              gdb
              heaptrack
            ] ++ scriptPackages;

            LANG = "C.UTF-8";
            LC_ALL = "C.UTF-8";

            shellHook = ''
              mkdir -p .nix-dev/bin

              if [ ! -x .nix-dev/bin/repo ]; then
                curl -L https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 \
                  -o .nix-dev/bin/repo
                chmod +x .nix-dev/bin/repo
              fi

              export PATH="$PWD/.nix-dev/bin:$PATH"

              echo ""
              echo "Helper commands:"
              echo "  ohos-fetch-source [branch]"
              echo "  ohos-env-prepare"
              echo "  ohos-clean-out --force"
              echo "  ohos-clean-all --force"
              echo ""
              echo "Build is expected to run in Ubuntu 22.04 docker compose."
            '';
          };
        });
    };
}

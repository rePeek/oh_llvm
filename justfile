[private]
default:
    @just --list

build-image:
    docker compose build

build-x86:
    rm -rf out
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder bash -lc '\
    PATCH_FILE="/workspace/patch/ohos-buildpy-libedit-fix.patch"; \
    if git -C "/workspace/$LLVM_PROJECT" apply --check "$PATCH_FILE"; then \
      git -C "/workspace/$LLVM_PROJECT" apply "$PATCH_FILE"; \
      echo "Applied patch: $PATCH_FILE"; \
    else \
      echo "Patch already applied or not applicable: $PATCH_FILE"; \
    fi; \
    python3 "$LLVM_PROJECT/llvm-build/build.py" \
      --strip \
      --build-lldb-static \
      --build-ncurses \
      --build-libedit \
      --build-libxml2 \
      --lldb-timeout \
      --compression-format gz \
      --no-strip-libs \
      --build-with-debug-info \
      --enable-lzma-7zip'

build-ohos:    
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder bash -lc '\
    for PATCH_FILE in \
      /workspace/patch/ohos-libedit-fix.patch \
      /workspace/patch/ohos-buildpy-libedit-fix.patch; do \
      if git -C "/workspace/$LLVM_PROJECT" apply --check "$PATCH_FILE"; then \
        git -C "/workspace/$LLVM_PROJECT" apply "$PATCH_FILE"; \
        echo "Applied patch: $PATCH_FILE"; \
      else \
        echo "Patch already applied or not applicable: $PATCH_FILE"; \
      fi; \
    done; \
    python3 "$LLVM_PROJECT/llvm-build/build-ohos-aarch64.py" \
      --strip \
      --build-python \
      --build-ncurses \
      --build-libedit \
      --build-libxml2 \
      --compression-format gz \
      --enable-lzma-7zip'

ninja-install-linux *targets:
    just ninja-install-in llvm_make {{targets}}

ninja-install-windows *targets:
    just ninja-install-in windows-x86_64 {{targets}}

ninja-install-ohos *targets:
    just ninja-install-in ohos-aarch64 {{targets}}

ninja-install-static-lldb:
    just ninja-install-in lib/lldb-server-aarch64-linux-ohos install-lldb-server

[private]
ninja-install-in build_dir *targets:
    docker compose run --rm ohos-llvm-builder bash -lc '\
    set -euo pipefail; \
    cd "/workspace/out/{{build_dir}}"; \
    TARGETS="{{targets}}"; \
    if [ -z "$TARGETS" ]; then TARGETS=install; fi; \
    /workspace/prebuilts/build-tools/linux-x86/bin/ninja $TARGETS'

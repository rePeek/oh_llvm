[private]
default:
    @just --list

build-image:
    docker compose build

build-x86:
    bash -lc 'set -euo pipefail; \
    mkdir -p log; \
    TS=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/build-x86-${TS}.log"; \
    echo "Writing log to $LOG_FILE"; \
    rm -rf out; \
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder bash -lc '\'' \
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
      --enable-lzma-7zip'\'' 2>&1 | tee "$LOG_FILE"'

build-ohos:    
    bash -lc 'set -euo pipefail; \
    mkdir -p log; \
    TS=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/build-ohos-${TS}.log"; \
    echo "Writing log to $LOG_FILE"; \
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder bash -lc '\'' \
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
      --enable-lzma-7zip'\'' 2>&1 | tee "$LOG_FILE"'

lldb-ut:
    bash -lc 'set -o pipefail; \
    mkdir -p log; \
    TIME=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/lldb-ut-${TIME}.log"; \
    echo "Writing log to $LOG_FILE"; \
    docker compose run --rm ohos-llvm-builder bash -lc '\'' \
    set +e; \
    mkdir -p /workspace/out/ffi-compat; \
    if [ ! -e /workspace/out/ffi-compat/libffi.so.6 ]; then \
      ln -s /usr/lib/x86_64-linux-gnu/libffi.so.8 /workspace/out/ffi-compat/libffi.so.6; \
    fi; \
    export LD_LIBRARY_PATH="/workspace/out/ffi-compat:/workspace/out/llvm_make/lib:/workspace/out/llvm_make/lib/x86_64-unknown-linux-gnu:/workspace/out/third_party/libedit/install/linux-x86_64/lib"; \
    dest_path="/workspace/out/llvm_make/tools/lldb/unittests/ScriptInterpreter"; \
    export LLDB_COMMAND_TRACE=YES; \
    if [ ! -d "${dest_path}/python3" ]; then \
      ln -s "/workspace/out/llvm_make/python3" "${dest_path}"; \
    fi; \
    startTime=$(date +%Y%m%d-%H:%M:%S); \
    startTime_s=$(date +%s); \
    echo "test exec start: ${startTime}"; \
    pushd /workspace/out/llvm_make; \
    /workspace/prebuilts/build-tools/linux-x86/bin/ninja -v lldb-unit-test-deps lldb-shell-test-deps lldb-api-test-deps; \
    deps=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/Unit/ --max-time 300; \
    unit=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/Shell/ --max-time 300; \
    shell=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/API/ --max-time 300; \
    api=$?; \
    popd; \
    endTime=$(date +%Y%m%d-%H:%M:%S); \
    endTime_s=$(date +%s); \
    echo "test exec end: ${endTime}, elapsed $((endTime_s - startTime_s))s"; \
    echo "result: deps=${deps}, unit=${unit}, shell=${shell}, api=${api}"; \
    if [ "${deps}" -ne 0 ] || [ "${unit}" -ne 0 ] || [ "${shell}" -ne 0 ] || [ "${api}" -ne 0 ]; then \
      exit 1; \
    fi'\'' 2>&1 | tee "$LOG_FILE"'

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

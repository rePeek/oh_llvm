[private]
default:
    @just --list

build-image:
    docker compose build

build-image-local:
    @echo "No local image build step is needed."

build-x86:
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder \
      bash -lc 'cd /workspace && just build-x86-local'

build-x86-local:
    bash -lc 'set -euo pipefail; \
    WORKSPACE="$PWD"; \
    LLVM_PROJECT="${LLVM_PROJECT:-toolchain/llvm-project}"; \
    mkdir -p log; \
    TS=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/build-x86-local-${TS}.log"; \
    echo "Writing log to $LOG_FILE"; \
    exec > >(tee "$LOG_FILE") 2>&1; \
    rm -rf out; \
    for PATCH_FILE in \
      "$WORKSPACE/patch/ohos-buildpy-libedit-fix.patch" \
      "$WORKSPACE/patch/ohos-llvm-project-local-changes.patch"; do \
      if git -C "$WORKSPACE/$LLVM_PROJECT" apply --check "$PATCH_FILE"; then \
        git -C "$WORKSPACE/$LLVM_PROJECT" apply "$PATCH_FILE"; \
        echo "Applied patch: $PATCH_FILE"; \
      else \
        echo "Patch already applied or not applicable: $PATCH_FILE"; \
      fi; \
    done; \
    python3 "$WORKSPACE/$LLVM_PROJECT/llvm-build/build.py" \
      --strip \
      --build-lldb-static \
      --build-ncurses \
      --build-libedit \
      --build-libxml2 \
      --lldb-timeout \
      --compression-format gz \
      --no-strip-libs \
      --build-with-debug-info \
      --parallel-link-jobs 4 \
      --enable-lzma-7zip'

build-x86-debug:
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder \
      bash -lc 'cd /workspace && just build-x86-debug-local'

build-x86-debug-local:
    bash -lc 'set -euo pipefail; \
    WORKSPACE="$PWD"; \
    LLVM_PROJECT="${LLVM_PROJECT:-toolchain/llvm-project}"; \
    mkdir -p log; \
    TS=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/build-x86-debug-local-${TS}.log"; \
    echo "Writing log to $LOG_FILE"; \
    exec > >(tee "$LOG_FILE") 2>&1; \
    rm -rf out; \
    for PATCH_FILE in \
      "$WORKSPACE/patch/ohos-buildpy-libedit-fix.patch" \
      "$WORKSPACE/patch/ohos-llvm-project-local-changes.patch"; do \
      if git -C "$WORKSPACE/$LLVM_PROJECT" apply --check "$PATCH_FILE"; then \
        git -C "$WORKSPACE/$LLVM_PROJECT" apply "$PATCH_FILE"; \
        echo "Applied patch: $PATCH_FILE"; \
      else \
        echo "Patch already applied or not applicable: $PATCH_FILE"; \
      fi; \
    done; \
    LLVM_ROOT="$WORKSPACE/$LLVM_PROJECT/llvm"; \
    OUT_DIR="$WORKSPACE/out/llvm_make"; \
    INSTALL_DIR="$WORKSPACE/out/llvm-install"; \
    CLANG_DIR="$WORKSPACE/prebuilts/clang/ohos/linux-x86_64/clang-15.0.4"; \
    PYTHON_DIR="$WORKSPACE/prebuilts/python3/linux-x86/3.12.10"; \
    CMAKE_BIN="$WORKSPACE/prebuilts/cmake/linux-x86/bin/cmake"; \
    NINJA_BIN="$WORKSPACE/prebuilts/build-tools/linux-x86/bin/ninja"; \
    SWIG_BIN="${SWIG_EXECUTABLE:-/usr/bin/swig}"; \
    LINKER_FLAGS="-fuse-ld=lld -L$CLANG_DIR/lib -l:libunwind.a -l:libc++abi.a --rtlib=compiler-rt -stdlib=libc++ -static-libstdc++ -Wl,-z,relro,-z,now -pie -Wl,-z,noexecstack"; \
    mkdir -p "$OUT_DIR" "$INSTALL_DIR"; \
    ln -sfn "../../prebuilts/python3/linux-x86/3.12.10" "$OUT_DIR/python3"; \
    "$CMAKE_BIN" -G Ninja \
      -S "$LLVM_ROOT" \
      -B "$OUT_DIR" \
      -DCMAKE_MAKE_PROGRAM="$NINJA_BIN" \
      -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      -DLLVM_ENABLE_PROJECTS="clang;lldb" \
      -DLLVM_ENABLE_RUNTIMES="" \
      -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;BPF;Mips;RISCV;X86;LoongArch" \
      -DLLVM_ENABLE_ASSERTIONS=OFF \
      -DLLVM_ENABLE_BINDINGS=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_THREADS=ON \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_ENABLE_LIBCXX=ON \
      -DLLVM_ENABLE_LLD=ON \
      -DCLANG_VENDOR="OHOS (dev) " \
      -DCLANG_BUILD_EXAMPLES=OFF \
      -DCMAKE_C_COMPILER="$CLANG_DIR/bin/clang" \
      -DCMAKE_CXX_COMPILER="$CLANG_DIR/bin/clang++" \
      -DCMAKE_AR="$CLANG_DIR/bin/llvm-ar" \
      -DCMAKE_RANLIB="$CLANG_DIR/bin/llvm-ranlib" \
      -DCMAKE_LINKER="$CLANG_DIR/bin/ld.lld" \
      -DCMAKE_ASM_FLAGS="-fstack-protector-strong" \
      -DCMAKE_C_FLAGS="-fstack-protector-strong" \
      -DCMAKE_CXX_FLAGS="-fstack-protector-strong -stdlib=libc++" \
      -DCMAKE_EXE_LINKER_FLAGS="$LINKER_FLAGS" \
      -DCMAKE_SHARED_LINKER_FLAGS="$LINKER_FLAGS" \
      -DCMAKE_MODULE_LINKER_FLAGS="$LINKER_FLAGS" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DPython3_EXECUTABLE="$PYTHON_DIR/bin/python3" \
      -DPython3_INCLUDE_DIRS="$PYTHON_DIR/include/python3.12" \
      -DPython3_LIBRARIES="$PYTHON_DIR/lib/libpython3.12.so" \
      -DPython3_RPATH="\$ORIGIN/../python3/lib" \
      -DLLDB_ENABLE_PYTHON=ON \
      -DLLDB_EMBED_PYTHON_HOME=ON \
      -DLLDB_PYTHON_HOME="../python3" \
      -DLLDB_PYTHON_RELATIVE_PATH="bin/python/lib/python3.12" \
      -DLLDB_PYTHON_EXE_RELATIVE_PATH="bin/python3" \
      -DLLDB_ENABLE_LIBEDIT=OFF \
      -DLLDB_ENABLE_CURSES=OFF \
      -DLLDB_ENABLE_LIBXML2=OFF \
      -DSWIG_EXECUTABLE="$SWIG_BIN"; \
    "$NINJA_BIN" -C "$OUT_DIR" lldb'

build-ohos:
    docker compose run --rm -e LLVM_PROJECT=toolchain/llvm-project ohos-llvm-builder \
      bash -lc 'cd /workspace && just build-ohos-local'

build-ohos-local:
    bash -lc 'set -euo pipefail; \
    WORKSPACE="$PWD"; \
    LLVM_PROJECT="${LLVM_PROJECT:-toolchain/llvm-project}"; \
    mkdir -p log; \
    TS=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/build-ohos-local-${TS}.log"; \
    echo "Writing log to $LOG_FILE"; \
    exec > >(tee "$LOG_FILE") 2>&1; \
    for PATCH_FILE in \
      "$WORKSPACE/patch/ohos-libedit-fix.patch" \
      "$WORKSPACE/patch/ohos-buildpy-libedit-fix.patch"; do \
      if git -C "$WORKSPACE/$LLVM_PROJECT" apply --check "$PATCH_FILE"; then \
        git -C "$WORKSPACE/$LLVM_PROJECT" apply "$PATCH_FILE"; \
        echo "Applied patch: $PATCH_FILE"; \
      else \
        echo "Patch already applied or not applicable: $PATCH_FILE"; \
      fi; \
    done; \
    python3 "$WORKSPACE/$LLVM_PROJECT/llvm-build/build-ohos-aarch64.py" \
      --strip \
      --build-python \
      --build-ncurses \
      --build-libedit \
      --build-libxml2 \
      --compression-format gz \
      --enable-lzma-7zip'

lldb-ut:
    docker compose run --rm ohos-llvm-builder \
      bash -lc 'cd /workspace && just lldb-ut-local'

lldb-ut-local:
    bash -lc 'set -o pipefail; \
    WORKSPACE="$PWD"; \
    mkdir -p log; \
    TIME=$(date +%Y%m%d-%H%M%S); \
    LOG_FILE="log/lldb-ut-local-${TIME}.log"; \
    echo "Writing log to $LOG_FILE"; \
    exec > >(tee "$LOG_FILE") 2>&1; \
    set +e; \
    mkdir -p "$WORKSPACE/out/ffi-compat"; \
    if [ ! -e "$WORKSPACE/out/ffi-compat/libffi.so.6" ] && [ -e /usr/lib/x86_64-linux-gnu/libffi.so.8 ]; then \
      ln -s /usr/lib/x86_64-linux-gnu/libffi.so.8 "$WORKSPACE/out/ffi-compat/libffi.so.6"; \
    fi; \
    export LD_LIBRARY_PATH="$WORKSPACE/out/ffi-compat:$WORKSPACE/out/llvm_make/lib:$WORKSPACE/out/llvm_make/lib/x86_64-unknown-linux-gnu:$WORKSPACE/out/third_party/libedit/install/linux-x86_64/lib"; \
    DEST_PATH="$WORKSPACE/out/llvm_make/tools/lldb/unittests/ScriptInterpreter"; \
    export LLDB_COMMAND_TRACE=YES; \
    if [ ! -d "${DEST_PATH}/python3" ]; then \
      ln -s "$WORKSPACE/out/llvm_make/python3" "${DEST_PATH}"; \
    fi; \
    START_TIME=$(date +%Y%m%d-%H:%M:%S); \
    START_TIME_S=$(date +%s); \
    echo "test exec start: ${START_TIME}"; \
    pushd "$WORKSPACE/out/llvm_make"; \
    "$WORKSPACE/prebuilts/build-tools/linux-x86/bin/ninja" -v lldb-unit-test-deps lldb-shell-test-deps lldb-api-test-deps; \
    DEPS=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/Unit/ --max-time 300; \
    UNIT=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/Shell/ --max-time 300; \
    SHELL=$?; \
    ./bin/llvm-lit -sv tools/lldb/test/API/ --max-time 300; \
    API=$?; \
    popd; \
    END_TIME=$(date +%Y%m%d-%H:%M:%S); \
    END_TIME_S=$(date +%s); \
    echo "test exec end: ${END_TIME}, elapsed $((END_TIME_S - START_TIME_S))s"; \
    echo "result: deps=${DEPS}, unit=${UNIT}, shell=${SHELL}, api=${API}"; \
    if [ "${DEPS}" -ne 0 ] || [ "${UNIT}" -ne 0 ] || [ "${SHELL}" -ne 0 ] || [ "${API}" -ne 0 ]; then \
      exit 1; \
    fi'

ninja-install-linux *targets:
    docker compose run --rm ohos-llvm-builder \
      bash -lc 'cd /workspace && just ninja-install-linux-local {{targets}}'

ninja-install-linux-local *targets:
    just ninja-install-in-local llvm_make {{targets}}

ninja-install-windows *targets:
    docker compose run --rm ohos-llvm-builder \
      bash -lc 'cd /workspace && just ninja-install-windows-local {{targets}}'

ninja-install-windows-local *targets:
    just ninja-install-in-local windows-x86_64 {{targets}}

ninja-install-ohos *targets:
    docker compose run --rm ohos-llvm-builder \
      bash -lc 'cd /workspace && just ninja-install-ohos-local {{targets}}'

ninja-install-ohos-local *targets:
    just ninja-install-in-local ohos-aarch64 {{targets}}

ninja-install-static-lldb:
    docker compose run --rm ohos-llvm-builder \
      bash -lc 'cd /workspace && just ninja-install-static-lldb-local'

ninja-install-static-lldb-local:
    just ninja-install-in-local lib/lldb-server-aarch64-linux-ohos install-lldb-server

[private]
ninja-install-in-local build_dir *targets:
    bash -lc 'set -euo pipefail; \
    WORKSPACE="$PWD"; \
    cd "$WORKSPACE/out/{{build_dir}}"; \
    if [ -z "{{targets}}" ]; then \
      "$WORKSPACE/prebuilts/build-tools/linux-x86/bin/ninja" install; \
    else \
      "$WORKSPACE/prebuilts/build-tools/linux-x86/bin/ninja" {{targets}}; \
    fi'

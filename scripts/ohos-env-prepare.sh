set -euo pipefail

LLVM_PROJECT="${LLVM_PROJECT:-toolchain/llvm-project}"

if [ ! -f "$LLVM_PROJECT/llvm-build/env_prepare.sh" ]; then
  echo "error: cannot find $LLVM_PROJECT/llvm-build/env_prepare.sh"
  echo "Set LLVM_PROJECT=/path/to/llvm-project if your layout is different."
  exit 1
fi

bash "$LLVM_PROJECT/llvm-build/env_prepare.sh"

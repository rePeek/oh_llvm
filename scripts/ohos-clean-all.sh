set -euo pipefail

FORCE="${1:-}"

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

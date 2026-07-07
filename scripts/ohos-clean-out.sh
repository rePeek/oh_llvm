set -euo pipefail

FORCE="${1:-}"

if [ "$FORCE" != "--force" ]; then
  echo "This will remove build output directory: out"
  echo "Run with --force to confirm:"
  echo "  ohos-clean-out --force"
  exit 1
fi

rm -rf out

echo "Cleaned build output: out"

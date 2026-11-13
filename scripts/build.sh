#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build}"

if [ ! -d PocSandbox.xcworkspace ]; then
  "$ROOT_DIR/scripts/generate.sh"
fi

echo "==> Compilando PocSandbox ($CONFIGURATION, simulador: $SIMULATOR_NAME)"
xcodebuild \
  -workspace PocSandbox.xcworkspace \
  -scheme PocSandbox \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

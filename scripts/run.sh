#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
CONFIGURATION="${CONFIGURATION:-Debug}"
BUNDLE_ID="${BUNDLE_ID:-com.example.PocSandbox}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build}"

"$ROOT_DIR/scripts/build.sh"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphonesimulator/PocSandbox.app"
if [ ! -d "$APP_PATH" ]; then
  echo "error: app não encontrado em $APP_PATH" >&2
  exit 1
fi

echo "==> Iniciando simulador $SIMULATOR_NAME"
xcrun simctl boot "$SIMULATOR_NAME" >/dev/null 2>&1 || true
open -a Simulator

for _ in $(seq 1 60); do
  if xcrun simctl list devices | grep -q "$SIMULATOR_NAME (.*) (Booted)"; then
    break
  fi
  sleep 1
done

echo "==> Instalando e executando $BUNDLE_ID"
xcrun simctl install "$SIMULATOR_NAME" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_NAME" "$BUNDLE_ID"

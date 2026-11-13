#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen não encontrado. Instale com: brew install xcodegen" >&2
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "error: CocoaPods não encontrado. Instale com: brew install cocoapods" >&2
  exit 1
fi

echo "==> Gerando PocSandbox.xcodeproj a partir de project.yml"
xcodegen generate

echo "==> Instalando pods"
pod install

echo "==> Pronto. Abra PocSandbox.xcworkspace"

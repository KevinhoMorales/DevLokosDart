#!/bin/bash
# IMPORTANTE: Ejecuta en Terminal.app (no en Cursor) - pod install hace timeout en Cursor.
# Ejecuta antes de SweetPad Launch o Product → Archive.

set -e
cd "$(dirname "$0")/.."

echo "→ flutter pub get"
flutter pub get

echo "→ cd ios && pod install (puede tardar 2-5 min)"
cd ios && pod install

echo ""
echo "✓ Listo."
echo "  - SweetPad: Launch desde Cursor"
echo "  - Archive: open ios/Runner.xcworkspace"
echo "    Product → Destination: Any iOS Device → Product → Archive"

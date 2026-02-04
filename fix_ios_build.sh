#!/bin/bash
# Script para corregir el build de iOS (sandbox/Podfile.lock + pods)
# EJECUTAR EN TERMINAL.app (no en Cursor): evita timeouts en pod install
# Uso: chmod +x fix_ios_build.sh && ./fix_ios_build.sh

set -e
cd "$(dirname "$0")"

echo "1/5 Limpiando DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true

echo "2/5 Flutter clean..."
flutter clean

echo "3/5 Flutter pub get..."
flutter pub get

echo "4/5 Eliminando Pods anteriores..."
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks 2>/dev/null || true

echo "5/5 Ejecutando pod install (5-10 min la primera vez, descarga BoringSSL-GRPC)..."
cd ios && pod install
cd ..

echo ""
echo "✅ Listo. Ahora:"
echo "   • SweetPad: Launch"
echo "   • o: flutter run"
echo "   • o: abrir ios/Runner.xcworkspace en Xcode"

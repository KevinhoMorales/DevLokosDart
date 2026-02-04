#!/bin/bash
# Corrige el error "Unable to load contents of file list" (Target Support Files vacíos).
# EJECUTAR EN Terminal.app - NO en Cursor (pod install hace timeout).

cd "$(dirname "$0")"

echo "1. flutter pub get"
flutter pub get

echo ""
echo "2. cd ios && pod install"
cd ios && pod install

echo ""
echo "✓ Listo. Prueba SweetPad: Launch de nuevo."

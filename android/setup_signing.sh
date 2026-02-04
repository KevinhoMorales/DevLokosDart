#!/bin/bash
# Configura key.properties para firma release.
# Ejecuta: cd android && ./setup_signing.sh

echo "Configuración de firma para DevLokos"
echo "Keystore: ../Keystore/DevLokosKS.jks"
echo ""

read -sp "Store password: " STORE_PW
echo ""
read -sp "Key password: " KEY_PW
echo ""
read -p "Key alias (ej: upload, key0): " KEY_ALIAS

cat > key.properties << EOF
storePassword=$STORE_PW
keyPassword=$KEY_PW
keyAlias=$KEY_ALIAS
storeFile=../../Keystore/DevLokosKS.jks
EOF

echo ""
echo "✓ key.properties creado. Ejecuta: flutter build appbundle --release"

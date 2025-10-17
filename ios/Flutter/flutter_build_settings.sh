#!/bin/bash

# Fix for unsupported option '-G' error in Xcode 26+
export FLUTTER_BUILD_MODE=debug
export FLUTTER_BUILD_DIR=build
export FLUTTER_ENGINE_VERSION=672c59cfa87c8070c20ba2cd1a6c2a1baf5cf08b

# Disable problematic compiler flags
export CC="clang"
export CXX="clang++"

# Set iOS deployment target
export IPHONEOS_DEPLOYMENT_TARGET=14.0

echo "Flutter build settings configured for iOS"


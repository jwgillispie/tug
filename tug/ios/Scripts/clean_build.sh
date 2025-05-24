#!/bin/bash

# Clean Flutter build artifacts
echo "Cleaning Flutter build artifacts..."
cd "$SRCROOT/.."
flutter clean
flutter pub get

# Clean iOS specific files
echo "Cleaning iOS build files..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
pod deintegrate
pod install --repo-update

echo "Build preparation complete!"
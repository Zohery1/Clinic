#!/bin/bash
echo "Downloading Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter Doctor:"
flutter doctor -v

echo "Cleaning project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release

echo "Build finished successfully!"

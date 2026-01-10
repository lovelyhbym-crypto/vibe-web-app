#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Vercel Build Script..."

# Define Flutter path
FLUTTER_PATH="$VERCEL_PATH/flutter"

# Check if Flutter is already installed in the Vercel cache
if [ -d "$FLUTTER_PATH" ]; then
    echo "Flutter found in cache."
else
    echo "Flutter not found. Cloning stable branch..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_PATH"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_PATH/bin:$PATH"

# Run Flutter doctor to complete installation and check for issues
echo "Running flutter doctor..."
flutter doctor

# Enable web support (just in case, though usually enabled by default on stable)
flutter config --enable-web

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Build the web application
echo "Building Flutter Web application..."
# Using --release for optimized build
# --web-renderer auto selects appropriate renderer (HTML vs CanvasKit)
flutter build web --release

echo "Build completed successfully!"

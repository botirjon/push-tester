#!/bin/bash

#
# Build script for PushTester
# Creates a DMG file for distribution (includes GUI app and CLI tool)
#

set -e

# Configuration
APP_NAME="PushTester"
CLI_NAME="pushtester"
SCHEME="PushTester"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build CLI tool
echo "🔨 Building CLI tool (${CLI_NAME})..."
cd "${PROJECT_DIR}"
swift build -c release

# Copy CLI binary
CLI_BINARY="${PROJECT_DIR}/.build/release/${CLI_NAME}"
if [ -f "${CLI_BINARY}" ]; then
    cp "${CLI_BINARY}" "${BUILD_DIR}/"
    echo "✓ CLI built: ${BUILD_DIR}/${CLI_NAME}"
else
    echo "⚠️  CLI binary not found, skipping..."
fi

# Build and archive macOS app
echo "🔨 Building ${APP_NAME} app..."
xcodebuild -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
echo "📦 Exporting app..."
mkdir -p "${EXPORT_PATH}"

# Copy the app from the archive
cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"

# Create DMG
echo "💿 Creating DMG..."

# Create a temporary directory for DMG contents
DMG_TEMP="${BUILD_DIR}/dmg_temp"
mkdir -p "${DMG_TEMP}"

# Copy app to temp directory
cp -R "${EXPORT_PATH}/${APP_NAME}.app" "${DMG_TEMP}/"

# Copy CLI binary if it exists
if [ -f "${BUILD_DIR}/${CLI_NAME}" ]; then
    cp "${BUILD_DIR}/${CLI_NAME}" "${DMG_TEMP}/"
fi

# Create symbolic link to Applications folder
ln -s /Applications "${DMG_TEMP}/Applications"

# Create the DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Clean up temp directory
rm -rf "${DMG_TEMP}"

echo ""
echo "✅ Build complete!"
echo "📍 DMG location: ${DMG_PATH}"
echo "📍 CLI location: ${BUILD_DIR}/${CLI_NAME}"
echo ""
echo "To install the app:"
echo "  1. Open the DMG"
echo "  2. Drag ${APP_NAME} to Applications"
echo "  3. Right-click the app → Open (first time only)"
echo ""
echo "To install the CLI:"
echo "  sudo cp ${BUILD_DIR}/${CLI_NAME} /usr/local/bin/"
echo "  # or"
echo "  cp ${BUILD_DIR}/${CLI_NAME} ~/.local/bin/"

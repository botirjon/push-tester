#!/bin/bash

#
# Build script for PushTester
# Creates a DMG file for distribution
#

set -e

# Configuration
APP_NAME="PushTester"
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

# Build and archive
echo "🔨 Building ${APP_NAME}..."
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
echo ""
echo "To install:"
echo "  1. Open the DMG"
echo "  2. Drag ${APP_NAME} to Applications"
echo "  3. Right-click the app → Open (first time only)"

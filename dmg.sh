#!/bin/bash
set -e

VERSION="1.0.0"
APP_NAME="BatteryRank"
DMG_NAME="${APP_NAME}-${VERSION}"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_NAME}.app/Contents/MacOS/"

cat > "${APP_NAME}.app/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BatteryRank</string>
    <key>CFBundleIdentifier</key>
    <string>com.batteryrank.app</string>
    <key>CFBundleName</key>
    <string>BatteryRank</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
PLIST

echo "Creating DMG..."
rm -f "${DMG_NAME}.dmg"

if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 200 \
        --app-drop-link 450 200 \
        --hide-extension "${APP_NAME}.app" \
        "${DMG_NAME}.dmg" \
        "${APP_NAME}.app/"
else
    echo "create-dmg not found, using hdiutil..."
    TMP_DIR=$(mktemp -d)
    cp -R "${APP_NAME}.app" "${TMP_DIR}/"
    ln -s /Applications "${TMP_DIR}/Applications"
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${TMP_DIR}" \
        -ov -format UDZO \
        "${DMG_NAME}.dmg"
    rm -rf "${TMP_DIR}"
fi

echo "Done! DMG: ${DMG_NAME}.dmg"

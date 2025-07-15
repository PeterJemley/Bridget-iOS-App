#!/bin/bash

set -e

SCHEME="Bridget"
APP_NAME="Bridget"
DEVICE_NAME="iPhone 16 Pro"

# 1. Find your device UDID
echo "Finding UDID for device named '$DEVICE_NAME'..."
DEVICE_UDID=$(xcrun xctrace list devices | grep "$DEVICE_NAME (" | head -n1 | sed -E 's/.*\[(.*)\].*/\1/')
if [ -z "$DEVICE_UDID" ]; then
  echo "Could not find device named '$DEVICE_NAME'. Is it connected and trusted?"
  exit 1
fi
echo "Found device UDID: $DEVICE_UDID"

# 2. Build for device
echo "Building $SCHEME for device $DEVICE_NAME ($DEVICE_UDID)..."
xcodebuild -scheme "$SCHEME" -destination "id=$DEVICE_UDID" clean build | tee build.log | cat

# 3. Find the .app bundle in DerivedData
DERIVED_DATA=$(mdfind "kMDItemCFBundleIdentifier == 'com.yourcompany.$APP_NAME'" | grep DerivedData | head -n1 | xargs dirname 2>/dev/null)
if [ -z "$DERIVED_DATA" ]; then
  DERIVED_DATA=~/Library/Developer/Xcode/DerivedData
fi
APP_PATH=$(find "$DERIVED_DATA" -type d -name "$APP_NAME.app" | grep -m1 "Release-iphoneos")
if [ -z "$APP_PATH" ]; then
  APP_PATH=$(find "$DERIVED_DATA" -type d -name "$APP_NAME.app" | grep -m1 "Debug-iphoneos")
fi
if [ -z "$APP_PATH" ]; then
  echo "Could not find $APP_NAME.app in DerivedData. Please check your build."
  exit 1
fi
echo "Found app at: $APP_PATH"

# 4. Launch Instruments with Time Profiler
echo "Launching Instruments with Time Profiler..."
open -a "Instruments" -g --args -t "Time Profiler" -w "$DEVICE_UDID" "$APP_PATH" 
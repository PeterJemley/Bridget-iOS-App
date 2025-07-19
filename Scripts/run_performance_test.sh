#!/bin/bash

# Performance Testing Script for Bridget
# This script runs the app on the iPhone 16 Pro simulator and begins performance profiling

set -e

echo "🚀 Bridget Performance Testing - Phase 1.1"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "Bridget.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: This script must be run from the Bridget project root directory"
    exit 1
fi

echo "✅ Project structure verified"
echo ""

# Check if PerformanceMeasurement.swift exists
if [ ! -f "Bridget/PerformanceMeasurement.swift" ]; then
    echo "❌ Error: PerformanceMeasurement.swift not found"
    echo "Please ensure the performance measurement utility is created"
    exit 1
fi

echo "✅ Performance measurement utility found"
echo ""

# Build the project first
echo "🔨 Building project for iPhone 16 Pro simulator..."
xcodebuild -project Bridget.xcodeproj -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "📱 Launching app on iPhone 16 Pro simulator..."
echo ""

# Launch the app on simulator
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
xcrun simctl install "iPhone 16 Pro" "$(xcodebuild -project Bridget.xcodeproj -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -showBuildSettings | grep -m 1 "BUILT_PRODUCTS_DIR" | cut -d "=" -f 2 | tr -d " ")/Bridget.app"
xcrun simctl launch "iPhone 16 Pro" com.peterjemley.Bridget

echo ""
echo "🎯 Performance Testing Started!"
echo "=============================="
echo ""
echo "The app is now running on the iPhone 16 Pro simulator."
echo ""
echo "📊 Performance measurements are being logged to the console."
echo ""
echo "🔍 TO VIEW PERFORMANCE LOGS:"
echo "   1. Open Xcode"
echo "   2. Go to Window > Devices and Simulators"
echo "   3. Select 'iPhone 16 Pro' simulator"
echo "   4. Click 'Open Console' button"
echo "   5. Look for logs starting with '[PERF]'"
echo ""
echo "   OR use this command in another terminal:"
echo "   xcrun simctl spawn booted log stream --predicate 'process == \"Bridget\"'"
echo ""
echo "📋 What to observe:"
echo "   1. App launch speed (target: < 2.0s cold launch)"
echo "   2. Initial data loading (target: < 3.0s for first fetch)"
echo "   3. Memory usage patterns"
echo "   4. UI responsiveness during loading"
echo "   5. Statistical analysis completion time"
echo ""
echo "⏱️  Test duration: 2-3 minutes for complete performance profile"
echo ""
echo "Press Enter to open the simulator console in a new terminal window..."
read -r

# Open simulator console in new terminal
osascript -e 'tell application "Terminal" to do script "xcrun simctl spawn booted log stream --predicate \"process == \\\"Bridget\\\"\" | grep -E \"(\\[PERF\\]|📊|🔄)\""'

echo ""
echo "✅ Console monitoring started in new terminal window"
echo "The performance logs will now be visible in real-time"
echo ""
echo "Press Ctrl+C to stop monitoring when testing is complete"
echo ""

# Keep the script running to monitor the app
echo "Monitoring app performance..."
echo "Check the new terminal window for detailed performance logs"
echo ""

# Wait for user to stop the test
trap 'echo ""; echo "✅ Performance testing completed"; echo "Check the console output for performance measurements"; exit 0' INT

# Keep the script alive
while true; do
    sleep 1
done 
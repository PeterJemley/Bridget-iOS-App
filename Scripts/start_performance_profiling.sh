#!/bin/bash

# Performance Profiling Setup Script for Bridget
# This script helps set up and begin the performance profiling phase

set -e

echo "🚀 Bridget Performance Profiling Setup"
echo "======================================"
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

# Check if performance profiling plan exists
if [ ! -f "Bridget Documentation/PERFORMANCE_PROFILING_PLAN.md" ]; then
    echo "❌ Error: PERFORMANCE_PROFILING_PLAN.md not found"
    echo "Please ensure the performance profiling plan is created"
    exit 1
fi

echo "✅ Performance profiling plan found"
echo ""

# Build the project to ensure everything compiles
echo "🔨 Building project to verify compilation..."
xcodebuild -project Bridget.xcodeproj -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

if [ $? -eq 0 ]; then
    echo "✅ Project builds successfully"
else
    echo "❌ Build failed. Please fix compilation errors before proceeding"
    exit 1
fi

echo ""
echo "📋 Performance Profiling Setup Complete!"
echo "========================================"
echo ""
echo "Next Steps:"
echo "1. Open Xcode and run the app in the iPhone 16 Pro simulator"
echo "2. Check the console for performance measurement output"
echo "3. Begin Phase 1.1: App Launch Performance Measurement"
echo "4. Follow the PERFORMANCE_PROFILING_PLAN.md for detailed steps"
echo ""
echo "Key Files:"
echo "- Bridget/PerformanceMeasurement.swift (measurement utility)"
echo "- Bridget Documentation/PERFORMANCE_PROFILING_PLAN.md (detailed plan)"
echo "- Bridget Documentation/NEXT_STEPS_TODO.md (updated tasks)"
echo ""
echo "Performance Targets:"
echo "- App Launch: < 2.0s cold, < 1.0s warm, < 0.5s hot"
echo "- SwiftData: < 100ms bridge query, < 200ms event query"
echo "- Network: < 1.0s API response, > 80% cache hit ratio"
echo "- UI: > 55 FPS scrolling, < 30MB UI memory"
echo ""
echo "Ready to begin performance profiling! 🎯" 
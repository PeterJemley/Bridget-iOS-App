#!/bin/bash
# Script to delete the Bridget app from all BOOTED iOS simulators when Xcode stops or for manual use in Cursor's terminal
# Usage: Hook this script to Xcode's post-action or run manually after development

set -x

echo "PATH is: $PATH"
which jq
which xcrun

BUNDLE_ID="com.peterjemley.Bridget" # Use your actual bundle identifier

# Find all booted simulator UDIDs
JQ_PATH=$(which jq)
SIMULATOR_UDIDS=$(xcrun simctl list devices booted -j | $JQ_PATH -r '.devices[][] | .udid')

for UDID in $SIMULATOR_UDIDS; do
    echo "Uninstalling $BUNDLE_ID from booted simulator $UDID..."
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID"
done

echo "Bridget app deleted from all booted simulators." 
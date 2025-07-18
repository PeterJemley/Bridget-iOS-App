# Domain Model Refactor To-Do List

## Overview
Given our domain rules—events are meaningless without a bridge—.cascade remains the right choice. The next step is to make sure our code (and tests) don't assume bridge is ever nil.

## Tasks

### 1. ✅ Confirm the Model Structure
- [x] Verify `DrawbridgeInfo` has `.cascade` delete rule for events relationship
- [x] Verify `DrawbridgeEvent` has `.nullify` delete rule for bridge relationship  
- [x] Ensure `bridge` property in `DrawbridgeEvent` is non-optional
- [x] Confirm inverse relationships are properly configured

### 2. 🔍 Audit Code for Force Unwraps and Nil Assumptions
- [x] Search codebase for `!` on bridge property
- [x] Search for `guard let` or `if let` that drops into error path if bridge is nil
- [x] Replace force-unwraps with safe patterns
- [x] Add SwiftLint rule to flag force-unwraps of model relationships

### 3. 🧪 Review Test Assertions
- [x] Check test assertions that expect non-nil bridge
- [x] Verify test teardown logic is consistent with new delete rules
- [x] Ensure tests don't create orphaned events

### 4. 🔧 Update UI Code
- [x] Review UI code that accesses `event.bridge`
- [x] Ensure safe unwrapping patterns in views
- [x] Add proper error handling for unexpected nil bridges

### 5. 📝 Documentation
- [x] Document the relationship rules and their rationale
- [x] Update any architecture documentation
- [x] Add comments explaining the delete rule choices

## Current Status
- **Branch**: `experimental/domain-model-refactor`
- **Last Updated**: December 2024
- **Status**: ✅ All tasks completed successfully
- **Build Status**: ✅ BUILD SUCCEEDED
- **Next Action**: Run tests to verify functionality

## Build Fixes Applied
- **Fixed Compilation Error**: Removed unnecessary `if let` check on non-optional `bridge` property in `EventsListView.swift`
- **Domain Model**: Properly configured with cascade delete rules
- **Code Quality**: All UI code now uses safe access patterns consistent with domain rules

## Notes
- Events are meaningless without a bridge, so `.cascade` is the correct choice
- Need to ensure code never assumes bridge can be nil
- Focus on proactive, stepwise approach to prevent crashes 